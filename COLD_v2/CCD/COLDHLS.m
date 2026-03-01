function COLDHLS(folderpath_cold, varargin)
%COLD This function is to detect changes using the COLD algorithem based on
%the inputs created by funtion <stackLandsatARD2Line>.
% Create the record of the rows that have not been processed yet before parallel.
%
% INPUT:
%
%   folderpath_cold:        Locate to COLD working folder, in which the
%                           metadata (metadata.mat) and the stacking folder
%                           <StackData> are necessery, and if single path
%                           Landsat will used, the single path layer
%                           (singlepath_landsat.tif) is also requried. All
%                           those can be generated using the function
%                           <stackLandsatARD2Line>
%
%   orbitpath (optional):   Orbit path of Landsat ('single' or 'all').
%                           'single' means change will be identified based
%                           on the single Landsat path layer with geotiff
%                           format. 'all' means not to do that. (default
%                           value: single)
%
%   onceread (optional):    To load all the time series data once time. It
%                           is recommended to set as true, if enough
%                           computer memory available. This will benefit
%                           the efficiency of I/O. For instance, to process
%                           a stacked row dataset with 10 rows by 5000
%                           columns by 8 bands by 2000 images, with uint16
%                           format, more 1.5 G memory (1,600,000,000 bytes)
%                           is required. Usually, we do not to set this as
%                           true in UCONN HPC because of the memory
%                           limitation. (default value is false)
%
%   delstack (optional):    To delete the stack row folder once change
%                           detection done. (default value is true)
%
%   cprob (optional):       Change probability threshold (default value is 0.99)
% 
%   conse (optional):       Number of consecutive observations (default value is 6)
% 
%   maxc (optional):        Maximum number of coefficients used (default value is 6)
%
%   task (optional):        Task ID of parallel computation
%
%   ntasks (optional):      Total number of tasks of parallel computation
%
%   msg (optional)          [false/true] Display processing status (default
%                           value: false)
%
%
%
% RETURN:
%
%   null
%
% REFERENCE(S):
%
%   Zhu, Zhe, et al. "Continuous monitoring of land disturbance based on
%   Landsat time series." Remote Sensing of Environment 238 (2020): 111116.
%
% EXAMPLE OF USE:
%
%   > To detect change using COLD version 2 with single path Landsat data at task # 1/20
%
%     COLD('/lustre/scratch/qiu25856/TestGERSToolbox/h029v005/', ...
%         'onceread', true, 'msg', true, ...
%         'task', 1 ,'ntasks', 20)
% 
% AUTHOR(s): Zhe Zhu and Shi Qiu
% DATE: Feb. 6, 2021
% COPYRIGHT @ GERSLab


%% Have user's inputs
% requried

if ~exist('folderpath_cold', 'var')
    folderpath_cold = pwd;
end

% optional
p = inputParser;
% addParameter(p,'cprob', 0.99); % probability for detecting surface change
% 07/08/
% addParameter(p,'cprob', 0.95);
addParameter(p,'cprob',0.99);
% 07/07/2021 change conse from 6 to 4
addParameter(p,'conse', 6); % number of consecutive observation
% addParameter(p,'conse', 4); % number of consecutive observation
addParameter(p,'maxc', 8); % number of maximum coefficients
addParameter(p,'onceread', false); % read the landsat data line by line, if enough memory, please set as true (optional)
% addParameter(p,'orbitpath', 'single'); % based on non-overlap landsat data
addParameter(p,'orbitpath', 'all'); % based on non-overlap landsat data
addParameter(p,'task', 1); % 1st task
addParameter(p,'ntasks', 1); % single task to compute
addParameter(p,'delstack', true); % delete stack data or not
addParameter(p,'msg', true); % not to display info
addParameter(p,'sensorname',[]); % not to display info
% request user's input
parse(p,varargin{:});

onceread = p.Results.onceread;
task = p.Results.task;
ntasks = p.Results.ntasks;
msg = p.Results.msg;
T_cg = p.Results.cprob;
conse = p.Results.conse;
max_c = p.Results.maxc;
delstack =  p.Results.delstack;
sensorname = p.Results.sensorname;

% char will be better understood for users
switch lower(p.Results.orbitpath)
    case 'single'
        singlepath = true;
        landsatpath = 'Single';
    case 'all'
        singlepath = false;
        landsatpath = 'All';
end
    

%% add the matlab search path of GLMnet
% addpath(fullfile(fileparts(mfilename('fullpath')), 'GLMnet'));

%% Constants:
% Bands for detection change
B_detect = 2:6;      % Landsat bands (HLS)
% Treshold of noisercg_new
Tmax_cg = 1-1e-5;

%% set paths and folders
% folderpath_cold = '/lustre/scratch/qiu25856/TestGERSToolbox/h029v005/';
% msg = true;
% singlepath = false;
% landsatpath = 'All';
% folderpath_cold = '/scratch/kes20012/COLDResults/T18TXL/';

if singlepath
    folderpath_stack = fullfile(folderpath_cold,'StackDataSingleOrbit');
    folderpath_tsf = fullfile(folderpath_cold, 'TSFitLineSingle');
else
    folderpath_stack = fullfile(folderpath_cold, 'StackData1');
    folderpath_tsf = fullfile(folderpath_cold, 'TSFitLine');
end

% make TSFitLine folder for storing coefficients of Time Series Fitting
if ~isfolder(folderpath_tsf)
    mkdir(folderpath_tsf);
end


%% Parallel tasks on the row datasats
% skx: First, check the non-processed rows before parallel 
rows = [];
ids = [];
for ir = 1: 3660
    filepath_rcg = fullfile(folderpath_tsf, sprintf('record_change_r%05d.mat', ir)); % r: row
    if ~isfile(filepath_rcg)
        rows = [rows; ir];
