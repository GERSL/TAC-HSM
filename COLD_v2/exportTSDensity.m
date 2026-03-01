function exportTSDensity(folderpath_cold,varargin)

%  This shows the time series density (number of non-zero & clear observations) for each pixel.
addpath('/home/kes20012/COLD_v2/CCD');

if ~exist('folderpath_cold', 'var')
    folderpath_cold = pwd;
end

p = inputParser;
addParameter(p,'task', 1); % 1st task
addParameter(p,'ntasks', 1); % single task to compute
% addParameter(p,'ARDTiles',[]);
addParameter(p,'msg', true); % not to display info

% request user's input
parse(p,varargin{:});
task = p.Results.task;
ntasks = p.Results.ntasks;
msg = p.Results.msg;
% ARDTiles = p.Results.ARDTiles;
% ARDTiles = {ARDTiles};

% or define here
% ARDTiles = {'18TYM'};
% task=1;
% ntask=549;

%% set inputs here
% yr = 2017;
% folderpath_cold = fullfile(globalsets.PathCOLDFusion, ARDTiles{1}); 
folderpath_cold = '/shared/cn450/Kexin/COLDS2Results/18TXM/';
% folderpath_stack = fullfile(folderpath_cold,'StackDataSingleOrbit');
folderpath_stack = fullfile(folderpath_cold,'StackData10');
folderpath_num = fullfile(folderpath_cold,'TSDensity');
if ~isfolder(folderpath_num)
    mkdir(folderpath_num)
end
mask = true;

%% Read mask image
if mask
    tilename = split(folderpath_cold,'/');
    tilename = char(tilename(end-1));
    folderpath_mask = fullfile(folderpath_cold,'MaskImage');
    mask = dir(fullfile(folderpath_mask,['T',tilename,'_Planet*.tif']));
    mask = readgeoraster(fullfile(mask(1).folder,mask(1).name));
    [rows,cols] = find(mask==0);
    %     [rows,cols] = find(mask==1);
    clear mask
    ROWs = unique(rows);
    COLs = unique(cols);
end

%% First, check the non-processed rows before parallel 
unprocessed_rows = [];
ids = [];
for ir = 1: length(ROWs)
    filepath_rcg = fullfile(folderpath_num, sprintf('TSDensity_r%05d.mat', ROWs(ir))); % r: row
    if ~isfile(filepath_rcg)
        unprocessed_rows = [unprocessed_rows; ROWs(ir)];
%         if msg
%             fprintf('\nNo exist change results for row #%d\n', ir);
%         end      
    end
end
% find the stackdata index that includs non-processed rows
ids = unique(ceil(unprocessed_rows/10));
stackrows = dir(fullfile(folderpath_stack, 'R*'));
if ~isempty(ids) 
    stackrows = stackrows(ids);
end
fprintf('Total of %d unprocessed stackrows.\n',length(stackrows));
% stackrows = dir(fullfile(folderpath_stack, 'R*'));
num_stacks = length(stackrows);
tasks_per = ceil(num_stacks/ntasks);
start_i = (task-1)*tasks_per + 1;
end_i = min(task*tasks_per, num_stacks);

%% Parallel starts here... Locate to a certain task, one task for one row folder
for i_task = start_i:end_i
    %% according to the name of stacking row dataset, the rows # at start and
    % end can be known well.
    foldername_stackrows = stackrows(i_task).name;
    % name format: R xxxxx xxxxx
    row_start = str2num(foldername_stackrows(2:6));
    row_end = str2num(foldername_stackrows(7:11));
    unprocessed_rows = row_start: row_end;
    folderpath_stackrows = fullfile(folderpath_stack, foldername_stackrows);
    
    %% load metadata.mat for having the basic info of the dataset that is in proccess
    load(fullfile(folderpath_stackrows, 'metadata.mat'));
        
    %% read stack data
    for ir = 1: length(unprocessed_rows)
        tic
        fprintf('\nProcessing row #%d at task# %d/%d\n', unprocessed_rows(ir), task, ntasks);
        [sdate, line_t] = readStackLineData(folderpath_stackrows, metadata.ncols, metadata.nbands, unprocessed_rows(ir), []);
        
        % extract years, fmask, and swir1
        years = year(datetime(sdate,'ConvertFrom','datenum'));
        fmask = line_t(:,11:11:end);
        swir1 = line_t(:,8:11:end);
        % filter non-zero observations in 2017
        num_nzeros = sum(swir1 > 0);
%         num_nzeros = sum(swir1 > 0 & years==yr);
        % filter clear observations in 2017
        num_good = sum(swir1 >0 & fmask<2);
%         num_good = sum(swir1 >0 & fmask<2 & years==yr);
        clear line_t;
        clear sdate;
        
        %% save records
        filepath_num = fullfile(folderpath_num, sprintf('TSDensity_r%05d.mat', unprocessed_rows(ir))); % r: row
        save(filepath_num,'num_good'); % save as .part
        clear num_good;
%         movefile([filepath_num, '.part'], filepath_num);  % and then rename it as normal format
        close all;
        toc
        if msg
            fprintf('ExportTimeSingleDensity = %0.2f mins for row #%d with %d images\r\n', toc/60, unprocessed_rows(ir), metadata.nimages); 
        end
    end
end
end

