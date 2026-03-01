function COLDTIF(folderpath_cold, varargin)
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
% if ~exist('folderpath_HLS', 'var')
%     folderpath_hls = pwd;
% end

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
addParameter(p,'delstack', false); % delete stack data or not
addParameter(p,'msg', true); % not to display info
addParameter(p,'sensorname',[]); % not to display info
addParameter(p,'mask',true);
addParameter(p,'doTIF',true);

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
mask = p.Results.mask;
doTIF = p.Results.doTIF;

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

%% set paths and folders (run COLDTIF directly)
% folderpath_cold = '/shared/cn450/Kexin/COLDTIFResults/18TXM/';
% 

% if singlepath
%     folderpath_stack = fullfile(folderpath_cold,'StackDataSingleOrbit');
%     folderpath_tsf = fullfile(folderpath_cold, 'TSFitLineSingle');
if doTIF
    folderpath_stack = fullfile(folderpath_cold, 'TimeSeriesPerPixel_t=1day_robustfit');
    folderpath_tsf = fullfile(folderpath_cold, 'TSFitLine_t=1day_robustfit');
else
    folderpath_stack = fullfile(folderpath_cold, 'TimeSeriesPerPixel_noTIF');
    folderpath_tsf = fullfile(folderpath_cold, 'TSFitLine_noTIF');
end

% make TSFitLine folder for storing coefficients of Time Series Fitting
if ~isfolder(folderpath_tsf)
    mkdir(folderpath_tsf);
end

%% Read mask image
if mask
    folderpath_mask = fullfile(folderpath_cold,'MaskImage');
    mask = dir(fullfile(folderpath_mask,'*.tif'));
    mask = readgeoraster(fullfile(mask(1).folder,mask(1).name));
    [rows,cols] = find(mask==0);
%     [rows,cols] = find(mask==1);
    clear mask;
    ROWs = unique(rows);
    COLs = unique(cols);
else
    ROWs = 1:10980;
    COLs = 1:10980;
end

%% Parallel tasks on the row datasats
% skx: First, check the non-processed rows before parallel 
rows = [];
% % for ir = 1: 10980
for ir = 1:length(ROWs)
    filepath_rcg = fullfile(folderpath_tsf, sprintf('record_change_r%05d.mat', ROWs(ir))); % r: row
    
    if ~isfile(filepath_rcg)
        rows = [rows; ir];
%         if msg
%             fprintf('\nNo exist change results for row #%d\n', ir);
%         end
        
    end
end
% find the stackdata index that includs non-processed rows
stackrows = dir(fullfile(folderpath_stack, 'line_t_r*.mat'));
if ~isempty(rows) 
    stackrows = stackrows(rows);
    fprintf('number of unprocessed lines %d  \n',length(stackrows));
else 
    fprintf('ALL FINISHED \n');
    return;
end

num_stacks = length(stackrows);
tasks_per = ceil(num_stacks/ntasks);
start_i = (task-1)*tasks_per + 1;
end_i = min(task*tasks_per, num_stacks);

%% Locate to a certain task, one task for one row folder
for i_task = start_i:end_i
    %% according to the name of stacking row dataset, the rows # at start and
    % end can be known well.
    foldername_stackrows = stackrows(i_task).name;
    rows = str2num(foldername_stackrows(9:13));
    % name format: R xxxxx xxxxx
%     row_start = str2num(foldername_stackrows(2:6));
%     row_end = str2num(foldername_stackrows(7:11));
%     rows = row_start: row_end;
    folderpath_stackrows = fullfile(folderpath_stack, foldername_stackrows);
   
    %% load metadata.mat for having the basic info of the dataset that is in proccess
%     load(fullfile(folderpath_stackrows, 'metadata.mat'));
    
    %% report log of CCD only for the first first task
    if task == 1 && i_task == 1
        nimages = 1; % not the real value
        reportLog(folderpath_cold, ntasks, folderpath_cold, nimages, landsatpath, T_cg, conse, max_c);
    end

    %% for each row, CCD
    for ir = 1: length(rows)
        tic % start to count computing time
        if msg
            fprintf('\nProcessing row #%d at task# %d/%d\n', rows(ir), task, ntasks);
        end
        
