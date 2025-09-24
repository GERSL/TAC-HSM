function TIF_coefficient = runTIFSinglePixel(varargin)
%%-------------------------------------------------------------------------
% runTIFSinglePixel()conducts Time-series based Image Fusing (TIF) algorithm and export coefficients. 
% 
% This function performs Time-series based Image Fusing (TIF) using input 
% time series data from Landsat and Sentinel-2. It matches clear observations 
% between the two datasets, performs k-means clustering, and builds weighted 
% linear models to derive the relationship between them. The function outputs 
% the TIF coefficients, including slopes, intercepts, number of observation
% pairs, R-squared values, and optionally plots the time series and saves the results.
%
% Inputs:
%   - data: Struct containing Landsat and Sentinel-2 time series data.
%   - L8_metadata: Struct containing Landsat metadata.
%   - S2_metadata: Struct containing Sentinel-2 metadata.
%   - varargin: Additional optional parameters for various processing options.
%
% Outputs:
%   - TIF_coefficient: Struct containing the calculated TIF coefficients for 
%     each spectral band.
%
% Example usage:
%   TIF_coefficient = runTIFSinglePixel(data, L8_metadata, S2_metadata, 'task', 1, 'ntasks', 1, 'msg', true);
%
% Author: Kexin Song (kexin.song@uconn.edu)
% Date: 2024/07/01
%
% ks 20230816: add slope, intercept, and rsuqred for obs pairs<4.
% ks 20231109: test weight functions (1/sqrt(d), 1/d, 1/d^2).
% ks 20231212: add lines to correct cloud mask issue (T10SFG) 251-255 to
% 0-4.
%%-------------------------------------------------------------------------
% warning('off','all')
close all;
% addpath(fullfile(pwd, 'Fusion'));
addpath(fullfile('/home/kes20012/TIF/Fusion'));
% band number for visulization
band_plot = 1;


% if ~exist('l57_data', 'var')
%     warning('Please input Landsat 5&7 time series!\r');
%     return;
% end
% 
% if ~exist('l89_data', 'var')
%     warning('Please input Landsat 8&9 time series!\r');
%     return;
% end


p = inputParser;
addParameter(p,'task', 1);                      % 1st task
addParameter(p,'ntasks', 1);                    % single task to compute
addParameter(p,'msg', false);                    % display info

addParameter(p,'t_threshold',1);               % default observation-matching threshold is +- 16 day(s).
addParameter(p,'regress_method','robustfit');   % default linear regression method is 'robustfit'. others are 'linear', 'multi-variable-robustfit', 'multi-variable-linear'.
addParameter(p,'maxK',1);                       % default value for the maximum K-means cluster is 2.    
addParameter(p,'wfun','Fair');                  % default is "Fair". Options: Fair, Cauchy, Sqrt

addParameter(p,'do_plot',false);
addParameter(p,'save_figure',false);


% request user's input
parse(p,varargin{:});
task = p.Results.task;
ntasks = p.Results.ntasks;
msg = p.Results.msg;

t_threshold = p.Results.t_threshold;
regress_method = p.Results.regress_method;
maxK = p.Results.maxK;
wfun = p.Results.wfun;

do_plot = p.Results.do_plot;
save_figure = p.Results.save_figure;

%% Set paths and folders
folderpath_output = fullfile('TIFResults_20250726');
if ~isfolder(folderpath_output)
    mkdir(folderpath_output)
end

%% Constants:
% band codes for Landsat and Sentinel-2 
band_codes_L = [1,2,3,4,5,6,7,8,9,10,11,12,13];
band_codes_S = [1,2,3,4,5,6,7,8,9,10,11,12,13];
% band_codes_L = [13];
% band_codes_S = [13];%[1];
% time series range for developing the TIF model
% daterange =[datenum(2013,1,1), datenum(2021,12,31)];

%% load metadata for having the basic info of the dataset that is in proccess
% nbands = 1;
scale = 10000;

%% Report log of TIF 
% reportTIFLog(folderpath_output, ntasks, regress_method, wfun, t_threshold);

%% read time series data
tic
      
%% Load time series data from inputs
directory = '/gpfs/sharedfs1/zhulab/Kexin/ProjectTACValidation/';
folderpath_L78 = fullfile(directory,'TIFL78BRDFData/');
% folderpath_L78 = fullfile(directory,['TIFL78Data_',datestr(now, 'yyyy-mm-dd')]);
if ~exist(folderpath_L78)
    mkdir(folderpath_L78);
end
filepath_L78 = dir(fullfile(folderpath_L78, 'L57_L89_data_*.mat'));  % 100 files, each file contains 100 pixels' time series
num_files = length(filepath_L78);

X = [];
Y = [];
D = [];
percentage = [];
MATCH_DATE_X = [];

