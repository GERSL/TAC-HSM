function generateRandomSample()
    % Load the NetCDF file
    folderpath = '/gpfs/sharedfs1/zhulab/SCRATCH/kes20012/ProjectTACValidation/ClimateData/';
    ncFile = fullfile(folderpath,'def_2000_2024.nc'); % Path to your file
    varName = 'def'; % Replace with the actual variable name in the NetCDF file
    
    % Read latitude, longitude, and data
    lon = ncread(ncFile, 'lon'); % Replace with the actual lon variable name
    lat = ncread(ncFile, 'lat'); % Replace with the actual lat variable name
    data = ncread(ncFile, varName);
    
    % Convert data into a 2D grid (assuming lat/lon dimensions match data)
    [lonGrid, latGrid] = meshgrid(lon, lat);
    
    % Find valid (non-NaN) locations
    def_mean = mean(data,3);
    validMask = ~isnan(def_mean); % Logical mask of valid data points
    
    % Extract valid coordinates and their indices
    validLon = lonGrid(validMask');
    validLat = latGrid(validMask');
    validData = def_mean(validMask'); % Optional: Extract values if needed

    % Get the number of valid points
    numValidPoints = numel(validLon);
    
    % Ensure we don't exceed the available valid points
    numSamples = min(10000, numValidPoints);
    
    % Randomly select indices from valid points
    rng(42);
    randIdx = randperm(numValidPoints, numSamples);
    
    % Extract sampled locations
    sampleLon = validLon(randIdx);
    sampleLat = validLat(randIdx);
    
    % Generate unique IDs for each sampled point
    sampleID = (1:numSamples)';
    
    
    % Save to CSV file
    outputFile = 'random_samples_10000.csv';
    T = table(sampleID, sampleLon, sampleLat);
    writetable(T, fullfile(folderpath,outputFile));
    
    disp(['Saved ', num2str(numSamples), ' samples to ', outputFile]);

    
end

