function COLDsamples(varargin)
% This function run COLD for smaples for validation.
%   The outputs are 'record_change_rxxxxxcxxxxx.mat' under 'SampleTSFit'
%   folder, which will be used in 'exportDOYsamples.m'. Run this script after saveTimeSeries.m

close all;
addpath(fullfile('/home/kes20012/COLD_v2/CCD'));

%% Inputs
p = inputParser;
addParameter(p,'task', 1); % 1st task
addParameter(p,'ntasks', 1); % single task to compute
addParameter(p,'Tiles',[]);
addParameter(p,'sensor',[]);

% model parameters 
addParameter(p,'cprob', 0.95); % probability for detecting surface change, default is 0.99
addParameter(p,'conse', 6); % number of consecutive observation, default is 6
addParameter(p,'maxc', 8); % number of maximum coefficients, default is 8
addParameter(p,'orbitpath', 'single'); % based on non-overlap landsat data
addParameter(p,'daterange',[datenummx(1984,1,1), now]); % display all bands
addParameter(p,'msg', false); %  to display info
addParameter(p,'forward', true);  % default is forward COLD
addParameter(p,'B_detect',[]);  % input spectral bands

% request user's input
parse(p,varargin{:});
task = p.Results.task;
ntasks = p.Results.ntasks;
Tiles = p.Results.Tiles;
sensor = p.Results.sensor;
% sensor = {sensor};
parse(p,varargin{:});
T_cg = p.Results.cprob;
conse = p.Results.conse;
max_c = p.Results.maxc;
msg = p.Results.msg;
daterange = p.Results.daterange;
forward = p.Results.forward; 
B_detect = p.Results.B_detect;

% Tiles = {'18TXL','18TYM','18TYL'};
% sensor={'S2'};
sensor={'HLS'};
Tiles = {'18TXM'};

%% Constants:
% Bands for detection change
% if strcmp(sensor,'S2')  % 10 spectral bands (B,G,R,E1,E2,E3,NIR,SWIR1,SWIR2,NNIR) + fmask
% %     B_detect = [2,3,7:9];   % COLD default: G,R,NIR,SWIR1,SWIR2
%     B_detect = [2:9];       % G,R,E1,E2,E3.NIR,SWIR1,SWIR2
% else
B_detect = [2:6];  % HLS
% end
% Treshold of noisercg_new
Tmax_cg = 1-1e-5;
if forward
    daterange =[datenummx(2015,1,1), datenummx(2021,12,1)];
else
    daterange =[datenummx(-2022,9,1), datenummx(-2015,9,1)];
end

%% set inputs here
for iTile = 1:length(Tiles)
    if strcmp(sensor,'HLS')
        folderpath_cold = fullfile('/scratch/zhz18039/kes20012/ProjectInsectDisturbance/COLDHLSResults/',Tiles{iTile});
    elseif strcmp(sensor,'HLS10')
        folderpath_cold = fullfile('/scratch/zhz18039/kes20012/ProjectInsectDisturbance/COLD10mHLSResults/',Tiles{iTile});
    elseif strcmp(sensor,'S2')
%         folderpath_cold = fullfile('/shared/cn450/Sentinel-2/COLDResults/',Tiles{iTile});
        folderpath_cold = fullfile('/shared/cn452/Kexin/COLDResults/',Tiles{iTile});
        
    end
folderpath_sampleTSFit = fullfile(folderpath_cold, 'SampleTSFit');
if ~isfolder(folderpath_sampleTSFit)
    mkdir(folderpath_sampleTSFit)
end
if strcmp(sensor,'HLS')
    folderpath_samplets = '/scratch/zhz18039/kes20012/ProjectInsectDisturbance/Data/HLS/';%fullfile(folderpath_cold,'SampleTSHLS');
elseif strcmp(sensor,'HLS10')
    folderpath_samplets = '/scratch/zhz18039/kes20012/ProjectInsectDisturbance/Data/10mHLS/';%fullfile(folderpath_cold,'SampleTSHLS');'fullfile(folderpath_cold,'SampleTS');
elseif strcmp(sensor,'L30')
    folderpath_samplets = fullfile(folderpath_cold,'SampleTSL30');
elseif strcmp(sensor,'S30')
    folderpath_samplets = fullfile(folderpath_cold,'SampleTSS30');