for j = 1:num_files
% for j = 1:10

    load(fullfile(filepath_L78(j).folder,filepath_L78(j).name));
    fprintf('Processing %.3f%%\n',j/num_files*100);

    n = 0;
    for i = 1:length(data_struct)
        data = data_struct(i);

        clrx_S = data.L89_dates;
        clry_S = data.L89_data;
        clry_S = table2array(clry_S);

        clrx_L = data.L57_dates; 
        clry_L = data.L57_data;
        clry_L = table2array(clry_L);

        clry_S = clry_S .*scale;
        clry_L = clry_L *scale;

        % %% plot time series (optional)
        % fig = figure();
        % fig.Position = [20, 20, 800, 300];
        % plot(clrx_L,clry_L(:,4),'b.','DisplayName','L57');
        % hold on;
        % plot(clrx_S,clry_S(:,4),'c.','DisplayName','L89');
        % hold on;
        
        
        %% match clear observations, i.e. X-Y pairs
        % t_threshold matching
        [x,y,d,match_date_x] = match_obs(clrx_L,clrx_S,clry_L,clry_S,band_codes_L,band_codes_S,t_threshold,[],'first');
        % [x1,y1,~] = match_obs(clrx_L,clrx_S,clry_L,clry_S,band_codes_L,band_codes_S,1,[],'first');
        
        %% remove nans
        valid_idx = all(~isnan(x), 2);
        physical_idx = x(:,1)>0 & x(:,1)<10000&...
            x(:,2)>0 & x(:,2)<10000 &...
            x(:,3)>0 & x(:,3)<10000 &...
            x(:,4)>0 & x(:,4)<10000 &...
            x(:,5)>0 & x(:,5)<10000 &...
            x(:,6)>0 & x(:,6)<10000;
        good_idx = valid_idx & physical_idx;
        x = x(good_idx,:);
        y = y(good_idx,:);
        d = d(good_idx,:);
        match_date_x = match_date_x(good_idx,:);
        
        % valid_idx = all(~isnan(x1),2);
        % x1 = x1(valid_idx,:);
        % y1 = y1(valid_idx,:);

        X = [X;x];
        Y = [Y;y];
        D = [D;d];
        MATCH_DATE_X = [MATCH_DATE_X;match_date_x];

        % test how many pixels have mathcing obs and contribute to X
        if height(x)>0
            n = n+1;
        end
        % % highlight matching obs pairs
        % plot(match_date_x,x(:,4),'r^','DisplayName','t=1 matching');
        % legend('Location','bestoutside')
        % datetick('x', 'yyyy-mm')  
  
    end
    percentage = [percentage,n./length(data_struct)];
    % fprintf('%d out of %d pixels have matching obs.\n',n,length(data_struct));
end
MATCH_DATE_X = datetime(MATCH_DATE_X,'ConvertFrom','datenum');

figure;
set(gcf,"Position",[50,50,700,400])
histogram(MATCH_DATE_X);
xlabel('Date');
ylabel('Frequency');
title('Distribution of Dates');
fprintf('Mean percentage is %.3f.\n',mean(percentage,'all'));

%% Create a structure to save TIF coefficient for each spectral band
TIF_coefficient = [];
ir = 1;ic = 1;
TIF_coefficient.row = ir;
TIF_coefficient.col = ic;
TIF_coefficient.NumofObs = length(X);

%% N-fold cross validation 
N=1;     % 20240628 ks: change N>1 to run multiple times
for cross_validation = 1:N
    if msg
        fprintf('Run TIF # %d...\n',cross_validation);
    end
    


    %% Build reflectance relationship for each pixel, each band
    % One homogenous group
    TIF_coefficient = build_weighted_linear_mdl(X,Y,band_codes_L,regress_method,'ir',ir,'ic',ic,'doplot',do_plot,'Band_plot',band_plot,'d',D,'wfun',wfun); 
    
    %% Save output
    if msg
        fprintf('    Export TIF parameters...\r');
    end
    filepath_TIFoutput = fullfile(folderpath_output, sprintf('TIFbrdf_coefficient_r%05dc%05d.mat',ir,ic));
    save([filepath_TIFoutput, '.part'] ,'TIF_coefficient'); % save as .part
    if ~isempty(TIF_coefficient)
        movefile([filepath_TIFoutput, '.part'], filepath_TIFoutput);
    end

    writematrix(X, 'X_brdf.csv');
    writematrix(Y, 'Y_brdf.csv');

    % %% Save sdate and TIF coefficients which contains Slopes, Intercepts, Rsquared, and Num of observation pairs
    % 
    % filepath_sdate = fullfile(folderpath_output,sprintf('sdate_r%05dc%05d.mat',ir,ic));
    % save(filepath_sdate,'sdate_M');
    % filepath_TIFoutput = fullfile(folderpath_output, sprintf('TIF_coefficient_r%05dc%05d.mat',ir,ic));
    % save([filepath_TIFoutput, '.part'] ,'TIF_coefficient'); % save as .part
    % if ~isempty(TIF_coefficient)
    %     movefile([filepath_TIFoutput, '.part'], filepath_TIFoutput);
    % end
if msg
    fprintf('Run time %.4f s.\n',toc);
end
   
end  % end of cross validation

end  % end of runTIF_coefficient_pixel func



function RMSE = CalRMSE(Ref, Pred)
    dif(:) = Ref(:) - Pred(:);
    dif(:) = dif(:).^2;
    RMSE = sqrt(mean2(dif(:)));      
end

function [AAD, AD] = CalBias(Ref, Pred)
% AAD: absolute average difference
% AD: average difference
    AAD = mean(abs(Pred-Ref));
    AD = mean(Pred-Ref);

end