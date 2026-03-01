function generateRandomSamples(N)
%%----------------------------------------------------------
% This function is for generating simple random samples of
% 10 m Land Change Maps from Sentinel-2 observations. 
% Note: This function needs to be run on Matlab R2020b and above as
% 'readgeoraster()' and 'geotiffinfo()' are not supported on R2019b.
% 
% INPUTS:
%       CCDC map (18TXM, 18TXL, 18TYM, 18TYL)
%       CT forest layer
%       sample size (N)
% OUTPUTS:
%       id 
%       row
%       column
% ----------------------------------------------------------
addpath('')
close all;

folderpath_cold = '/scratch/kes20012/COLDFusionResults/18TYM';

folderpath_validate = fullfile(folderpath_cold, 'Validate');
if ~isfolder(folderpath_validate)
    mkdir(folderpath_validate);
end
cd(folderpath_validate);
%% read change map 
% read CCDC map
changemap = dir(fullfile(folderpath_cold,'ChangeMap*','*accuchangemap*.tif'));
[change_map,R] = readgeoraster(fullfile(changemap.folder,changemap.name));
geoinfo = geotiffinfo(fullfile(changemap.folder,changemap.name));
%% read forest layer as the mask 
% you can change this part as I focus on forest disturbances.
folderpath_mask = '/gpfs/sharedfs1/zhulab/Kexin/S2_CT_Forest_Layer/';
forestmask = dir(fullfile(folderpath_mask,'18TYM*'));
[forest_msk,R] = readgeoraster(fullfile(forestmask(1).folder,forestmask(1).name));
[row,col,~] = find(forest_msk > 41);
forest_id = find(forest_msk > 41);

%% Generate samples
% Initilize array of struct ahead of time (this will be more efficient compared to 1-by-1 appendent)
% size_samples = N;
size_samples = 10;
samples = [];
samples(size_samples).ID = [];
samples(size_samples).row = [];
samples(size_samples).col = [];
samples(size_samples).lat = [];
samples(size_samples).lon = [];
samples(size_samples).changeyear = [];

% Select samples randomly
ids = 1:size_samples;
y = randperm(length(forest_id),size_samples);
% Save samples indices
cell_ids = num2cell(ids);
[samples.ID] = deal(cell_ids{:});
% Convert samples indices to subscripts
% % ind = forest_id(y);
[samp_row, samp_col]= ind2sub(size(change_map), forest_id(y));
% Conver row/col to lat/lon
% pro = projcrs(32618);       % projected crs for Sentinel-2 ARD
pro = R.ProjectedCRS;
[X,Y] = pixcenters(R,size(change_map));
samp_x = X(samp_col);samp_y = Y(samp_row);  % center point
clear X;
clear Y;
[samp_lat,samp_lon] = projinv(pro,samp_x,samp_y);
% Save lat,lon,row,col
samp_lat = num2cell(samp_lat);
[samples(ids).lat] = deal(samp_lat{:});
samp_lon = num2cell(samp_lon);
[samples(ids).lon] = deal(samp_lon{:});
samp_row = num2cell(samp_row);
[samples(ids).row] = deal(samp_row{:});
samp_col = num2cell(samp_col);
[samples(ids).col] = deal(samp_col{:});
% Save samples value - accumulated change year
samp_values = num2cell(change_map(forest_id(y)));
[samples(ids).changeyear] = deal(samp_values{:});

%% Export samples to .csv file
tilename = split(folderpath_cold,'/');
tilename = char(tilename(end));
writetable(struct2table(samples), strcat(tilename,'_samples.csv'));

%% Save samples to samples.mat
save(strcat(tilename,'_samples.mat'),'samples');

end












