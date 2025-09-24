function prepareResponseVariable(varargin)
    warning('off');
    folderpath = '/gpfs/sharedfs1/zhulab/Kexin/ProjectTACValidation/';
    msg = false;   % don't print message

    p = inputParser;
    % addParameter(p,'ci', 294); % 1st task
    % addParameter(p,'cn', 294); % single task to compute
    addParameter(p,'ci', 1); % 1st task
    addParameter(p,'cn', 294); 
    % request user's input
    parse(p,varargin{:});
    ci = p.Results.ci;
    cn = p.Results.cn;


    VIs = {'NDVI','kNDVI','NIRv','NBR','NDMI','EVI','EVI2'};
    composite_intervals ={'biweekly','monthly','bimonthly'};  % {'quarterly'};%
    rolling_windows_y = [1,2,3,4,5,6,7];
    use_2000_climateTACs = [0,1];

    combos = struct('VI', {}, 'ci', {}, 'rw_y', {}, 'use_2000_climateTAC',{});
    for iV = 1:numel(VIs)
        for ic = 1:numel(composite_intervals)
            for ir = 1:numel(rolling_windows_y)
                for iu = 1:numel(use_2000_climateTACs)
                    combos(end+1) = struct( ...
                        'VI',   VIs{iV}, ...
                        'ci',   composite_intervals{ic}, ...
                        'rw_y', rolling_windows_y(ir),...
                        'use_2000_climateTAC', use_2000_climateTACs(iu));
                end
            end
        end
    end

    csv_file = 'random_samples_4184.csv';
    % csv_file = 'random_sample_forest_cover_input.csv';
    [~, base] = fileparts(csv_file);


    %% split the tasks  by ci and cn
    for c = ci: cn: length(combos)
         start_timer = tic; % start to count computing time
         combo = combos(c);

         % for iV = 1:length(VIs)
         VI = combo.VI;
        
        % for ic = 1:length(composite_intervals)
         composite_interval = combo.ci;
    
            % for ir = 1:length(rolling_windows_y)
         rolling_window_y = combo.rw_y;  % rolling window in year
         use_2000_climateTAC = combo.use_2000_climateTAC;
                
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

        response_variable = ['TAC_',VI,'_',composite_interval,'_',num2str(rolling_window)];
        response_variable_short = ['TAC_',VI,'_',num2str(rolling_window)];
        response_var_Inyear = ['TAC_',VI,'_',composite_interval,'_',num2str(rolling_window_y),'year'];

        if use_2000_climateTAC
            filename = fullfile(folderpath,'Input',sprintf('%s_input_%dyr_use_2000_climateTAC.csv', base, rolling_window_y));
        else
            filename = fullfile(folderpath,'Input',sprintf('%s_input_%dyr.csv', base, rolling_window_y));
        end
               
            
                %% Load plot ids
                T2 = readtable(filename);
                Plot_Ids = T2.sampleID;  % Assumed column name for plot IDs
            
                % Initialize new columns for response and predictor variables
                num_samples = length(Plot_Ids);
                TAC_values = nan(num_samples, 1);  % Response variable
                COLD_coefs = nan(num_samples, 8); % Assuming 86 coefficients from rec_cg.coefs
            
                for i = 1:num_samples
                    
                    try
                        % Construct the .mat file path for each plot
                        tac_filename = fullfile(folderpath, 'TACResults_2025-08-04/',['Landsat_',composite_interval], sprintf('TAC_record_change_plot%05d.mat',Plot_Ids(i)));
                        % tac_filename = fullfile(folderpath, 'TACResults_AllForestPixels_2025-08-04/',['Landsat_',composite_interval], sprintf('TAC_record_change_plot%05d.mat',Plot_Ids(i)));
                       % fprintf('Processing #%d \n', Plot_Ids(i));
                    catch
                        if msg
                            fprintf('Not forest pixel. Skip #%d..\n', Plot_Ids(i));
                        end
                        continue;
                    end
            
                    % Check if file exists
                    if isfile(tac_filename)
                        % Load .mat file
                        data_struct = load(tac_filename);
                        TAC_record_change = data_struct.TAC_record_change;
            
                        % Extract response variable
                        if isfield(TAC_record_change, ['TAC_',composite_interval])
                            y = T2.year(i);
                            winStart = datetime(y - (rolling_window_y-1), 1, 1);
                            winEnd   = datetime(y, 12, 31);
                            idxWin   = (TAC_record_change.(['TAC_',composite_interval]).Dates >= winStart) & (TAC_record_change.(['TAC_',composite_interval]).Dates  <= winEnd);
                            TAC_values(i) = nanmean(TAC_record_change.(['TAC_',composite_interval]).(response_variable_short)(idxWin),'all');
                        else
                            if msg
                                warning('Field TAC_bimonthly missing in %s', tac_filename);
                            end
                        end
            
                        % Extract predictor variables
                        if isfield(TAC_record_change, 'rec_cg_vi') && isfield(TAC_record_change.rec_cg_vi, 'coefs')
                            try
                                % the colume index based on the response_variable
                                idx = find(strcmp(VIs, VI));
                                COLD_coefs(i,:) = TAC_record_change.rec_cg_vi.coefs(:,idx+6);   % COLD coefficients for EVI time series
                            catch
                                if msg
                                    fprintf('Disturbed pixel! Skip #%d \n',Plot_Ids(i));
                                end
                            end
                        else
                            warning('rec_cg.coefs missing in %s', tac_filename);
                        end
                    else
                        warning('File not found: %s', tac_filename);
                    end
                end   % end of i=1:num_samples
            
                % Add extracted values to the table
                T2.(response_variable) = TAC_values;
                % T2.COLD_coefs = COLD_coefs;
                predictor_table = array2table(COLD_coefs, 'VariableNames', ...
                    {'Coef1', 'Coef2', 'Coef3', 'Coef4', 'Coef5', 'Coef6','Coef7','Coef8'});
                T2 = [T2 predictor_table];
            
                % Save updated table
                parts = split(filename,'/');
                parts = split(parts{end},'.');
            
                folderpath_output = fullfile(folderpath, 'Input',response_var_Inyear);
                if ~exist(folderpath_output)
                    mkdir(folderpath_output);
                end
                output_filename = fullfile(folderpath_output, [parts{1},'_',response_var_Inyear,'_updated.csv']);
                writetable(T2, output_filename);
            
                disp(['Updated table saved to: ', output_filename]);
                fprintf('(%04d/%04d) Finished %s with %0.2f mins\n', c, length(combos), output_filename, toc(start_timer)/60);

    end   %end of c
end   % end of function
