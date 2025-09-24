function plotLandsatDensity()
%PLOTLANDSATDENSITY Summary of this function goes here
%   Detailed explanation goes here
    close all;

    directory = '/gpfs/sharedfs1/zhulab/Kexin/ProjectTACValidation/Supplementary';

    composite_intervals = {'biweekly','monthly','bimonthly','quarterly'};

    n = 53;
    % n = 2712;
    density_valid = zeros(n,size(composite_intervals,1));
    density_single_missing = zeros(n,size(composite_intervals,1));
    density_double_missing = zeros(n,size(composite_intervals,1));
    density_more_missing = zeros(n,size(composite_intervals,1));
    

    %% Load sample data from different composite intervals
    for j = 1:length(composite_intervals)
        ci = composite_intervals{j};
        fprintf('Processing %s..\n', ci);

        % Landsat density for the 2712 forest sample points
        folderpath_DensityResults = fullfile(directory,['Landsat_FieldSample_density_',ci]);
        % folderpath_DensityResults = fullfile(directory,['Landsat_density_',ci]);
        if ~exist(folderpath_DensityResults)
            fprintf('Run checkLandsatDensityAllSample.m first!\n');
        end

        files = dir(fullfile(folderpath_DensityResults,'*.mat'));
 
        for i = 1:length(files)
            filename = files(i).name;
            load(fullfile(folderpath_DensityResults,filename));
            density_valid(i,j) = valid_data_pct;   % i is sample idx, j is composite interval
            density_single_missing(i,j) = single_missing_pct;
            density_double_missing(i,j) = double_missing_pct;
            density_more_missing(i,j) = more_missing_pct;
        end
    end


    %% Plot Figures   
    % === Calls for your four datasets ===
    labels = composite_intervals;  % {'biweekly','monthly','bimonthly','quarterly'}
    
    % Optional: set a common bandwidth for comparability (comment out to auto)
    commonBW = [];  % e.g., 0.5 or 1 if your units are percent; leave [] for auto
    
    % plot valid percentage scatter and boxplot for each composite interval
    % Number of categories (columns)
    [numObs, numCats] = size(density_valid);
    
    % Create figure
    figure; hold on;

    % --- Scatter points for each category ---
    for c = 1:numCats
        scatter(ones(numObs,1)*c, density_valid(:,c), 30, 'filled', ...
            'MarkerFaceAlpha', 0.6);  % aligned at category c
    end
    
    % --- Boxchart overlay ---
    boxchart(repelem(1:numCats, numObs), density_valid(:), ...
        'BoxFaceAlpha', 0.2, 'MarkerStyle', 'none', 'WhiskerLineColor','k');

    % Format axes
    xticks(1:numCats);
    xticklabels(composite_intervals);
    ylabel('Percentage of Valid Data');
    % title('Scatter points + Boxchart per Category');
    grid on;
    box on;
    set(gca,'fontsize',14)
    set(gca,'fontname','Arial')
    
 % plotDensityCurves(density_valid,           labels, ...
    % 'Distribution of Valid Data % (Density Curves)', 'Valid Data %', ...
    % 'Bandwidth', commonBW);
    
    % plotDensityCurves(density_single_missing,  labels, ...
    %     'Distribution of Single Missing % (Density Curves)', 'Single Missing %', ...
    %     'Bandwidth', commonBW);
    % 
    % plotDensityCurves(density_double_missing,  labels, ...
    %     'Distribution of Double Missing % (Density Curves)', 'Double Missing %', ...
    %     'Bandwidth', commonBW);
    % 
    % plotDensityCurves(density_more_missing,    labels, ...
    %     'Distribution of More-Than-Double Missing % (Density Curves)', 'More Missing %', ...
    %     'Bandwidth', commonBW);
  
 
end

% Helper: plot multiple density curves on one figure
function plotDensityCurves(matrixData, labels, titleStr, xLabelStr, varargin)
    % matrixData: N x K (each column is a group to plot)
    % labels:     1 x K cell array of legend labels
    % Optional name-value: 'Bandwidth', bw (scalar) to fix ksdensity bandwidth
    p = inputParser;
    addParameter(p, 'Bandwidth', []);
    parse(p, varargin{:});
    bw = p.Results.Bandwidth;

    colors = lines(size(matrixData,2));
    figure('Name', titleStr); set(gcf,'Position',[100,100,1000,500]);
    hold on; box on;
    for j = 1:size(matrixData,2)
        xj = matrixData(:,j);
        xj = xj(~isnan(xj));                  % drop NaNs if any
        if isempty(bw)
            [f, xi] = ksdensity(xj);
        else
            [f, xi]= ksdensity(xj, 'Bandwidth', bw);
        end
        plot(xi, f, 'LineWidth', 2, 'Color', colors(j,:), 'DisplayName', labels{j});
    end
    xlabel(xLabelStr);
    ylabel('Density');
    title(titleStr);
    legend('Location','best');
    grid on;
    set(gca,'FontName','Lucida Bright');
    set(gca,'FontSize',16);

    exportgraphics(gcf, [titleStr,'.png'], 'Resolution', 500);
end
