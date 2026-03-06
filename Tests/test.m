function test(varargin)
%TEST Run TAC on an example Landsat time series.
%
% This function:
% 1. Loads an example Landsat time series
% 2. Filters clear and physically valid observations
% 3. Converts year + doy to datetime
% 4. Removes Landsat 7 observations after Landsat 9 became available
% 5. Computes vegetation indices
% 6. Optionally harmonizes L5/L7 to L8/L9 using TIF coefficients
% 7. Runs TAC and saves the output
%
% Optional inputs:
%   'do_harmo'           true/false, apply sensor harmonization
%   'composite_interval' temporal compositing interval, e.g.
%   'monthly','bimonthly','quarterly'
%
% Author: Kexin Song (kexin.song@uconn.edu) 2026/03/06

    warning('off','all')
    addpath(fullfile(pwd, 'TAC'));

    %% Settings
    directory = pwd;
    sensor = 'Landsat';
    scale = 10000;
    l9_acq_date = datetime('2021-10-31');   % Landsat 9 acquisition date

    % Bands and VIs to harmonize
    band_names = {'blue','green','red', ...
                  'nir','swir1','swir2', ...
                  'NDVI','kNDVI','NIRv', ...
                  'NBR','NDMI','EVI','EVI2'};

    %% Parse inputs
    p = inputParser;
    addParameter(p, 'do_harmo', true);
    addParameter(p, 'composite_interval', 'bimonthly');
    parse(p, varargin{:});

    do_harmo = p.Results.do_harmo;
    composite_interval = p.Results.composite_interval;

    %% Create output folder
    folderpath_TACResults = fullfile(directory, 'output', composite_interval);
    if ~exist(folderpath_TACResults, 'dir')
        mkdir(folderpath_TACResults);
    end

    %% Load harmonization coefficients
    TIFname = fullfile('..', 'L57_L89_Harmonization', ...
        'TIFResults', 'TIFbrdf_coefficient_r00001c00001.mat');
    load(TIFname, 'TIF_coefficient');

    %% Load example time series
    filename = fullfile(directory, 'TS_example.csv');
    plot_data = readtable(filename);

    % Extract plot metadata
    lat = unique(plot_data.sampleLat);
    lon = unique(plot_data.sampleLon);
    plot_id = unique(plot_data.plotid);

    %% Filter observations
    % Convert QA_PIXEL to simplified Fmask classes
    plot_data.fmask = convertQA2Fmask(plot_data.qa_pixel);

    % Keep only observations with reflectance values in physical range
    good_id = plot_data.blue  > 0 & plot_data.blue  < 1 & ...
              plot_data.green > 0 & plot_data.green < 1 & ...
              plot_data.red   > 0 & plot_data.red   < 1 & ...
              plot_data.nir   > 0 & plot_data.nir   < 1 & ...
              plot_data.swir1 > 0 & plot_data.swir1 < 1 & ...
              plot_data.swir2 > 0 & plot_data.swir2 < 1;

    % Keep clear land/water observations only
    valid_id = good_id & plot_data.fmask <= 1;
    plot_data = plot_data(valid_id, :);

    %% Convert year + doy to datetime
    plot_data.date = datetime(plot_data.year, 1, 1) + days(plot_data.doy - 1);

    %% Remove Landsat 7 observations after Landsat 9 acquisition
    remove_id = strcmp(plot_data.sensor, 'LE07') & plot_data.date > l9_acq_date;
    plot_data(remove_id, :) = [];

    %% Compute vegetation indices
    plot_data.NDVI  = (plot_data.nir - plot_data.red) ./ (plot_data.nir + plot_data.red);
    plot_data.kNDVI = tanh(plot_data.NDVI .^ 2);
    plot_data.NIRv  = (plot_data.NDVI - 0.08) .* plot_data.nir;
    plot_data.NBR   = (plot_data.nir - plot_data.swir2) ./ (plot_data.nir + plot_data.swir2);
    plot_data.NDMI  = (plot_data.nir - plot_data.swir1) ./ (plot_data.nir + plot_data.swir1);
    plot_data.EVI   = 2.5 * (plot_data.nir - plot_data.red) ./ ...
                      (plot_data.nir + 6 * plot_data.red - 7.5 * plot_data.blue + 1);
    plot_data.EVI2  = 2.5 * (plot_data.nir - plot_data.red) ./ ...
                      (plot_data.nir + plot_data.red + 1);

    %% Harmonize L5/L7 to L8/L9 if requested
    if do_harmo
        sensor_name = string(plot_data.sensor);
        L57_id = sensor_name == "LE07" | sensor_name == "LT05";

        for iband = 1:numel(band_names)
            band_name = band_names{iband};

            a = TIF_coefficient.Slopes(iband);
            b = TIF_coefficient.Intercepts(iband);

            plot_data.(band_name)(L57_id) = ...
                plot_data.(band_name)(L57_id) * a + (b / scale);
        end
    end

    %% Run TAC
    TAC_record_change = autoTAC_sample(sensor, plot_data, ...
        'composite_interval', {composite_interval}, ...
        'VI', {'NDVI','kNDVI','NIRv','NBR','NDMI','EVI','EVI2'}, ...
        'rm_outliers', 1, ...
        'plot_id', plot_id, ...
        'plot_lat', lat, ...
        'plot_lon', lon, ...
        'plot_name', '', ...
        'savefig', true, ...
        'doplot', true, ...
        'plot_VI', 'NIRv');

    %% Save result safely
    filepath_rcg = fullfile(folderpath_TACResults, ...
        sprintf('TAC_record_change_plot%05d.mat', plot_id));

    save([filepath_rcg, '.part'], 'TAC_record_change');
    movefile([filepath_rcg, '.part'], filepath_rcg);

    fprintf('complete!\n');

end


function cfmask = convertQA2Fmask(qa)
%CONVERTQA2FMASK Convert Landsat QA_PIXEL bit flags to simplified Fmask classes.
%
% Output classes:
%   255 = Filled
%   0   = Clear land/water
%   1   = Water
%   2   = Cloud shadow
%   3   = Snow
%   4   = Cloud / dilated cloud

    cfmask = qa;

    cfmask(bitget(qa,1) == 1) = 255; % Filled
    cfmask(bitget(qa,7) == 1) = 0;   % Clear
    cfmask(bitget(qa,8) == 1) = 1;   % Water
    cfmask(bitget(qa,5) == 1) = 2;   % Cloud shadow
    cfmask(bitget(qa,6) == 1) = 3;   % Snow
    cfmask(bitget(qa,2) == 1) = 4;   % Dilated cloud
    cfmask(bitget(qa,4) == 1) = 4;   % Cloud

end
