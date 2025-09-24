function detrended_data  = climateDeseasonDetrend(data)
%DESEASON Summary of this function goes here

    do_plot = false;
    % do_plot = true;
    
    % Time vector for monthly data from 2000 to 2024
    years = 2000:2024;
    months = repmat(1:12, 1, length(years))'; % Monthly indices
    time = (2000 + (0:length(data)-1)/12)'; % Converts to decimal years
    
    % Step 1: Calculate Multi-Year Monthly Mean (Seasonal Component)
    monthly_means = zeros(12, 1); % Placeholder for monthly means
    
    for m = 1:12
        monthly_means(m) = mean(data(months == m)); % Average across all years for month 'm'
    end
    
    % Create a seasonal component for each data point
    seasonal_component = monthly_means(months); % Assign month-wise seasonal mean
    
    % Step 2: Deseasonalization
    deseasonalized_data = data - seasonal_component;
    
    % Step 3: Detrending using Linear Regression
    X = [ones(length(time),1), time]; % Design matrix for linear regression
    b = X \ deseasonalized_data; % Linear regression coefficients
    trend = X * b; % Estimated trend
    
    % Remove trend to get the residual component
    detrended_data = deseasonalized_data - trend;
    
    % Plot results
    if do_plot
        figure;
        subplot(3,1,1);
        plot(time, data, 'b'); hold on;
        plot(time, seasonal_component, 'r--', 'LineWidth', 1.5);
        title('Original Data with Multi-Year Monthly Mean');
        xlabel('Year');
        ylabel('Data');
        legend('Original', 'Seasonal Component');
        
        subplot(3,1,2);
        plot(time, deseasonalized_data, 'g');
        title('Deseasonalized Data');
        xlabel('Year');
        ylabel('Data');
        
        subplot(3,1,3);
        plot(time, detrended_data, 'k');
        title('Detrended Data');
        xlabel('Year');
        ylabel('Data');
    end

% Save the results
% save('deseasonalized_detrended.mat', 'deseasonalized_data', 'detrended_data', 'time');

end

