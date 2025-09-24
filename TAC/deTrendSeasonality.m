function [outputy, linear_trend, seasonalities, refs]  = deTrendSeasonality(x,y,rec_cg_coef)
%DETRENDSEASONALITY Summary of this function goes here
% INPUTS:
% x       - Julian day [1; 2; 3];
% y       - original observations [0.1; 0.2; 0.3];
% fit_cft - fitted coefficients;

% OUTPUTS:
% outputy - reflectances after detrending and deseasonality [0.1; 0.2; 0.3];
% linear_trend - long term trend
% seasonalities - seasonal cycle 1,2,3

% General model TSModel:
% f(x) =  a0 + b0*x + a1*cos(x*w) + b1*sin(x*w) 

% author: Kexin Song (kexin.song@uconn.edu)
% created: 2024/03/12
% modified: 2024/09/15

    % num_yrs = 365.25; % number of days per year
    % w=2*pi/num_yrs; % anual cycle 
    w = 2*pi/365.25;
    
    outputy = zeros(size(y));
    linear_trend = zeros(size(y));
    seasonalities = zeros(size(y));
    refs = zeros(size(y));
    for iband = 1:size(y,2)
        fit_cft = rec_cg_coef(2:end,iband);    
        ref = rec_cg_coef(1,iband);
        trend = x*fit_cft(1);
        seasonality = [cos(w*x),sin(w*x),...% add unimodal seasonality
                cos(2*w*x),sin(2*w*x),...   % add bimodal seasonality
                cos(3*w*x),sin(3*w*x)]*fit_cft(2:end); % add trimodal seasonality
        
        linear_trend(:,iband) = trend;
        seasonalities(:,iband) = seasonality;
        refs(:,iband) = ref;
        
        outputy(:,iband) = y(:,iband) - ref - trend - seasonality;
    end

end

