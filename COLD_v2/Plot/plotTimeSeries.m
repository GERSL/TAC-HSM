function plotTimeSeries(folderpath_cold, pt_row, pt_col,varargin)
%PLOTTIMESERIES This is to plot the CCD results for a certain pixel
%
% INPUT:
%
%   folderpath_cold:          Locate to COLD working folder, in which the
%                             change folder <TSFitLine> is necessery, and
%                             this folder was created by <COLD.m>.
%
%   pt_row:                   [Number] Row of pixel. 
%
%   pt_col:                   [Number] Columns of pixel.  
%
%  displaybands (optional):   Which bands to display? like { 'Blue', 'Green',  'Red',  'NIR', 'SWIR1', 'SWIR2', 'Thermal'}
%
%  daterange (optional):      To control xlim. like [datenummx(1984,1,1), now]
%
%   orbitpath (optional):     Orbit path of Landsat ('single' or 'all').
%                             'single' means change will be identified
%                             based on the single Landsat path layer with
%                             geotiff format. 'all' means not to do that.
%                             (defaultvalue : single)
%
%   cprob (optional):         Change probability threshold (default value is 0.99)
% 
%   conse (optional):         Number of consecutive observations (default value is 6)
% 
%   maxc (optional):          Maximum number of coefficients used (default value is 6)
%
%   msg (optional):           [false/true] Display processing status (default value: true)
%
%
% EXAMPLE OF USE:
%
%   > To display the time series for the pixel (2500, 9) for blue, green,
%   and red bands
%
%     displaybands = { 'Blue', 'Green',  'Red'};
%     daterange =[datenummx(1984,1,1), datenummx(2015, 6, 1)];
%     plotTimeSeries('C:\Users\qsly0\Downloads\test_cold_v2\h029v005\', 2500, 9, 'displaybands', displaybands, 'daterange', daterange);
%
% 
% AUTHOR(s): Zhe Zhu and Shi Qiu
% DATE: Feb. 7, 2021
% COPYRIGHT @ GERSLab

% close all;
addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'CCD'));
addpath('/home/kes20012/COLD_v2/Export');

% % good pixel to test with mutiple changes for h029v005
% pt_row = 2500;
% pt_col = 9;

% optional
p = inputParser;
addParameter(p,'cprob', 0.95); % probability for detecting surface change
addParameter(p,'conse', 5); % number of consecutive observation
% addParameter(p,'conse',5);
addParameter(p,'maxc', 8); % number of maximum coefficients
addParameter(p,'orbitpath', 'all'); % based on non-overlap landsat data
addParameter(p,'displaybands', { 'Blue', 'Green',  'Red',  'NNIR', 'SWIR1', 'SWIR2'}); % display all bands
% addParameter(p,'displaybands',{'Blue','Green','Red','Edge1','Edge2','Edge3','NIR','SWIR1','SWIR2'});
addParameter(p,'daterange',[datenummx(1984,1,1), now]); % display all bands
addParameter(p,'msg', true); %  to display info


% request user's input
parse(p,varargin{:});
T_cg = p.Results.cprob;
conse = p.Results.conse;
max_c = p.Results.maxc;
msg = p.Results.msg;
displaybands = p.Results.displaybands;
daterange = p.Results.daterange;
% char will be better understood for users
switch lower(p.Results.orbitpath)
    case 'single'
        singlepath = true;
        s2path = 'Single';
    case 'all'
        singlepath = false;
        s2path = 'All';
end

%% skx: can also set inputs here
% folderpath_cold = '/shared/cn451/Kexin/COLDHLSResults/18TM';
% folderpath_cold = '/shared/cn450/Kexin/COLDHLSResults/18TYM';
% folderpath_cold = '/shared/cn450/Kexin/COLDHLSv2Results/18TXL';
folderpath_cold = '/shared/cn451/Kexin/COLDHLSResults/18TXL';

% pt_row = 3593;
% pt_col = 3215;
% pt_row = ceil(pt_row/3);  % convert to HLS pixel
% pt_col = ceil(pt_col/3);
% pt_row = 2515;
% pt_col = 2268;
% pt_row = 2682;
% pt_col = 1646;

% CT dead tree site 1
% pt_row = 472;
% pt_col = 1502;
% pt_row = 529;
% pt_col = 1593;
% pt_row = 539;
% pt_col = 1639;
pt_row = 674;
pt_col = 1697;
daterange =[datenummx(2013,1,1), datenummx(2023,12,31)];
% daterange =[datenummx(2015,1,1), datenummx(2020,11,1)];
% singlepath = true;

