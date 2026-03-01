function plotTSFitsamples(folderpath_cold, folderpath_csv, varargin)
% Tis function is used to plot time series of surface reflectance and CCD model fit (optional) for reference interpretation. 
% 
% Inputs: 
%   folderpath_cold
%   folderpath_csv
% Outputs: time series plots under 'COLDTimeSeriesPlot' folder.
% Notes: To use, adjust line 46,48,65. 
%        Run this script after saveTimeSeries.m   
% Kexin Song 
%(03/30/2020)

% close all;
addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'CCD'));
addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'Export'));

%% set inputs here
if ~exist('folderpath_cold', 'var')
    folderpath_cold = pwd;
end
if ~exist('folderpath_csv', 'var')
    folderpath_csv = pwd;
end
p = inputParser;
addParameter(p,'task', 1); % 1st task
addParameter(p,'ntasks', 1); % single task to compute
addParameter(p,'cprob', 0.99); % probability for detecting surface change
addParameter(p,'conse', 8); % number of consecutive observation
addParameter(p,'maxc', 8); % number of maximum coefficients
addParameter(p,'orbitpath', 'single'); % based on non-overlap landsat data
addParameter(p,'daterange',[datenummx(2015,1,1), now]); % display all bands
addParameter(p,'msg', true); %  to display info
addParameter(p,'forward',true);   % default is forward COLD
addParameter(p,'sensor',[]);


% request user's input
parse(p,varargin{:});
task = p.Results.task;
ntasks = p.Results.ntasks;
T_cg = p.Results.cprob;
conse = p.Results.conse;
max_c = p.Results.maxc;
msg = p.Results.msg;
daterange = p.Results.daterange;
forward = p.Results.forward;
sensor = p.Results.sensor;


sensor={'S2'};
forward = true;

% folderpath_cold = '/shared/cn450/Kexin/COLDTIFResults/18TXM';
folderpath_cold = '/shared/cn450/Sentinel-2/COLDResults/18TXM';
% folderpath_cold = '/shared/cn451/Kexin/COLDHLSResults/18TYM/';
folderpath_csv = '/shared/cn450/Kexin/Samples/18TXM/';
% folderpath_csv = '/shared/cn452/Kexin/Survey/';

folderpath_plot = fullfile(folderpath_cold,'COLDTimeSeriesPlot');
if ~isfolder(folderpath_plot)
    mkdir(folderpath_plot)
end
folderpath_samplets = fullfile(folderpath_cold,'SampleTSS2');
cd(folderpath_samplets);
% folderpath_sampleTSFit = fullfile(folderpath_cold, 'SampleTSFit');
% if ~isfolder(folderpath_sampleTSFit)
%     mkdir(folderpath_sampleTSFit)
% end


%% load samples here
% samplecsv = dir(fullfile(folderpath_csv,'*18TXL*GMSurveys.csv'));
% samplecsv = dir(fullfile(folderpath_csv,'*18TXM*S2*.csv'));
% T = readtable(fullfile(samplecsv(1).folder,samplecsv(1).name));
% ID = table2array(T(:,1));
% rows = table2array(T(:,2));
% cols = table2array(T(:,3));
% clear T

%% Constants:
% % optional
% Bands for detection change
% B_detect = [2:10];         % G,R,E1,E2,E3.NIR,SWIR1,SWIR2
B_detect = [2,3,7:10];   % G,R,NIR,SWIR1,SWIR2    
% Treshold of noisercg_new
Tmax_cg = 1-1e-5;

% if forward
if contains(sensor,{'S2','HLS10'})
    daterange =[datenummx(2015,1,1), datenummx(2021,12,1)];
else
    daterange =[datenummx(2013,1,1), datenummx(2021,12,1)];
end
% else
% 	daterange =[datenummx(-2022,9,1), datenummx(-2015,1,1)];
% end


%% load metadata.mat for having the basic info of the dataset that is in proccess
load(fullfile(folderpath_cold, 'metadata.mat'));
% load(fullfile('/shared/cn451/Kexin/COLDHLSResults/18TYM/','metadata.mat'));   % use other tiles for T18TXM
nbands = metadata.nbands;
% nbands = 19;
% ncols = 10980;
% nbands = 7;
%% parallel starts here...
ID = 1;
num_stacks = length(ID);
tasks_per = ceil(num_stacks/ntasks);
start_i = (task-1)*tasks_per + 1;
end_i = min(task*tasks_per, num_stacks);

