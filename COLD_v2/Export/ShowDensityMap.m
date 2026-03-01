function ShowDensityMap(varargin)

addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'GRIDobj'));
addpath('/home/kes20012/COLD_v2/Export');

p = inputParser;
addParameter(p,'ARDTiles',[]);
parse(p,varargin{:});
ARDTiles = p.Results.ARDTiles;
ARDTiles = {ARDTiles};


mask = true;
folderpath_cold = '/shared/cn450/Kexin/COLDS2Results/18TXM/';
folderpath_density = fullfile(folderpath_cold,'TSDensityMap');
if ~isfolder(folderpath_density)
    mkdir(folderpath_density);
end
% cd(folderpath_density)
% folderpath_cold = fullfile(folderpath_cold,Tile);
% cd(folderpath_cold)

% % % % % % % % % % % % % % % % % % %% Read mask image
% % % % % % % % % % % % % % % % % % if mask
% % % % % % % % % % % % % % % % % %     tilename = split(folderpath_cold,'/');
% % % % % % % % % % % % % % % % % %     tilename = char(tilename(end-1));
% % % % % % % % % % % % % % % % % %     folderpath_mask = fullfile(folderpath_cold,'MaskImage');
% % % % % % % % % % % % % % % % % %     mask = dir(fullfile(folderpath_mask,['T',tilename,'_Planet*.tif']));
% % % % % % % % % % % % % % % % % %     mask = readgeoraster(fullfile(mask(1).folder,mask(1).name));
% % % % % % % % % % % % % % % % % %     [rows,cols] = find(mask==0);
% % % % % % % % % % % % % % % % % %     %     [rows,cols] = find(mask==1);
% % % % % % % % % % % % % % % % % %     clear mask
% % % % % % % % % % % % % % % % % %     ROWs = unique(rows);
% % % % % % % % % % % % % % % % % %     COLs = unique(cols);
% % % % % % % % % % % % % % % % % % end

%% get metadata
load(fullfile(folderpath_cold,'StackData10', 'metadata.mat'));
nrows = metadata.nrows;
ncols = metadata.ncols;
nbands = metadata.nbands; % 7 Landsat bands + 1 QA band
% dimension and projection of the image
jiDim = [ncols,nrows];
% slope threshold
% t_min = -200; % 0.02 change in surf ref 
% % INPUTS:
% % all_yrs = start_year:end_year;% all of years for producing maps
% % max number of maps
% max_n = length(all_yrs);

% produce disturbance map
% 65535 is given because of the max of uint16
DensityMap = zeros(nrows,ncols,'uint16'); % disturbance magnitude

% % cd to the folder for storing recored structure
n_str = 'TSDensity';
imf = dir(fullfile(folderpath_cold,n_str,'TSDensity*')); % folder names
num_line = size(imf,1);
% 
for line = 1:num_line
% % for line = 1:50
%     
    % show processing status
    if line/num_line < 1
        fprintf('Processing %.2f percent\r',100*(line/num_line));
    else
        fprintf('Processing %.2f percent\n',100*(line/num_line));
    end
    
    % load one line of time series models
    load(fullfile(folderpath_cold,n_str,imf(line).name)); %#ok<LOAD>
    s = split(imf(line).name,'.');
    ir = sscanf(s{1},'TSDensity_r%05d');
    DensityMap(ir,:) = num_good;
   
end
% 
geotif_obj = metadata.GRIDobj;
% Export Density Map
geotif_obj.Z = uint16(DensityMap);
filename_out = ['TSDensityMap','_T18TXM.tif'];
GRIDobj2geotiff(geotif_obj, fullfile(folderpath_cold,'TSDensityMap',filename_out));
% 
% %% Display Density Map
imshow(DensityMap,[]);
colormap(jet)
colorbar()
saveas(gcf,fullfile(folderpath_cold,[filename_out,'.png']))
end


% end

% ARD_enviwrite_bands_n(fullfile(n_map,filename_out),LandDistMagMap,'uint16','bip',all_yrs,folderpath_cold); % dir_cur means where the stacked data are
% filename_out = sprintf('LandDistDOYMap_%d_%d',start_year, end_year);
% ARD_enviwrite_bands_n(fullfile(n_map,filename_out),LandDistDOYMap,'uint16','bip',all_yrs,folderpath_cold); % dir_cur means where the stacked data are
