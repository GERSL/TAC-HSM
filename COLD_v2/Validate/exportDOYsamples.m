function exportDOYsamples(varargin)
% exportDOYsamples
% This function extracts samples change_type, year, and DOY from record_change_rxxxxxcxxxxx.mat 
% and save them to a csv file. Run this script after COLDsamples.m
%
% INPUT:
%
%   folderpath_cold:        Locate to COLD working folder, in which the
%                           change folder <TSFitLine> is necessery, and
%                           this folder was created by <COLD.m>.
%
% Also see labelDisturbanceType.m

addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'GRIDobj'));
addpath('/home/kes20012/COLD_v2/Export');


% INPUTS
p = inputParser;
addParameter(p,'ctype', true); % export change type
addParameter(p,'msg', true); % display info
addParameter(p,'sensor',[]);
addParameter(p,'Tiles',['18TXM','18TXL','18TYM','18TYL']);  % default is all tiles

parse(p,varargin{:});
msg = p.Results.msg;
ctype = p.Results.ctype;
sensor = p.Results.sensor;
sensor = {sensor};
Tiles = p.Results.Tiles;


% Tiles = {'18TXL','18TYM','18TYL'};
Tiles = {'18TXM'};
% sensor = {'S2'};
sensor = {'HLS'};

for iTile = 1:length(Tiles)
    
if ~exist('folderpath_cold', 'var')
    if strcmp(sensor,'S2')
        folderpath_cold = fullfile('/shared/cn450/Sentinel-2/COLDResults/',Tiles{iTile});
    elseif strcmp(sensor,'HLS')
        folderpath_cold = fullfile('/shared/cn451/Kexin/COLDHLSResults/',Tiles{iTile});
end
if ~exist('years', 'var')
    years = [2013:2021];
end


foldername_working = folderpath_cold;
folderpath_tsf = fullfile(folderpath_cold, 'SampleTSFit');
folderpath_chgyear = fullfile(folderpath_cold, 'SampleChangeYear');
if ~isfolder(folderpath_chgyear)
    mkdir(folderpath_chgyear);
end

tic
% fprintf('Start extracting disturbance type, year, and DOY for Tile %s\r\n', foldername_working);

%% get metadata
load(fullfile(folderpath_cold, 'metadata.mat'));
nrows = metadata.nrows;
ncols = metadata.ncols;
% no ndvi
nbands = metadata.nbands;
% nbands = 19;  % S2
nbands = 10;  % HLS: 6 spectral bands + 3 NDVIs + 1 QA band
% ndvi
% nbands = metadata.nbands+1; % 10 Sentinel-2 bands + 1 QA band
% % dimension and projection of the image
jiDim = [ncols,nrows];
% slope threshold
t_min = -200; % 0.02 change in surf ref 

%% Load reference samples here
if strcmp(sensor,'S2')
    folderpath_ref = '/shared/cn450/Kexin/Samples/';
    samplecsv = dir(fullfile(folderpath_ref,Tiles{iTile},'*samples*S2.csv'));
else
    folderpath_ref = '/shared/cn450/Kexin/Samples/';
    samplecsv = dir(fullfile(folderpath_ref,Tiles{iTile},'*samples*HLS*.csv'));
end
T = readtable(fullfile(samplecsv(1).folder,samplecsv(1).name));
ID = table2array(T(:,1));
rows = table2array(T(:,2));
cols = table2array(T(:,3));
clear T;

%% Create COLD results struct
samples = [];
size_samples = length(ID);
samples(size_samples).ID = [];
samples(size_samples).row = [];
samples(size_samples).col = [];
samples(size_samples).change_type = [];
samples(size_samples).year = [];
samples(size_samples).doy = [];

%% Save ID, rows, and cols which are identical to the reference sample csv
ID = num2cell(ID);
[samples.ID] = deal(ID{:});
rows_cell = num2cell(rows);
[samples.row] = deal(rows_cell{:});
cols_cell = num2cell(cols);
[samples.col] = deal(cols_cell{:});

Type = {};
Year = {};
DOY = {};
for id = 1: length(ID)
% for id = 6
    pt_row = rows(id);
    pt_col = cols(id);
    
    %% read rec_cg (forward and backward) from .mat files
    filepath_rcg1 =  fullfile(folderpath_tsf,sprintf('record_change_forward_r%05dc%05d.mat', pt_row,pt_col)); % r:row c:col
    load(filepath_rcg1);
    filepath_rcg2 =  fullfile(folderpath_tsf,sprintf('record_change_backward_r%05dc%05d.mat', pt_row,pt_col)); % r:row c:col
    load(filepath_rcg2);
    
    % postions
    pos = [rec_cg.pos];
    
    % continue if there is no model available
    l_pos = length(pos);
    if l_pos == 0
        continue
    end
    
    % break time
    t_break_f = abs([rec_cg_f.t_break]);
    t_break_b = abs([rec_cg_f.t_break]);
    
    % change probability
    change_prob = [rec_cg.change_prob];
    % change vector magnitude
    mag = [rec_cg.magnitude];
    % reshape magnitude
    mag = reshape(mag,nbands-1,[]);
    % coefficients
    coefs = [rec_cg.coefs];
    coefs = reshape(coefs,8,nbands-1,[]);
    
    % derive change_type, disturbance_year, and day_of_year from rec_cg.mat
    type = [];
    year = [];
    doy = [];
    for i = 1:l_pos - 1 % -1: segment of time series will not have change record!
        if change_prob(i) == 1   % if break detected
            [break_type,break_year,break_doy] = labelDisturbanceType(coefs(:,:,i),t_break(i),t_min,mag(:,i),coefs(:,:,i+1));
        else                     % if change_prob less than 1, no break confirmed, give 0
            break_type = 0;
            break_year = 0;
            break_doy = 0;
        end  
        type = [type;[break_type]];
        year = [year;[break_year]];
        doy = [doy;[break_doy]];
    end
    %% if no break detected or 'regrowth', give 0
    if isempty(type)     
        type = [0];
        year = [0];
        doy = [0];
    end
    Type{id} = type;
    Year{id} = year;
    DOY{id} = doy;
end

Type = num2cell(Type);
Year = num2cell(Year);
DOY = num2cell(DOY);
[samples.change_type] = deal(Type{:});
[samples.year] = deal(Year{:});
[samples.doy] = deal(DOY{:});

%% Export and save sample to .csv file
writetable(struct2table(samples), fullfile(folderpath_chgyear,sprintf('%s_samplechangeyear_%d_HLS_conse8_BiCOLD_%s.csv',char(Tiles{iTile}),length(ID),char(sensor{1}))));

end
end