elseif strcmp(sensor,'S2')
    folderpath_samplets = fullfile(folderpath_cold,'SampleTSS2');
end
cd(folderpath_samplets);

%% load samples here
if contains(sensor,{'S2','HLS'})
    folderpath_ref = '/scratch/zhz18039/kes20012/ProjectInsectDisturbance/Sample/';
    samplecsv = dir(fullfile(folderpath_ref,'samples_IDSpositive_puredamage_rowcol.csv'));
else
    folderpath_ref = '/shared/cn450/Kexin/Samples/';   % or cn449
    samplecsv = dir(fullfile(folderpath_ref,Tiles{iTile},'*samples*HLS*.csv'));
end
T = readtable(fullfile(samplecsv(1).folder,samplecsv(1).name));
% ID = table2array(T(:,1));
rows = table2array(T(:,1));
cols = table2array(T(:,2));
clear T

%% load metadata.mat for having the basic info of the dataset that is in proccess
try
    load(fullfile(folderpath_cold, 'metadata.mat'));
catch
    metadata.ncols = 3660;
    metadata.nbands = 7;
end

%% Loop strarts here, total number of points is 49...
for i = 1 : length(rows)
    tic
    pt_row = rows(i);
    pt_col = cols(i);
    
    %% read sadate and line_t from .mat file
    load('sdate');
    filepath_rcg =  sprintf('line_t_r%05dc%05d.mat', pt_row,pt_col); % r:row c:col
    load(filepath_rcg);
    
    % %% Optional: calculate vegetation index and update line_t, B_detect, and nbands
    % if strcmp(sensor,'S2')
    %     b2 = line_t(:,1);  % blue
    %     b3 = line_t(:,2);  % green
    %     b4 = line_t(:,3);  % red
    %     b5 = line_t(:,4);  % edge 1
    %     b6 = line_t(:,5);  % edge 2
    %     b7 = line_t(:,6);  % edge 3
    %     b8 = line_t(:,7);  % NIR
    %     b11 = line_t(:,8);  % SWIR1
    %     b12 = line_t(:,9); % SWIR2
    %     b8a = line_t(:,10); % NNIR
    %     % NDVI  11
    %     ndvi = double(b8-b4)./double(b8+b4);
    %     ndvi = ndvi*10000;
    %     % GNDVI (green ndvi)  12
    %     gndvi = double(b8-b3)./double(b8+b3);
    %     gndvi = gndvi*10000;
    %     %  MTCI (MERIS Terrestrial Chlorophyll Index)   13
    %     mtci = double(b6-b5)./double(b5-b4);
    %     mtci = mtci*10000;
    %     % EVI   14
    %     evi = 2.5*double(b8-b4)./double(b8+6*b4-7.5*b2+1);
    %     evi = evi*10000;
    %     % NDVI705   15
    %     ndvi_705 = double(b6-b5)./double(b6+b5);
    %     ndvi_705 = ndvi_705*10000;
    %     % NDVI red edge 1   16
    %     ndvi_ed1 = double(b8-b5)./double(b8+b5);
    %     ndvi_ed1 = ndvi_ed1*10000;
    %     % NDVI red edge 2   17
    %     ndvi_ed2 = double(b6-b4)./double(b6+b4);
    %     ndvi_ed2 = ndvi_ed2*10000;
    %     % NBR   18
    %     nbr = double(b8-b12)./double(b8+b12);
    %     nbr = nbr*10000;    
    %     % update line_t
    %     line_t = [line_t(:,1:end-1),ndvi,gndvi,mtci,evi,ndvi_705,ndvi_ed1,ndvi_ed2,nbr,line_t(:,end)];      
    % 
    % %     B_detect = [2:17];
    %     metadata.nbands = 19;
    % else
    %     b1 = line_t_ic(:,1);  % blue
    %     b2 = line_t_ic(:,2);  % green
    %     b3 = line_t_ic(:,3);  % red
    %     b4 = line_t_ic(:,4);  % nir
    %     b5 = line_t_ic(:,5);  % swir1
    %     b6 = line_t_ic(:,6);  % swir2
    %     metadata.nbands = 6;
    % end
    
    %% run COLD
    %  forward
    if strcmp(sensor,'S2')
        [rec_cg_f, clrx, clry] = TrendSeasonalFit_COLDLineSample(sdate, line_t_ic, [], [], ...
        metadata.ncols, pt_row, pt_col, T_cg, Tmax_cg, conse, max_c, metadata.nbands, B_detect);

    else
        [rec_cg_f, clrx, clry] = TrendSeasonalFit_COLDLineSampleHLS(sdate, line_t_ic, [], [], ...
        metadata.ncols, pt_row, pt_col, T_cg, Tmax_cg, conse, max_c, metadata.nbands, B_detect);
    end
    % % backward
    % forward = false;
    % sdate1 = -sdate;
    % if strcmp(sensor,'S2')
    %     [rec_cg_b, clrx, clry] = TrendSeasonalFit_COLDLineSample(sdate1, line_t, [], [], ...
    %     metadata.ncols, pt_row, pt_col, T_cg, Tmax_cg, conse, max_c, metadata.nbands, B_detect);
    % else
    %     [rec_cg_b, clrx, clry] = TrendSeasonalFit_COLDLineSampleHLS(sdate1, line_t, [], [], ...
    %     metadata.ncols, pt_row, pt_col, T_cg, Tmax_cg, conse, max_c, metadata.nbands, B_detect);
    % end 
    % clrx = -clrx;

    %% Export record of change to .mat file
    filepath_rcg = fullfile(folderpath_sampleTSFit, sprintf('record_change_forward_r%05dc%05d.mat', pt_row,pt_col)); % r:row c:col
    save([filepath_rcg, '.part'] ,'rec_cg_f'); % save as .part
    clear line_t;
    clear rec_cg_f;
    movefile([filepath_rcg, '.part'], filepath_rcg);  % and then rename it as normal format
    
    filepath_rcg = fullfile(folderpath_sampleTSFit, sprintf('record_change_backward_r%05dc%05d.mat', pt_row,pt_col)); % r:row c:col
    save([filepath_rcg, '.part'] ,'rec_cg_b'); % save as .part
    clear rec_cg_b;
    movefile([filepath_rcg, '.part'], filepath_rcg);  % and then rename it as normal format
    close all;
    
    if msg
        fprintf('ProcessingTSFitRowCol = %0.2f mins for row/col %d/%d with %d images\r\n', toc/60, pt_row, pt_col, length(sdate)); 
    end
    
