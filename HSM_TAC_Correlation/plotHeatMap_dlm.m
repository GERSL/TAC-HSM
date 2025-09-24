function plotHeatMap_dlm()
    % Function to visualize a 7 × 6 matrix of R² values as a heatmap.
    % 
    % INPUTS:
    %   R2_matrix  - A 7×6 matrix of R² values
    %   save_fig   - (Optional) Boolean, whether to save the figure (default: false)
    %   save_path  - (Optional) Path to save the figure if save_fig = true
    %
    % Example:
    %   R2_matrix = rand(7,6);  % Example R² matrix
    %   plotHeatMap(R2_matrix, true, 'C:\Users\YourName\Documents\heatmap.png')
    
    save_fig = 1;%true;
    use_p88 = false; %true;%  % 
    
    % composite_interval = 'biweekly';
    composite_interval = 'monthly';
    % composite_interval = 'bimonthly';%'monthly';%'biweekly';%% 

    directory = '/gpfs/sharedfs1/zhulab/SCRATCH/kes20012/ProjectTACValidation/';

    if use_p88
        load(fullfile(directory,'R2_dlmTAC_HSM_2025-03-31',composite_interval,"HSM_p88_R2_results.mat"));
        R2_matrix = HSM_p88_R2_results;
    else
        load(fullfile(directory,'R2_dlmTAC_HSM_2025-03-31',composite_interval,"HSM_p50_R2_results.mat"));
        R2_matrix = HSM_p50_R2_results;
    end
    

    % Labels for the axes
    vegetation_indices = {'NDVI', 'kNDVI', 'NIRv', 'NBR', 'NDMI', 'EVI', 'EVI2'};
    climate_variables = {'t2m', 'tp', 'def', 'ssrd'};

    % Set the colormap range
    colormap_range = [0, 0.5]; % Define range for colormap

    % Create the heatmap
    
    fig = figure("Name",'R2 heat map');
    fig.Position = [20, 20, 500, 400];
    h = heatmap(climate_variables, vegetation_indices, R2_matrix, ...
        'Colormap', parula, 'ColorbarVisible', 'on');

    % Handle missing/negative values
    h.ColorData(R2_matrix < 0) = NaN; % Mark negative values as NaN
    h.ColorLimits = colormap_range;   % Set the colormap range
    h.MissingDataLabel = 'r ≤ 0';    % Label for NaN values
    h.MissingDataColor = [0.5, 0.5, 0.5];   % Display NaN values in black

    % Customize appearance
    if use_p88
        title('R² Heatmap (HSM p88)');
    else
        title('R² Heatmap (HSM p50)');
    end
    set(gca, 'FontSize', 16);

    % Save figure if required
    if save_fig
        if use_p88
            save_path = fullfile(directory,'Figure/',['dlmTACR2_heatmap_HSMp88_',composite_interval,'.png']);
        else
            save_path = fullfile(directory,'Figure/',['dlmTACR2_heatmap_HSMp50_',composite_interval,'.png']);
        end
        exportgraphics(gcf, save_path, 'Resolution', 600);
        fprintf('Figure saved to: %s\n', save_path);
    end
end



