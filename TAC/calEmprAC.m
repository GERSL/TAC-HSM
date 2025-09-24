function empr_ac = calEmprAC(nn,data_flag,window)
%calEmprAC Summary of this function goes here
% INPUTS:
% nn       - time series of vegetation index of surface reflectance;
% window   - moving/rolling window, the unit is the same as the composite interval;

% OUTPUTS:
% empr_ac - lag-1 temporal autocorrelation of the time series (nn) with the defined rolling window;

% author: Kexin Song (kexin.song@uconn.edu)
% created: 2024/03/12
% modified: 2024/10/30 add data_flag to exclude three consecutive missing
% values, then calculate autocorrelation with the rest observations.

    % empr_ac = zeros([length(nn)-window-1,1]);
    empr_ac = zeros([length(nn) 1]);
    for i=1:length(empr_ac)-window-1
        % temporal bin 1
        t1 = nn(i:i+window);
        df1 = data_flag(i:i+window);
        % Find indices of three consecutive zeros
        indices = find(df1(1:end-2) == 0 & df1(2:end-1) == 0 & df1(3:end) == 0);
        if ~isempty(indices)
            t1(indices:indices+2) = nan;
        end
        % temporal bin 2
        t2 = nn(i+1:i+window+1);
        df2 = data_flag(i+1:i+window+1);
        indices = find(df2(1:end-2) == 0 & df2(2:end-1) == 0 & df2(3:end) == 0);
        if ~isempty(indices)
            t2(indices:indices+2) = nan;
        end
        % scatter(t1,t2,'red');
        % autocorr_values = corrcoef(t1,t2,'Rows','complete');
        tmp1 = t1(~isnan(t1)&~isnan(t2));
        tmp2 = t2(~isnan(t1)&~isnan(t2));
        if length(tmp1)>1
            autocorr_values = corrcoef(tmp1,tmp2);
            empr_ac(i+window+1) = autocorr_values(1,2);
        else
            empr_ac(i+window+1) = NaN;
        end
    end
    empr_ac(1:window+1) = NaN;
end