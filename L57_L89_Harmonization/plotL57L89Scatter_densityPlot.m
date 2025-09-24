function plotL57L89Scatter_densityPlot()
% Conduct the scatter plot comparing reference and prediction of each
% spectral band.
% X: reference surface reflectance 
% Y: predicted surface reflectance

    % close all;
    % save_fig = false;
    save_fig = true;%false; 
    directory = pwd;
    % band_names = {'NIR'};
    band_names = {'Blue','Green','Red'...
        'NIR','SWIR1','SWIR2'...
        'NDVI','kNDVI','NIRv'...
        'NBR','NDMI',...
        'EVI','EVI2'};
    scale = 10000;

    % load TIF coefficients
    filename = fullfile(directory,'TIFResults/TIFbrdf_coefficient_r00001c00001.mat');
    load(filename);

    % read L57
    filename = fullfile(directory,'X_brdf.csv');
    T1 = readtable(filename);
    T1.Properties.VariableNames = band_names;

    % read L89
    filename = fullfile(directory,'Y_brdf.csv');
    T2 = readtable(filename);
    T2.Properties.VariableNames = band_names;

    % density_plot_XY(T1,T2)
    %% load L57 and L89
    for iband = 1:length(band_names)

        band_name = band_names{iband};

        % read harmonization coefficients
        a = TIF_coefficient.Slopes(iband);
        b = TIF_coefficient.Intercepts(iband);

        % plot figure
        figure('Name',band_name);
        L57 = T1.(band_name)./scale;
        L89 = T2.(band_name)./scale;

        % Create colormap
        cmap = parula;  % You can choose any colormap you prefer

        %% Calculate density
        x = [L57,L89];
        if iband==1
            xrange = linspace(0, 0.3, 31);
            yrange = linspace(0, 0.3, 31);
        elseif iband >1 && iband<=3;
            xrange = linspace(0, 0.5, 31);
            yrange = linspace(0, 0.5, 31);
        elseif iband>3 && iband<7;
            % Define grid for density estimation
            xrange = linspace(0, 0.8, 31);
            yrange = linspace(0, 0.8, 31);
        else 
            % Define grid for density estimation
            xrange = linspace(-0.2, 1, 31);
            yrange = linspace(-0.2, 1, 31);
        end
        [X, Y] = meshgrid(xrange, yrange);

        % Estimate density using ksdensity
        [density,~] = ksdensity(x, [X(:) Y(:)]);
        density = reshape(density, size(X));

        % Interpolate density values for the scatter points
        densityValues = interp2(X, Y, density, x(:,1), x(:,2));
        
        % **Filter points where density > 1**
        validIdx = densityValues > 1;
        if sum(validIdx) == 0
            fprintf('No points with density > 1 for band: %s\n', band_name);
            continue;  % Skip plotting if no valid points
        end

        % Normalize density for coloring
        colormap(cmap); % Choose colormap
        colors = densityValues - min(densityValues);
        colors = colors / max(colors); % Normalize to [0, 1]            

        % Scatter plot with continuous color scale
        set(gcf,'Position',[100 100 600 500]);
        set(gcf,'color','w');
        p1 = scatter(L57(validIdx), L89(validIdx), 20, densityValues(validIdx), 'filled');
        hold on;

        % add 1:1 line
        p2 = line([-0.2, 1], [-0.2, 1], 'Color', 'r', 'LineStyle', '--','LineWidth',2,'DisplayName','1:1 Line');  % 1:1 line
        hold on;

        % add x and y labels
        xlabel('L57');
        ylabel('L89');
        title(band_names{iband});

        % set up xlim and ylim
        if iband==1
            ylim([0,0.3]);
            xlim([0,0.3]);
        elseif iband >1 && iband<=3;
            ylim([0,0.5]);
            xlim([0,0.5]);
        elseif iband>3 && iband<7;
            ylim([0,0.8]);
            xlim([0,0.8]);
        else
            ylim([-0.2,1]);
            xlim([-0.2,1]);
        end

        plot_colorbar = true;
        if plot_colorbar
            colorbar;
        end
        colormap(cmap);
        box on;
        % title(sprintf('%s Band',band_names{iband}));

        % add regression line
        y = (a*xrange.*scale+b)./scale;
        p3 = plot(xrange,y,'k-','LineWidth', 2,'DisplayName',sprintf('y = %.2f x+%.3f',a,b./scale));%'regression line');

        % add legend
        hold off;
        legend([p2,p3],'Location','southeast','Box','on','FontSize',16);

        fontname(gcf,"Serif");
        set(gca,'FontSize',16);
        
        folderpath_output = fullfile(directory,'Figures');
        if ~exist(folderpath_output)
            mkdir(folderpath_output);
        end

        if save_fig
            saveas(gcf,fullfile(folderpath_output,sprintf('brdfL57vsL89_%s.png',band_name)));
        end
        close all;
    end

    % close all;
end    % end of func