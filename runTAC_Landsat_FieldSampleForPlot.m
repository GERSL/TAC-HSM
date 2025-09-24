function runTAC_Landsat_FieldSampleForPlot(varargin)
% ks 20250302: 1. correct the clear observation idx
%              2. add L57 & L89 surface refelctance adjustment coefficients
%
    % close all;

    warning('off','all')   
    addpath(fullfile(pwd),'TAC');

    directory = '/gpfs/sharedfs1/zhulab/SCRATCH/kes20012/ProjectTACValidation/';

    p = inputParser;
    addParameter(p,'task', 1);                     % 1st task
    addParameter(p,'ntasks', 1);                   % single task to compute

    addParameter(p,'do_harmo', true); 
    % addParameter(p,'do_harmo', false); 
    addParameter(p,'use_TACabs',false);

    % request user's input
    parse(p,varargin{:});
    task = p.Results.task;
    ntasks = p.Results.ntasks;
    do_harmo = p.Results.do_harmo;
    use_TACabs = p.Results.use_TACabs;

    % composite_interval = 'bimonthly';
    % composite_interval = 'monthly';
    composite_interval = 'biweekly';
    composite_interval = 'quarterly';
    sensor = 'Landsat';

    band_names = {'blue','green','red'...
        'nir','swir1','swir2'...
        'NDVI','kNDVI','NIRv'...
        'NBR','NDMI',...
        'EVI','EVI2'};
     scale  = 10000;

    %% load TIF coefficients
    TIFname = fullfile('/home/kes20012/ProjectTACValidation/L57_L89_Harmonization/TIFResults/TIF_coefficient_r00001c00001.mat');
    load(TIFname);

    %% define the TAC output folder
    % folderpath_TACResults = fullfile(directory,['TACResults_FieldSample_',datestr(now, 'yyyy-mm-dd')],[sensor,'_',composite_interval]);
   
    folderpath_TACResults = fullfile(directory,['TACResults_FieldSample_2025-03-05'],[sensor,'_',composite_interval]);
    if ~exist(folderpath_TACResults)
        mkdir(folderpath_TACResults);
    end

    %% load plotname from the hydraulic trait data
    filename = fullfile(directory,'Input','Sample_multipleInPlot_HPC.csv');
    T2 = readtable(filename);
    Lat = T2.sampleLat;
    Lon = T2.sampleLon;
    Plot_Ids = T2.sampleID;
    
    %% All Landsat surface reflectance files
    sr_files = dir(fullfile(directory,'LandsatData/SurfaceReflectance/','Sample_multipleInPlot_surface_reflectance_000001_000053.csv'));
    filename = fullfile(sr_files(1).folder,sr_files(1).name);
    T = readtable(filename);

    % %% Check unprocessed pixels before parallel
    % id_unprocessed = [];
    % for j = 1:length(Plot_Ids)
    %     id = Plot_Ids(j);
    %     filepath_TAC = dir(fullfile(folderpath_TACResults, sprintf('TAC_record_change_plot%05d.mat', id)));
    %     if isempty(filepath_TAC)
    %         id_unprocessed = [id_unprocessed;j];
    %     end
    % end
    % 
    % % exit if all pixels have been processed
    % if isempty(id_unprocessed)
    %     fprintf('\nFinished all sample points!\n');
    %     return;
    % else
    %     Plot_Ids = Plot_Ids(id_unprocessed);
    % end

    %% Assign job for each task 
    num_pixels = length(Plot_Ids);
    tasks_per = ceil(num_pixels/ntasks);
    start_i = (task-1)*tasks_per + 1;
    end_i = min(task*tasks_per, num_pixels);
    fprintf('Need %d cores for optimal use.\n',num_pixels);

    %% Parallel starts here ...
    %  Locate to a certain task, one task for one S2 row folder
    for i_task = start_i:end_i
    % for i_task = 42
        id = Plot_Ids(i_task);
        
        %% load Landsat Time Series 
        % Filter the data for the current plotid
        plot_data = T(T.plotid == id, :);  
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
        plot_data = plot_data(valid_id,:);   % TO DO: test the QA

        % figure('Name','NIR');
        % set(gcf,'Position',[100,100,600,300]);
        % plot(plot_data.date,plot_data.nir,'k.','DisplayName','all');
    
        % convert year doy to datetime and add to 'plot_data'
        year = plot_data.year;
        doy = plot_data.doy;
        date = datetime(year, 1, 1) + days(doy - 1);
        plot_data.date = date;
    
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
            L57_dates = plot_data.date(L57_id);
            L89_dates = plot_data.date(L89_id);

            for iband = 1:length(band_names)
                band_name = band_names{iband};
                % read harmonization coefficients
                a = TIF_coefficient.Slopes(iband);
                b = TIF_coefficient.Intercepts(iband);

                data = plot_data.(band_name);
                harmonized_data = data(L57_id)*a+(b./scale);
                plot_data.(band_name)(L57_id) = harmonized_data;
                
                % figure('Name',band_name);
                % set(gcf,"Position",[100,200,1000,300]);
                % plot(L57_dates,data(L57_id),'bo','DisplayName','L57');
                % hold on
                % plot(L89_dates,data(L89_id),'md','DisplayName','L89');
                % hold on
                % % plot(L57_dates,harmonized_data,'kd','DisplayName','harmonized L57');
                % ylim([0.2,0.8])
                % legend('Location','best');
                
            end
        end
            
        %% run TAC
        TAC_record_change = autoTAC_sample(sensor,plot_data,'composite_interval',{composite_interval},...
            'VI',{'NDVI','kNDVI','NIRv','NBR','NDMI','EVI','EVI2'},...
            'rm_outliers',1,'plot_id',id,'plot_lat',lat,'plot_lon',lon,'plot_name',...
            'test','savefig',true,'doplot',true,'plot_VI','EVI2');         
        
        %% Save results
        filepath_rcg = fullfile(folderpath_TACResults, sprintf('TAC_record_change_plot%05d.mat', id)); % r: row
        save([filepath_rcg, '.part'] ,'TAC_record_change'); % save as .part
        movefile([filepath_rcg, '.part'], filepath_rcg);  % and then rename it as normal format
          
        fprintf('Processing %.2f%%..\n',i_task/length(Plot_Ids)*100);
        close all;
        
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