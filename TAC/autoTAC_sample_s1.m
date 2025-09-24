function TAC_record_change = autoTAC_sample_s1(sensor,plot_data, varargin)
%%---------------------------------------------------------------------------------------
% AUTO_TAC performs change detection and calculates lag-1 temporal autocorrelation using PlanetScope time series.
%
% Syntax: autoTAC(folderpath_stack, folderpath_TACResults, folderpath_mask, ...)
%
% Inputs:
%   folderpath_stack - Path to the directory containing stacked time series data.
%   folderpath_TACResults - Path to the directory where the results will be saved.
%   folderpath_mask - Path to the mask image for the region of interest (ROI).
%
% Arguments:
%   'task' - Task number for parallel processing (default: 1).
%   'ntasks' - Total number of tasks for parallel processing (default: 1).
%   'msg' - Display progress messages (default: true).
%
% Description:
% The autoTAC function automates the process of detecting changes and calculating temporal autocorrelation (TAC) in PlanetScope time series data. The function performs the following steps:
%
% 1. Initializes paths and parameters.
% 2. Loads metadata and mask image for the ROI.
% 3. Identifies rows of data that have not been processed.
% 4. Processes each row in parallel, performing the following sub-steps:
%     a. Reads the stack data for the current row.
%     b. Runs the Continuous Change Detection (CCD) algorithm to detect changes.
%     c. Removes linear trends and seasonality from the data.
%     d. Calculates different vegetation indices (NDVI, kNDVI, EVI).
%     e. Resamples the data to different composite intervals (weekly, biweekly, monthly). 
%     f. Calculates TAC for different rolling windows and vegetation indices.
% 5. Saves the results for each processed row.
%
% Example:
% autoTAC('/path/to/stack', '/path/to/results', '/path/to/mask', 'task', 1, 'ntasks', 4, 'msg', false);
%
% Author: Kexin Song (kexin.song@uconn.edu)
% Date: 2024/07/01
% Version: 1.1
%
% 20240701 ks: fix the preprocess step of linear trend and seasonality
% removal, based on each CCD segment.
%%---------------------------------------------------------------------------------------

    % close all;

    addpath('/home/kes20012/COLD_v2/CCD');
    addpath('/home/kes20012/COLD_v2/Export');
    
    p = inputParser;
    addParameter(p,'task', 1); % 1st task
    addParameter(p,'ntasks', 1); % single task to compute
    addParameter(p,'msg', true); % not to display info
    addParameter(p,'rm_outliers', true);
    addParameter(p,'composite_interval', 'monthly'); % 1st task
    % addParameter(p,'rolling_window', 48); % single task to compute
    addParameter(p,'VI', 'NDVI'); % default is NDVI
    addParameter(p,'plot_id',[]);
    addParameter(p,'plot_lat',[]);
    addParameter(p,'plot_lon',[]);
    addParameter(p,'plot_name',[]);
    addParameter(p,'savefig',false);
    addParameter(p,'doplot',false);
    addParameter(p,'plot_VI','NIRv');
    addParameter(p,'missing_data_pct',0); % default is all available data
    
    % request user's input
    parse(p,varargin{:});
    task = p.Results.task;
    ntasks = p.Results.ntasks;
    msg = p.Results.msg;
    rm_outliers = p.Results.rm_outliers;
    Composite_Intervals = p.Results.composite_interval;
    Vegetation_Indices = p.Results.VI;
    pt_id = p.Results.plot_id;
    pt_lat = p.Results.plot_lat;
    pt_lon = p.Results.plot_lon;
    pt_name = p.Results.plot_name;
    savefig = p.Results.savefig;
    do_plot = p.Results.doplot;
    plot_VI = p.Results.plot_VI;
    missing_data_pct = p.Results.missing_data_pct;
    
    % do_plot  = false;
    % do_plot = true;
    
    %% Define COLD Constants
    B_detect = 2:6;   % G,R,NIR,SWIR1, and SWIR2
    conse = 6;   % ks: change conse to 10.
    max_c = 8; % number of maximum coefficients
    T_cg = 0.99;
    Tmax_cg = 1-1e-5;
    
    %% report log of TAC only for the first first task
    % if task == 1 && i_task == 1
    %     reportLog(folderpath_cold, ntasks, folderpath_cold, metadata.nimages, landsatpath, T_cg, conse, max_c);
    % end
    % if msg
    %     fprintf('\ncomposite interval is #%s... \n', Composite_Intervals);
    % end
    TAC_record_change = [];
    
    %% Step 1. Read the plot_data
    sdate = datenum(plot_data.date);
    plotid = unique(plot_data.plotid);
    data_layers = {'blue','green','red'...
        'nir','swir1','swir2'...
        'NDVI','kNDVI','NIRv'...
        'NBR','NDMI',...
        'EVI','EVI2'};
