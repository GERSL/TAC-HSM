function [comi,omi,F1] = calculateF1score(varargin)
% This function is to calculate omission, commission, and F1 score export.
% Detailed information can be found in COLD paper (Zhu et al., 2020).
% Run this script after exportDOYsamples.m

% INPUT:
%
%   folderpath_cold:        Locate to COLD working folder, in which the
%                           change folder <TSFitLine> is necessery, and
%                           this folder was created by <COLD.m>.
%

addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'GRIDobj'));
addpath('/home/kes20012/COLD_v2/Export');

% INPUTS
p = inputParser;
addParameter(p,'sensor',[]);
addParameter(p,'start_year',2013);    % default year is 2013
addParameter(p,'Tiles',{'18TXM','18TXL','18TYM','18TYL'});  % default is all tiles
addParameter(p,'scenario',1);

parse(p,varargin{:});
sensor = p.Results.sensor;
start_year = p.Results.start_year;
Tiles = p.Results.Tiles;
scenario = p.Results.scenario;

% Tiles = {'18TXM','18TXL','18TYM','18TYL'};
Tiles = {'18TXM'};
% sensor = 'S2';
% sensor = 'L30';
sensor = 'HLS';
start_year = 2015;

if ~exist('folderpath_cold', 'var')
    if strcmp(sensor,'HLS')
        folderpath_cold = '/shared/cn451/Kexin/COLDHLSResults/';
    elseif strcmp(sensor,'S2')
        folderpath_cold = '/shared/cn450/Sentinel-2/COLDResults/';
    end
end
if ~exist('folderpath_ref', 'var')
    folderpath_ref = '/shared/cn450/Kexin/Samples/';
end

if ~exist('years', 'var')
    years = [2013:2021];
end


N1 = 0;
N2 = 0;
Total_Det_Dist = 0; 
Total_Ref_Dist = 0; 

%% Loop of tiles start here...
for iTile = 1:length(Tiles)
    foldername_working = fullfile(folderpath_cold,Tiles{iTile});
%     fprintf('Start to analyze %s\r\n', foldername_working);

    folderpath_result = fullfile(foldername_working, 'SampleChangeYear');   % result path
    if ~isfolder(folderpath_result)
        mkdir(folderpath_result);
%         fprintf('Run exportDOYsamples.m first for %s\r\n', foldername_working);
    end

    %% load samples here
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
    ref_year = table2array(T(:,6));    % disturbance year
    ref_year(ref_year<start_year) = 0;   % filter reference disturbance before assigned start year.
    clear T;

    %% load results here
    if strcmp(sensor,'S30')
        sampleresult = dir(fullfile(folderpath_result,'*samplechangeyear*S30*'));
    elseif strcmp(sensor,'HLS')
%         sampleresult = dir(fullfile(folderpath_result,'*samplechangeyear*ndvi*HLS*'));
        sampleresult = dir(fullfile(folderpath_result,'*samplechangeyear*HLS*'));
    elseif strcmp(sensor,'L30')
        sampleresult = dir(fullfile(folderpath_result,'*samplechangeyear*L30*'));
    elseif strcmp(sensor,'S2')
        sampleresult = dir(fullfile(folderpath_result,'*samplechangeyear*conse8*hybrid*S2*'));
    end 
    T = readtable(fullfile(sampleresult(scenario).folder,sampleresult(scenario).name));
    headers = T.Properties.VariableNames;    % read all header names, there may contains more than one changes

    ct_start = 4; 
    for j =1: length(headers)   % find the start column of change_type and year
        if contains(headers{j},'year_1')
            yr_start = j; 
            break
        else 
            yr_start = 5;
        end 
    end

    %% Calculate n1 and n2
    n1 = 0;    % number of detected disturbance disagree with reference (for commission)
    n2 = 0;    % number of reference disturbance disagree with detection  (for omission)
    total_det_dist = 0;                        % total number of detected disturbance (for commission)
    total_ref_dist = length(find(ref_year));   % total number of reference disturbance (for omission)

    for i = 1: length(ID)
%     for i = 23
        reference_year = ref_year(i);
        change_type = table2array(T(i,ct_start:yr_start-1));        % read all change types
        max_num = yr_start-ct_start;                                % maximum number of changes/breaks detected
        change_year = table2array(T(i,yr_start:yr_start+max_num-1));% read all change years
        % filter reference disturbance before assigned start year.
        change_type(change_year<start_year) = NaN;
        change_year(change_year<start_year) = NaN;                    
        % now, remove 'regrowth' break (1 in change_type) for further analysis
        change_year(change_type==1)=NaN;

        %% find detected disturbances year disagree with reference disturbance year (n1)
        if ~isempty(find(change_type==3))           % if detected disturbance exists
            total_det_dist = total_det_dist+sum(~isnan(change_year));   % sum u detected disturbances of each pixel
            num_detcted_dist = length(find(change_year>=min(years)));   
            num_matched_dist = length(find(change_year==reference_year));
            num_com = num_detcted_dist-num_matched_dist;
            n1 = n1+num_com;  
        end   
        %% find reference disturbances year disagree with detected disturbance year (n2)
        if reference_year~=0                        % if reference disturbance exists
            if isempty(find(change_year==reference_year))
                n2=n2+1;
            end
        end    
    end
    N1 = N1+n1;
    N2 = N2+n2;
    Total_Det_Dist = Total_Det_Dist+total_det_dist;
    Total_Ref_Dist = Total_Ref_Dist+total_ref_dist;
end

%% Now, calculate commission, omission, and F1 score
% comi = n1/total_det_dist                % n1/total number of detected disturbances
% omi = n2/total_ref_dist                 % n2/total number of reference disturbances
% F1 =  (1-omi)*(1-comi)/(2-omi-comi)*2

comi = N1/Total_Det_Dist;                % n1/total number of detected disturbances
omi = N2/Total_Ref_Dist;                 % n2/total number of reference disturbances
F1 =  (1-omi)*(1-comi)/(2-omi-comi)*2;
end