%% Constants:
% Bands for detection change
B_detect = 2:6;   % HLS: G,R,NIR,SWIR1,SWIR2
% B_detect = [2,3,7:9];   % G,R,NIR,SWIR1,SWIR2
% B_detect = [2:9];       % G,R,E1,E2,E3.NIR,SWIR1,SWIR2
% Treshold of noisercg_new
Tmax_cg = 1-1e-5;

if singlepath
    folderpath_stack = fullfile(folderpath_cold, 'StackDataSingleOrbit');
else
    % folderpath_stack = fullfile(folderpath_cold, 'StackData10HLS');
    folderpath_stack = fullfile(folderpath_cold, 'StackData10');
end
folderpath_plot = fullfile(folderpath_cold, 'TimeSeriesPlot');
if ~isfolder(folderpath_plot)
    mkdir(folderpath_plot);
end

%% load metadata.mat for having the basic info of the dataset that is in proccess
% load(fullfile(folderpath_cold, 'metadataHLS.mat'));
load(fullfile(folderpath_cold, 'metadata.mat'));
    

%% find the row dataset within all the dataset
foldername_rowdata = [];
for irow = 1: metadata.nsubrows: metadata.nrows % total of 5000 rows
    % @ the current task, only parts of the images will be reconstructed
    irow_end = min(irow + metadata.nsubrows -1, metadata.nrows);
    if irow <= pt_row && pt_row <= irow_end
        foldername_rowdata = sprintf('R%05d%05d', irow, irow_end);
        break;
    end
end
if isempty(foldername_rowdata)
    if msg
        fprintf('No row dataset found\r\n');
    end
    return;
end

folderpath_stackrows = fullfile(folderpath_stack, foldername_rowdata);

%% based on all path data, ...
ncols = metadata.ncols;
sensor = 'HLS';
switch sensor
    case 'HLS'
        [sdate, line_t, sensorgroup] = readStackLineDataHLS(folderpath_stackrows, ncols, metadata.nbands, pt_row,[],sensor);
        % ccd processing
        [rec_cg, clrx, clry] = TrendSeasonalFit_COLDLineHLS(sdate, line_t, [], [], ...
        metadata.ncols, pt_row, pt_col, T_cg, Tmax_cg, conse, max_c, metadata.nbands, B_detect);
        % label L10 and S10 
        [~,~,ib] = intersect(clrx,sdate);
        clrsensorgroup = sensorgroup(ib);
        % assign bandnames
        Band_Plot = [1,2,3,4,5,6];
        bandnames = { 'Blue', 'Green',  'Red',  'NNIR', 'SWIR1', 'SWIR2'};
        % set bands for display
        % plot_ids = [3,4,5,6];
        plot_ids = [4];
    case 'S2'
        [sdate, line_t] = readStackLineDataSample(folderpath_stackrows, metadata.ncols, metadata.nbands, pt_row, pt_col,[]);
        % ccd processing
        [rec_cg, clrx, clry] = TrendSeasonalFit_COLDLineSample(sdate, line_t, [], [], ...
        metadata.ncols, pt_row, pt_col, T_cg, Tmax_cg, conse, max_c, metadata.nbands, B_detect);
        % assign bandnames
        Band_Plot = [1,2,3,4,5,6,7,8,9];
        bandnames = {'Blue','Green','Red','Edge1','Edge2','Edge3','NIR','SWIR1','SWIR2'};
        % set bands for display
        plot_ids = [3,5,7,9];
end


% update the bands for display
ids_display = ismember(bandnames, displaybands);
Band_Plot = Band_Plot(ids_display);
figure
% set(gcf,'Position',[0 0 1200 250]);
set(gcf,'Position',[0 0 1200 800]);
% set(gca,'FontSize',13);
set(gcf,'color','w');

iplot = 1;
for B_plot = plot_ids    % Look at the Red, NIR, SWIR1 bands first
    subplot(length(plot_ids),1,iplot);
    switch sensor
        case 'HLS'
            % display L30 observations
            k = find(clrsensorgroup==0);
            plot_obs = plot(clrx(k),clry(k,B_plot), 'b.', 'Marker', '.','Color', '#0000FF', 'Markersize', 18,'DisplayName', 'Clear Observations');
            hold on
            % diaplay S30 observations
            k = find(clrsensorgroup==1);
            plot_obs = plot(clrx(k),clry(k,B_plot), 'r.', 'Marker', '.', 'Color', '#FF0000', 'Markersize', 18,'DisplayName', 'Clear Observations');
        case 'S2'    
            plot_obs = plot(clrx,clry(:,B_plot), 'b.', 'Marker', '.', 'Color', '#0000FF', 'Markersize', 12,'DisplayName', 'Clear Observations');
    end
    hold on;

