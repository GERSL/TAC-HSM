function adjustL57values(varargin)
%ADJUSTL57VALUES Summary of this function goes here
%   Detailed explanation goes here
% this function is not needed 


    close all;
    warning('off','all')   

    directory = '/gpfs/sharedfs1/zhulab/SCRATCH/kes20012/ProjectTACValidation/';

    p = inputParser;
    addParameter(p,'task', 1);                     % 1st task
    addParameter(p,'ntasks', 1);                   % single task to compute
    

    % request user's input
    parse(p,varargin{:});
    task = p.Results.task;
    ntasks = p.Results.ntasks;
    
   
    band_names = {'Blue','Green','Red'...
        'NIR','SWIR1','SWIR2'...
        'NDVI','kNDVI','NIRv'...
        'NBR','NDMI',...
        'EVI','EVI2'};
    scale = 10000;

    %% define the output folder
    folderpath_output = fullfile(directory,'Landsat/SurfaceReflectance_adjusted');
    if ~exist(folderpath_output)
        mkdir(folderpath_output);
    end
   
    %% All Landsat surface reflectance files
    sr_files = dir(fullfile(directory,'LandsatData/SurfaceReflectance/','random_samples_10000_surface_reflectance_*.csv'));
    
    %% Check unprocessed files before parallel
    id_unprocessed = [];
    for j = 1:length(sr_files)
        
        filepath_output = dir(fullfile(folderpath_output, sr_files(j).name));
        if isempty(filepath_output)
            id_unprocessed = [id_unprocessed;j];
        end
    end

    % exit if all pixels have been processed
    if isempty(id_unprocessed)
        fprintf('\nFinished all files!\n');
        return;
    else
        sr_files = sr_files(id_unprocessed);
    end

    %% Assign job for each task 
    num_files = length(sr_files);
    tasks_per = ceil(num_files/ntasks);
    start_i = (task-1)*tasks_per + 1;
    end_i = min(task*tasks_per, num_files);
    fprintf('Need %d cores for optimal use.\n',num_files);

    %% Parallel starts here ...
    %  Locate to a certain task, one task for one S2 row folder
    for i_task = start_i:end_i
        
        % load TIF coefficients
        TIFname = fullfile('/home/kes20012/ProjectTACValidation/L57_L89_Harmonization/TIFResults/TIF_coefficient_r00001c00001.mat');
        load(TIFname);

        % load surface reflectance data
        filename = sr_files(i_task).name;
        T = readtable(fullfile(sr_files(i_task).folder,filename));

        % extract L57 data
        sensor = string(T.sensor);
        L57_id = sensor=='LE07'|sensor=='LT05';
        L57_data = T(L57_id,[6:11]);

        for iband = 1:length(band_names)

            % read harmonization coefficients
            a = TIF_coefficient.Slopes(iband);
            b = TIF_coefficient.Intercepts(iband);

            % adjust L57 data for each band
            L57_data(:,iband) = L57_data(:,iband).*a+(b./scale);
        end
        T(L57_id,[6:11,15:21]) = L57_data;
        
        filename_out = fullfile(folderpath_output,sr_files(j).name);
        writetable(T,filename_out)
        fprintf('Processing %.2f%%.\n',i_task/num_files*100);
    end   % end of i_task
end   % end of function


