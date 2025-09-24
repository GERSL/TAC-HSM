function autoCOLD(folderpath_stack, folderpath_TACResults,folderpath_tsf, varargin)
%AUTOTAC Summary of this function goes here
%   Detailed explanation goes here
addpath('/home/kes20012/COLD_v2/CCD/');

if ~exist('folderpath_stack', 'var')
    folderpath_stack = pwd;
end

if ~exist('folderpath_TACResults', 'var')
    folderpath_TACResults = pwd;
end

if ~exist('folderpath_tsf', 'var')
    folderpath_TACResults = pwd;
end

p = inputParser;
addParameter(p,'task', 1); % 1st task
addParameter(p,'ntasks', 1); % single task to compute
addParameter(p,'msg', true); % not to display info


% addParameter(p,'composite_window', 'weekly'); % 1st task
% addParameter(p,'rolling_window', 48); % single task to compute
% addParameter(p,'VI', 'NDVI'); % not to display info

% request user's input
parse(p,varargin{:});
task = p.Results.task;
ntasks = p.Results.ntasks;
msg = p.Results.msg;
% composite_window = p.Results.composite_window;
% rolling_window = p.Results.rolling_window;
% VI = p.Results.VI;


%% Define COLD Constants
B_detect = 1:4;   % B,G,R,NIR
conse = 6;
max_c = 8; % number of maximum coefficients
T_cg = 0.99;
Tmax_cg = 1-1e-5;


%% First, check the non-processed rows before parallel 
load(fullfile(folderpath_stack,'metadata.mat'));
rows = [];
for ir = 1: metadata.nrows
    filepath_rcg = fullfile(folderpath_TACResults, sprintf('record_change_r%05d.mat', ir)); % r: row
    if ~isfile(filepath_rcg)
        rows = [rows; ir];
%         if msg
%             fprintf('\nNo exist change results for row #%d\n', ir);
%         end
        
    end
end
% find the stackdata index that includs non-processed rows
ids = unique(ceil(rows/metadata.nsubrows));  
stackrows = dir(fullfile(folderpath_stack, 'R*'));
if ~isempty(ids) 
    stackrows = stackrows(ids);
end

%% Parallel tasks on the row datasats
num_stacks = length(stackrows);
tasks_per = ceil(num_stacks/ntasks);
start_i = (task-1)*tasks_per + 1;
end_i = min(task*tasks_per, num_stacks);

%% Locate to a certain task, one task for one row folder
for i_task = start_i:end_i
% for i_task = 17
    %% according to the name of stacking row dataset, the rows # at start and
    % end can be known well.
    foldername_stackrows = stackrows(i_task).name;
    % name format: R xxxxx xxxxx
    row_start = str2num(foldername_stackrows(2:6));
    row_end = str2num(foldername_stackrows(7:11));
    rows = row_start: row_end;
    folderpath_stackrows = fullfile(folderpath_stack, foldername_stackrows);
    

    %% load metadata.mat for having the basic info of the dataset that is in proccess
    load(fullfile(folderpath_stackrows, 'metadata.mat'));
    
    %% report log of TAC only for the first first task
    % if task == 1 && i_task == 1
    %     reportLog(folderpath_cold, ntasks, folderpath_cold, metadata.nimages, landsatpath, T_cg, conse, max_c);
    % end

    %% for each row
    for ir = 1: length(rows)
        tic % start to count computing time
        if msg
            fprintf('\nProcessing row #%d at task# %d/%d\n', rows(ir), task, ntasks);
        end
        
        %% CCD
        [sdate, line_t] = readStackLineDataPS(folderpath_stackrows, metadata.ncols, metadata.nbands, rows(ir), []);
        [rec_cg,~,~] = TrendSeasonalFit_COLDLinePS(sdate, line_t, [], [], ...
            metadata.ncols, rows(ir), 1:metadata.ncols, ... % process each pixel vis columns
            T_cg, Tmax_cg, conse, max_c, metadata.nbands-1, B_detect);
        
        % save record of time series segments
        filepath_rcg = fullfile(folderpath_tsf, sprintf('record_change_r%05d.mat', rows(ir))); % r: row
        save([filepath_rcg, '.part'] ,'rec_cg'); % save as .part
        clear rec_cg;
        movefile([filepath_rcg, '.part'], filepath_rcg);  % and then rename it as normal format
        close all;

        if msg

            fprintf('ProcesingTimeSingleRow = %0.2f mins for row #%d with %d images\r\n', toc/60, rows(ir), metadata.nimages); 
        end
    end

end

end   % end of function

