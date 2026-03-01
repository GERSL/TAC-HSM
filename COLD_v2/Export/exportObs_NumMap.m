function exportChangeMap(folderpath_cold, years, varargin)
% EXPORTCHANGEMAP This is to export the change map based on the COLD
% results.
%
% INPUT:
%
%   folderpath_cold:        Locate to COLD working folder, in which the
%                           change folder <TSFitLine> is necessery, and
%                           this folder was created by <COLD.m>.
%
%   years:                  [Array] The years of change map. 
%
%   ctype (optional):       [false/true] Export the change type or not.
%
%   msg (optional):         [false/true] Display processing status (default
%                           value: false)
%
% OUTPUT:
%
% changemap_typedoy_yyyy.tif in folder <ChangeMap> (yyyy means the year)
% uint16
% pixel value: xdoy (x indicates the type of change, and doy indicates DOY) 
% x's range is between 1 to 3
% 1 => regrowth break
% 2 => aforestation break
% 3 => land disturbance
%
% i.e., 1002 means the regrowth break occurred in the 2nd day
%
%
% REFERENCE(S):
%
%   Zhu, Zhe, et al. "Continuous monitoring of land disturbance based on
%   Landsat time series." Remote Sensing of Environment 238 (2020): 111116.
%
% EXAMPLE OF USE:
%
%   > To export change maps between 1985 and 2019 (without labling change type).
%
%     exportChangeMap('/lustre/scratch/qiu25856/TestGERSToolbox/h029v005/',
%     [1985:2019])
% 
% AUTHOR(s): Zhe Zhu and Shi Qiu
% DATE: Feb. 7, 2021
% COPYRIGHT @ GERSLab
%
% Also see labelDisturbanceType.m

addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'GRIDobj'));

if ~exist('folderpath_cold', 'var')
%     folderpath_cold = '/scratch/kes20012/COLDResults/T18TXL/';
%     folderpath_cold = '/scratch/kes20012/COLDFusionResults/18TYM/';
    folderpath_cold = '/shared/cn451/Kexin/COLDHLSResults/18TYM/';
%     folderpath_cold = '/shared/cn450/Kexin/COLDTIFResults/18TYM/';
end
if ~exist('years', 'var')
    years = [2015:2021];
end

% optional
p = inputParser;
addParameter(p,'ctype', true); % export change type
addParameter(p,'msg', true); % display info
addParameter(p,'sensor','HLS10'); % satellite sensor, e.g. 'S2','Landsat','HLS','HLS10'
parse(p,varargin{:});
msg = p.Results.msg;
ctype = p.Results.ctype;
sensor = p.Results.sensor;

% sensor = 'HLS10';
mask = true;

% [~, foldername_working] = fileparts(folderpath_cold);
foldername_working = folderpath_cold;
if msg
    if ctype
        fprintf('Start to export change maps with change type for %s\r\n', foldername_working);
    else
        fprintf('Start to export change maps for %s\r\n', foldername_working);
    end
end
% 
% folderpath_tsf = fullfile(folderpath_cold, 'TSFitLine_robustfit_sdateIntersect');
% folderpath_chgmap = fullfile(folderpath_cold, 'CCDCMap_robustfit_sdateIntersect');
folderpath_tsf = fullfile(folderpath_cold, 'TSFitLine');
folderpath_chgmap = fullfile(folderpath_cold, 'CCDCMap');
if ~isfolder(folderpath_chgmap)
    mkdir(folderpath_chgmap);
end

tic
%% get metadata
load(fullfile(folderpath_cold, 'metadata.mat'));
nrows = metadata.nrows;
ncols = metadata.ncols;
nbands = metadata.nbands; % 7 Landsat bands + 1 QA band
% dimension and projection of the image
jiDim = [ncols,nrows];
% slope threshold
t_min = -200; % 0.02 change in surf ref 


%% Read mask image
if mask
    folderpath_mask = fullfile('/shared/cn450/Kexin/COLDTIFResults/18TYM/','MaskImage');
    mask = dir(fullfile(folderpath_mask,'*.tif'));
    mask = readgeoraster(fullfile(mask(2).folder,mask(2).name));
    [rows,cols] = find(mask==1);
    clear mask;
    ROWs = unique(ceil(rows/3));
    COLs = unique(ceil(cols/3));
else
    ROWs = 1:3660;
    COLs = 1:3660;
end

% produce ObsNumMap
ObsNumMap = 9999*zeros(nrows,ncols,'uint16'); % e.g., 1365:  1 is type; 365 is DOY; 

% cd to the folder for storing recored structure
% cd(v_input.name_rst);
records = dir(fullfile(folderpath_tsf,'record_change*.mat')); % folder names
% records = records(ROWs);
num_line = size(records,1);


% for line = 1:
for line = 1: num_line
    % show processing status
    if msg
        if line/num_line < 1
            fprintf('Processing %.2f percent\r',100*(line/num_line));
        else
            fprintf('Processing %.2f percent\n',100*(line/num_line));
        end
    end
    % load one line of time series models
    load(fullfile(folderpath_tsf,records(line).name)); %#ok<LOAD>
    
    % postions
    pos = [rec_cg.pos];
    % continue if there is no model available
%     l_pos = 200;   % give a fix number for HLS
    l_pos = length(pos);
    if l_pos == 0
        continue
    end

    for i = 1:l_pos - 1 % -1: segment of time series will not have change record!
        % number of obs
        num_obs = rec_cg(i).num_obs;
        % get row and col
        [I,J] = ind2sub(jiDim,pos(i));  
        if ObsNumMap(J,I)==0
            ObsNumMap(J,I) = num_obs; 
        else
            ObsNumMap(J,I) = ObsNumMap(J,I)+num_obs;
        end
        
    end
end


geotif_obj = metadata.GRIDobj;
geotif_obj.Z = uint16(ObsNumMap(:,:));
filenameout = 'ObsNumMap.tif';
GRIDobj2geotiff(geotif_obj, fullfile(folderpath_chgmap, filenameout));

if msg
    fprintf('Finished exporting change map for %s with %0.2f mins\r\n', foldername_working, toc/60); 
end
end