%         %% find the row dataset within all the dataset (This is for
%         sdate/clrx intersection, we don't need this)
%         pt_row = rows(ir);
%         folderpath_stack_HLS = fullfile(folderpath_HLS, 'StackData10');
%         foldername_rowdata = [];
%         nsubrows = 10;
%         nrows = 3660;
%         for irow = 1: nsubrows: nrows % total of 5000 rows
%             % @ the current task, only parts of the images will be reconstructed
%             irow_end = min(irow + nsubrows -1, nrows);
%             if irow <= ceil(pt_row/3) && ceil(pt_row/3) <= irow_end
%                 foldername_rowdata = sprintf('R%05d%05d', irow, irow_end);
%                 break;
%             end
%         end
%         if isempty(foldername_rowdata)
%             if msg
%                 fprintf('No row dataset found\r\n');
%             end
%             return;
%         end
%         folderpath_stackrows_HLS = fullfile(folderpath_stack_HLS, foldername_rowdata);
    
%         %% read HLSv1.4 sdate 
%         ncols = 3660;
%         nbands = 7;
%         [sdate_HLS, line_t_HLS, ~] = readStackLineDataHLS(folderpath_stackrows_HLS, ncols, nbands, ceil(pt_row/3),[],{'HLS'});
    
        %% read sadate and line_t from .mat file
        load(fullfile(folderpath_stack,'sdate'));  % sdata_M
        load(folderpath_stackrows);                % line_t_M
%         %% Try 0: no intersection
%         load('sdate'); 
%         filepath_rcg =  sprintf('line_t_r%05d.mat', pt_row); % r:row c:col
%         load(filepath_rcg);
%         line_t_M = line_t_M(:,metadata.nbands*(pt_col-1)+1:metadata.nbands*(pt_col));
    
%         %% Try 1: set intersection based on two sdates
%         % This step is very important as only preocess the intersection of sdate_M and sdate_HLS to make sure
%         % the temporal density of two time series are the same 
%         [sdate,ia,ib] = intersect(sdate_M,sdate_HLS);  
%         line_t = line_t_M(ia,:);
% %         sensorgroup = sensorgroup(ib);
%         clear sdate_HLS;
%         clear sdate_M;
%         clear line_t_M;
%         
%         %% Try2: set intersection based on clrx
%         % This step is very important as only preocess the intersection of sdate_M and sdate_HLS to make sure
%         % the temporal density of two time series are the same 
%         rec_cg = [];
%         for icol = 1:length(COLs)
%             pt_col = COLs(icol);
% %             fprintf('10-m pixel %d/%d corresponds to HLS pixel row/col is %d/%d. \n',pt_row,pt_col,ceil(pt_row/3), ceil(pt_col/3));
%             [~, clrx_HLS, ~] = TrendSeasonalFit_COLDLineHLS(sdate_HLS, line_t_HLS, [], [], ...
%                 ncols, ceil(pt_row/3), ceil(pt_col/3), T_cg, Tmax_cg, conse, max_c, nbands, B_detect);
%             [sdate,ia,~] = intersect(sdate_M,clrx_HLS);   % sdate for CCD
%             line_t = line_t_M(ia,:);                      % line_t for CCD
% 
%             % ccd processing
%             ncols = 10980;
%             [rec_cg_M,~,~]= TrendSeasonalFit_COLDLineHLS(sdate, line_t, [], [], ...
%                 ncols, rows(ir), pt_col, ... % process each pixel vis columns  1:metadata.ncols,
%                 T_cg, Tmax_cg, conse, max_c, nbands, B_detect);
%             rec_cg = [rec_cg,rec_cg_M];
%         end
        ncols = 10980;
        nbands = 7;
        sdate = sdate_M;
        line_t = line_t_M;
        [rec_cg,~,~]= TrendSeasonalFit_COLDLineHLS(sdate, line_t, [], [], ...
            ncols, rows(ir), COLs, ... % process each pixel vis columns  1:metadata.ncols,
            T_cg, Tmax_cg, conse, max_c, nbands, B_detect);
        %% save record of time series segments
        filepath_rcg = fullfile(folderpath_tsf, sprintf('record_change_r%05d.mat', rows(ir))); % r: row
        save([filepath_rcg, '.part'] ,'rec_cg'); % save as .part
        clear rec_cg;
        clear line_t_HLS;
        clear sdate_HLS;
        clear sdate_M;
        clear line_t_M;
        movefile([filepath_rcg, '.part'], filepath_rcg);  % and then rename it as normal format
        close all;

        if msg
            fprintf('ProcesingTimeSingleRow = %0.2f mins for row #%d with %d images\r\n', toc/60, rows(ir), size(line_t,1)); 
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