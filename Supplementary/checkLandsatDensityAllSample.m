function checkLandsatDensityAllSample(varargin)
%%-----------------------------------------------------
%
%
% ks 20250227: 1. Correct the clear observation idx.
%              2. Add L57 & L89 surface refelctance adjustment
%              coefficients.
% ks 20250305: Convert QA to fmask.
% ks 20250727: 1. Use the brdf corrected L57 & L89 adjustment coefficients
%              2. Remove L7 observations after L9 data is available (2021.10.31).
%                   2000-2013: L5 and L7
%                   2013-2021: L7 and L8
%                   2022 onwards: L8 and L9
%
%%-----------------------------------------------------
    % close all;

    warning('off','all')   
    addpath('/home/kes20012/ProjectTACValidation/TAC');

    directory = '/gpfs/sharedfs1/zhulab/Kexin/ProjectTACValidation/';

    p = inputParser;
    addParameter(p,'task', 1);                     % 1st task
    addParameter(p,'ntasks', 1);                   % single task to compute

    addParameter(p,'do_harmo', true); 
    addParameter(p,'use_TACabs',false);
    addParameter(p,'remove_outliers',true);
    addParameter(p,'composite_interval','quarterly');

    % request user's input
    parse(p,varargin{:});
    task = p.Results.task;
    ntasks = p.Results.ntasks;

    do_harmo = p.Results.do_harmo;
    use_TACabs = p.Results.use_TACabs;
    remove_outliers = p.Results.remove_outliers;
    composite_interval = p.Results.composite_interval;

    % composite_interval = 'bimonthly';
    sensor = 'Landsat';
    band_names = {'blue','green','red'...
        'nir','swir1','swir2'...
        'NDVI','kNDVI','NIRv'...
        'NBR','NDMI',...
        'EVI','EVI2'};
    scale = 10000;
    l9_acq_date = datetime('2021-10-31');

    %% define the TAC output folder
    folderpath_DensityResults = fullfile(directory,[sensor,'_density_',composite_interval]);
    if ~exist(folderpath_DensityResults)
        mkdir(folderpath_DensityResults);
    end

    %% load TIF coefficients
    TIFname = fullfile('/home/kes20012/ProjectTACValidation/L57_L89_Harmonization/TIFResults/TIFbrdf_coefficient_r00001c00001.mat');
    load(TIFname);

    %% load input data
    % filename = fullfile(directory,'Input_backup','random_samples_4184.csv');
    filename = fullfile(directory,'Input_backup','random_forest_input_4184.csv');%samples_4184.csv');
    T2 = readtable(filename);
    FC = T2.fc;
    % filter forest pixels (forest cover >=10%)
    forest_pixel = FC>=10;  
    T2 = T2(forest_pixel,:);
    Lat = T2.sampleLat;
    Lon = T2.sampleLon;
    Plot_Ids = T2.sampleID;
    
    %% All Landsat surface reflectance files
    sr_files = dir(fullfile(directory,'LandsatData/SurfaceReflectanceAnglesBRDF/','random_samples_10000_surface_reflectance_*.csv'));
    
    %% Check unprocessed pixels before parallel
    id_unprocessed = [];
    for j = 1:length(Plot_Ids)
        id = Plot_Ids(j);
        filepath_TAC = dir(fullfile(folderpath_DensityResults, sprintf('Landsat_density_plot%05d.mat', id)));
        if isempty(filepath_TAC)
            id_unprocessed = [id_unprocessed;j];
        end
    end

    % exit if all pixels have been processed
    if isempty(id_unprocessed)
        fprintf('\nFinished all sample points!\n');
        return;
    else
        Plot_Ids = Plot_Ids(id_unprocessed);
    end

    %% Assign job for each task 
    num_pixels = length(Plot_Ids);
    tasks_per = ceil(num_pixels/ntasks);
    start_i = (task-1)*tasks_per + 1;
    end_i = min(task*tasks_per, num_pixels);
    fprintf('Need %d cores for optimal use.\n',num_pixels);

    %% Parallel starts here ...
    %  Locate to a certain task, one task for one S2 row folder
    for i_task = start_i:end_i
        id = Plot_Ids(i_task);
        FC = T2.fc;
        fc = FC(T2.sampleID==id);
    
        % Only process forest pixels
        if fc<10
            fprintf('Not forest pixel. Skip #%d..\n',id);
            continue;
        else
            
            %% load Landsat Time Series
            idx = ceil(id/100);   % each sr_file contains 100 plots.
            filename = fullfile(sr_files(idx).folder,sr_files(idx).name);
            T = readtable(filename);
    
            % Filter the data for the current plotid
            plot_data = T(T.plotid == id, :);  
            if isempty(plot_data)
                % fprintf('No Landsat data for plot %d.\n',id);
                continue;  % if there's no corresponding Landsat data for the forest plot
            end
            lat = Lat(i_task);
            lon = Lon(i_task);

            % fillter clear observations
            % see details at https://developers.google.com/earth-engine/datasets/catalog/LANDSAT_LC08_C02_T2_L2#bands
            cfmask = convertQA2Fmask(plot_data.qa_pixel);
            plot_data.fmask = cfmask;
            % filter out good observations based on physical range
            good_id = plot_data.blue>0 & plot_data.blue<1 &...
                plot_data.green>0 & plot_data.green<1 &...
                plot_data.red>0 & plot_data.red<1 &...
                plot_data.nir>0 & plot_data.nir<1 &...
                plot_data.swir1>0 & plot_data.swir1<1 &...
                plot_data.swir2>0 & plot_data.swir2<1;
            valid_id = good_id & cfmask<=1;  
            plot_data = plot_data(valid_id,:);
        
            % convert year doy to datetime and add to 'plot_data'
            year = plot_data.year;
            doy = plot_data.doy;
            date = datetime(year, 1, 1) + days(doy - 1);
            plot_data.date = date;

            % remote L7 data after the acquisition date of L9
            % create a logical index for rows to remove
            rowsToRemove = strcmp(plot_data.sensor, 'LE07') & plot_data.date > l9_acq_date;
            % Remove the rows
            plot_data(rowsToRemove, :) = [];
        
            % 7 VIs to test
            % normalized difference vegetation index (NDVI)
            plot_data.NDVI = (plot_data.nir - plot_data.red)./(plot_data.nir + plot_data.red);
            % kernal NDVI (kNDVI)
            plot_data.kNDVI = tanh((plot_data.NDVI).^2);
            % NIR reflectance of vegetation (NIRv)
            plot_data.NIRv = (plot_data.NDVI-0.08).*plot_data.nir;   % source:https://www.science.org/doi/full/10.1126/sciadv.1602244
            % normalized burn ratio (NBR)
            plot_data.NBR = (plot_data.nir - plot_data.swir2)./(plot_data.nir + plot_data.swir2);
            % normalized difference moisture index (NDMI)
            plot_data.NDMI = (plot_data.nir - plot_data.swir1)./(plot_data.nir + plot_data.swir1);
            % enhanced vegetation index (EVI)
            plot_data.EVI = 2.5*(plot_data.nir - plot_data.red)./(plot_data.nir + 6*plot_data.red - 7.5*plot_data.blue + 1);
            % enhanced vegetation index 2 (EVI2)
            plot_data.EVI2 = 2.5*(plot_data.nir - plot_data.red)./(plot_data.nir + plot_data.red + 1);
        
            if do_harmo
                % harmonize L57 and L89 with TIF
                Lsensor = string(plot_data.sensor);
                L57_id = Lsensor=='LE07'|Lsensor=='LT05';
                L89_id = Lsensor=='LC09'|Lsensor=='LC08';
                % L57_dates = plot_data.date(L57_id);
                % L89_dates = plot_data.date(L89_id);

                for iband = 1:length(band_names)
                    band_name = band_names{iband};

                    % read harmonization coefficients
                    a = TIF_coefficient.Slopes(iband);
                    b = TIF_coefficient.Intercepts(iband);

                    data = plot_data.(band_name);%(L57_id);
                    harmonized_data = data(L57_id)*a+(b./scale);
                    plot_data.(band_name)(L57_id) = harmonized_data;
                    
                    % figure('Name',band_name);
                    % set(gcf,"Position",[-1000,200,800,300]);
                    % plot(L57_dates,data(L57_id),'r>');
                    % hold on
                    % plot(L89_dates,data(L89_id),'bo');
                    % hold on
                    % plot(L57_dates,harmonized_data,'k>')
                    % ylim([0,0.8])
                    
                end
            end
                
            % check plot_data again before running TAC
            if isempty(plot_data)
                % fprintf('No Landsat data for plot %d.\n',id);
               continue;  % if there's no corresponding Landsat data for the forest plot
            end
            %% run TAC
            TAC_record_change = autoTAC_sample(sensor,plot_data,'composite_interval',{composite_interval},...
                 'VI',{'NDVI','kNDVI','NIRv','NBR','NDMI','EVI','EVI2'},...
                 'rm_outliers',remove_outliers,'plot_id',id,'plot_lat',lat,'plot_lon',lon,...
                 'plot_name','test','savefig',false,'doplot',false,'plot_VI','EVI2');
            
            %% Calculate data density (the percentage of valid quarterly data within the 25 years)
            if ~isempty(TAC_record_change)
                data_count = TAC_record_change.(['TAC_',composite_interval]).data_count;

                % Logical vector: where are the zeros?
                isZero = (data_count == 0)';
                
                % Find run lengths of consecutive zeros
                d = diff([0 isZero 0]);       % detect starts (+1) and ends (−1)
                runStarts = find(d == 1);
                runEnds   = find(d == -1) - 1;
                runLengths = runEnds - runStarts + 1;
                
                % Count runs of different lengths
                n1 = sum(runLengths == 1);     % single 0
                n2 = sum(runLengths == 2);     % exactly two 0s in a row
                nMore = sum(runLengths > 2);   % more than two 0s in a row
    
                valid_data_pct = sum(data_count>0)./size(data_count,1);
                single_missing_pct = n1./size(data_count,1);
                double_missing_pct = n2./size(data_count,1);
                more_missing_pct = nMore./size(data_count,1);
    
                % fprintf('The percentage of valid data pct is %.3f%%\n',valid_data_pct*100);   
                % fprintf('The percentage of single missing data is %.3f%%\n',single_missing_pct*100);
                % fprintf('The percentage of double missing data in a row is %.3f%%\n',double_missing_pct*100);
                % fprintf('The percentage of more than two missing data in a row is %.3f%%\n',more_missing_pct*100);
                
                %% Save results
                filepath_rcg = fullfile(folderpath_DensityResults, sprintf('Landsat_density_plot%05d.mat', id)); % r: row
                save([filepath_rcg, '.part'] ,'valid_data_pct','single_missing_pct','double_missing_pct','more_missing_pct'); % save as .part
                movefile([filepath_rcg, '.part'], filepath_rcg);  % and then rename it as normal format
                
            end   % end of ~isempty
            fprintf('Processing %.2f%%..\n',i_task/length(Plot_Ids)*100);
        end
    end   % end of i_task

end   % end of function



function cfmask = convertQA2Fmask(qa)
    cfmask = qa;
    cfmask(bitget(qa,1) == 1) = 255; % Filled
    cfmask(bitget(qa,7) == 1) = 0; % Clear Land and Water [No Cloud & No Dialted Cloud]
    cfmask(bitget(qa,8) == 1) = 1; % Water
    cfmask(bitget(qa,5) == 1) = 2; % Cloud Shadow
    cfmask(bitget(qa,6) == 1) = 3; % Snow
    cfmask(bitget(qa,2) == 1) = 4; % Dilated Cloud
    cfmask(bitget(qa,4) == 1) = 4; % Cloud
end