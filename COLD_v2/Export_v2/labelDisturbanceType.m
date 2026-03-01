function [dist_type,dist_year,dist_doy]=labelDisturbanceType(curr_cft,curr_time,t_c,vec,next_cft,sensor)
% This function is used to provide distubance year and disturbance type 
% 1 => regrowth break
% 2 => aforestation break
% 3 => land disturbance
% 
% Version 1.0: (Zhe Zhu 10/30/2018)
% Modification: Identifications of Aforestation and Regrowth breaks are modified in Line #27. (Zhe and Shi, 21/08/2020)
%
%% get disurbance pixel
% vec = obs - pred
% only provide disturbance map
% obs - pred



%% sentinel-2
if strcmp(sensor,'S2')
% nir = vec(7);  
% c_nir = curr_cft(2,7);
% n_nir = next_cft(2,7);
    nir = vec(10);  
    c_nir = curr_cft(2,10);
    n_nir = next_cft(2,10);

    vis = vec(3);
    c_vis = curr_cft(2,3);
    n_vis = next_cft(2,3);

    swir = vec(8);
    c_swir = curr_cft(2,8);
    n_swir = next_cft(2,8);
else
    % Landsat/HLS/HLS10 
    % nir = vec(4);
    % c_nir = curr_cft(2,4);
    % n_nir = next_cft(2,4);
    % 
    % vis = vec(3);
    % c_vis = curr_cft(2,3);
    % n_vis = next_cft(2,3);
    % 
    % swir = vec(5);
    % c_swir = curr_cft(2,5);
    % n_swir = next_cft(2,5);

    % ks: test Landsat
    nir = vec(2);
    c_nir = curr_cft(2,2);
    n_nir = next_cft(2,2);

    vis = vec(1);
    c_vis = curr_cft(2,1);
    n_vis = next_cft(2,1);

    swir = vec(3);
    c_swir = curr_cft(2,3);
    n_swir = next_cft(2,3);
end


if nir > t_c && vis < -t_c && swir < -t_c
    if n_nir > abs(c_nir) && n_vis < -abs(c_vis) && n_swir < -abs(c_swir)
        dist_type = 2; % aforestation
    else
        dist_type = 1; % regrowth
    end
else
    dist_type = 3; % land disturbance
end

dist_year = datevecmx(curr_time);
dist_year = dist_year(1);
dist_doy = curr_time - datenummx(dist_year,1,0);