%% Loop strarts here, total number of points is ...
for id = start_i:end_i
% for id = [114]
    tic
    
%     pt_row = rows(id);
%     pt_col = cols(id);
    pt_row = 7348;
    pt_col = 3295;

    
    %% read sadate and line_t from .mat file
    load('sdate');
    filepath_rcg =  sprintf('line_t_r%05dc%05d.mat', pt_row,pt_col); % r:row c:col
    load(filepath_rcg);
    
%     %% optional: calculate vegetation index and update line_t, B_detect, and nbands
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
%     B_detect = [2:17]; % best scenarios: b3-b8,b8a,b11,b12,vi(3),revi(4)
%     metadata.nbands = 19;
    %% run COLD
    % optional: forward
    if strcmp(sensor,'S2')
        [rec_cg, clrx, clry] = TrendSeasonalFit_COLDLineSample(sdate, line_t, [], [], ...
        metadata.ncols, pt_row, pt_col, T_cg, Tmax_cg, conse, max_c, metadata.nbands, B_detect);
    else
        [rec_cg, clrx, clry] = TrendSeasonalFit_COLDLineSampleHLS(sdate, line_t, [], [], ...
        ncols, pt_row, pt_col, T_cg, Tmax_cg, conse, max_c, nbands, B_detect);
    end

%     optional: backward
%     forward=false;
%     sdate1 = -sdate;
%     if strcmp(sensor,'S2')
%         [rec_cg, clrx, clry] = TrendSeasonalFit_COLDLineSample(sdate1, line_t, [], [], ...
%         metadata.ncols, pt_row, pt_col, T_cg, Tmax_cg, conse, max_c, metadata.nbands, B_detect);
%     else
%         [rec_cg, clrx, clry] = TrendSeasonalFit_COLDLineSample(sdate1, line_t, [], [], ...
%         metadata.ncols, pt_row, pt_col, T_cg, Tmax_cg, conse, max_c, metadata.nbands, B_detect);
%     end 
%     clrx = -clrx;
%     end
   
    %% plot time series
    bandnames = {'Blue','Green','Red','Edge1','Edge2','Edge3','NIR','SWIR1','SWIR2','NNIR'};%,'NNIR',...
       % 'NDVI','GNDVI','MTCI','EVI','NDVI705','NDVIed1','NDVIed2','NBR'};  % Sentinel-2
%     bandnames = {'Blue','Green','Red','NNIR','SWIR1','SWIR2','NDVI'};   %  HLS
    figure
    set(gcf,'Position',[0 0 1200 300]);
%     set(gcf,'Position',[0 0 1200 1800]);
    set(gca,'FontSize',13);
    set(gcf,'color','w');
    iplot = 1;
    
%     plot_ids = [4];  % HLS
    plot_ids = [10];  % S2: Look at the R, E3, NIR, SWIR1, and SWIR2
%     plot_ids = [4,5,6,7];     % Look at the E1, E2, E3, NIR
%     plot_ids = [11,12,14,18];      % Look at NDVI (traditonal bands) and NBR
%     plot_ids = [13,15,16,17];   % Look at NDVI (including red edge bands) 

    for B_plot = plot_ids    
        % Filter x and y
        x = sdate;
        y = line_t(:,B_plot);
%         x = sdate(line_t(:,end)<2);
        x = sdate(line_t(:,end)<2); % Apply Fmask not apply Tamsk 
        y = y(line_t(:,end)<2);
        x = x(y>0&y<10000);       % filter valid date
        y = y(y>0&y<10000);       % filter valid value
        % display observations
        subplot(length(plot_ids),1,iplot);
        if forward
            plot_obs = plot(clrx,clry(:,B_plot), 'k.', 'Color', '#000000', 'Markersize', 15,'DisplayName', 'Clear Observations');
        else
