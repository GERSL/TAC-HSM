function plotHeatMap_AIC()
    % Function to visualize a 7 × 7 matrix of R² values as a heatmap.
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

    save_fig = 1;
    use_p88 = 0;
    
    % composite_interval = 'quarterly';
    composite_interval = 'bimonthly';
    % composite_interval = 'monthly';
    
    conseGap = 0;
    % conseGap = 1;
    % conseGap = 2;

    directory = 'C:\ProjectTACValidation\';


    load(fullfile(directory,'r_TAC_HSM_AIC_conseGapTest',composite_interval,['HSM_p50_r_','conseGap',int2str(conseGap),'.mat']));
    slope_matrix = HSM_p50_r;
    load(fullfile(directory,'r_TAC_HSM_AIC_conseGapTest',composite_interval,['HSM_p50_pValue_','conseGap',int2str(conseGap),'.mat']));
    pValues = HSM_p50_pValues;

    load(fullfile(directory,'r_TAC_HSM_AIC_conseGapTest',composite_interval,['HSM_p50_AIC1_','conseGap',int2str(conseGap),'.mat']));
    AIC1_matrix = HSM_p50_AIC1;
    load(fullfile(directory,'r_TAC_HSM_AIC_conseGapTest',composite_interval,['HSM_p50_AIC2_','conseGap',int2str(conseGap),'.mat']));
    AIC2_matrix = HSM_p50_AIC2;

    load(fullfile(directory,'r_TAC_HSM_AIC_conseGapTest',composite_interval,['HSM_p50_R2_mdl1_','conseGap',int2str(conseGap),'.mat']));
    R2_mdl1_matrix = HSM_p50_R2_mdl1;
    load(fullfile(directory,'r_TAC_HSM_AIC_conseGapTest',composite_interval,['HSM_p50_R2_mdl2_','conseGap',int2str(conseGap),'.mat']));
    R2_mdl2_matrix = HSM_p50_R2_mdl2;

    slope_matrix = round(slope_matrix,2);
    model_sel = AIC1_matrix>AIC2_matrix;  % 0 mean model_1 is better, 1 mean model_2 is better


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
    model_sel = model_sel(new_idx,:);
    R2_mdl1_matrix = R2_mdl1_matrix(new_idx,:);
    R2_mdl2_matrix = R2_mdl2_matrix(new_idx,:);
    vegetation_indices = new_order;

    % Prepare figure
    figure("Name", ['R2 Heat Map ',composite_interval], "Position", [100, 100, 650, 500]);
    slope_matrix(slope_matrix<0)=0;
    imagesc(slope_matrix);
    clim([0 1]);  
    % cmap = greyBlueYellowBlend(256, 0.10, 2);
    cmap = greyYellowBlend(256,0.35,1);
    % cmap = grey_yellow_orange(256);
    % cmapRev = flipud(cmap);
    colormap(gca, cmap);%greyBlueYellowBlend(256, 0.10,2));
    % cb = colorbar;
    % cb.Limits  = [0,1];
    % cb.Ticks = 0:0.2:1;
    % 
    % %Replace first tick label with "≤0"
    % tickLabels = strsplit(num2str(cb.Ticks));   % convert to cell array of strings
    % tickLabels{1} = '≤ 0';
    % cb.TickLabels = tickLabels;

    % clim([0,1]);
    set(gca, 'XTick', 1:length(rolling_windows), 'XTickLabel', rolling_windows, ...
             'YTick', 1:length(vegetation_indices), 'YTickLabel', vegetation_indices, ...
             'FontSize', 16, 'YDir', 'normal');

    % Add slope values and stars
    for i = 1:size(slope_matrix, 1)
        for j = 1:size(slope_matrix, 2)
            slope_val = slope_matrix(i,j);
            mdl = model_sel(i,j);
            R2_mdl1 = R2_mdl1_matrix(i,j);
            R2_mdl2 = R2_mdl2_matrix(i,j);

            % Display R2 in center
            if mdl==1    % second model is better
                if R2_mdl2>0 && slope_val>0
                    text(j, i, sprintf('%.2f', R2_mdl2), ...
                        'HorizontalAlignment', 'center', 'FontSize', 14, 'Color', 'k','FontWeight','bold');
                else
                    text(j, i, 'NA', ...
                    'HorizontalAlignment', 'center', 'FontSize', 14, 'Color', 'k','FontWeight','bold');
                end
            else         % first model is better
                if R2_mdl1>0 && slope_val>0
                    text(j, i, sprintf('%.2f', R2_mdl1), ...
                        'HorizontalAlignment', 'center', 'FontSize', 14, 'Color', 'k');
                else
                    text(j, i, 'NA', ...
                    'HorizontalAlignment', 'center', 'FontSize', 14, 'Color', 'k');
                end
            end
      
            % Determine significance and add star in top right corner
            if ~isnan(pValues(i,j)) && slope_val>0
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
                    'FontSize',8, 'FontWeight', 'bold', 'Color', 'k');
            end
        end   % end of j
    end   % end of i

    % Save figure if required
    if save_fig
        mkdir(fullfile(directory,'ValidationFigures'));
        save_path = fullfile(directory,'ValidationFigures/',['AIC_R2_heatmap_HSMp50VS1-TAC_',composite_interval,'_conseGap',int2str(conseGap),'_nocolorbar.png']);
        exportgraphics(gcf, save_path, 'Resolution', 1000);
        fprintf('Figure saved to: %s\n', save_path);
        close all;
    end

   


