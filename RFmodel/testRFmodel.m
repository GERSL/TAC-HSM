function testRFmodel(directory)

    close all;
    do_plot =  true;%
    % do_plot = true;
    directory = '/gpfs/sharedfs1/zhulab/Kexin/ProjectTACValidation/';
    
    use_2000_climateTAC = true;
    % use_2000_climateTAC = false;

    % VIs = {'NDVI','kNDVI','NIRv','NBR','NDMI','EVI','EVI2'};
    % composite_intervals = {'biweekly','monthly','bimonthly'};
    % rolling_windows_y = [1,2,3,4,5,6];

    VIs = {'NIRv'};
    composite_intervals = {'bimonthly'};
    rolling_windows_y = [6];

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
                end
                fprintf('Processing vi=%s, composite interval=%s, rolling window = %d-year\n',...
                    VI,composite_interval,rolling_window_y);
    
                response_var = ['TAC_',VI,'_',composite_interval,'_',num2str(rolling_window)];
                response_var_Inyear = ['TAC_',VI,'_',composite_interval,'_',num2str(rolling_window_y),'year'];
    
                %% Load trained Random Forest model
                model_filename = fullfile(directory, 'RFmodel/', ['random_forest_model_',response_var_Inyear,'.mat']);
                if ~isfile(model_filename)
                    error('Random Forest model not found! Train the model first.');
                end
                load(model_filename, 'rf_model', 'predictor_vars');
                fprintf('Loading %s\n',model_filename);
            
                %% Load test dataset
                if use_2000_climateTAC
                    filename = dir(fullfile(directory,'Input',response_var_Inyear,...
                        sprintf('random_samples_4184_input_%dyr_use_2000_climateTAC_%s_updated.csv',rolling_window_y,response_var_Inyear)));
                else
                    filename = dir(fullfile(directory, 'Input',response_var_Inyear, ...
                        sprintf('random_samples_4184_input_%dyr_%s_updated.csv', rolling_window_y,response_var_Inyear)));
                    % 
                    % filename = fullfile(directory,'Input',response_var_Inyear,['random_samples_4184_input_',response_var_Inyear,'_updated.csv']); % Output CSV file
                end
                T = readtable(fullfile(filename(1).folder,filename(1).name));
                % TODO:
                % Rename 't2m_ave' to 't2_ave'   (here's a typo in the previous csvfile)
                try
                    T = renamevars(T, 't2m_ave', 't2_ave');
                catch
                end
            
                % Exclude non-predictor columns (lat, lon, sampleID)
                exclude_vars = {'sampleLat', 'sampleLon', 'sampleID', 'window_years','year',response_var};
                
                % Identify predictor variables
                predictor_vars_test = setdiff(T.Properties.VariableNames, exclude_vars);
            
                % Check if predictor names match the trained model
                if ~isequal(sort(predictor_vars_test), sort(predictor_vars))
                    error('Mismatch in predictor variable names between training and test data.');
                end
            
                % Extract predictors (X_test) and true response values (Y_test)
                X_test = T{:, predictor_vars};
                Y_test = T{:, response_var};  % Actual TAC values
            
                % Remove rows with missing values
                valid_idx = all(~isnan(X_test), 2);
                X_test = X_test(valid_idx, :);
                Y_test = Y_test(valid_idx);
            
                % Predict TAC using the trained Random Forest model
                Y_pred = predict(rf_model, X_test);
            
                % Save predictions
                T.Predicted_TAC = nan(height(T), 1);  % Initialize full column
                T.Predicted_TAC(valid_idx) = Y_pred;  % Assign predictions to valid rows
                
                folderpath_output = fullfile(directory, 'Output',response_var_Inyear);
                if ~exist(folderpath_output)
                    mkdir(folderpath_output);
                end

                if use_2000_climateTAC
                    output_filename =  fullfile(folderpath_output, ['random_forest_output_4184_use_2000_climateTAC_',response_var_Inyear,'.csv']);
                else
                    output_filename = fullfile(folderpath_output, ['random_forest_output_4184_',response_var_Inyear,'.csv']);
                end
                writetable(T, output_filename);
            
                % disp(['Predictions saved to: ', output_filename]);
            
                if do_plot
                    % Plot: Actual vs. Predicted TAC values
                    figure;
                    set(gcf, 'Units', 'centimeters', 'Position', [2, 2, 15, 15]);
                    scatter( Y_test,Y_pred, 'filled');
                    hold on;
                
                    mdl = fitlm(Y_pred,Y_test);
                    % plot(mdl)
                    fprintf('R2 = %.3f\n',mdl.Rsquared.Ordinary);
                    hold on;
                
                    plot( [min(Y_test), max(Y_test)], [min(Y_test), max(Y_test)],'r--', 'LineWidth', 1.5);
                    hold off;
                    ylabel('Modeled TAC');
                    xlabel('Observed TAC');
                    title('Random Forest Predictions: Observed vs. Modeled');
                    grid on;
                    legend('Predicted', 'Perfect Prediction', 'Location', 'Best');
                end  % end of do_plot
                close all;
            end   % end of ir
        end   % end of ic
    end   % end of iV
end   % end of func
