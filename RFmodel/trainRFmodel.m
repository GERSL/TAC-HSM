function trainRFmodel(varargin)
    close all;
    do_plot = false;
    % do_plot = true;

    p = inputParser;
    addParameter(p,'ci', 1); % 1st task
    addParameter(p,'cn', 1); % single task to compute
    % request user's input
    parse(p,varargin{:});
    ci = p.Results.ci;
    cn = p.Results.cn;


    directory = '/gpfs/sharedfs1/zhulab/Kexin/ProjectTACValidation/';

    VIs = {'NDVI','kNDVI','NIRv','NBR','NDMI','EVI','EVI2'};% {'NBR'};%
    composite_intervals = {'biweekly','monthly','bimonthly','quarterly'};
    rolling_windows_y = [1,2,3,4,5,6,7];

    combos = struct('VI', {}, 'ci', {}, 'rw_y', {});
    for iV = 1:numel(VIs)
        for ic = 1:numel(composite_intervals)
            for ir = 1:numel(rolling_windows_y) 
                combos(end+1) = struct( ...
                    'VI',   VIs{iV}, ...
                    'ci',   composite_intervals{ic}, ...
                    'rw_y', rolling_windows_y(ir));
            end
        end
    end
    % For test run
    % VIs = {'NIRv'};
    % composite_intervals = {'bimonthly'};
    % rolling_windows_y = 6;


    %% split the tasks  by ci and cn
    for c = ci: cn: length(combos)
         start_timer = tic; % start to count computing time
         combo = combos(c);

         VI = combo.VI;
         composite_interval = combo.ci;
         rolling_window_y = combo.rw_y;  % rolling window in year

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
                response_var_Inyear = ['TAC_',VI,'_',composite_interval,'_',num2str(rolling_window_y),'year'];
    
                filename = dir(fullfile(directory, 'Input',response_var_Inyear, ...
                    sprintf('random_samples_4184_input_%dyr_%s_updated.csv', rolling_window_y,response_var_Inyear)));
                T = readtable(fullfile(filename(1).folder,filename(1).name));
            
                % Exclude non-predictor columns (lat, lon, sampleID)
                exclude_vars = {'sampleLat','sampleLon','sampleID', 'window_years','year',response_var};
            
                % Identify predictor columns
                predictor_vars = setdiff(T.Properties.VariableNames, exclude_vars);
            
                % Convert table to array for training
                X = T{:, predictor_vars};  % Predictor variables (numeric matrix)
                Y = T{:, response_var};    % Response variable
            
                % Remove NaN rows (optional: to avoid errors in training)
                valid_idx = ~isnan(Y) & all(~isnan(X), 2);
                X = X(valid_idx, :);
                Y = Y(valid_idx, :);
            
                %% Train Random Forest (TreeBagger)
                numTrees = 100;  % Number of trees in the ensemble
                rng(42);  % Set seed for reproducibility
                rf_model = TreeBagger(numTrees, X, Y, 'Method', 'regression', ...
                                      'OOBPrediction', 'on', ...
                                      'OOBPredictorImportance', 'on');
            
                %% Save trained model
                model_filename = fullfile(directory, 'RFmodel', ['random_forest_model_',response_var_Inyear,'.mat']);
                save(model_filename, 'rf_model', 'predictor_vars');
                disp(['Random Forest model saved to: ', model_filename]);
            
                if do_plot
                    %% Plot Out-of-Bag Error
                    figure;
                    set(gcf, 'Units', 'centimeters', 'Position', [2, 2, 15, 15]);
                    plot(oobError(rf_model), 'LineWidth', 2);
                    xlabel('Number of Trees');
                    ylabel('Out-of-Bag MSE');
                    title('Random Forest Out-of-Bag Error');
                    grid on;
                
                    %% Plot Feature Importance
                    % Extract feature importance scores
                    importance_scores = rf_model.OOBPermutedPredictorDeltaError;
                    
                    % Sort the predictors by importance (descending order)
                    [sorted_importance, sort_idx] = sort(importance_scores, 'descend');
                    sorted_predictors = predictor_vars(sort_idx); % Reorder predictor names
                    
                    % Truncate long predictor names for readability & replace '_' with space
                    max_label_length = 15; % Adjust if needed
                    shortened_labels = sorted_predictors;
                    
                    for i = 1:length(sorted_predictors)
                        % Replace underscores with spaces
                        label = strrep(sorted_predictors{i}, '_', '.');
                    
                        % Truncate long labels if needed
                        if length(label) > max_label_length
                            label = [label(1:max_label_length), '...'];
                        end
                    
                        shortened_labels{i} = label;
                    end
                    
                    % Plot sorted feature importance
                    figure;
                    set(gcf, 'Units', 'centimeters', 'Position', [2, 2, 20, 15]); % Adjust figure size
                    
                    bar(sorted_importance);
                    % xlabel('Predictors');
                    ylabel('Variable Importance [score]');
                    % title('Feature Importance (Sorted) - Random Forest');
                    grid on;
                    
                    % Apply labels and formatting
                    xticks(1:length(sorted_importance)); % Set x-ticks
                    xticklabels(shortened_labels); % Set x-labels with spaces instead of '_'
                    xtickangle(45); % Rotate labels for readability
                    set(gca, 'FontSize', 14); % Adjust font size for clarity
            
                end
        fprintf('(%04d/%04d) Finished %s with %0.2f mins\n', c, length(combos), model_filename, toc(start_timer)/60);

    end    % end of c
end   % end of function
