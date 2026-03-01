function saveTimeSeries(varargin)
% Tis function add time series properties to samples for quicker loading.
%   The output of this script script should be saved as .mat file,
%   which can then be loaded in the 'samplesInterpretation'.


close all;
addpath(fullfile(pwd, 'CCD'));
addpath(fullfile(pwd, 'Validate'));

p = inputParser;
addParameter(p,'task', 1); % 1st task
addParameter(p,'ntasks', 1); % single task to compute
addParameter(p,'ARDTiles',[]);
addParameter(p,'sensor',[]);

% request user's input
parse(p,varargin{:});
task = p.Results.task;
ntasks = p.Results.ntasks;
ARDTiles = p.Results.ARDTiles;
ARDTiles = {ARDTiles};
sensor = p.Results.sensor;
sensor = {sensor};

for iARD = 1: length(ARDTiles)
    hv_name = ARDTiles{iARD};

    %% set input path here
    folderpath_cold = fullfile('/shared/cn451/Kexin/COLDHLSResults/',hv_name);
    folderpath_stack = fullfile(folderpath_cold, 'StackData');
    % folderpath_stack = fullfile(folderpath_cold, 'StackDataSingleOrbit');
    folderpath_samplets = fullfile(folderpath_cold,'SampleTSL30');
    if ~isfolder(folderpath_samplets)
        mkdir(folderpath_samplets);
    end
    msg =true;

    %% load samples here
    samplecsv = dir(fullfile('/shared/cn449/Kexin/Samples/',hv_name,'*samples*HLS.csv'));
    T = readtable(fullfile(samplecsv(1).folder,samplecsv(1).name));
    ID = table2array(T(:,1));
    rows = table2array(T(:,2));
    cols = table2array(T(:,3));
    clear T

    %% load metadata.mat for having the basic info of the dataset that is in proccess
    load(fullfile(folderpath_cold, 'metadata.mat'));
    
    total_num = length(ID);
    tasks_per = ceil(total_num/ntasks);
    start_i = (task-1)*tasks_per + 1;
    end_i = min(task*tasks_per, total_num);

    %% Loop strarts here, total number of points is ...
    for i = start_i:end_i

    % for i = 1
    % for i = 1:length(ID)
        tic

        pt_row = rows(i);
        pt_col = cols(i);

        %% find the row dataset within all the dataset
        foldername_rowdata = [];
        for irow = 1: metadata.nsubrows: metadata.nrows % total of 5000 rows
            % @ the current task, only parts of the images will be reconstructed
            irow_end = min(irow + metadata.nsubrows -1, metadata.nrows);
            if irow <= pt_row && pt_row <= irow_end
                foldername_rowdata = sprintf('R%05d%05d', irow, irow_end);
                break;
            end
        end
        if isempty(foldername_rowdata)
            if msg
                fprintf('No row dataset found\r\n');
            end
            return;
        end
        folderpath_stackrows = fullfile(folderpath_stack, foldername_rowdata);
        % read sample time series from stackrows
        [sdate, line_t] = readStackLineDataSample(folderpath_stackrows, metadata.ncols, metadata.nbands, pt_row, pt_col, [],sensor{1});
    %     [sdate, line_t] = readStackLineDataSample(folderpath_stackrows, 3660, 7, pt_row, pt_col, []);

        %% Export sdate and line_t to .mat file
        if i ==1
            filepath_sdate = fullfile(folderpath_samplets,'sdate.mat');
            save(filepath_sdate,'sdate');
        end
        % save time series 
        filepath_linet = fullfile(folderpath_samplets, sprintf('line_t_r%05dc%05d.mat', pt_row,pt_col)); % r:row c:col
        save([filepath_linet, '.part'] ,'line_t'); % save as .part
        clear line_t;
        movefile([filepath_linet, '.part'], filepath_linet);  % and then rename it as normal format
        close all;

        if msg
    %         fprintf('ExportingTimeSingleRowCol = %0.2f mins for row/col %d/%d with %d images\r\n', toc/60, pt_row, pt_col, metadata.nimages); 
            fprintf('ExportingTimeSingleRowCol = %0.2f mins for row/col %d/%d\r\n', toc/60, pt_row, pt_col); 
        end
    end
end
end


