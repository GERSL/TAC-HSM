function plotSensitivityToMissingDataPercentage()
%PLOTSENSITIVITYTOMISSINGDATAPERCENTAGE Summary of this function goes here
    close all;
    msg = false;

    directory = '/gpfs/sharedfs1/zhulab/Kexin/ProjectTACValidation/';
   
    composite_interval = 'biweekly';
    % composite_interval = 'bimonthly';
    % composite_interval = 'quarterly';

    rolling_window_yr = [1];%,2,3,4,5,6,7];
    switch composite_interval
        case 'bimonthly'
            rolling_window = rolling_window_yr*6;
        case 'quarterly'
            rolling_window = rolling_window_yr*4;
    end
    missing_data_pct_thresholds =[0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]; %linspace(0,1,11);

    Equivalence_Outcome = [];
    for ir = 1:length(rolling_window_yr)
        w = rolling_window(ir);
        fprintf('Processing rolling window = %d-year.\n',rolling_window_yr(ir));
        % Equivalence_Outcome(ir) = [];
        Equivalence_Outcome(ir).rolling_window_yr = rolling_window_yr(ir);
    
        TACs = [];
        for j = 1:length(missing_data_pct_thresholds)
            pct = missing_data_pct_thresholds(j);
              
            % Access foldername
            folderpath_Results_s1 = fullfile(directory,...
                ['s1_Landsat_',composite_interval],...
                ['missing_',num2str(pct*100)]);
            
            % Access filename
            files = dir(fullfile(folderpath_Results_s1,'TAC*.mat'));
            
            % % Print output info (optional)
            if msg
                fprintf('Processing missing data pct=%.1f\n',pct);
                fprintf('Total of %d files.\n',length(files));
            end
        
            y = [];
            for i=1:length(files)
                load(fullfile(folderpath_Results_s1,files(i).name));
                tac = TAC_record_change.(['TAC_',composite_interval]).(['TAC_NIRv_',num2str(w)]);
                y = [y;tac];     % use the long-term tac
                % y = [y;mean(tac,'omitmissing')];     % use the long-term tac
            end
            TACs(j).missing_data_pct = pct;
            TACs(j).y = y;
    
        end

        %% Perform TOST (Two One-Sided Tests) equivalence test
        for j = 1:length(missing_data_pct_thresholds)
            data1 = TACs(end).y;   % baseline is using 10% data
            data2 = TACs(j).y;

           % Remove NaN pairs
            valid = ~isnan(data1) & ~isnan(data2);
            d = data1(valid) - data2(valid);

            % Define equivalence bounds
            lowerBound = -0.01;
            upperBound =  0.01;

            % Test 1: mean(d) > lowerBound
            [h1,p1] = ttest(d, lowerBound, 'Tail','right');

            % Test 2: mean(d) < upperBound
            [h2,p2] = ttest(d, upperBound, 'Tail','left');

            % Both tests must reject H0 to claim equivalence
            isEquivalent = h1 && h2;

            % Report
            meanDiff = mean(d,'omitnan');
            fprintf('\rMissing pct = %.1f\n',missing_data_pct_thresholds(j))
            fprintf('Mean difference = %.6f\n', meanDiff);
            fprintf('Test1 ( > %.3f): h=%d, p=%.4g\n', lowerBound, h1, p1);
            fprintf('Test2 ( < %.3f): h=%d, p=%.4g\n', upperBound, h2, p2);
            fprintf('Conclusion: Equivalent within [%.3f, %.3f]? %d\n', lowerBound, upperBound, isEquivalent);


            % Store outcomes
            Equivalence_Outcome(ir).(j-1).maxMissing = missing_data_pct_thresholds(j);
            Equivalence_Outcome(ir).(j-1).isEquivalent = isEquivalent;
           
            
            % [h,p,ci,stats] = ttest(data1, data2);
            % figure()
            % scatter(data1,data2)
            % histogram(data1);hold on;
            % histogram(data2)
        
        end   % end of j

    end   % end of ir 

end   % end of function

