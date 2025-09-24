function plotHeatMapSlope()
    % Function to visualize a 7 × 7matrix of R² values as a heatmap.
    % 
    % INPUTS
    %   R2_matrix  - A 7×7 matrix of R² values
    %   save_fig   - (Optional) Boolean, whether to save the figure (default: false)
    %   save_path  - (Optional) Path to save the figure if save_fig = true
    %
    % Example:
    %   R2_matrix = rand(7,7);  % Example R² matrix
    %   plotHeatMap(R2_matrix, true, 'C:\Users\YourName\Documents\heatmap.png')
    
    close all;

    save_fig = false;%true;
    use_p88 = false; %true;%  % 
    
    composite_interval = 'bimonthly';
    % composite_interval = 'monthly';
    % composite_interval = 'biweekly';%'monthly';%'bimonthly';%'monthly';%'biweekly';%% 

    directory = '/gpfs/sharedfs1/zhulab/Kexin/ProjectTACValidation/';

    if use_p88
        load(fullfile(directory,'slope_TAC_HSM_2025-08-01',composite_interval,"HSM_p88_slopes.mat"));
        slope_matrix = HSM_p88_slopes;
    else
        load(fullfile(directory,'slope_TAC_HSM_2025-08-01',composite_interval,"HSM_p50_slopes.mat"));
        slope_matrix = HSM_p50_slopes;
        load(fullfile(directory,'slope_TAC_HSM_2025-08-01',composite_interval,"HSM_p50_pValues.mat"));
        pValues = HSM_p50_pValues;
    end
    slope_matrix = round(slope_matrix,2);


    % Labels for the axes
    vegetation_indices = {'NDVI', 'kNDVI', 'NIRv', 'NBR', 'NDMI', 'EVI', 'EVI2'};
    rolling_windows = {'1 Year', '2 Years', '3 Years', '4 Years', '5 Years', '6 Years','7 Years'};

    % Reorder rows of slope_matrix and pValues to match new vegetation index order
    old_order = {'NDVI', 'kNDVI', 'NIRv', 'NBR', 'NDMI', 'EVI', 'EVI2'};
    new_order = {'NDVI', 'kNDVI', 'NBR', 'NDMI', 'NIRv', 'EVI', 'EVI2'};
    
    % Find the row indices for the new order
    [~, new_idx] = ismember(new_order, old_order);
    
    slope_matrix = slope_matrix(new_idx, :);
    pValues = pValues(new_idx, :);
    vegetation_indices = new_order;



    % Prepare figure
    figure("Name", 'Slope Heat Map', "Position", [100, 100, 750, 500]);
    imagesc(slope_matrix);
    colormap(flipud(parula));
    colorbar;
    caxis([-4, 4]);
    set(gca, 'XTick', 1:length(rolling_windows), 'XTickLabel', rolling_windows, ...
             'YTick', 1:length(vegetation_indices), 'YTickLabel', vegetation_indices, ...
             'FontSize', 14, 'YDir', 'normal');

    % Add slope values and stars
    for i = 1:size(slope_matrix, 1)
        for j = 1:size(slope_matrix, 2)
            slope_val = slope_matrix(i,j);
            % Display slope in center
            text(j, i, sprintf('%.2f', slope_val), ...
                'HorizontalAlignment', 'center', 'FontSize', 12, 'Color', 'k');
    
            % Determine significance and add star in top right corner
            if ~isnan(pValues(i,j))
                if pValues(i,j) < 0.01
                    stars = '**';
                elseif pValues(i,j) < 0.05
                    stars = '*';
                else
                    stars = '';
                end
            else
                stars = '';
            end
    
            if ~isempty(stars)
                text(j + 0.45, i + 0.3, stars, ...
                    'HorizontalAlignment', 'right', ...
                    'VerticalAlignment', 'top', ...
                    'FontSize', 10, 'FontWeight', 'bold', 'Color', 'k');
            end
        end
    end


    set(gca, 'FontSize', 16);

    % Save figure if required
    if save_fig
        if use_p88
            save_path = fullfile(directory,'Figure/','slope_heatmap_HSMp88.png');
        else
            save_path = fullfile(directory,'Figure/','slope_heatmap_HSMp50.png');
        end
        exportgraphics(gcf, save_path, 'Resolution', 600);
        fprintf('Figure saved to: %s\n', save_path);
    end
end



