%% download forest cover maps (30 m)
% Define bounding box for tropical forest
lat_min = -30; lat_max = 10;
lon_min = -90; lon_max = -30;

% Directory for saving forest cover maps
folderpath = '/gpfs/sharedfs1/zhulab/SCRATCH/kes20012/ProjectTACValidation';
map_dir = fullfile(folderpath,'ForestCover');
if ~exist(map_dir, 'dir')
    mkdir(map_dir);
end

% Loop through each sample point

for i = lat_min:10:lat_max
    for j = lon_min:10:lon_max
        tile_lon = j;
        tile_lat = i;
        
        % Convert to correct naming convention
        if tile_lat >= 0
            lat_str = sprintf('%02dN', tile_lat);
        else
            lat_str = sprintf('%02dS', abs(tile_lat));
        end
        
        if tile_lon >= 0
            lon_str = sprintf('%03dE', tile_lon);
        else
            lon_str = sprintf('%03dW', abs(tile_lon));
        end
        
        % Construct the tile filename
        tile_name = sprintf('treecover2010_%s_%s.tif', lat_str, lon_str);

       
        tile_url = sprintf('https://glad.umd.edu/Potapov/TCC_2010/%s', tile_name);
        tile_path = fullfile(map_dir, tile_name);

        % Download the tile if it doesn't exist
        if ~isfile(tile_path)
            try
                websave(tile_path, tile_url);
                fprintf('Downloading %s\n', tile_name)
            catch
                warning('Could not download %s. Skipping...', tile_name);
                continue;
            end
        end
    end

   
end

disp('Complete!');
