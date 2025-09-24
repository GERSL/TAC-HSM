function runRegressionPlot_dlm()

    display_ids = [1:47,50,51,53];
    directory = '/gpfs/sharedfs1/zhulab/SCRATCH/kes20012/ProjectTACValidation/';

    % Define start and end dates
    startDate = datetime(2000, 1, 1);
    endDate = datetime(2024, 12, 31);
    
    use_p88 = 0;
    msg = 1;
    save_output = 0;
    do_plot = 1;
    save_fig = 1;

    %% define folder paths
    folderpath_figures = fullfile(directory,'Figures');
    if ~exist(folderpath_figures)
        mkdir(folderpath_figures);
    end

    %% load Hydraulic traits
    filename = fullfile(directory,'FieldData','hydraulic_data_compiled_allSample_HPC.xlsx');
    T_HSM = readtable(filename);

    %% Calculate correlation btw TAC and HSM
    % VIs = {'NDVI','kNDVI','NIRv','NBR','NDMI','EVI','EVI2'};
    composite_intervals = {'biweekly','monthly','bimonthly'};
    % climate_vars = {'t2m','tp','def','ssrd'};

    VIs = {'NDVI'};
    climate_vars = {'def'};
    

    % % empty array to hold R2
    HSM_p50_R2_results = zeros([length(VIs),length(climate_vars)]);   
    HSM_p88_R2_results = zeros([length(VIs),length(climate_vars)]);   


    % Loop starts here...
    for iV = 1:length(VIs)
        VI = VIs{iV};
        
        for ic = 2%:length(composite_intervals)
            composite_interval = composite_intervals{ic};
            switch composite_interval
                case 'biweekly'
                    % Generate the dates with 14-day intervals
                    dlmDates = startDate:days(14):endDate;
                case 'monthly'
                    dlmDates = startDate:calmonths(1):endDate;
                case 'bimonthly'
                    dlmDates = startDate:calmonths(2):endDate;

            end
            annualDates = startDate:calyears(1):endDate;
    
            for ir = 1:length(climate_vars)
                climate_var = climate_vars{ir};  
                fprintf('Processing vi=%s, composite interval=%s, climate variable = %s\n',...
                    VI,composite_interval,climate_var);
    
                response_var = ['TAC_',VI,'_',composite_interval,'_',climate_var];
                response_var_short = ['TAC_',VI,'_',climate_var];
                response_var_Inyear = ['TAC_',VI,'_',composite_interval,'_',num2str(climate_var)];
               

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
                plot_names = plot_names(idx);
                   
                %% Loop by plotid to access TAC on the sample year
                TAC = nan(length(point_ids),1);
                for i = 1:length(point_ids)
                        
                    plotname = plot_names{i}; 
                    pointid = point_ids(i);
                    plotid = plot_ids(i);
                    % fprintf('Processing Plot %d %s, Point %d ...\n',plotid, plotname, pointid);               
                            
                    %% load the TAC csv file
                    folderpath_TACResults = fullfile(directory,'DLM/data/Output_csv');
       
                    filepath_TAC = fullfile(folderpath_TACResults,sprintf('point_%02d',pointid), sprintf('point_%02d_sm_%s_%s_%s.csv', pointid,VI,composite_interval,climate_var)); % r: row
                    dlmTAC = readtable(filepath_TAC);
                    % #nrow: number of theta estimates
                    % #0:mean, 1:trend, 2:lag-1 autocorrelation of EVI
                    % #3:EVI sentivitity to Tave
                    % #4:seasonal cycle 1, 5:seasonal cycle 1
                    % #6:seasonal cycle 2, 7:seasonal cycle 2
                    dlmTAC = table2array(dlmTAC(2:end,:));
                    dlmTAC_mean = dlmTAC(3,:);

                    N = length(dlmTAC_mean);
                    M = length(dlmDates);
                    switch composite_interval
                        case 'biweekly'
                            if M>=N
                                TAC_dlm = table(dlmDates(1:N)',dlmTAC_mean','VariableNames',{'Date','TAC'});
                            else
                                TAC_dlm = table(dlmDates',dlmTAC_mean(1:M)','VariableNames',{'Date','TAC'});
                            end
                        case 'monthly'
                            if M>=N
                                TAC_dlm = table(dlmDates(1:N)',dlmTAC_mean','VariableNames',{'Date','TAC'});
                            else
                                TAC_dlm = table(dlmDates',dlmTAC_mean(1:M)','VariableNames',{'Date','TAC'});
                            end
                        case 'bimonthly'
                            if M>=N
                                TAC_dlm = table(dlmDates(1:N)',dlmTAC_mean','VariableNames',{'Date','TAC'});
                            else
                                TAC_dlm = table(dlmDates',dlmTAC_mean(1:M)','VariableNames',{'Date','TAC'});
                            end   
                    end
                    % calculate annual TAC
                    TAC_annual = retime(table2timetable(TAC_dlm),'yearly','mean');
               
                    % extract TAC on the sample year month
                    year_field = sample_year(i);
                    month_field  = sample_month(i);
                    targetDate = datetime(year_field,month_field,1);
                    [~, nearestIndex] = min(abs(dlmDates - targetDate));
                    if ~isempty(nearestIndex)
                        TAC(i) = TAC_dlm.TAC(nearestIndex);
                    else
                        [~, nearestIndex] = min(abs(annualDates - datetime(year_field,1,1)));
                        % nearestIndex = find(TAC_annual.Dates== datetime(year_field,1,1)); 
                        try
                            TAC(i) = TAC_annual.TAC(nearestIndex);
                        catch
                            TAC(i) = NaN;
                        end
                    end
                end   % end of i

                % %% Use absolute values
                % if use_abs
                %     TAC = abs(TAC);
                % end
                
                %% Calculate mean for each unique plot name
                % Convert plotnames into a numeric grouping variable
                [unique_names, ~, group_idx] = unique(plot_names);
                
                for j = 1:length(unique_names)
                    % Get the TAC values for the current group
                    group_data_1 = TAC(strcmp(plot_names, unique_names{j}));
                    % Calculate the mean
                    mean_TAC(j) = mean(group_data_1);
                    % Get the HSM_p50 values for the current group
                    if use_p88
                        group_data_2 = HSM_p88(strcmp(plot_names, unique_names{j}));
                    else
                        group_data_2 = HSM_p50(strcmp(plot_names, unique_names{j}));
                    end
                    % Calculate the mean
                    mean_HSM(j) = mean(group_data_2);
                end

                %% Fit linear regression between TAC and HSM
                mdl_3 = fitlm(mean_TAC,mean_HSM); 
                slope = mdl_3.Coefficients.Estimate(2);
                if msg
                    if slope<0
                        fprintf('HSM vs TAC Rsquared = %.3f \n',mdl_3.Rsquared.Ordinary);
                    else
                        fprintf('TAC vs HSM IS WRONG!\n')
                    end
                end

                if use_p88
                    if slope<0
                        HSM_p88_R2_results(iV,ir) = mdl_3.Rsquared.Ordinary;
                    else
                        HSM_p88_R2_results(iV,ir) = -1*mdl_3.Rsquared.Ordinary;
                    end
                else
                    if slope<0
                        HSM_p50_R2_results(iV,ir) = mdl_3.Rsquared.Ordinary;
                    else
                        HSM_p50_R2_results(iV,ir) = -1*mdl_3.Rsquared.Ordinary;
                    end
                end
               
            end  % end of ir
        end   % end of ic
    end   % end of iV
                    
    folderpath_output = fullfile(directory,['R2_dlmTAC_HSM_2025-03-31'],composite_interval);
    
    if ~exist(folderpath_output)
        mkdir(folderpath_output);
    end
    if save_output
        % save(fullfile(folderpath_output,'p50_R2_results.mat'),"p50_R2_results");
        % save(fullfile(folderpath_output,'psi_min_R2_results.mat'),"psi_min_R2_results");
        if use_p88
            save(fullfile(folderpath_output,'HSM_p88_R2_results.mat'),"HSM_p88_R2_results");
        else
            save(fullfile(folderpath_output,'HSM_p50_R2_results.mat'),"HSM_p50_R2_results");
        end
    end
            
    if do_plot
        %% Fig. TAC vs HSM_p50
        % Convert plotnames into a numeric grouping variable
        [unique_names, ~, group_idx] = unique(plot_names);
        % Calculate mean for each unique plot name
        mean_TAC = zeros(size(unique_names));
        mean_HSM = zeros(size(unique_names));
        for i = 1:length(unique_names)
            % Get the TAC values for the current group
            group_data_1 = TAC(strcmp(plot_names, unique_names{i}));
            % Calculate the mean
            mean_TAC(i) = mean(group_data_1);
            % Get the HSM_p50 values for the current group
            if use_p88
                group_data_2 = HSM_p88(strcmp(plot_names, unique_names{i}));
            else
                group_data_2 = HSM_p50(strcmp(plot_names, unique_names{i}));
            end
            % Calculate the mean
            mean_HSM(i) = mean(group_data_2);
        end
        
        fig = figure("Name",'TAC vs HSM');
        fig.Position = [20, 20, 500, 400];
        sz = 30;
        for ip = 1:length(unique_names)
            scatter(mean_TAC(ip),mean_HSM(ip),sz,'filled');
            text(mean_TAC(ip)-0.01,mean_HSM(ip)-0.1,unique_names{ip});
            hold on;
        end
        
        % Plot simple linear regression
        mdl_3 = fitlm(mean_TAC,mean_HSM);  
        x_fit = linspace(min(mean_TAC), max(mean_TAC), 100); % Create 100 evenly spaced x values
        [y_fit,y_ci] = predict(mdl_3, x_fit'); % Predict y values using the model
        % Plot the regression line
        plot(x_fit, y_fit, 'k-', 'LineWidth', 1.5); 
        hold on;
        % Plot the 95% confidence interval
        fill([x_fit, fliplr(x_fit)], [y_ci(:,1)', fliplr(y_ci(:,2)')], 'r', 'FaceAlpha', 0.1, 'EdgeColor', 'none'); % Shaded confidence interval
        legend('off')
        
        % add text
        dim = [.2 .01 .3 .3];
        str = sprintf('R^2 = %.2f',mdl_3.Rsquared.Ordinary);
        annotation('textbox',dim,'String',str,'FitBoxToText','on');
        
        dim1 = [.4 .6 .3 .3];
        str1 = sprintf('VI = %s, CI = %s, CV = %s',VI,composite_interval,climate_var);
        annotation('textbox',dim1,'String',str1,'FitBoxToText','on');
        
        xlabel('TAC');
        if use_p88
            ylabel('HSM p88');
        else
            ylabel('HSM p50');
        end
        
        set(gca,'FontSize',16);
        fontname(fig,'Lucida Bright');

        if save_fig
            if use_p88
                figurename = sprintf('HSM_p88vsdlm%s.png',response_var_Inyear);
            else
                figurename = sprintf('HSM_p50vsdlm%s.png',response_var_Inyear);
            end
            
           
            saveas(gcf, fullfile(folderpath_figures,string(figurename)));
            % exportgraphics(gcf, fullfile(folderpath_figures,string(figurename)),'Resolution',600);
        end
    end   % end of do_plot
    
    fprintf('Complete! \n');

    % %% Define variables
    % VIs = {'NDVI','kNDVI','NIRv','NBR','NDMI','EVI','EVI2'};
    % Composite_Intervals = {'biweekly','monthly','bimonthly'};
    % Climate_Vars = {'t2m','tp','def','ssrd'};
    % 
    % %% Define data paths
    % folderpath = '/gpfs/sharedfs1/zhulab/SCRATCH/kes20012/ProjectTACValidation/';
    % plot_file = fullfile(folderpath,'Input','Sample_multipleInPlot_HPC.csv');
    % plot_data = readtable(plot_file);












end