%         if msg
%             fprintf('\nNo exist change results for row #%d\n', ir);
%         end
        
    end
end
% find the stackdata index that includs non-processed rows
% ids = unique(ceil(rows/10));   % HLS
ids = unique(rows/10);   % HLS
stackrows = dir(fullfile(folderpath_stack, 'R*'));
if ~isempty(ids) 
    stackrows = stackrows(ids);
    fprintf('\nNeed #%d cores for optimal use.\n', length(ids));
end

% %% add mask manually
% ROWs = 1773:1840;
% COLs = 2378:2445;
% ids = unique(ceil(ROWs/10));
% stackrows = stackrows(ids);

num_stacks = length(stackrows);
tasks_per = ceil(num_stacks/ntasks);
start_i = (task-1)*tasks_per + 1;
end_i = min(task*tasks_per, num_stacks);

%% Locate to a certain task, one task for one row folder
for i_task = start_i:end_i
    %% according to the name of stacking row dataset, the rows # at start and
    % end can be known well.
    foldername_stackrows = stackrows(i_task).name;
    % name format: R xxxxx xxxxx
    row_start = str2num(foldername_stackrows(2:6));
    row_end = str2num(foldername_stackrows(7:11));
    rows = row_start: row_end;
    folderpath_stackrows = fullfile(folderpath_stack, foldername_stackrows);
    
%     %% check exsiting record files, and remain the id of the rows that have no results
%     ids_more = [];
%     for ir = 1: length(rows)
%         filepath_rcg = fullfile(folderpath_tsf, sprintf('record_change_r%05d.mat', rows(ir))); % r: row
%         if isfile(filepath_rcg)
%             ids_more = [ids_more; ir];
%             if msg
%                 fprintf('\nAlready exist change results for row #%d\n', rows(ir));
%             end
%             continue;
%         end
%     end
%     rows(ids_more) = [];
%     
%     % if all the rows at current task are well done, just skip to next
%     % process
%     if isempty(rows)
%         continue;
%     end
    
    %% load metadata.mat for having the basic info of the dataset that is in proccess
    load(fullfile(folderpath_stackrows, 'metadata.mat'));
    
    %% report log of CCD only for the first first task
    if task == 1 && i_task == 1
        reportLog(folderpath_cold, ntasks, folderpath_cold, metadata.nimages, landsatpath, T_cg, conse, max_c);
    end
    
%     %% read single path Landsat data, we don't need this 
%     if singlepath
%         singlepathlayer = imread(fullfile(folderpath_stackrows, 'singlepath_landsat.tif'));
%         singlepathlayer = singlepathlayer(rows,:); % only sub rows for lowing memery
%     end
%     
    %% read all the time series data ahead of time if enough memory
    if onceread
        %     For instance, to process a stacked row dataset with 10 rows by 5000
        %     columns by 8 bands by 2000 images, with uint16 format, more 1.5 G
        %     memory (1,600,000,000 bytes) is required
        %     1) 10 rows by 5000 pixels by 1300 images will need 1 G mememory
        %     2) 10 rows by 5000 pixels by 2600 images will need 2 G mememory for
        %     the places that have very dense landsat data

        % ~8 secs for loading 2000 images; if single row, ~2 secs
        [sdate, line_t_all, path_t] = readStackLineDataHLS(folderpath_stackrows, metadata.ncols, metadata.nbands, rows, singlepathlayer,sensorname);
    end

    %% for each row, CCD
    for ir = 1: length(rows)
        tic % start to count computing time
        if msg
            fprintf('\nProcessing row #%d at task# %d/%d\n', rows(ir), task, ntasks);
        end

        %% based on HLS data, ...
        if onceread
            line_t = line_t_all(:,:,1);
            line_t_all(:,:,1) = []; % when loading successfully, empty the row data for saving memeory
        else
            % skx: check error
%           try
            [sdate, line_t] = readStackLineDataHLS(folderpath_stackrows, metadata.ncols, metadata.nbands, rows(ir), [],sensorname);
%           catch me
%                     fprintf('\nError readstackline #%d\n', rows(ir));
%                 end
        end
        % ccd processing - process each pixel vis columns
        rec_cg = TrendSeasonalFit_COLDLineHLS(sdate, line_t, [], [], ...
            metadata.ncols, rows(ir), 1:metadata.ncols, ... 
            T_cg, Tmax_cg, conse, max_c, metadata.nbands, B_detect);

        % test a single pixel
        % rec_cg = TrendSeasonalFit_COLDLineHLS(sdate, line_t, [], [], ...
        %     metadata.ncols, rows(ir), COLs, ... % process each pixel vis columns
        %     T_cg, Tmax_cg, conse, max_c, metadata.nbands, B_detect);
%         end
        
        %% save record of time series segments
        filepath_rcg = fullfile(folderpath_tsf, sprintf('record_change_r%05d.mat', rows(ir))); % r: row
        save([filepath_rcg, '.part'] ,'rec_cg'); % save as .part
        clear rec_cg;
        movefile([filepath_rcg, '.part'], filepath_rcg);  % and then rename it as normal format
        close all;
        
        if msg
            fprintf('ProcesingTimeSingleRow = %0.2f mins for row #%d with %d images\r\n', toc/60, rows(ir), metadata.nimages); 
        end
    end
    if delstack
        rmdir(folderpath_stackrows, 's');
        if msg
            fprintf('Finished deleting the stack row dataset %s\r\n', foldername_stackrows); 
        end
    end
end % end of all tasks

end % end of function 