%     %% plot model curves (optional)
%     t_min = -200;
%     num_fit = size(rec_cg, 2);
%     for i = 1: num_fit
%         x_plot=rec_cg(i).t_start:rec_cg(i).t_end;
%         pred_y=autoTSPred(x_plot',rec_cg(i).coefs(:,B_plot));
% 
%         %% plot model curve
%         plot_model = plot(x_plot,pred_y, 'Marker', '.','Color', '#5A5A5A','LineWidth',1,'DisplayName', 'Time Series Model');
%         hold on;
%         % break time
%         t_break = [rec_cg.t_break];
%         % change probability
%         change_prob = [rec_cg.change_prob];
%         % change vector magnitude
%         mag = [rec_cg.magnitude];
%         % reshape magnitude
%         mag = reshape(mag,metadata.nbands-1,[]);
%         % coefficients
%         coefs = [rec_cg.coefs];
%         coefs = reshape(coefs,8,metadata.nbands-1,[]);
% 
%         %% display break points
%         if rec_cg(i).change_prob > 0
%             bp = rec_cg(i).t_break;
%             if rec_cg(i).change_prob < 1
%                 % label potential change (no enough conse to confirm yet)
%                 % as red line
%                 plot_change_r = xline(bp,'r--','LineWidth',3.5,'DisplayNme','Potential Change');
%                 hold on
%                 % or, label potential changes as circles
% %               plot_change = plot(bp,clry(clrx==rec_cg(i).t_break,B_plot),'o','Markersize',10, 'DisplayName', 'Change');  
%             else
%                 [break_type,~,~] = labelDisturbanceType(coefs(:,:,i),t_break(i),t_min,mag(:,i),coefs(:,:,i+1),sensor);
%                 if break_type ==3   
%                    % label 'disturbance' break as a black dash line
%                    plot_change_k = xline(bp,'k--','Color','#663D00','LineWidth',2.5,'DisplayName', 'Disturbance');
%                    hold on
%                 else  
%                     % label 'aforestation/reforestation' as green dash line
%                     % label 'regrowth' break as a green dash line
%                    plot_change_g = xline(bp,'g--','Color','#108910', 'LineWidth',2.5,'DisplayName', 'Regrowth');
%                 end 
%             end
%         end
% 
%         if msg
%             ntime = datevec(rec_cg(i).t_break);
%             ndays = datenum(rec_cg(i).t_break)-datenum(ntime(1),0,0);
%             if B_plot == Band_Plot(1)
%                 fprintf('The %dth change occurred at %d %d\n',i,ntime(1),ndays);
%             end
%         end
%     end  % end of i=1:numfit

    % %% plot shadow of disturbance duration (optional)
    % y_lmt = [0,max(clry(:,B_plot)+20)];
    % x_lmt = [plot_change_k.Value+10, plot_change_g.Value-10];
    % v = [x_lmt(1) y_lmt(1); x_lmt(2) y_lmt(1); x_lmt(2) y_lmt(2); x_lmt(1) y_lmt(2)];
    % patch('Faces', [1 2 3 4], 'Vertices', v, 'FaceColor', 'k', 'FaceAlpha', .25+mod(i, 2)*0.1);
   
    %% add x y labels
    datetick('x', 10, 'keeplimits');   % 29
    xlim(daterange);
    str_ylabel = sprintf('%s', bandnames{B_plot}); 
    ylabel(str_ylabel,'Color','r','FontSize',22);
    if iplot ==1
        title(sprintf('Row/Column:%d/%d', pt_row, pt_col));
    end
    if iplot == length(plot_ids)
        xlabel('Date','FontSize',18);
    end
%     if iplot==1
%     if exist('plot_change','var') 
%             legend([plot_obs, plot_model, plot_change], {'Clear Observation', 'Time Series Model', 'Change'}, 'Location', 'northeastoutside');
%     else
%             legend([plot_obs, plot_model], {'Clear Observation', 'Time Series Model'}, 'Location', 'northeastoutside');
%     end
%     end
    box on;
    iplot = iplot+1;
end   % end of B_plot
% ax = gca;
% ax.FontSize = 18; 

%% save plots
plotname = strcat('T18TXL_',num2str(pt_row),'_',num2str(pt_col),'_HLS.png');
%     plotname = strcat(num2str(pt_row),'_',num2str(pt_col),'_',bandnames(B_plot),'.png');
saveas(gcf, fullfile(folderpath_cold,'TimeSeriesPlot',string(plotname)));
end


