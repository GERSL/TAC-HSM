function plotHeatMap()
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
    
    save_fig = false;%true;
    use_p88 = false; %true;%  % 
    
    composite_interval = 'bimonthly';%'monthly';%'biweekly';%% 

    directory = '/gpfs/sharedfs1/zhulab/Kexin/ProjectTACValidation/';

    if use_p88
        load(fullfile(directory,'R2_TAC_HSM_2025-08-11',composite_interval,"HSM_p88_R2_results.mat"));
        R2_matrix = HSM_p88_R2_results;
    else
        load(fullfile(directory,'R2_TAC_HSM_2025-08-11',composite_interval,"HSM_p50_R2_results.mat"));
        R2_matrix = HSM_p50_R2_results;
    end
    

    % Labels for the axes
    vegetation_indices = {'NDVI', 'kNDVI', 'NIRv', 'NBR', 'NDMI', 'EVI', 'EVI2'};
    rolling_windows = {'1 Year', '2 Years', '3 Years', '4 Years', '5 Years', '6 Years','7 Years'};

    % Set the colormap range
    colormap_range = [0, 0.8]; % Define range for colormap

    % Create the heatmap
    
    fig = figure("Name",'R2 heat map');
    fig.Position = [20, 20, 500, 400];
    h = heatmap(rolling_windows, vegetation_indices, R2_matrix, ...
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
            save_path = fullfile(directory,'Figure/','R2_heatmap_HSMp88_v1.png');
        else
            save_path = fullfile(directory,'Figure/','R2_heatmap_HSMp50_v1.png');
        end
        exportgraphics(gcf, save_path, 'Resolution', 600);
        fprintf('Figure saved to: %s\n', save_path);
    end
end



