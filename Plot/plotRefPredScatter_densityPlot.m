function plotRefPredScatter_densityPlot()
% Conduct the scatter plot comparing reference and prediction of each
% spectral band.
% X: reference surface reflectance 
% Y: predicted surface reflectance

    close all;
    % plot_metric = false;
    plot_metric = true;
    directory = '/gpfs/sharedfs1/zhulab/Kexin/ProjectTACValidation/';

    % Define response variable
    VI = 'EVI2';
    composite_interval = 'bimonthly';
    rolling_window = 24;
    rolling_window_y = rolling_window/6;
    response_var = ['TAC_',VI,'_',composite_interval,'_',num2str(rolling_window)];
    response_var_Inyear = ['TAC_',VI,'_',composite_interval,'_',num2str(rolling_window_y),'year'];

    % filename = fullfile(directory,'Output/random_forest_output_4184.csv');
    filename = fullfile(directory,'Output',response_var_Inyear,['random_forest_output_4184_',response_var_Inyear,'.csv']);

    T = readtable(filename);

    %% load ref and pred
    ref = T.(response_var);
    pred = T.Predicted_TAC;
    valid_idx = ~isnan(pred);
    ref = ref(valid_idx);
    pred = pred(valid_idx);
    
    % Create colormap
    cmap = parula;  % You can choose any colormap you prefer

    %% Calculate density
    x = [ref,pred];
    % Define grid for density estimation
    xrange = linspace(min(x(:,1)), max(x(:,1)), 30);
    yrange = linspace(min(x(:,2)), max(x(:,2)), 30);
    [X, Y] = meshgrid(xrange, yrange);
        
    % Estimate density using ksdensity
    [density,~] = ksdensity(x, [X(:) Y(:)]);
    density = reshape(density, size(X));
        
    % Interpolate density values for the scatter points
    densityValues = interp2(X, Y, density, x(:,1), x(:,2));
        
    % Normalize density for coloring
    colormap(cmap); % Choose colormap
    colors = densityValues - min(densityValues);
    colors = colors / max(colors); % Normalize to [0, 1]            
    
    % Scatter plot with continuous color scale
    set(gcf,'Position',[100 100 600 500]);
    set(gcf,'color','w');
    p1 = scatter(ref, pred, 20, densityValues, 'filled');
    hold on;
    
    xlabel('Reference');
    ylabel('Prediction');
    % title(response_var);
    xlim([0,0.82]);
    xticks(linspace(0,0.8,5));
    ylim([0,0.82]);
    yticks(linspace(0,0.8,5));
        % clim([0,0.2]);
        % clim([0,120]);
    plot_colorbar = true;
    if plot_colorbar
        colorbar;
    end
    colormap(cmap);
    box on;
    % title(sprintf('%s Band',band_names{iband}));

    % add 1:1 line
    p2 = line([0, 1], [0, 1], 'Color', 'r', 'LineStyle', '--','LineWidth',2,'DisplayName','1:1 Line');  % 1:1 line
    
    hold off;
    legend(p2,'Location','northwest','Box','off','FontSize',16);
        
    if plot_metric
        CC_str = sprintf('CC = %.4f', cc(iband));
        text(0.8, 0.18, CC_str, 'HorizontalAlignment', 'right', 'FontSize', 14, 'Color', 'black');
        
        RMSE_str = sprintf('RMSE = %.4f', rmse(iband)./10000.0);
        text(0.8, 0.13, RMSE_str, 'HorizontalAlignment', 'right', 'FontSize', 14, 'Color', 'black');
        
        AAD_str = sprintf('AAD = %.4f', aad(iband)./10000.0);
        text(0.8, 0.08, AAD_str, 'HorizontalAlignment', 'right', 'FontSize', 14, 'Color', 'black');
    
        ERGAS_str = sprintf('ERGAS = %.4f', ergas(iband));
        text(0.8, 0.03, ERGAS_str, 'HorizontalAlignment', 'right', 'FontSize', 14, 'Color', 'black');
    end

    fontname(gcf,"Serif");
    set(gca,'FontSize',16);

      
end    % end of func