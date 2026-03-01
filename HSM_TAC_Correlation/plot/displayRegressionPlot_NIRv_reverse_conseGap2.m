function displayRegressionPlot_NIRv_reverse_conseGap2(varargin)
    %RUNREGRESSIONPLOT Summary of this function goes here
    %   Detailed explanation goes here
     

    % ks 20250119: add lines to calculate mean annual temperature (t2m).

    close all;
    addpath("TAC\");

    % Define default values
    default_display_ids = [1:45];  % plot ids to analyze, remove 48 and 49 due to sparse observation, remove 52 due to the lack of climate data
    % default_display_ids = [1:47,50,51,53];

    default_save_fig = 0;               % do not save figures
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

    % directory = 'C:\Users\kes20012\OneDrive - University of Connecticut\Documents\TACResilienceValidation\';
    directory = 'C:/ProjectTACValidation';

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
    composite_intervals = {'bimonthly'};
    % composite_intervals = {'quarterly'};
    VIs = {'NIRv'};
    % VIs = {'EVI2'};
    rolling_windows_y = 4;
    trait = 'HSM';
    conseGap = 2;
    % trait = 'Pmin';

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
                % filename = fullfile(directory,'Input_gap_filling_test',['conseGap',int2str(conseGap)],...
                %     response_var_Inyear,['Sample_multipleInPlot_HPC_input_5yr_',response_var_Inyear,'_updated.csv']);
                T = readtable(filename);
                diff = T.diff;
                year = T.year;
                sampleID = T.sampleID;
                def = T.def_mean;    % def = total precipitation - ET
                tp = T.tp_mean;
                t2m = T.t2m_mean;
                mean_def = groupsummary(def, sampleID, "mean")*365*1000;  % 25-year annual water deficit (mm)
                MAP = groupsummary(tp,sampleID,'mean')*365*1000;  % 25-year annual precipitation (mm)
                MAT = groupsummary(t2m,sampleID,'mean');
                T_HSM.mean_def = mean_def;
                T_HSM.MAP = MAP;
                T_HSM.MAT = MAT;
               
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
                MAP = T_HSM(display_ids,:).MAP;
                MAT = T_HSM(display_ids,:).MAT;

                
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
                MAP = MAP(idx);
                MAT = MAT(idx);
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
                    else
                        folderpath_TACResults = fullfile(directory,'result','TACResults_FieldSample_2026-01-15noOutlierRemoval/',['Landsat_',composite_interval]);
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

                    % Get the mean DEF for the current group  
                    group_data_3 = DEF(strcmp(plot_names, unique_names{j}));
                    mean_DEF(j) = mean(group_data_3);

                    % Get the MAP for the current group  
                    group_data_4 = MAP(strcmp(plot_names, unique_names{j}));
                    mean_MAP(j) = mean(group_data_4);

                    % Get the MAT for the current group  
                    group_data_5 = MAT(strcmp(plot_names, unique_names{j}));
                    mean_MAT(j) = mean(group_data_5);
                end

                %% Fit linear regression between TAC and HSM
                id = ~isnan(mean_HSM);
                [r,p_value] = corrcoef(mean_HSM(id),1-mean_TAC(id)); 
                r = r(1,2);
                p_value = p_value(1,2);
                if msg
                    fprintf('HSM vs TAC r = %.3f,p_value = %.4f \n',r,p_value);
                end
                if use_p88
                    HSM_p88_r_results(iV,ir) = r;
                else
                    HSM_50_r_results(iV,ir) = r;
                end
               
            end  % end of ir
        end   % end of ic
    end   % end of iV
                    

    folderpath_output = fullfile(directory,['plot-mean_TAC'],composite_interval,int2str(rolling_window_y));
    if ~exist(folderpath_output)
        mkdir(folderpath_output);
    end
    if save_output
        outT = table(unique_names,mean_TAC',mean_MAT',mean_MAP',mean_DEF'*1000,'VariableNames', {'Site',sprintf('TAC of %s',VI),'MAT','MAP','CWD'});
        if remove_climateTAC
            writetable(outT,fullfile(folderpath_output,'enhancedTAC.csv'));
        else
            writetable(outT,fullfile(folderpath_output,'observedTAC.csv'));
        end
    end
            
   
    if do_plot
        %% Fig. TAC vs HSM_p50
        fig = figure("Name",'TAC vs HSM');
        % fig.Position = [20, 20, 700, 500];
        fig.Position = [20, 20, 500, 460];
        sz = 40;

        % Display each forest ploe as a colored dot
        scatter(mean_HSM,1-mean_TAC,sz,mean_DEF,'filled');
        % scatter(mean_HSM,1-mean_TAC,sz,mean_MAP,'filled');
        cmap = turbo(64);
        colormap(cmap);
        clim([-1800,-300]);
        % cb = colorbar;
        % cb.Ticks = [-1800,-1500,-1200,-900,-600,-300];
        % cb.Label.String='Cumulative Water Deficit (mm/year)';
        hold on;

        % % Add forest plot names
        for ip = 1:length(unique_names)
            fprintf(unique_names{ip},'/n');
            disp(mean_DEF(ip))
            % text(mean_HSM(ip)-0.1,1-mean_TAC(ip),unique_names{ip},'fontsize',12);
            switch trait 
                case 'HSM'
                    switch unique_names{ip} 
                        case {'MAN','NVX'}%'ATTO'
                            text(mean_HSM(ip)+0.02,1-mean_TAC(ip)-0.02,unique_names{ip},'fontsize',12);
                        case 'SUC'
                            text(mean_HSM(ip)+0.02,1-mean_TAC(ip)-0.03,unique_names{ip},'fontsize',12);
                        case 'ALP1'
                            text(mean_HSM(ip)+0.02,1-mean_TAC(ip)-0.01,unique_names{ip},'fontsize',12);
                        case 'KEN1'
                            text(mean_HSM(ip)-0.2,1-mean_TAC(ip)-0.04,unique_names{ip},'fontsize',12)
                        case 'TAM'
                            text(mean_HSM(ip)+0.03,1-mean_TAC(ip)-0.02,unique_names{ip},'fontsize',12);
                        case 'ALP2'
                            text(mean_HSM(ip)+0.03,1-mean_TAC(ip)-0.02,unique_names{ip},'fontsize',12);
                        case 'CAX' 
                            text(mean_HSM(ip)+0.03,1-mean_TAC(ip)-0.02,unique_names{ip},'fontsize',12);
                        % case 'FEC'
                        %     text(mean_HSM(ip)+0.02,1-mean_TAC(ip)+0.02,unique_names{ip},'fontsize',12);
                        case 'FEC'
                            text(mean_HSM(ip)+0.03,1-mean_TAC(ip)-0.02,unique_names{ip},'fontsize',12);
                        % case 'PNSL'
                        %     text(mean_HSM(ip)+0.04,1-mean_TAC(ip)+0.01,unique_names{ip},'fontsize',12);
                        % case 'ZF-2'
                        %     text(mean_HSM(ip)+0.01,1-mean_TAC(ip)+0.03,unique_names{ip},'fontsize',12);
                        % case 'LSFENSO'
                        %     text(mean_HSM(ip)-0.55,1-mean_TAC(ip),unique_names{ip},'fontsize',12);
                        % case 'LSFnonENSO'
                        %     text(mean_HSM(ip)-0.04,1-mean_TAC(ip)-0.02,'LSF','fontsize',12);
                    end
                case 'Pmin'
                    switch unique_names{ip} 
                        case {'MAN','NVX','ATTO','SUC'}
                            text(mean_HSM(ip)+0.02,1-mean_TAC(ip)-0.01,unique_names{ip},'fontsize',12);
                        case 'ALP1'
                            text(mean_HSM(ip)+0.01,1-mean_TAC(ip)-0.01,unique_names{ip},'fontsize',12);
                        case 'KEN1'
                            text(mean_HSM(ip)-0.6,1-mean_TAC(ip),unique_names{ip},'fontsize',12)
                        case 'TAM'
                            text(mean_HSM(ip)+0.01,1-mean_TAC(ip)+0.02,unique_names{ip},'fontsize',12);
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
                            text(mean_HSM(ip)-1,1-mean_TAC(ip),unique_names{ip},'fontsize',12);
                        case 'LSFnonENSO'
                            text(mean_HSM(ip)-0.02,1-mean_TAC(ip)-0.02,'LSF','fontsize',12);
                    end
            end
            hold on;
        end
      
        %% Plot linear regression
        mdl = fitlm(mean_HSM,1-mean_TAC);  
        % x_fit = linspace(min(mean_TAC)-0.1, 0.62, 100); % Create 100 evenly spaced x values
        if use_p88
            x_fit = linspace(min(mean_HSM)-0.2, 3.5, 100);
        else
            switch trait
                case 'HSM'
                    x_fit = linspace(min(mean_HSM)-0.1, 1.5, 100);
                otherwise
                    x_fit = linspace(min(mean_HSM)-0.5, 1.5, 100);
            end
        end
        [y_fit,y_ci] = predict(mdl, x_fit'); % Predict y values using the model
        % Plot the regression line
        plot(x_fit, y_fit, 'k-', 'LineWidth', 1.5); 
        hold on;
        % Plot the 95% confidence interval
        fill([x_fit, fliplr(x_fit)], [y_ci(:,1)', fliplr(y_ci(:,2)')],[0.5,0.5,0.5], 'FaceAlpha', 0.1, 'EdgeColor', 'none'); % Shaded confidence interval
        legend('off')
        
        % %% Calculate bootstraping R2 with uncertainty (optional)
        % [R2_bt,ci] = R2_bootstrap(mean_TAC,mean_HSM,2000,0.05);
        % fprintf('Observed R^2 = %.3f\n', R2_bt);
        % fprintf('95%% CI = [%.3f, %.3f]\n', ci(1), ci(2));
       
        ylabel(['1- (TAC of ', VI,')']);
        % ylim([0.25,0.92]);
        ylim([0.25,1.1]);
        yticks(linspace(0.3,1.0,8));

        %% Add text 
        slope = mdl.Coefficients.Estimate(2);
        intercept = mdl.Coefficients.Estimate(1);
        R2 = mdl.Rsquared.Adjusted;
        pval = mdl.Coefficients.pValue(2);

        % Create annotation text
        ax = gca;
        txt = sprintf('y = %.3f x + %.3f\nR^2 = %.2f\np = %.4f',...
            slope, intercept, R2, pval);
        % txt = sprintf('y = %.3f x + %.3f\nR^2 = %.2f [%.2f, %.2f]\np = %.4f',...
            % slope, intercept, R2, ci(1), ci(2), pval);
        switch trait
            case 'HSM'
                text(ax.XLim(1) + 0.55*range(ax.XLim), ...
                     ax.YLim(1) + 0.25*range(ax.YLim), ...
                     txt, 'FontSize', 11, 'VerticalAlignment', 'top', 'BackgroundColor', 'none');
            otherwise
                text(ax.XLim(1) + 0.43*range(ax.XLim), ...
                     ax.YLim(1) + 0.25*range(ax.YLim), ...
                     txt, 'FontSize', 14, 'VerticalAlignment', 'top', 'BackgroundColor', 'none');
        end
        % add conseGap
        txt1 = sprintf('conseGap = %d',conseGap);
        text(ax.XLim(1) + 0.15*range(ax.XLim), ...
                     ax.YLim(1) + 0.95*range(ax.YLim), ...
                     txt1, 'FontSize', 14, 'FontWeight','bold','VerticalAlignment', 'top', 'BackgroundColor', 'none');
       
       
        if use_p88
            xlim([-0.1,3.5]);
            % ylabel('$\mathrm{HSM}_{P88}$ (MPa)','Interpreter','latex');
            xlabel('HSM_{P88} (MPa)', 'Interpreter','tex', 'FontName','Arial');
        else
            switch trait
                case 'HSM'
                    xlim([-1.1,1.5]);
                    xlabel('HSM (MPa)', 'Interpreter','tex', 'FontName','Arial');
                    % xlabel('HSM_{P50} (MPa)', 'Interpreter','tex', 'FontName','Arial');
                case 'Pmin'
                    xlim([-4.5,0]);
                    xlabel('P_{min} (MPa)', 'Interpreter','tex', 'FontName','Arial');
                case 'P50'
                    xlim([-4.5,0]);
                    xlabel('P_{50} (MPa)', 'Interpreter','tex', 'FontName','Arial');
            end
        end
        
        % grid on;
        box on;
        set(gca,'FontSize',14);
        % fontname(fig,'Lucida Bright');
        fontname(fig,'Arial');

        if save_fig
            if use_p88
                figurename = sprintf('%s_p88vs%s_reverse_%s_conseGap%s.png',trait,response_var_Inyear,int2str(default_remove_climateTAC),int2str(conseGap));
            else
                figurename = sprintf('%s_p50vs%s_reverse_%s_conseGap%s.png',trait,response_var_Inyear,int2str(default_remove_climateTAC),int2str(conseGap));
            end
            exportgraphics(gcf, fullfile(folderpath_figures,string(figurename)),'Resolution',600);
        end
    end   % end of do_plot
    
    fprintf('Complete! \n');

end   % end of func




function [R2, ci] = R2_bootstrap(x, y, nboot, alpha)
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

    if nargin < 3 || isempty(nboot)
        nboot = 1000;
    end
    if nargin < 4 || isempty(alpha)
        alpha = 0.05;
    end

    % Ensure column vectors
    x = x(:); y = y(:);
    n = numel(x);

    % Fit regression once to get observed R^2
    mdl = fitlm(x, y);
    R2  = mdl.Rsquared.Ordinary;

    % Bootstrap distribution
    R2boot = zeros(nboot,1);
    for b = 1:nboot
        idx = randsample(n, n, true); % resample with replacement
        xb = x(idx);
        yb = y(idx);
        mdl_b = fitlm(xb, yb);
        R2boot(b) = mdl_b.Rsquared.Ordinary;
    end

    % CI from bootstrap percentiles
    ci = prctile(R2boot, [100*alpha/2, 100*(1-alpha/2)]);
end
