function ShowDistMagMaps(varargin)

addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'GRIDobj'));
addpath('/home/kes20012/COLD_v2/Export');

start_year = 2016;
end_year = 2017;


p = inputParser;
addParameter(p,'ARDTiles',[]);
parse(p,varargin{:});
ARDTiles = p.Results.ARDTiles;
ARDTiles = {ARDTiles};

% ARDTiles = {'18TYM','18TYL','18TXL'};
ARDTiles = {'18TYM'};
for i = 1:length(ARDTiles)
Tile = ARDTiles{i};
% Tile = '18TXM';
% folderpath_cold = '/gpfs/sharedfs1/zhulab/Kexin/COLDResults/';
folderpath_cold = '/shared/cn451/Kexin/COLDHLSResults/';
folderpath_cold = fullfile(folderpath_cold,Tile);
cd(folderpath_cold)

% % get image parameters automatically
% imf = dir('L*'); % folder names
% 
% % filter for Landsat folders
% % imf = regexpi({imf.name}, 'L(T5|T4|E7|C8|ND)(\w*)', 'match');
% imf = regexpi({imf.name}, '\w*S2(A|B)', 'match');
% imf = [imf{:}];
% imf = vertcat(imf{:});
% % name of the first stacked image
% % filename = dir([imf(1,:),'/','L*stack']);
% filename = dir([imf(1,:),'/','T18*stack']);
% % read in ENVI hdr
% info = read_envihdr([imf(1,:),'/',filename.name,'.hdr']);
% % provide values from info
% nrows = info.lines;
% ncols = info.samples;
% nbands = info.bands;
% % get current directory
% l_dir = pwd;
%% get metadata
load(fullfile(folderpath_cold, 'metadata.mat'));
nrows = metadata.nrows;
ncols = metadata.ncols;
nbands = metadata.nbands; % 7 Landsat bands + 1 QA band
% dimension and projection of the image
jiDim = [ncols,nrows];
% slope threshold
t_min = -200; % 0.02 change in surf ref 
% INPUTS:
all_yrs = start_year:end_year;% all of years for producing maps
% max number of maps
max_n = length(all_yrs);

% produce disturbance map
% 65535 is given because of the max of uint16
LandDistMagMap = 65535*ones(nrows,ncols,max_n,'uint16'); % disturbance magnitude
LandDistDOYMap = 65535*ones(nrows,ncols,max_n,'uint16'); % disturbance DOY per year

% make Predict folder for storing predict images
n_map = 'CCDCMap';
if isempty(dir(n_map))
    mkdir(n_map);
end

% cd to the folder for storing recored structure
% cd(v_input.name_rst);
n_str = 'TSFitLine_HLS';
imf = dir(fullfile(folderpath_cold,n_str,'record_change*')); % folder names
num_line = size(imf,1);

for line = 1:num_line
% for line = 1:50
    
    % show processing status
    if line/num_line < 1
        fprintf('Processing %.2f percent\r',100*(line/num_line));
    else
        fprintf('Processing %.2f percent\n',100*(line/num_line));
    end
    
    % load one line of time series models
    load([n_str,'/',imf(line).name]); %#ok<LOAD>
    
    % postions
    pos = [rec_cg.pos];
    
    % continue if there is no model available
    l_pos = length(pos);
    if l_pos == 0
        continue
    end
    
    % break time
    t_break = [rec_cg.t_break];
    % change probability
    change_prob = [rec_cg.change_prob];
    % change vector magnitude
    mag = [rec_cg.magnitude];
    % reshape magnitude
    mag = reshape(mag,nbands-1,[]);
    
    %% Disturbance Magnitude
%     Change Magnitude is calculated as the square root of the sum
%     of the squared per-band median residuals (excluding the blue and BT bands) between
%     the observed per-band Landsat surface reflectance (scaled) and CCDC predictions at
%     the time of a detected CCDC model break. Change Magnitude is unitless and generally
%     ranges between 1 and 10,000. A value of zero indicates there is no recorded model break
%     in the current year
%   USGS used this python function at https://numpy.org/doc/stable/reference/generated/numpy.linalg.norm.html
%   USGS document: https://prd-wret.s3.us-west-2.amazonaws.com/assets/palladium/production/atoms/files/LSDS-1982%20LCMAP%20Continuous%20Change%20Detection%20and%20Classification%20%28CCDC%29%20Algorithm%20Description%20Document%20%28ADD%29.pdf
    % ks: comment line below for HLS
%     magDist = mag(2:9,:);% exclude blue and BT bands
    % matlab function norm can do this, but cannot process array at one
    % time.
    magDist = mag(:,:);
    magDist = sqrt(sum(magDist.^2, 1)); % usually 1 - 10,000
    magDist = uint16(magDist);
    
    % coefficients
    coefs = [rec_cg.coefs];
    coefs = reshape(coefs,8,nbands-1,[]);
    
    
    for i = 1:l_pos - 1
        % get row and col
        [I,J] = ind2sub(jiDim,pos(i));
        
        % initialize pixels have at least one model
        if sum(LandDistMagMap(J,I,:) == 65535) == max_n
            % write doy to ChangeMap
            LandDistMagMap(J,I,:) = 0;
            LandDistDOYMap(J,I,:) = 0;
        end
        
        if change_prob(i) == 1
            [break_type,break_year,break_doy] = labelDisturbanceType(coefs(:,:,i),t_break(i),t_min,mag(:,i),coefs(:,:,i+1));
            % [break_type,break_year,break_doy] = label_dist_type(tst(j).coefs,tst(j).t_break,-200,tst(j).magnitude,tst(j+1).coefs);

            if break_type > 1 % land distrubance
                % do not consider the disturbances after Aug 06, 2020 (Isaias hurricane)
                if break_year == 2020 && break_doy > 219
                    continue;
                end
                % get the band number for abrupt disturbance
                n_band = all_yrs == break_year;
                % magnitude of disturbance
                LandDistMagMap(J,I,n_band) = magDist(i);
                LandDistDOYMap(J,I,n_band) = break_doy;
            end
        end
    end
end
end


geotif_obj = metadata.GRIDobj;
% Export Magnitude map
geotif_obj.Z = uint16(LandDistMagMap);
filename_out1 = sprintf('LandDistMagMap_%d_%d',start_year, end_year);
GRIDobj2geotiff(geotif_obj, fullfile(folderpath_cold,n_map, filename_out1));
% % Export DOY map
% geotif_obj.Z = uint16(LandDistDOYMap);
% filename_out2 = sprintf('LandDistDOYMap_%d_%d',start_year, end_year);
% GRIDobj2geotiff(geotif_obj, fullfile(folderpath_cold,n_map, filename_out2));


% end

% ARD_enviwrite_bands_n(fullfile(n_map,filename_out),LandDistMagMap,'uint16','bip',all_yrs,folderpath_cold); % dir_cur means where the stacked data are
% filename_out = sprintf('LandDistDOYMap_%d_%d',start_year, end_year);
% ARD_enviwrite_bands_n(fullfile(n_map,filename_out),LandDistDOYMap,'uint16','bip',all_yrs,folderpath_cold); % dir_cur means where the stacked data are
