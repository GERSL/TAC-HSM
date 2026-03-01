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
addParameter(p,'scenario',1);

parse(p,varargin{:});
msg = p.Results.msg;
ctype = p.Results.ctype;
sensor = p.Results.sensor;
sensor = {sensor};
Tiles = p.Results.Tiles;
scenario = p.Results.scenario;


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
nbands = 10;  % HLS: 6 + 3 + 1 QA

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
    pos_f = [rec_cg_f.pos];
    pos_b = [rec_cg_b.pos];
    
    % continue if there is no model available
    l_pos_f = length(pos_f);
    if l_pos_f == 0
        continue
    end
    l_pos_b = length(pos_b);
    if l_pos_b == 0
        continue
    end
    
    % break time
    t_break_f = abs([rec_cg_f.t_break]);
    t_break_b = abs([rec_cg_b.t_break]);
    % change probability
    change_prob_f = [rec_cg_f.change_prob];
    change_prob_b = [rec_cg_b.change_prob];
    % change vector magnitude
    mag_f = [rec_cg_f.magnitude];
    mag_f = reshape(mag_f,nbands-1,[]);  % reshape magnitude
    mag_b = [rec_cg_b.magnitude];
    mag_b = reshape(mag_b,nbands-1,[]);  % reshape magnitude
    % coefficients
    coefs_f = [rec_cg_f.coefs];
    coefs_f = reshape(coefs_f,8,nbands-1,[]);
    coefs_b = [rec_cg_b.coefs];
    coefs_b = reshape(coefs_b,8,nbands-1,[]);
    
    %% First, derive forward COLD change_type, disturbance_year, and day_of_year from rec_cg.mat
    type_f = [];
    year_f = [];
    doy_f = [];
    for i = 1:l_pos_f - 1 % -1: segment of time series will not have change record!
        if change_prob_f(i) == 1   % if break detected
            [break_type_f,break_year_f,break_doy_f] = labelDisturbanceType(coefs_f(:,:,i),t_break_f(i),t_min,mag_f(:,i),coefs_f(:,:,i+1));
        else                     % if change_prob less than 1, no break confirmed, give 0
            break_type_f = 0;
            break_year_f = 0;
            break_doy_f = 0;

        end 
        type_f = [type_f;[break_type_f]];
        year_f = [year_f;[break_year_f]];
        doy_f = [doy_f;[break_doy_f]];
    end
    % if no break detected or 'regrowth', give 0
    if isempty(type_f)     
        type_f = [0];
        year_f = [0];
        doy_f = [0];
    end
    
    %% Second, derive backward COLD change_type, disturbance_year, and day_of_year from rec_cg.mat
    type_b = [];
    year_b = [];
    doy_b = [];
    for i = 1:l_pos_b - 1 % -1: segment of time series will not have change record!
    if change_prob_b(i) ==1
        [break_type_b,break_year_b,break_doy_b] = labelDisturbanceType(coefs_b(:,:,i),t_break_b(i),t_min,mag_b(:,i),coefs_b(:,:,i+1));
    else
        break_type_b = 0;
        break_year_b = 0;
        break_doy_b = 0;
    end
    type_b = [type_b;[break_type_b]];
    year_b = [year_b;[break_year_b]];
    doy_b = [doy_b;[break_doy_b]];
    end
    % if no break detected or 'regrowth', give 0
    if isempty(type_b)     
        type_b = [0];
        year_b = [0];
        doy_b = [0];
    end
    
    %% Adjust final change results by combining forward and backward COLD
    type = [];
    year = [];
    doy = [];
    for k = 1:length(type_f)
        switch type_f(k)
            case 3
                year(k) = year_f(k);
                doy(k) = doy_f(k);
                try
                    switch type_b(k)
                        case 0
                            type(k) = type_b(k);
                            year(k) = 0;
                            doy(k) = 0;
                        case 1
                            if year_b(k)<=year_f(k)
                                type(k) = type_f(k);
                            else
                                type(k) = 4;   % haven't see this condition
                            end
                        case 3
                            if year_b(k)>=year_f(k)
                                type(k) = type_f(k);
                            else
                                type(k) = 4;   % haven't see this condition
                            end
                        otherwise% 2
                            type(k) = type_f(k);
                    end
                catch
                    type(k) = 0;
                    year(k) = 0;
                    doy(k) = 0;
                end
            otherwise   % 0,1,2
                type(k) = type_f(k);
                year(k) = year_f(k);
                doy(k) = doy_f(k);
%             case 2
%                 type(k) = type_f(k);
%             case 1
%                 type(k) = type_f(k);
%             case 0
%                 type(k) = type_f(k);
        end
    end
    
    %% 
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
writetable(struct2table(samples), fullfile(folderpath_chgyear,sprintf('%s_samplechangeyear_%d_%s_conse8_hybrid_%s.csv',char(Tiles{iTile}),length(ID),num2str(scenario),char(sensor{1}))));

end
end