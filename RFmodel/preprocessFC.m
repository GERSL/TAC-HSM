function preprocessFC()
%PREPROCESSFC Summary of this function goes here
%   Detailed explanation goes here

    close all;
    folderpath = '/gpfs/sharedfs1/zhulab/Kexin/ProjectTACValidation';
    data = readtable(fullfile(folderpath,'ForestCover','random_sample_forest_cover.csv'));
    
    % Check if the "FC" column exists
    if ismember('FC', data.Properties.VariableNames)
        % Count NaN values in FC column
        numNaN = sum(isnan(data.FC));
    
        % Count forest pixels (FC>10) in FC column
        n = sum(data.FC >= 10);
        m = sum(data.FC < 10);
    
        % histogram(data.FC)

        % Display results
        fprintf('Percentage of Non-forest area is (fc is nan): %.2f%%\n', numNaN./height(data)*100);
        fprintf('Percentage of forest pixels (fc gt 10) is: %.2f%%\n', n./height(data)*100);
        fprintf('Percentage of vegetation pixels (fc lte 10) is: %.2f%%\n', m./height(data)*100);
    else
        fprintf('Error: Column "FC" not found in the dataset.\n');
    end


    %% Create scatter plot of amazon forest samples
    fig = figure("Name","Scatter plot:Amazon Forest Cover (2010)");
    fig.Position = [50 50 1000 500];
    forest_id = find(data.FC>10);
    
    scatter(data.sampleLon(forest_id),data.sampleLat(forest_id),20,data.FC(forest_id),'filled');
    colormap(flipud(summer))
    colorbar();
    hold on;
 

    % Add country boundaries
    land = shaperead(fullfile(matlabroot, 'toolbox', 'map', 'mapdata', 'landareas.shp'), ...
                     'UseGeoCoords', true);
    for k = 1:length(land)
        plot(land(k).Lon, land(k).Lat, 'k', 'LineWidth', 0.5);
        hold on;
    end
   
    % Tropical
    ylim([-25,12]) 
    xlim([-90,-30])
    
end