% 
      % data_layers = {plot_data.Properties.VariableNames{6:11},plot_data.Properties.VariableNames{16:end}};
   
    %% Step 2. Preprocess of the plot_data
    % scale up the surface reflectance values by 10,000 
    scale = 10000;
    line_t = [plot_data.blue*scale,...
        plot_data.green*scale,...
        plot_data.red*scale,...
        plot_data.nir*scale,...
        plot_data.swir1*scale,...
        plot_data.swir2*scale,...
        plot_data.fmask];

    if ~any(line_t(:,:),'all')  
        % if all elements are zero, return
        fprintf('No observations for the entire plot #%d.\n',plotid);
        TAC_record_change = [];
        return;
    else   
        % if contains non-zero elements, run TAC             
        %% Step 3.1.1: Calculate NDVI and kNDVI and save as line_t_vi
        % red = plot_data.red;
        % nir = plot_data.nir;
        % NDVI = (nir - red)./(nir + red);
        % kNDVI = tanh((NDVI).^2);
        tmp = line_t(:,1:6);
        for iv = 1:length(Vegetation_Indices)
            vi = Vegetation_Indices{iv};
            tmp = [tmp,plot_data.(vi)*scale];
            % plot_data.NDVI*scale,plot_data.kNDVI*scale,plot_data.NIRv*scale,plot_data.NBR*scale,plot_data.NDMI*scale,line_t(:,end)];
        end
        line_t_vi = [tmp,line_t(:,end)];

        %% Step 3.1.2: Remove outliers based on kNDVI with the robust loess (ks 20241104)
        if rm_outliers
            % kNDVI_smoothed = smooth(sdate,kNDVI,0.1,'rloess');
            try
                kNDVI_smoothed = smooth(sdate,plot_data.kNDVI,0.1,'rloess');
            catch
                fprintf('Error!\n')
                return;
            end
            if do_plot
                figure('Name','Loess Smoothed kNDVI');
                set(gcf,"Position",[100,100,800,300]);
                p1 = plot(sdate,plot_data.kNDVI,'b.','DisplayName','raw kNDVI');
                hold on;
                p2 = plot(sdate,kNDVI_smoothed,'r*','DisplayName','smoothed kNDVI');
                hold on;
            end
            residuals = plot_data.kNDVI - kNDVI_smoothed;
            mean_residual = mean(residuals);
            std_residual = std(residuals);
            coef = 1.96; % using confidence interval = 95%
            ci_lower = mean_residual - coef * std_residual;
            ci_upper = mean_residual + coef * std_residual;
            outliers = (residuals<ci_lower) | (residuals>ci_upper);
            sdate = sdate(~outliers) ;
            line_t_vi = line_t_vi(~outliers,:);
            line_t = line_t(~outliers,:);
            if do_plot
                p3 = plot(sdate,line_t_vi(:,8)./scale,'mo','DisplayName','outlier removed kNDVI');
                legend([p1,p2,p3]);
                ylabel('kNDVI');
                datetick('x', 10, 'keeplimits');
            end
        else

        end

        %% Step 3.1.3 Run CCD with 6 spectral bands, line_t
        % create an empty struct to hold TAC_record_change
        N = 1;
        nbands = size(line_t,2);
        [rec_cg, clrx, ~] = TrendSeasonalFit_COLDLineSampleHLS(sdate, line_t, [], [], ...
            1, 1, 1, T_cg, Tmax_cg, conse, max_c, nbands, B_detect);
    
        if isempty([rec_cg.t_start])
            fprintf('Rec_cg is empty for the entire plot #%d.\n',plotid);
            return;
        else
            % add rec_cg to TAC_record_change
            TAC_record_change(N).rec_cg = rec_cg;
            TAC_record_change(N).plotid = plotid;
    
            %% Step 3.1.4: Run CCD with line_t_vi to fit harmonic model for VIs (ks 20240909)
            [rec_cg_vi, clrx_vi, clry_vi] = TrendSeasonalFit_COLDLineSampleHLS(sdate, line_t_vi, [], [], ...
                1, 1, 1, T_cg, Tmax_cg, conse, max_c, nbands+length(Vegetation_Indices), B_detect);
            % add rec_cg_vi to TAC_record_change
            TAC_record_change(N).rec_cg_vi = rec_cg_vi;

            %% Step 3.2: Remove the linear trend and seasonality of VIs based on each CCD segment, output: output_y
            num_fit = size(rec_cg, 2);
            if num_fit==1
                % if no breaks, de-trend and de-seasonality using the only harmonic model
                [output_y,linear_trend, seasonalities] = deTrendSeasonality(clrx_vi,clry_vi,rec_cg_vi(1).coefs);
            else
                % if breaks detected, de-trend and de-seasonality for each segment 
                start_ind = 1;
                output_y = zeros(length(clrx_vi),nbands-1+length(Vegetation_Indices));
                for i = 1:num_fit
                    break_ind = interp1(clrx_vi,1:length(clrx_vi),rec_cg(i).t_break,'nearest');
                    if isnan(break_ind)
                        break_ind = length(clrx_vi);
                    end
                    try
                        [output_y(start_ind:break_ind,:),linear_trend(start_ind:break_ind,:),seasonalities(start_ind:break_ind,:)] = deTrendSeasonality(clrx_vi(start_ind:break_ind),clry_vi(start_ind:break_ind,:),rec_cg_vi(i).coefs);
                    catch
                        fprintf('error \n')
                    end
                    start_ind = break_ind+1;
                end
            end
            % calculate the temporal variability of the residuals
            res_var = var(output_y./scale);
                        
            %% Step 4. Resample data using different composite intervals, output: TT3
            Dates = datetime(clrx_vi,'ConvertFrom', 'datenum');
            T = table(Dates,output_y);
            TT = table2timetable(T,'RowTimes','Dates');
            bandnames = { 'Blue', 'Green',  'Red',  'NIR', 'SWIR1','SWIR2'};%,'NDVI','kNDVI','NIRv','NBR','NDMI'}; 
            TT1 = splitvars(TT,'output_y','NewVariableNames',[bandnames,Vegetation_Indices]);
            TT2 = TT1;
            % convert to weekly time table (select the last day obs, note we don't need this for Landsat)
            % TT2 = convert2weekly(TT1);
        
        for iC = 1:length(Composite_Intervals)
            composite_interval = Composite_Intervals{iC};
            % resample or aggregate data in the time table and fill in data gaps using linear interpolation
            switch composite_interval
                case 'weekly'
                    TT3 = retime(TT2,'weekly','linear');
                    TT4 = retime(TT2,'weekly', 'count');
                case 'biweekly'
                    TT3 = retime(TT2,'regular', 'linear', 'TimeStep', days(14));
                    TT4 = retime(TT2,'regular', 'count','TimeStep', days(14));
                    % if height(TT4)==height(TT3)
                    %     TT3 = addvars(TT3,TT4.('kNDVI'),'NewVariableNames',{'data_count'});
                    % else
                    %     TT3 = addvars(TT3,[TT4.('kNDVI');1],'NewVariableNames',{'data_count'});
                    % end
                case 'monthly'
                    TT3 = retime(TT2,'monthly','linear');
                    TT4 = retime(TT2,'monthly','count');
                case '48days'
                    TT3 = retime(TT2,'regular', 'linear', 'TimeStep', days(48));
                    TT4 = retime(TT2,'regular', 'count','TimeStep', days(48));
                case 'bimonthly'
                    TT3 = retime(TT2,'regular', 'linear', 'TimeStep', days(60));
                    TT4 = retime(TT2,'regular', 'count', 'TimeStep', days(60));
                case '70days'
                    TT3 = retime(TT2,'regular', 'linear', 'TimeStep', days(70));
                    TT4 = retime(TT2,'regular', 'count','TimeStep', days(70));
                case 'quarterly'
                    TT3 = retime(TT2,'quarterly','linear');
                    TT4 = retime(TT2,'quarterly','count');

            end
            if height(TT4)==height(TT3)
                TT3 = addvars(TT3,TT4.('kNDVI'),'NewVariableNames',{'data_count'});
            else
                TT3 = addvars(TT3,[TT4.('kNDVI');1],'NewVariableNames',{'data_count'});
            end
            
            if do_plot  % plot time series of vegetation index
                % VI = Vegetation_Indices{end};
                VI = plot_VI;
                fig = figure();
                set(gcf,'Position',[0 0 1200 500]);
                tiledlayout("vertical")
                
                %% Subplot 1
                nexttile
                % plot 1.1: The original VI
                idx = find(strcmp(data_layers,plot_VI));
                h1 = plot(clrx_vi,clry_vi(:,idx)./scale,'k.','DisplayName',strcat(VI,' original'));
                hold on
                % plot 1.2: The harmonic model curve of VI and detected breaks
                t_min = -200;
                num_fit = size(rec_cg, 2);
                t_break = [rec_cg.t_break];
                coefs = [rec_cg.coefs];
                coefs = reshape(coefs,8, nbands-1,[]);
                mag = [rec_cg.magnitude];
                mag = reshape(mag,nbands-1,[]);

                for i = 1: num_fit
                    x_plot=rec_cg(i).t_start:rec_cg(i).t_end;
                    pred_y = autoTSPred(x_plot',rec_cg_vi(i).coefs(:,idx)); 
                    % harmonic model
                    h2 = plot(x_plot,pred_y./scale, 'Marker', '.','Color', 'c','LineWidth',1,'DisplayName', 'Harmonic Model');
                    hold on;
                    if rec_cg(i).change_prob == 1
                        xShade = [rec_cg(i).t_end rec_cg(i+1).t_start rec_cg(i+1).t_start rec_cg(i).t_end];
                        yShade = [0 0 0.7 0.7];
                        % highlight the during-change period
                        fill(xShade, yShade, 'black', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
                    end
                end   % end of i = 1:num_fit

                % add lat/lon to the figure 
                if pt_lat>0
                    if pt_lon>0
                        title(sprintf('PointId=%03d (%.3f°N, %.3f°E), max missing data pct=%.1f',pt_id,pt_lat,pt_lon,missing_data_pct));
                    else
                        title(sprintf('PointId=%03d (%.3f°N, %.3f°W), max missing data pct=%.1f',pt_id,pt_lat,abs(pt_lon),missing_data_pct));
                    end
                else
                    if pt_lon>0
                        title(sprintf('PointId=%03d (%.3f°S, %.3f°E), max missing data pct=%.1f',pt_id,abs(pt_lat),pt_lon,missing_data_pct));
                    else
                        title(sprintf('PointId=%03d (%.3f°S, %.3f°W), max missing data pct=%.1f',pt_id,abs(pt_lat),abs(pt_lon),missing_data_pct));
                    end
                end      
                legend([h1,h2],'Location','southeastoutside');
                xlim([datenum('2000-01-01'),datenum('2024-12-31')]);
                datetick('x', 10, 'keeplimits');
                % str_ylabel = strcat(VI, '*10000');
                str_ylabel = VI;
                ylabel(str_ylabel,'Color','k','FontSize',18);
                set(gca,'FontSize',14);
                fontname(fig,"Times");

                %% Subplot 2
                nexttile
                % plot 2.1: The VI residuals
                plot(clrx_vi,output_y(:,idx)./scale,'r.','DisplayName',strcat(VI,' residuals'));
                hold on;
                % plot 2.2: The gap-filled VI residuals
                plot(datenum(TT3.Dates),TT3.(plot_VI)./scale,'o','Color', '#5A5A5A','LineWidth',0.5,'DisplayName',sprintf('%s %s', composite_interval, 'residuals'));%,'Color','k');
                % plot(datenum(TT4.Dates),TT4.kNDVI./scale,'o','Color', '#5A5A5A','LineWidth',0.5,'DisplayName',sprintf('%s %s', composite_interval, 'residuals'));%,'Color','k');
                ylim([-0.4 0.4]);
                legend('Location','southeastoutside');
                xlim([datenum('2000-01-01'),datenum('2024-12-31')]);
                datetick('x', 10, 'keeplimits');
                str_ylabel = strcat(VI,' residual');
                ylabel(str_ylabel,'Color','k','FontSize',18);

                set(gca,'FontSize',14);
                fontname(fig,"Times");
                
            end   % end of do_plot
                            
             
            %% TODO: adjust TT3 based on missing_data_pct
            % Calculate n based on missing_data_pct
            n = round(missing_data_pct * height(TT3));
            % Set seed for reproducibility
            rng(123);   % fixed seed   
            % Filter rows where data_count == 0 and >0
            TT3_missing = find(TT3.data_count == 0);
            TT3_valid_idx = find(TT3.data_count > 0);
            % Total number of already missing rows
            numMissing = length(TT3_missing);
            % Check the raw missing rate of the time series
            original_missing_rate = numMissing./height(TT3);
            % If contains less than 90% missing data
            if original_missing_rate<0.9
                % Total number of valid rows
                numValid = length(TT3_valid_idx);
                if numMissing>=n
                    % already too many missing data
                    TT3_new = TT3;
                else
                    m = n-numMissing;
                    % Generate random row indices without replacement
                    randIdx = randperm(numValid, m);
                    % Select rows
                    TT3_new = TT3;
                    TT3_new.data_count(TT3_valid_idx(randIdx)) = zeros(m,1);
                end
            else
                fprintf('Skip plot #%d due to less than 10%% valid data!\n',pt_id);
                return;
            end

            %%  Loop to calculate TAC of VIs
            for iV = 1:length(Vegetation_Indices)
                VI = Vegetation_Indices{iV};
                % fprintf('Vegetation index is %s.\n',VI);
                switch composite_interval
                    case 'weekly'
                        rolling_window = [52,52*2,52*3,52*4,52*5,52*6, 52*7];   % how many weeks in one year, two years,... and 7 years
                        factor = 52;
                    case 'biweekly' 
                        rolling_window = [26,52,78,104,130,156,182];
                        factor = 26;
                    case 'monthly'
                        rolling_window = [12,24,36,48,60,72,84]; % rolling window 1 year - 7 years
                        factor = 12;
                    case '48days'
                        rolling_window = [8,8*2,8*3,8*4,8*5,8*6,8*7]; % rolling window 1 year - 7 years
                        factor = 8;
                    case '50days'
                        rolling_window = [7,7*2,7*3,7*4,7*5,7*6,7*7];
                        factor = 7;
                    case 'bimonthly'
                        rolling_window = [6,12,18,24,30,36,42]; % rolling window 1 year - 7 years
                        factor = 6;
                    case '70days'
                        rolling_window = [5,5*2,5*3,5*4,5*5,5*6,5*7];
                        factor = 5;
                    case 'quarterly'
                        rolling_window = [4,4*2,4*3,4*4,4*5,4*6,4*7];
                        factor = 4;
                end

                if do_plot && strcmp(VI,plot_VI)
                    nexttile;
                end
                
                %% Loop for rolling windows
                for iw = 1:length(rolling_window)
                    var_name = strcat('TAC_',VI,'_',num2str(rolling_window(iw)));

                    switch VI
                        case 'NDVI'
                            tmp = calEmprAC(TT3_new.NDVI, TT3_new.data_count, rolling_window(iw));
                        case 'kNDVI'
                            tmp = calEmprAC(TT3_new.kNDVI, TT3_new.data_count, rolling_window(iw)); 
                        case 'NIRv'
                            tmp = calEmprAC(TT3_new.NIRv, TT3_new.data_count, rolling_window(iw)); 
                        case 'NBR'
                            tmp = calEmprAC(TT3_new.NBR, TT3_new.data_count, rolling_window(iw)); 
                        case 'NDMI'
                            tmp = calEmprAC(TT3_new.NDMI, TT3_new.data_count, rolling_window(iw)); 
                        case 'EVI'
                            tmp = calEmprAC(TT3_new.EVI, TT3_new.data_count, rolling_window(iw)); 
                        case 'EVI2'
                            tmp = calEmprAC(TT3_new.EVI2, TT3_new.data_count, rolling_window(iw)); 

                    end
                    TT3_new.(var_name) = tmp;
                 
                    if do_plot && iw>=1
                        if startsWith(var_name,['TAC_',plot_VI,'_'])
                            
                            plot(TT3_new.Dates,TT3_new.(var_name),'LineWidth',1.5,'DisplayName',[num2str(rolling_window(iw)/factor),' year']);
                            hold on
                     
                            if iw==length(rolling_window)
                                % if iV==length(Vegetation_Indices)
                                legend('Location','southeastoutside');
                                % end
                                xlim([datetime('2000-01-01'),datetime('2024-12-31')])
                                datetick('x', 10, 'keeplimits');
                                ylim([-1 1]);
                                yticks(-1:0.5:1);
                                str_ylabel = ['TAC ',plot_VI];
                                ylabel(str_ylabel,'Color','k','FontSize',18);
                                yline(0,'--','DisplayName','TAC=0');
       
                                set(gca,'FontSize',14);
                                fontname(fig,'Times');  
                            end
                        end
                    end   % end of do_plot
                end   % end of iw = 1:length(rolling_window)
            end    % end of iV = 1:length(Vegetation_Indicies)
          
            if savefig
                folderpath_TACplot = fullfile('/gpfs/sharedfs1/zhulab/SCRATCH/kes20012/ProjectTACValidation/Figure',[sensor,composite_interval]);
                % folderpath_TACplot = fullfile('C:\Users\kes20012\OneDrive - University of Connecticut\Documents\TACResilienceValidation\Figures\',[sensor,'_harmonized']);
                if ~exist(folderpath_TACplot)
                    mkdir(folderpath_TACplot);
                end
                plotname = sprintf('TAC_%s_%s_pointId_%03d.png',composite_interval,plot_VI,plotid);
                exportgraphics(gcf, fullfile(folderpath_TACplot,string(plotname)),'Resolution',1000);
            end

            %% Save to TAC_record_change (output)
            switch composite_interval
                case 'weekly'
                    TAC_record_change(N).TAC_weekly = TT3_new;
                case 'biweekly'
                    TAC_record_change(N).TAC_biweekly = TT3_new;
                case 'monthly'
                    TAC_record_change(N).TAC_monthly = TT3_new;
                case '48days'
                    TAC_record_change(N).TAC_48days = TT3_new;
                case '50days'
                    TAC_record_change(N).TAC_50days = TT3_new;
                case 'bimonthly'
                    TAC_record_change(N).TAC_bimonthly = TT3_new;
                case '70days'
                    TAC_record_change(N).TAC_70days = TT3_new;
                case 'quarterly'
                    TAC_record_change(N).TAC_quarterly = TT3_new;
            end
        end    % end of iC = 1:length(Composite_Intervals)
        TAC_record_change(N).res_var = res_var;
        clear T
        clear TT
        clear TT1
        clear TT2
        clear TT3_new
        end  % end of isempty(rec_cg)
    end   % end of ~any(line_t_j,'all')

            
   % %% Save results
   %  folderpath_TACResults = fullfile('/gpfs/sharedfs1/zhulab/SCRATCH/kes20012/ProjectTACValidation/',['TACResults_',datestr(now, 'yyyy-mm-dd')],[sensor,'_',composite_interval]);
   %  if ~exist(folderpath_TACResults)
   %      mkdir(folderpath_TACResults);
   %  end
   %  filepath_rcg = fullfile(folderpath_TACResults, sprintf('TAC_record_change_plot%03d.mat', plotid)); % r: row
   %  save([filepath_rcg, '.part'] ,'TAC_record_change'); % save as .part
   %  clear rec_cg;
   %  movefile([filepath_rcg, '.part'], filepath_rcg);  % and then rename it as normal format
                
end   % end of function

