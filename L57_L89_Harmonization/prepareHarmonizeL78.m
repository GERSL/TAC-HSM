function prepareHarmonizeL78(varargin)
%HARMONIZEL78 Summary of this function goes here

% ks 20250305: convert the QA to cfmask
% ks 20250727: update the selected table columns for the output  
    close all;
    warning('off','all')   

    directory = '/gpfs/sharedfs1/zhulab/Kexin/ProjectTACValidation/';

    p = inputParser;
    addParameter(p,'task', 1);                     % 1st task
    addParameter(p,'ntasks', 1);                   % single task to compute
    addParameter(p,'VI','EVI2');

    % request user's input
    parse(p,varargin{:});
    task = p.Results.task;
    ntasks = p.Results.ntasks;
    VI = p.Results.VI;
   
    sensor = 'Landsat';

    %% define the output folder
    folderpath_L78 = fullfile(directory,'TIFL78BRDFData');
    if ~exist(folderpath_L78)
        mkdir(folderpath_L78);
    end
    % folderpath_TIFResults = fullfile(directory,['TIFResults_',datestr(now, 'yyyy-mm-dd')]);
    % if ~exist(folderpath_TIFResults)
    %     mkdir(folderpath_TIFResults);
    % end

    %% All Landsat surface reflectance files
    sr_files = dir(fullfile(directory,'LandsatData/SurfaceReflectanceAnglesBRDF/','random_samples_10000_*.csv'));
    
    % %% Check unprocessed files before parallel (optiaonal)
    % id_unprocessed = [];
    % for j = 1:length(sr_files)
    % 
    %     filepath_L78 = dir(fullfile(folderpath_L78, sprintf('L57_L89_data_%05d.mat', j)));
    %     if isempty(filepath_L78)
    %         id_unprocessed = [id_unprocessed;j];
    %     end
    % end
    % 
    % % exit if all pixels have been processed
    % if isempty(id_unprocessed)
    %     fprintf('\nFinished all files!\n');
    %     return;
    % else
    %     sr_files = sr_files(id_unprocessed);
    % end

    %% Assign job for each task 
    num_files = length(sr_files);
    tasks_per = ceil(num_files/ntasks);
    start_i = (task-1)*tasks_per + 1;
    end_i = min(task*tasks_per, num_files);
    fprintf('Need %d cores for optimal use.\n',num_files);

    %% Parallel starts here ...
    %  Locate to a certain task, one task for one S2 row folder
    for i_task = start_i:end_i
        data_struct = [];
        filename = sr_files(i_task).name;    
        matches = regexp(filename, '_([0-9]{6})_([0-9]{6})_', 'tokens');
        endNum = str2double(matches{1}{2});
        index = round(endNum/100);

        T = readtable(fullfile(sr_files(i_task).folder,filename));

        plots = unique(T.plotid);
        % Loop by plots
        for i = 1:length(plots)
            id = plots(i);

            % Filter the data for the current plotid
            plot_data = T(T.plotid == id, :); 

            % convert year doy to datetime and add to 'plot_data'
            year = plot_data.year;
            doy = plot_data.doy;
            date = datetime(year, 1, 1) + days(doy - 1);
            plot_data.date = date;

            % figure()
            % set(gcf,'Position',[-1000 100 800 400]);
            % plot(plot_data.date,plot_data.nir,'ko','MarkerSize',4,'MarkerFaceColor','k','DisplayName','all');
            % hold on

            % fillter clear observations
            % see details at https://developers.google.com/earth-engine/datasets/catalog/LANDSAT_LC08_C02_T2_L2#bands
            cfmask = convertQA2Fmask(plot_data.qa_pixel);
            good_id = plot_data.blue>0 & plot_data.blue<1 &...
                plot_data.green>0 & plot_data.green<1 &...
                plot_data.red>0 & plot_data.red<1 &...
                plot_data.nir>0 & plot_data.nir<1 &...
                plot_data.swir1>0 & plot_data.swir1<1 &...
                plot_data.swir2>0 & plot_data.swir2<1;
            valid_id = cfmask<=1 & good_id;
            % plot_data_01 = plot_data(clear_id & good_id,:); % just for visulization           
            % plot_data_02 = plot_data(cfmask<=1,:);
            plot_data = plot_data(valid_id,:);


            % plot(plot_data_01.date,plot_data_01.nir,'m>','MarkerSize',6,'MarkerFaceColor','m','DisplayName','clear + other QA masked + physical range');
            % hold on;
            % % plot(plot_data_02.date,plot_data_02.nir,'k>','MarkerSize',6,'MarkerFaceColor','y','DisplayName','cfmask');
            % % hold on;
            % plot(plot_data.date,plot_data.nir,'y>','MarkerSize',5,'MarkerFaceColor','y','DisplayName','cfmask + physical range');
            % hold on;
            % 
            % 
            % legend('Location','best');
            % ylabel('NIR');
            % xlabel('Date');
            % title(sprintf('Point %s',num2str(id)));
            % set(gca,'FontSize',16);
            % set(gca,'FontName','Lucida');
            % saveas(gcf,sprintf('Point %s_cfmask.png',num2str(id)));

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
   
            % extract L57 and L89 observations
            sensor = string(plot_data.sensor);
            L57_id = sensor=='LE07'|sensor=='LT05';
            L89_id = sensor=='LC08'|sensor=='LC09';
            L57_dates = datenum(plot_data.date(L57_id)); % ks: fixed error 20250226
            L89_dates = datenum(plot_data.date(L89_id));
            % L57_data = plot_data(L57_id,[6:11,15:21]);
            % L89_data = plot_data(L89_id,[6:11,15:21]);
            L57_data = plot_data(L57_id,{'blue','green','red','nir','swir1','swir2','NDVI','kNDVI','NIRv','NBR','NDMI','EVI','EVI2'});
            L89_data = plot_data(L89_id,{'blue','green','red','nir','swir1','swir2','NDVI','kNDVI','NIRv','NBR','NDMI','EVI','EVI2'});

            % add to the data_struct
            data_struct(i).plot_id = id;
            data_struct(i).L57_dates = L57_dates;
            data_struct(i).L89_dates = L89_dates;
            data_struct(i).L57_data = L57_data;
            data_struct(i).L89_data = L89_data;

            % TIF_coefficient = runTIFSinglePixel(L89_dates,L89_data,L57_dates,L57_data,1,1,'t_threshold',8,'do_plot','true');
        end   % end of i = 1:length(plots)

        output_filename = fullfile(folderpath_L78, sprintf('L57_L89_data_%05d.mat', index));
        save(output_filename,"data_struct");
        fprintf('Processing %.2f%%.\n',i_task/num_files*100);
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