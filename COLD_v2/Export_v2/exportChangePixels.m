function exportChangePixels(folderpath_cold, geolocations, folderpath_out, varargin)
%EXPORTCHANGEPIXELS is to export change information for each pixel
%
% INPUT:
%
%   folderpath_cold:        Locate to COLD working folder, in which the
%                           change folder <TSFitLine> is necessery, and
%                           this folder was created by <COLD.m>.
%
%   geolocations:           [Array] [Lat, Lon]

% optional
p = inputParser;
addParameter(p,'years', []); % label the type of change
parse(p,varargin{:});
years = p.Results.years;

if ~isfolder(folderpath_out)
    mkdir(folderpath_out);
end

[~, foldername_working] = fileparts(folderpath_cold);

info = geotiffinfo(fullfile(folderpath_cold, 'singlepath_landsat.tif'));
folderpath_tsf = fullfile(folderpath_cold, 'TSFitLine');

% [x,y] = projfwd(proj,lat,lon)
[x,y] = projfwd(info,geolocations(:,1),geolocations(:,2)); % lat lon

% [row,col] = map2pix(R,x,y)
[row, col] = map2pix(info.RefMatrix, x, y);
row = ceil(row);
col = ceil(col);

ids_in = find(row <= info.Height & col <= info.Width & row >= 1 & col >= 1);
row_tile = row(ids_in);
col_tile = col(ids_in);
year_tile = years(ids_in);
geolocations = geolocations(ids_in, :);
clear ids_in;

[row_tile, idsort]= sort(row_tile);
col_tile = col_tile(idsort);
year_tile = year_tile(idsort);
geolocations = geolocations(idsort, :);
clear idsort;

% variable output

if ~isempty(row_tile) && ~isempty(col_tile)
    
    record_disturbance = [];
    row_pre = 0;
    for ir = 1: length(row_tile)
        if row_pre~= row_tile(ir)
            % load one line of time series models
            load(fullfile(folderpath_tsf, sprintf('record_change_r%05d.mat', row_tile(ir)))); %#ok<LOAD>
        end
        row_pre = row_tile(ir); % updated
        loc = sub2ind([info.Height, info.Width], col_tile(ir), row_tile(ir)); % col and row different to match COLD result
        
        rec_cg_pt = rec_cg([rec_cg.pos] == loc);
        
        record_disturbance(ir).Latitude = geolocations(ir, 1);
        record_disturbance(ir).Longitude = geolocations(ir, 2);
        record_disturbance(ir).Year = year_tile(ir);
        record_disturbance(ir).Change = rec_cg_pt;
        
        % continue if there is no model available
        l_pos = length(rec_cg_pt);
        if l_pos == 0
            continue
        end
    
%         % break time
%         nbands = 8; % 7 spectral bands + 1 QA Band
%         
%         t_min = -200; % 0.02 change in surf ref 
%         t_break = [rec_cg_pt.t_break];
%         % change probability
%         change_prob = [rec_cg_pt.change_prob];
%         % change vector magnitude
%         mag = [rec_cg_pt.magnitude];
%         % reshape magnitude
%         mag = reshape(mag,nbands-1,[]);
%         % coefficients
%         coefs = [rec_cg_pt.coefs];
%         coefs = reshape(coefs,8, nbands-1,[]);
%         changerecord = [];
%         for i = 1:l_pos - 1 % -1: segment of time series will not have change record!
%             if change_prob(i) == 1
%                 [break_type, break_year, break_doy] = labelDisturbanceType(coefs(:,:,i),t_break(i),t_min,mag(:,i),coefs(:,:,i+1));
%                 changerecord
%                 % record most recent changes, and the first change will have higher priority
%                 if abs(break_year - record_disturbance(ir).Year) < record_disturbance(ir).ChangeYear
%                     record_disturbance(ir).ChangeYear = break_year;
%                     record_disturbance(ir).ChangeDOY = break_doy;
%                     record_disturbance(ir).ChangeType = break_type;
%                     record_disturbance(ir).ChangeMagnitude = mag(:,i);
%                     break;
%                 end
%                 
%             end
%         end
    end
    if ~isempty(record_disturbance)
        save(fullfile(folderpath_out, [foldername_working, '_record_disturbance.mat']), 'record_disturbance');
    end
end
