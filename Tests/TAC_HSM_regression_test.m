function TAC_HSM_regression_test()
    
    close all;
    % addpath("TAC\");
    directory = pwd;%C:/ProjectTACValidation';

    %% define folder paths
    folderpath_figures = fullfile('.\figures');
    if ~exist(folderpath_figures)
        mkdir(folderpath_figures);
    end

    %% load Hydraulic traits
    filename = '..\Data\FieldData\hydraulic_data_compiled_allSample_HPC.csv';
    T_HSM = readtable(filename);

    %% Calculate correlation btw TAC and HSM
    composite_intervals = {'bimonthly'};
    VIs = {'NIRv','EVI','EVI2'};
    rolling_windows_y = 4;
    trait = 'HSM';
    conseGap = 1;
    
    
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
                filename = fullfile('..\Results/enhancedTACResults_FieldSample\',['Landsat_',composite_interval,'_conseGap',int2str(conseGap)],[response_var_Inyear,'.csv']);
                T = readtable(filename);
                diff = T.diff;      % difference btw observed TAC and enhanced TAC
                year = T.year;
                sampleID = T.sampleID;
                def = T.def_mean;    % def = actural ET - precipitation 
                tp = T.tp_mean;
                t2m = T.t2m_mean;
                mean_def = groupsummary(def, sampleID, "mean")*365*1000;  % 25-year mean annual water deficit (mm)
                MAP = groupsummary(tp,sampleID,'mean')*365*1000;  % 25-year mean  annual precipitation (mm)
                MAT = groupsummary(t2m,sampleID,'mean');
                T_HSM.mean_def = mean_def;
                T_HSM.MAP = MAP;
                T_HSM.MAT = MAT;
               
                clear T;

                %% Field data basic information
                point_ids = T_HSM.pointID;
                plot_ids = T_HSM.ID;
                plot_names = T_HSM.Site;
                sample_year = T_HSM.SampleYear;
                sample_month = T_HSM.SampleMonth;
                % hydraulic traits
                p50 = T_HSM.p50;
                psi_min = T_HSM.Psi_min;
                HSM_p50 = T_HSM.HSM_p50;
                DEF = T_HSM.mean_def;
                MAP = T_HSM.MAP;
                MAT = T_HSM.MAT;
                MCWD = T_HSM.MCWD;
                   
                %% Loop by plotid to access TAC on the sample year
                TAC = nan(length(point_ids),1);
                climate_ac_effect = nan(length(point_ids),1);
                for i = 1:length(point_ids)
                        
                    plotname = plot_names{i}; 
                    pointid = point_ids(i);
                    plotid = plot_ids(i);
                    % fprintf('Processing Plot %d %s, Point %d ...\n',plotid, plotname, pointid);               
                            
                    %% load the TAC_rec_cg file
                    folderpath_TACResults = fullfile('..\Results\TACResults_FieldSample',['Landsat_',composite_interval,'_conseGap',int2str(conseGap)]);
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
                TAC = TAC-climate_ac_effect;
         
                
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
                    switch trait
                        case 'HSM'
                            group_data_2 = HSM_p50(strcmp(plot_names, unique_names{j}));
                        case 'Pmin'
                            group_data_2 = psi_min(strcmp(plot_names, unique_names{j}));   % TEST Pmin
                        case 'P50'
                            group_data_2 = p50(strcmp(plot_names, unique_names{j}));   % TEST P50
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

                    % Get the MCWD for the current group  
                    group_data_5 = MCWD(strcmp(plot_names, unique_names{j}));
                    mean_MCWD(j) = mean(group_data_5);
                end

                %% Fit linear regression between TAC and HSM
                id = ~isnan(mean_HSM);
                [r,p_value] = corrcoef(mean_HSM(id),1-mean_TAC(id)); 
                r = r(1,2);
                p_value = p_value(1,2);
                fprintf('HSM vs TAC r = %.3f,p_value = %.4f \n',r,p_value);

                 %% Fig. HSM vs 1-TAC
                fig = figure("Name",'HSM vs 1-TAC');
                fig.Position = [20, 20, 700, 500];
                sz = 40;
            
                % Display each forest ploe as a colored dot
                scatter(mean_HSM,1-mean_TAC,sz,mean_DEF,'filled');
                cmap = turbo(64);
                colormap(cmap);
                clim([-1800,-300]);
            
                % add colorbar (optional)
                cb = colorbar;
                cb.Ticks = [-1800,-1500,-1200,-900,-600,-300];
                cb.Label.String='Cumulative Water Deficit (mm/year)';
            
                hold on;
            
                % Add forest plot names
                for ip = 1:length(unique_names)
                    fprintf(unique_names{ip},'/n');
                    disp(mean_DEF(ip))
                   
                    switch unique_names{ip} 
                        case {'MAN','NVX'}
                            text(mean_HSM(ip)+0.03,1-mean_TAC(ip)+0.02,unique_names{ip},'fontsize',12);
                        case 'SUC'
                            text(mean_HSM(ip)+0.02,1-mean_TAC(ip)+0.02,unique_names{ip},'fontsize',12);
                        case 'ALP1'
                            text(mean_HSM(ip)+0.03,1-mean_TAC(ip)+0.03,unique_names{ip},'fontsize',12);
                        case 'KEN1'
                            text(mean_HSM(ip)-0.2,1-mean_TAC(ip)-0.04,unique_names{ip},'fontsize',12)
                        case 'TAM'
                            text(mean_HSM(ip)+0.03,1-mean_TAC(ip)-0.02,unique_names{ip},'fontsize',12);
                        case 'ALP2'
                            text(mean_HSM(ip)-0.13,1-mean_TAC(ip)+0.04,unique_names{ip},'fontsize',12);
                        case 'CAX' 
                            text(mean_HSM(ip)+0.03,1-mean_TAC(ip)-0.02,unique_names{ip},'fontsize',12);
                        case 'FEC'
                            text(mean_HSM(ip)+0.02,1-mean_TAC(ip)+0.02,unique_names{ip},'fontsize',12);
                    end
                    
                end
                hold on;
              
                %% Plot linear regression
                mdl = fitlm(mean_HSM,1-mean_TAC);  
                % x_fit = linspace(min(mean_TAC)-0.1, 0.62, 100); % Create 100 evenly spaced x values
                switch trait
                    case 'HSM'
                        x_fit = linspace(min(mean_HSM)-0.1, 1.5, 100);
                    otherwise
                        x_fit = linspace(min(mean_HSM)-0.5, 1.5, 100);
                end
                [y_fit,y_ci] = predict(mdl, x_fit'); % Predict y values using the model
            
                % Plot the regression line
                plot(x_fit, y_fit, 'k-', 'LineWidth', 1.5); 
                hold on;
            
                % Plot the 95% confidence interval
                fill([x_fit, fliplr(x_fit)], [y_ci(:,1)', fliplr(y_ci(:,2)')],[0.5,0.5,0.5], 'FaceAlpha', 0.1, 'EdgeColor', 'none'); % Shaded confidence interval
                legend('off')
                ylabel(['1- (TAC of ', VI,')']);
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
        
                %% Save figure
                figurename = sprintf('%s_vs%s_reverse_conseGap%s.png',trait,response_var_Inyear,int2str(conseGap));
                exportgraphics(gcf, fullfile(folderpath_figures,string(figurename)),'Resolution',600);
                fprintf('Complete! \n');
             
            end  % end of ir
        end   % end of ic
    end   % end of iV
end   % end of func