%     %% plot time series (Please use the other function
%     'plotTSFitsamples.m' for visulization)
%     bandnames = {'Blue','Green','Red','Edge1','Edge2','Edge3','NIR','SWIR1','SWIR2'};
%     for B_plot = [7]    % Look at the NIR first
%         figure
%         set(gcf,'Position',[0 0 1200 250]);
%         set(gca,'FontSize',13);
%         set(gcf,'color','w');
%         % display observations
%         plot_obs = plot(clrx,clry(:,B_plot), 'k.', 'Color', '#000000', 'Markersize', 15,'DisplayName', 'Clear Observations');
%             hold on;
%     
        % plot curves
        num_fit = size(rec_cg, 2);
        for i = 1: num_fit
            x_plot=rec_cg(i).t_start:rec_cg(i).t_end;
            pred_y=autoTSPred(x_plot',rec_cg(i).coefs(:,B_plot));
            plot_model = plot(x_plot,pred_y, 'Marker', '.', 'Color', '#0072BD','LineWidth',1,'DisplayName', 'Time Series Model');
            hold on;
            % display breaks
            if rec_cg(i).change_prob > 0
                if rec_cg(i).change_prob < 1
                    plot_change = plot(rec_cg(i).t_break,clry(clrx==rec_cg(i).t_break,B_plot),'ko','Markersize',12, 'DisplayName', 'Change');
                else
                    try
                        plot_change = plot(rec_cg(i).t_break,clry(clrx==rec_cg(i).t_break,B_plot),'ro','Markersize',12, 'DisplayName', 'Change');
                    catch me
                        continue
                    end
                end
                hold on;
%                 if B_plot == Band_Plot(1)
%                 fprintf('The %dth change occurred at %d %d\n',i,ntime(1),ndays);
%                 end
            end
        end
%         datetick('x', 29, 'keeplimits');
%         xlim(daterange);
%         str_ylabel = sprintf('SR of %s Band (\\times 10^4)', bandnames{B_plot});     
%         ylabel(str_ylabel);
%         title(sprintf('Row/Columns:%d/%d', pt_row, pt_col));
%         xlabel('Date');
%     end
end
end

end


