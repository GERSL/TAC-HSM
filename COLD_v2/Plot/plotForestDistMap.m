addpath('/home/kes20012/COLD_v2/GRIDobj/');

% read disturbance map
dist_map_path = '/scratch/kes20012/';
dist_map = dir(fullfile(dist_map_path,'HLS_mosaic*.tif'));
[dist_map_value,R] = readgeoraster(fullfile(dist_map.folder,dist_map.name));

%% read forest mask
forest_map_path = '/gpfs/sharedfs1/zhulab/Kexin/ForestLayer_CT/';
% forest_map_path = '/scratch/kes20012/';
forest_map = dir(fullfile(forest_map_path,'*Forest*.tif'));
[forest_map_value,R] = readgeoraster(fullfile(forest_map.folder,forest_map.name));
% downscale to 30 m
forest_map_30m = imresize(forest_map_value,[size(forest_map_value,1)/3,size(forest_map_value,2)/3]);
% write to tiff file
MapGridobj = GRIDobj(fullfile(dist_map.folder,dist_map.name)); 
MapGridobj.Z = forest_map_30m;
MapGridobj.Z = uint8(MapGridobj.Z);
GRIDobj2geotiff(MapGridobj, '/scratch/kes20012/forest_mask_30m.tif');

%% apply mask
dist_map_value(forest_map_30m < 41) = 255;

%% write to tiff file
MapGridobj = GRIDobj(fullfile(dist_map.folder,dist_map.name)); 
MapGridobj.Z = dist_map_value;
MapGridobj.Z = uint16(MapGridobj.Z);
GRIDobj2geotiff(MapGridobj, '/scratch/kes20012/HLS_mosaic_CT_forest_dist_map.tif');
% geotiffwrite('/scratch/kes20012/mosaic_S2_CT_forest_dist_map.tif',dist_map,R);