end


function cmap = greyBlueYellowBlend(n, fracLight, gammaPow)
% Smooth diverging colormap with grey at 0, yellow for negatives, blue for positives.
%   n         - total colors (default 256)
%   fracLight - fraction (0–1) where "light" waypoint sits from grey to dark (default 0.35)
%   gammaPow  - nonlinearity (>=1). >1 compresses colors near grey (default 1.0)

    if nargin < 1 || isempty(n), n = 256; end
    if nargin < 2 || isempty(fracLight), fracLight = 0.35; end
    if nargin < 3 || isempty(gammaPow), gammaPow = 1.0; end
    fracLight = max(0.05, min(0.95, fracLight));

    % Colors
    grey   = [0.82 0.82 0.82];

    % Yellow side (negative): light near zero to darker away from zero
    yLight = [1.00 1.00 0.70];
    yDark  = [1.00 0.75 0.00];

    % Blue side (positive): light near zero to darker away from zero
    bLight = [0.80 0.90 1.00];
    bDark  = [0.00 0.20 0.60];

    % Sizes
    nSide = floor(n/2);
    t = linspace(0,1,nSide)'.^gammaPow;  % 0 near grey → 1 far from zero

    % Piecewise: grey→light (0..fracLight), light→dark (fracLight..1)
    % helper
    interp2seg = @(c0,c1,c2,t,f) ...
        (t <= f).*(c0 + (c1-c0).* (t./max(f,eps))) + ...
        (t  > f).*(c1 + (c2-c1).* ((t-f)./max(1-f,eps)));

    % Build sides from grey outward
    sideGY = [ ...
        interp2seg(grey(1), yLight(1), yDark(1), t, fracLight), ...
        interp2seg(grey(2), yLight(2), yDark(2), t, fracLight), ...
        interp2seg(grey(3), yLight(3), yDark(3), t, fracLight) ];

    sideGB = [ ...
        interp2seg(grey(1), bLight(1), bDark(1), t, fracLight), ...
        interp2seg(grey(2), bLight(2), bDark(2), t, fracLight), ...
        interp2seg(grey(3), bLight(3), bDark(3), t, fracLight) ];

    % Arrange: low (most negative) → high (most positive)
    negHalf = flipud(sideGY);       % dark yellow → ... → grey
    posHalf = sideGB;               % grey → ... → dark blue

    if mod(n,2)==0
        cmap = [negHalf; posHalf];
    else
        cmap = [negHalf; grey; posHalf];
    end
end


function cmap = greyYellowBlend(n, fracLight, gammaPow)
%GREYYELLOWBLEND  Smooth sequential colormap: grey → light yellow → dark yellow
%
%   cmap = greyYellowBlend(n, fracLight, gammaPow)
%
%   Inputs:
%       n         - total colors (default = 256)
%       fracLight - fraction (0–1) where "light" waypoint sits (default = 0.35)
%       gammaPow  - nonlinearity (>=1). >1 compresses colors near grey (default = 1.0)
%
%   Output:
%       cmap      - n×3 RGB colormap from grey → yellow
%
%   Example:
%       colormap(greyYellowBlend(256,0.3,1.5)); colorbar;

    if nargin < 1 || isempty(n), n = 256; end
    if nargin < 2 || isempty(fracLight), fracLight = 0.35; end
    if nargin < 3 || isempty(gammaPow), gammaPow = 1.0; end
    fracLight = max(0.05, min(0.95, fracLight));

    % Define anchor colors
    grey   = [0.82 0.82 0.82];
    yLight = [1.00 1.00 0.70];   % pale yellow
    yDark  = [1.00 0.75 0.00];   % orange-yellow

    % Parameter space
    t = linspace(0,1,n)'.^gammaPow;  % 0 near grey → 1 near dark yellow

    % Piecewise interpolation: grey→light→dark yellow
    interp2seg = @(c0,c1,c2,t,f) ...
        (t <= f).*(c0 + (c1-c0).* (t./max(f,eps))) + ...
        (t  > f).*(c1 + (c2-c1).* ((t-f)./max(1-f,eps)));
    cmap = [ ...
        interp2seg(grey(1), yLight(1), yDark(1), t, fracLight), ...
        interp2seg(grey(2), yLight(2), yDark(2), t, fracLight), ...
        interp2seg(grey(3), yLight(3), yDark(3), t, fracLight) ];
end

