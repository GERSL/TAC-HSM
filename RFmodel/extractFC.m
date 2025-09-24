function extractFC()
    %% Load sample points
    folderpath = '/gpfs/sharedfs1/zhulab/SCRATCH/kes20012/ProjectTACValidation';
    % data = readtable(fullfile(folderpath,'RandomSample','random_samples_10000.csv'));
    data = readtable(fullfile(folderpath,'Input','Sample_multipleInPlot_HPC.csv'));

    % Define the directory containing the downloaded maps
    map_dir = fullfile(folderpath,'ForestCover');
    
    % Initialize the output forest cover (FC) array
    FC = nan(height(data), 1);

    %% Loop through each unique map file
    map_files = dir(fullfile(map_dir, 'treecover2010_*.tif'));

    for k = 1:length(map_files)
        tile_name = map_files(k).name;
        tile_path = fullfile(map_dir, tile_name);
        
        % Extract latitude and longitude information from filename
        parts = regexp(tile_name, 'treecover2010_(\d{2}[NS])_(\d{3}[EW])\.tif', 'tokens');
        if isempty(parts)
            warning('Skipping invalid file: %s', tile_name);
            continue;
        end
    
        % Convert extracted lat/lon to numerical values
        lat_str = parts{1}{1};
        lon_str = parts{1}{2};
       
        % Read the forest cover raster and reference matrix
        try
            [forest_cover, R] = readgeoraster(tile_path);
        catch
            warning('Error reading %s. Skipping...', tile_name);
            continue;
        end
        
        tile_lat_min = R.LatitudeLimits(1);
        tile_lat_max = R.LatitudeLimits(2);
        tile_lon_min = R.LongitudeLimits(1);
        tile_lon_max = R.LongitudeLimits(2);
        % Find sample points that fall within this tile
        in_tile = data.sampleLat >= tile_lat_min & data.sampleLat < tile_lat_max & ...
                  data.sampleLon >= tile_lon_min & data.sampleLon < tile_lon_max;
        
        % Process only the points within this tile
        sample_indices = find(in_tile);
        
        for idx = sample_indices'
            lat = data.sampleLat(idx);
            lon = data.sampleLon(idx);
            
            
            % Convert lat/lon to pixel coordinates using geographicToIntrinsic
            [col, row] = geographicToIntrinsic(R, lat, lon);
            row = round(row);
            col = round(col);
            
            
            % Extract forest cover value if valid
            if row > 0 && row <= size(forest_cover,1) && col > 0 && col <= size(forest_cover,2)
                FC(idx) = forest_cover(row, col);
            else
                warning('Point (Lon: %f, Lat: %f) is out of bounds in %s', lon, lat, tile_name);
            end
        end
    end
    
    %% Save results to CSV
    results = table(data.sampleID,data.plotID, data.sampleLon,data.sampleLat,FC,...
        'VariableNames', {'sampleID','plotID','sampleLon','sampleLat', 'FC'});
    % writetable(results,fullfile(folderpath,'ForestCover/','random_sample_forest_cover.csv'));
    writetable(results,fullfile(folderpath,'ForestCover/','Sample_multipleInPlot_forest_cover.csv'));

    disp('Processing completed. Results saved as forest_cover_results.csv');

end

