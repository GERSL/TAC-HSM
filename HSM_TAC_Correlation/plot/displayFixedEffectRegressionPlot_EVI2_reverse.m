function displayFixedEffectRegressionPlot_EVI2_reverse(varargin)
    %RUNREGRESSIONPLOT Summary of this function goes here
    %   Detailed explanation goes here
     
    close all;
    addpath("TAC\");

    % Define default values
    default_display_ids = [1:45];  % plot ids to analyze, remove 48 and 49 due to sparse observation, remove 52 due to the lack of climate data
    % default_display_ids = [1:47,50,51,53];

    default_save_fig = 1;               % do not save figures
    default_save_output = 0;            % do not save R2 output
    default_use_p88 = 0;                % use HSM p88 instead of HSM p50
    default_do_plot = 1;                 % display plots
    default_remove_climateTAC = 1;       % remove climate autocorrelatino impacts from observed TAC
    % default_remove_climateTAC = 0; 
    default_outlierRemoval = 1;         % remove outliers using loess
    default_use_abs = 0;                 % use the absolute value of TAC
    default_msg = 1;                     % display message


    % Create input parser
    p = inputParser;
    addParameter(p, 'display_ids', default_display_ids, @isnumeric);
    addParameter(p, 'use_p88', default_use_p88, @islogical);

    addParameter(p, 'do_plot', default_do_plot, @islogical);
    addParameter(p, 'save_fig', default_save_fig, @islogical);
    addParameter(p, 'save_output', default_save_output, @islogical);

    addParameter(p, 'remove_climateTAC', default_remove_climateTAC, @islogical);
    addParameter(p, 'outlier_removed',default_outlierRemoval, @islogical);
    addParameter(p, 'use_abs', default_use_abs, @islogical);
    addParameter(p, 'msg', default_msg, @islogical);

    % Parse inputs
    parse(p, varargin{:});

    % Assign parsed values to variables
    display_ids = p.Results.display_ids;
    save_fig = p.Results.save_fig;
    save_output = p.Results.save_output;
    use_p88 = p.Results.use_p88;
    do_plot = p.Results.do_plot;
    use_abs = p.Results.use_abs;
    msg = p.Results.msg;
    remove_climateTAC = p.Results.remove_climateTAC;
    outlier_removed = p.Results.outlier_removed;

    % Display parsed values (for debugging)
    disp('Parsed inputs:');
    disp(p.Results);

    directory = 'C:\ProjectTACValidation\';

    %% define folder paths
    folderpath_figures = fullfile(directory,'Figures');
    if ~exist(folderpath_figures)
        mkdir(folderpath_figures);
    end

    %% load Hydraulic traits
    filename = fullfile(directory,'data','FieldData','hydraulic_data_compiled_allSample_HPC.csv');
    T_HSM = readtable(filename);

    %% Calculate correlation btw TAC and HSM
    % VIs = {'NDVI','kNDVI','NIRv','NBR','NDMI','EVI','EVI2'};
    % composite_intervals = {'monthly'};
    composite_intervals = {'bimonthly'};
    % composite_intervals = {'quarterly'};
    % VIs = {'EVI2'};
    VIs = {'NDVI'};
    rolling_windows_y = 4;
    % trait = 'Pmin';
    trait = 'HSM';

    conseGap = 1;

    % empty array to hold R2
    HSM_p50_R2_results = zeros([length(VIs),length(rolling_windows_y)]);   
    HSM_p88_R2_results = zeros([length(VIs),length(rolling_windows_y)]);   

    for iV = 1:length(VIs)
        VI = VIs{iV};
        
        for ic = 1:length(composite_intervals)
            composite_interval = composite_intervals{ic};
    
            for ir = 1:length(rolling_windows_y)
                rolling_window_y = rolling_windows_y(ir);  % rolling window in year
                switch composite_interval
                    case 'biweekly'
                        rolling_window = rolling_window_y*26;
                    case 'monthly'
                        rolling_window = rolling_window_y*12;
                    case 'bimonthly'
                        rolling_window = rolling_window_y*6;
                    case 'quarterly'
                        rolling_window = rolling_window_y*4;
                end
                fprintf('Processing vi=%s, composite interval=%s, rolling window = %d-year\n',...
                    VI,composite_interval,rolling_window_y);
    
                response_var = ['TAC_',VI,'_',composite_interval,'_',num2str(rolling_window)];
                response_var_short = ['TAC_',VI,'_',num2str(rolling_window)];
                response_var_Inyear = ['TAC_',VI,'_',composite_interval,'_',num2str(rolling_window_y),'year'];
                

                %% Load VI (TACt-TACt|Xac)
                if outlier_removed
                    filename = fullfile(directory,'enhancedTAC_gap_filling_test/',['conseGap',int2str(conseGap)],[response_var_Inyear,'.csv']);
                else
                    filename = fullfile(directory,'enhancedTAC_gap_filling_test/',['conseGap',int2str(conseGap)],[response_var_Inyear,'_noOutlierRemoval.csv']);
                end
                T = readtable(filename);
                diff = T.diff;
                year = T.year;
                sampleID = T.sampleID;
                def = T.def_mean;    % def = total precipitation - ET
                mean_def = groupsummary(def, sampleID, "mean");  % annual mean of def
                T_HSM.mean_def = mean_def;
               
                clear T;

                %% Field data basic information
                point_ids = T_HSM(display_ids,:).pointID;
                plot_ids = T_HSM(display_ids,:).ID;
                plot_names = T_HSM(display_ids,:).Site;
                sample_year = T_HSM(display_ids,:).SampleYear;
                sample_month = T_HSM(display_ids,:).SampleMonth;
                rank = T_HSM(display_ids,:).rank;
                                
                % hydraulic traits
                p50 = T_HSM(display_ids,:).p50;
                p88 = T_HSM(display_ids,:).p88;
                psi_min = T_HSM(display_ids,:).Psi_min;
                HSM_p50 = T_HSM(display_ids,:).HSM_p50;
                HSM_p88 = T_HSM(display_ids,:).HSM_p88;
                DEF = T_HSM(display_ids,:).mean_def;
                
                %% only process the first rank plots (optional)
                % idx = rank==1|rank==2;
                idx = rank<=3;
                plot_ids = plot_ids(idx);
                sample_year = sample_year(idx);
                sample_month = sample_month(idx);
                p50 = p50(idx);
                p88 = p88(idx);
                psi_min = psi_min(idx);
                HSM_p50 = HSM_p50(idx);
                HSM_p88 = HSM_p88(idx);
                DEF = DEF(idx);
                plot_names = plot_names(idx);
                   
                %% Loop by plotid to access TAC on the sample year
                TAC = nan(length(point_ids),1);
                climate_ac_effect = nan(length(point_ids),1);
                for i = 1:length(point_ids)
                        
                    plotname = plot_names{i}; 
                    pointid = point_ids(i);
                    plotid = plot_ids(i);
                    % fprintf('Processing Plot %d %s, Point %d ...\n',plotid, plotname, pointid);               
                            
                    %% load the TAC_rec_cg file
                    if outlier_removed
                        folderpath_TACResults = fullfile(directory,'result','TACResults_FieldSample_2026-01-15',['Landsat_',composite_interval,'_conseGap',int2str(conseGap)]);
                    % else
                    %     folderpath_TACResults = fullfile(directory,'result','TACResults_FieldSample_2026-01-15',['Landsat_',composite_interval,'_conseGap',int2str(conseGap)]);
                    end
                    filepath_rcg = fullfile(folderpath_TACResults, sprintf('TAC_record_change_plot%05d.mat', pointid)); % r: row
                    load(filepath_rcg);
                        
                    % calculate annual TAC
                    TAC_annual = retime(TAC_record_change.(['TAC_',composite_interval]),"yearly","mean");
               
                    % extract TAC on the sample year month
                    year_field = sample_year(i);
                    month_field  = sample_month(i);
                    targetDate = datetime(year_field,month_field,1);
                    [~, nearestIndex] = min(abs(TAC_record_change.(['TAC_',composite_interval]).Dates - targetDate));
                    if ~isempty(nearestIndex)
                        TAC(i) = TAC_record_change.(['TAC_',composite_interval]).(response_var_short)(nearestIndex);
                    else
                        [~, nearestIndex] = min(abs(TAC_annual.Dates - datetime(year_field,1,1)));
                        % nearestIndex = find(TAC_annual.Dates== datetime(year_field,1,1)); 
                        try
                            TAC(i) = TAC_annual.(response_var_short)(nearestIndex);
                        catch
                            TAC(i) = NaN;
                        end
                    end
                    
                    climate_ac_effect(i) = diff(sampleID==pointid & year==year_field);
                end   % end of i

                %% Remove the impact of climate autocorrelation
                find(isnan(climate_ac_effect));
                % use mean value within the plot to fill nan
                climate_ac_effect(39) = mean(climate_ac_effect(36:40),"omitmissing");
                climate_ac_effect(41) = mean(climate_ac_effect(41:45),"omitmissing");
                climate_ac_effect(44) = mean(climate_ac_effect(41:45),"omitmissing");
                if remove_climateTAC
                    % TAC = TAC-diff(display_ids);
                    TAC = TAC-climate_ac_effect;
                end

                %% Use absolute values (optional)
                if use_abs
                    TAC = abs(TAC);
                end
                
                %% Calculate mean for each unique plot name
                % Convert plotnames into a numeric grouping variable
                [unique_names, ~, group_idx] = unique(plot_names);
                
                for j = 1:length(unique_names)
                    % Get the TAC values for the current group
                    group_data_1 = TAC(strcmp(plot_names, unique_names{j}));
                    fprintf('TAC of %s:\n',unique_names{j});
                    disp(group_data_1);
                    % Calculate the mean
                    % mean_TAC(j) = mean(group_data_1);
                    mean_TAC(j) = mean(group_data_1,'omitmissing');
                    
                    % Get the HSM_p50 values for the current group
                    if use_p88
                        group_data_2 = HSM_p88(strcmp(plot_names, unique_names{j}));
                    else
                         switch trait
                            case 'HSM'
                                group_data_2 = HSM_p50(strcmp(plot_names, unique_names{j}));
                            case 'Pmin'
                                group_data_2 = psi_min(strcmp(plot_names, unique_names{j}));   % TEST Pmin
                            case 'P50'
                                group_data_2 = p50(strcmp(plot_names, unique_names{j}));   % TEST P50
                         end
                    end
                    % Calculate the mean
                    mean_HSM(j) = mean(group_data_2);
                    % % Get the ET deficit for the current group  
                    group_data_3 = DEF(strcmp(plot_names, unique_names{j}));
                    mean_DEF(j) = mean(group_data_3);
                end

                 %% Fig. TAC vs HSM_p50
                fig = figure("Name",'TAC vs HSM');
                % fig.Position = [20, 20, 550, 400];
                fig.Position = [20, 20, 500, 460];

                %% Fit fixed effect regression between TAC and HSM
                % y = b1 + b2*HSM + B3*DEF + e;
                mean_DEF = mean_DEF*365*1000;
                mdl = slope_common_intercept_water(mean_HSM', 1-mean_TAC', mean_DEF');
                fprintf('R2 = %.2f\n',mdl.Rsquared.Adjusted);

                %% Visualize the regression
                beta1 = mdl.Coefficients.Estimate(1);  % intercept
                beta2 = mdl.Coefficients.Estimate(2);  % slope - HSM
                beta3 = mdl.Coefficients.Estimate(3);  % slope - water

                beta = [beta1;beta2;beta3];  % [beta1, beta2, beta0]
                plot_fe_slope_intercept_water(mean_HSM', 1-mean_TAC', mean_DEF', beta);
                
                % add colorbar
                cmap = turbo(64);
                colormap(cmap);
                clim([-1800,-300]);
                % cb = colorbar;
                % cb.Ticks = [-1800,-1500,-1200,-900,-600,-300];
                % cb.Label.String='Cumulative Water Deficit (mm/year)';

                % % Add forest plot names
                for ip = 1:length(unique_names)
                    switch trait 
                         case 'HSM'
                            switch unique_names{ip} 
                                case {'MAN','NVX'}%'ATTO'
                                    text(mean_HSM(ip)+0.03,1-mean_TAC(ip)+0.02,unique_names{ip},'fontsize',12);
                                case 'SUC'
                                    text(mean_HSM(ip)-0.35,1-mean_TAC(ip)-0.01,unique_names{ip},'fontsize',12);
                                case 'ALP1'
                                    text(mean_HSM(ip)+0.02,1-mean_TAC(ip)+0.04,unique_names{ip},'fontsize',12);
                                case 'KEN1'
                                    text(mean_HSM(ip)-0.3,1-mean_TAC(ip)+0.04,unique_names{ip},'fontsize',12)
                                case 'TAM'
                                    text(mean_HSM(ip)+0.03,1-mean_TAC(ip)-0.02,unique_names{ip},'fontsize',12);
                                case 'ALP2'
                                    text(mean_HSM(ip)-0.2,1-mean_TAC(ip)+0.04,unique_names{ip},'fontsize',12);
                                case 'CAX' 
                                    text(mean_HSM(ip)+0.03,1-mean_TAC(ip)-0.02,unique_names{ip},'fontsize',12);
                                case 'FEC'
                                    text(mean_HSM(ip)+0.02,1-mean_TAC(ip)+0.02,unique_names{ip},'fontsize',12);
                           end
                        case 'Pmin'
                            switch unique_names{ip} 
                                case {'MAN','NVX','ATTO','SUC'}
                                    text(mean_HSM(ip)+0.02,1-mean_TAC(ip)-0.01,unique_names{ip},'fontsize',12);
                                case 'ALP1'
                                    text(mean_HSM(ip)+0.01,1-mean_TAC(ip)-0.01,unique_names{ip},'fontsize',12);
                                case 'KEN1'
                                    text(mean_HSM(ip)-0.7,1-mean_TAC(ip),unique_names{ip},'fontsize',12)
                                case 'TAM'
                                    text(mean_HSM(ip)+0.01,1-mean_TAC(ip)-0.02,unique_names{ip},'fontsize',12);
                                case 'ALP2'
                                    text(mean_HSM(ip)+0.02,1-mean_TAC(ip)+0.01,unique_names{ip},'fontsize',12);
                                case 'CAX' % same HSM as FEC
                                    text(mean_HSM(ip)-0.1,1-mean_TAC(ip)-0.02,unique_names{ip},'fontsize',12);
                                case 'FEC'
                                    text(mean_HSM(ip)+0.02,1-mean_TAC(ip)+0.03,unique_names{ip},'fontsize',12);
                                case 'PNSL'
                                    text(mean_HSM(ip)+0.04,1-mean_TAC(ip)+0.01,unique_names{ip},'fontsize',12);
                                case 'ZF-2'
                                    text(mean_HSM(ip)+0.01,1-mean_TAC(ip)+0.03,unique_names{ip},'fontsize',12);
                                case 'LSFENSO'
                                    text(mean_HSM(ip)-1.3,1-mean_TAC(ip),unique_names{ip},'fontsize',12);
                                case 'LSFnonENSO'
                                    text(mean_HSM(ip)-0.02,1-mean_TAC(ip)-0.02,'LSF','fontsize',12);
                            end
                    end
                    hold on;
                end
                ylabel(['1- (TAC of ', VI,')']);
                % ylim([0.25,0.92]);
                ylim([0.25,1.1]);
                yticks(linspace(0.3,1.0,8));
                
                % %% Calculate bootstraping R2 with uncertainty (optional)
                % [R2_bt,ci] = R2_bootstrap(mean_TAC,mean_HSM,2000,0.05);
                % fprintf('Observed R^2 = %.3f\n', R2_bt);
                % fprintf('95%% CI = [%.3f, %.3f]\n', ci(1), ci(2));


                %% Add text 
                R2 = mdl.Rsquared.Adjusted;
                pval = mdl.Coefficients.pValue(2);
                pval_water = mdl.Coefficients.pValue(3);

                %  %% Calculate bootstraping R2 with uncertainty (optional)
                % [R2,ci] = R2_bootstrap(mean_HSM,1-mean_TAC,2000,0.05);
                % fprintf('Observed R^2 = %.3f\n', R2);
                % fprintf('95%% CI = [%.3f, %.3f]\n', ci(1), ci(2));
                % xlabel('TAC','Interpreter','latex');

                % Create annotation text
                ax = gca;
            
                txt = sprintf('y = %.3fx+%.4f*CWD+%.2f\nR^2 = %.2f\np(HSM) = %.4f\np(CWD) = %.4f',...
                    beta2, beta3, beta1, R2, pval, pval_water);
                switch trait
                    case 'HSM'
                        text(ax.XLim(1) + 0.4*range(ax.XLim), ...
                             ax.YLim(1) + 0.25*range(ax.YLim), ...
                             txt, 'FontSize', 9, 'VerticalAlignment', 'top', 'BackgroundColor', 'none');
                    otherwise
                        text(ax.XLim(1) + 0.43*range(ax.XLim), ...
                             ax.YLim(1) + 0.25*range(ax.YLim), ...
                             txt, 'FontSize', 12, 'VerticalAlignment', 'top', 'BackgroundColor', 'none');
                end

                if use_p88
                    xlim([-0.1,3.5]);
                    % ylabel('$\mathrm{HSM}_{P88}$ (MPa)','Interpreter','latex');
                    xlabel('HSM_{P88} (MPa)', 'Interpreter','tex', 'FontName','Arial');
                else
                    switch trait
                        case 'HSM'
                            xlim([-1.1,1.5]);
                            xlabel('HSM (MPa)', 'Interpreter','tex', 'FontName','Arial');
                        case 'Pmin'
                            xlim([-4.5,0]);
                            xlabel('P_{min} (MPa)', 'Interpreter','tex', 'FontName','Arial');
                        case 'P50'
                            xlim([-4.5,0]);
                            xlabel('P_{50} (MPa)', 'Interpreter','tex', 'FontName','Arial');
                    end
                    box on;
                    set(gca,'FontSize',14);
                    fontname(fig,'Arial');
                    if save_fig
                        if use_p88
                            figurename = sprintf('%s_p88vs%s_reverse.png',trait,response_var_Inyear);
                        else
                            figurename = sprintf('Fixed_effect_%s_p50vs%s_reverse_%s.png',trait,response_var_Inyear,int2str(default_remove_climateTAC));
                        end
                        exportgraphics(gcf, fullfile(folderpath_figures,string(figurename)),'Resolution',600);
                    end
                end

            end  % end of ir
        end   % end of ic
    end   % end of iV
 
end   % end of func



function [R2, ci] = R2_bootstrap(x, water, y, nboot, alpha)
%R2_BOOTSTRAP Estimate R^2 and its bootstrap confidence interval
%
%   [R2, ci] = R2_bootstrap(x, y, nboot, alpha)
%
%   Inputs:
%       x     - predictor vector (numeric, length n)
%       y     - response vector (numeric, same length as x)
%       nboot - number of bootstrap replicates (default = 1000)
%       alpha - significance level for CI (default = 0.05 → 95% CI)
%
%   Outputs:
%       R2    - observed R^2 from linear regression
%       ci    - [low, high] bootstrap confidence interval for R^2
%
%   Example:
%       x = (1:14)'; 
%       y = 2*x + randn(14,1);
%       [R2, ci] = R2_bootstrap(x,y,2000,0.05)

    if nargin < 4 || isempty(nboot)
        nboot = 1000;
    end
    if nargin < 5 || isempty(alpha)
        alpha = 0.05;
    end

    % Ensure column vectors
    x = x(:); y = y(:);
    n = numel(x);

    % Fit regression once to get observed R^2
    X = [ones(size(x)), x(:), water(:)];
    mdl = fitlm(X, y, 'Intercept', false);
    mdl = fitlm(x, y);
    R2  = mdl.Rsquared.Adjusted;

    % Bootstrap distribution
    R2boot = zeros(nboot,1);
    for b = 1:nboot
        idx = randsample(n, n, true); % resample with replacement
        xb = x(idx);
        yb = y(idx);
        mdl_b = fitlm(xb, yb);
        R2boot(b) = mdl_b.Rsquared.Adjusted;
    end

    % CI from bootstrap percentiles
    ci = prctile(R2boot, [100*alpha/2, 100*(1-alpha/2)]);
end


function mdl = slope_common_intercept_water(x, y, water)
% y_i = alpha + beta*x_i + gamma*water_i + e_i

    X = [ones(size(x)), x(:), water(:)];
    mdl = fitlm(X, y, 'Intercept', false); % intercept already in X
    % disp(mdl);

end


function plot_fe_slope_intercept_water(x, y, water, beta)
% Visualize model: y = beta0 + beta1*x + beta2*water
%
% Inputs:
%   x, y, water : n×1 vectors
%   beta        : [beta1, beta2, beta0] from your regression
%
% Example:
%   beta = [1.1873; 0.27953; -58.062];
%   plot_fe_slope_intercept_water(x, y, water, beta);

    x = x(:); y = y(:); water = water(:);

    % Scatter of observed data, color by water availability
    scatter(x, y, 40, water, 'filled'); 
    cmap = turbo(64);
    colormap(flipud(cmap));
    % colorbar;
    clim([min(water),0.013*1000]);
    xlabel('x'); ylabel('y');
    % title('Same slope, water-dependent intercept');
    hold on;

    % Choose representative water levels (low, mid, high)
    w_levels = [min(water), median(water), max(water)];
    colors = {[0 0.4470 0.7410], ...   % blue
          [0.4660 0.6740 0.1880], ... % green
          [0.8500 0.3250 0.0980]};    % orange

    % Plot regression lines
    xline = linspace(min(x)-0.5, max(x)+0.5, 200);
    for i = 1:numel(w_levels)
        yline = beta(1) + beta(2)*xline + beta(3)*w_levels(i);
        plot(xline, yline, ':', 'LineWidth', 2, 'Color', colors{i}, ...
             'DisplayName', sprintf('CWD = %.2f', w_levels(i)));
    end
    

    % legend('Data','Location','best');
    hold off;
end