%             y = flip(clry(:,B_plot),1);
            plot_obs = plot(clrx,clry(:,B_plot), 'k.', 'Color', '#000000', 'Markersize', 15,'DisplayName', 'Clear Observations');
        end
        hold on;
    
        %% plot model curves (optional)
        t_min = -200;
        % break time
        t_break = [rec_cg.t_break];
        % change probability
        change_prob = [rec_cg.change_prob];
        % change vector magnitude
        mag = [rec_cg.magnitude];
        % reshape magnitude
        mag = reshape(mag,nbands-1,[]);
        % coefficients
        coefs = [rec_cg.coefs];
        coefs = reshape(coefs,8,nbands-1,[]);
        
        num_fit = size(rec_cg, 2);
        for i = 1: num_fit
            x_plot=rec_cg(i).t_start:rec_cg(i).t_end;
            pred_y=autoTSPred(x_plot',rec_cg(i).coefs(:,B_plot));
            if forward
                plot_model = plot(x_plot,pred_y, 'Marker', '.', 'Color', '#0072BD','LineWidth',1,'DisplayName', 'Time Series Model');
            else
                x_plot_b = -x_plot;
                plot_model = plot(x_plot_b,pred_y, 'Marker', '.', 'Color', '#0072BD','LineWidth',1,'DisplayName', 'Time Series Model');
            end
            hold on;
            % display breaks
            if rec_cg(i).change_prob > 0
                bp = rec_cg(i).t_break;
                if rec_cg(i).change_prob < 1
                    if forward
                        plot_change = plot(bp,clry(clrx==rec_cg(i).t_break,B_plot),'ko','Markersize',12, 'DisplayName', 'Change');
                    else
                        plot_change = plot(-bp,clry(clrx==-bp,B_plot),'ko','Markersize',12, 'DisplayName', 'Change');
                    end
                else
                    [break_type,~,~] = labelDisturbanceType(coefs(:,:,i),t_break(i),t_min,mag(:,i),coefs(:,:,i+1));
                    if break_type ~=1    % label 'nonregrowth' break as red circle
                        try
                            if forward
                                [~,closestIndex] = min(abs(clrx-bp));
                                plot_change = plot(bp,clry(closestIndex,B_plot),'ro','LineWidth', 3,'Markersize',12, 'DisplayName', 'Change');
                            else
                                plot_change = plot(-bp,clry(clrx==-bp,B_plot),'ro','LineWidth', 3,'Markersize',12, 'DisplayName', 'Change');
                            end
                        catch me
                            continue
                        end
                    else     % label 'regrowth' break as green circle
                       try
                           [~,closestIndex] = min(abs(clrx-bp));
                            if forward
                                plot_change = plot(bp,clry(closestIndex,B_plot),'go','LineWidth', 3,'Markersize',12, 'DisplayName', 'Change');
                            else
                                plot_change = plot(-bp,clry(clrx==-bp,B_plot),'go','LineWidth', 3,'Markersize',12, 'DisplayName', 'Change');
                            end   
                        catch me
                            continue
                        end 
                    end
                end
                hold on;
%                 if B_plot == Band_Plot(1)
%                 fprintf('The %dth change occurred at %d %d\n',i,ntime(1),ndays);
%                 end
            end
        end
         
        datetick('x', 29, 'keeplimits');
        xlim(daterange);
        if ~forward
            set(gca, 'XDir','reverse');   
        end
        str_ylabel = sprintf('%s', bandnames{B_plot}); 
        ylabel(str_ylabel,'Color','r','FontSize',18);
        if iplot == 1
            title(sprintf('Row/Column:%d/%d', pt_row, pt_col),'FontSize',16);
%             if forward
%                 subtitle('Forward COLD', 'Color','red','FontSize',16);
%             else
%                 subtitle('Backward COLD', 'Color','red','FontSize',16);
%             end
        end
        if iplot == length(plot_ids)
            xlabel('Date','FontSize',22);
        end
        
        iplot = iplot+1;
    end
    %% save plots
    if forward
        fname = ['TSplot_',sprintf('%03d',id),'_forward.png'];
    else
        fname = ['TSplot_',sprintf('%03d',id),'_backward.png'];
    end
%     saveas(gcf,fullfile(folderpath_plot,fname));
%     saveas(gcf,'/home/kes20012/timeseries_id32_forward.png');

    clear line_t;
end
end


