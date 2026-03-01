% TBD
% used for agent work

function exportChangeCoeffs(folderHV, n_str, yearout, outputFolder, savemat, isupdate)
% This function is used to provde disturbance maps for each year
% Version 1.00 No disturbance class in the cover map (03/29/2018)
% vr = varead('COLD_log.txt','Version');

n_str = (fullfile(folderHV, n_str));
        
geotif_file = fullfile(folderHV,'h*extent.tif');
geotif_file = dir(geotif_file);
geotif_file = fullfile(folderHV, geotif_file.name);

% provide values from info
nrows = 5000;
ncols = 5000;
nbands = 8; % 7 Landsat bands + 1 QA band

% INPUTS:
all_yrs = yearout;% all of years for producing maps

% dimension and projection of the image
jiDim = [ncols,nrows];
% max number of maps
max_n = length(all_yrs);
% slope threshold
t_min = -200; % 0.02 change in surf ref 

% saveout .mat or not
if ~exist('savemat', 'var')
    savemat = 1; % Default is to save .mat with coeffs
end
if ~exist('isupdate', 'var')
    isupdate = 0;
end

% produce disturbance map
LandDistMap = 9999*ones(nrows,ncols,max_n,'uint16'); % e.g., 1365:  1 is type; 365 is DOY; 

% make Predict folder for storing predict images
% n_map = 'YearlyCOLDDisturbanceDataV3';
% n_map = 'YearlyCOLDDisturbanceDataV4'; % label aforestation/ regrowth
% n_map = 'YearlyCOLDDisturbanceDataV5'; % moving window for adjusted therholds
% n_map = 'YearlyCOLDDisturbanceDataV14'; % COLD version 14; jump 4 observations; 8 coeffs
% n_map = 'YearlyCOLDDisturbanceDataTest'; % COLD version 13.4 but erod 333 pixels for images
% n_map = 'YearlyCOLDDisturbanceDataTest1'; % COLD version 13.4 but same extent of all images
% n_map = 'YearlyCOLDDisturbanceData'; % COLD version 14.00
% n_map = 'YearlyCOLDDisturbanceData8C'; % COLD version 14.00
% n_map = 'YearlyCOLDDisturbanceData4C_AdjNtimes'; % COLD version 14.00
% n_map = 'YearlyCOLDDisturbanceData4C_1halfYearsInit'; % COLD version 14.00

if ~isfolder(outputFolder)
    mkdir(outputFolder);
end
filename_distmap = globalsets.FilenameDistMap;
filename_distcoeffs = globalsets.FilenameDistCoeffs;
% check existing files
if ~isupdate % do to not update the old files
    totalFiles = 0;
    for i_yr = 1: length(all_yrs)
        yr = all_yrs(i_yr);
        if isfile(fullfile(outputFolder, [filename_distmap, '_',num2str(yr),'.tif']))
            totalFiles = totalFiles + 1;
        end
        if savemat&& ...
                ~isempty(dir(fullfile(outputFolder, [filename_distcoeffs, '_',num2str(yr),'*.mat'])))
            totalFiles = totalFiles + 1;
        end
    end
    if totalFiles==length(all_yrs) + savemat*length(all_yrs)
        fprintf('Exist %s\r', outputFolder);
        return;
    end
else
    % year to year for deleting
    for i_yr = 1: length(all_yrs)
        yr = all_yrs(i_yr);
        % delete the all coeffs mat files
        matfiles = dir(fullfile(outputFolder, [filename_distcoeffs, '_',num2str(yr),'*.mat']));
        for imat = 1: length(matfiles)
            delete(fullfile(outputFolder, matfiles(imat).name));
        end
        clear matfiles.
    end
end

% cd to the folder for storing recored structure
% cd(v_input.name_rst);
% n_str = 'TSFitMap8C';
% n_str = 'TSFitMap4C_AdjNtimes';
% n_str = 'TSFitMapTest';
imf = dir(fullfile(n_str,'record_change*.mat')); % folder names
fprintf('At %s\n', n_str);
num_line = size(imf,1);
if savemat
    Coeffs_AllYs = struct('POS',[]);
    % Coeffs_AllYs(100000).POS = [];
end
count_mag = 0;
part_identifier = 1;
for line = 1:num_line
    % show processing status
    fprintf('Processing %.2f percent\r',100*(line/num_line));

    % Limit range to load data
    line_num = str2num(imf(line).name(14:end-4));
    if line_num > 1000
        continue;
    end
%     if 100*(line/num_line)< 47
%         continue;
%     end
    
    % load one line of time series models
    try
        load(fullfile(n_str,imf(line).name)); %#ok<LOAD>
    catch
        fprintf('Errors = %s\r', fullfile(n_str,imf(line).name));
    end
    % postions
    pos = [rec_cg.pos];
    
    % continue if there is no model available
    l_pos = length(pos);
    if l_pos == 0
        continue
    end
    
    %% Select change pixels
    % change probability
    change_prob = [rec_cg.change_prob];
    ids_change = find(change_prob >= 1); % change probality >= 1
    
    % break time
    t_break = [rec_cg(ids_change).t_break];
    [yr_break, ~, ~] = datevecmx(t_break);
    doy_break = t_break - datenummx(yr_break,1,0);
    % within predefined year range 
    is_yrs = ismember(yr_break, all_yrs);
    ids_change = ids_change(is_yrs);
    yr_break = yr_break(is_yrs);
    doy_break = doy_break(is_yrs);
    
    
    % other coeffs, and all of them will be restored.
    t_start = [rec_cg.t_start];
    t_end = [rec_cg.t_end];
    rmse = [rec_cg.rmse];
    rmse = reshape(rmse,nbands-1,[]);
    % change vector magnitude
    mag = [rec_cg.magnitude];
    % reshape magnitude
    mag = reshape(mag,nbands-1,[]);
    % durchange
    durchange = [rec_cg.durchange];
    durchange = reshape(durchange,2,nbands-1,[]);
    % coefficients
    coefs = [rec_cg.coefs];
    coefs = reshape(coefs,8,nbands-1,[]);
  
    %% Extract out
    for i_chg = 1:min(length(ids_change), l_pos - 1)
        i = ids_change(i_chg);
        break_year = yr_break(i_chg);
        break_doy = doy_break(i_chg);
        % get row and col
        [I,J] = ind2sub(jiDim,pos(i));
        
        % initialize pixels have at least one model
        if sum(LandDistMap(J,I,:) == 9999) == max_n
            % write doy to ChangeMap
            LandDistMap(J,I,:) = 0;
        end
%         break_type = dist_types(i);
        break_type = labelDisturbanceType(coefs(:,:,i),t_min,mag(:,i),coefs(:,:,i+1));
        % give them to map
        LandDistMap(J,I,all_yrs == break_year) = break_type.*1000 + break_doy; % e.g., 1365:  1 is type; 365 is DOY;
        % give them to mat
        count_mag = count_mag + 1;
        if savemat
            Coeffs_AllYs(count_mag).POS = pos(i);
            Coeffs_AllYs(count_mag).Year = break_year;
            Coeffs_AllYs(count_mag).DOY = break_doy;
            Coeffs_AllYs(count_mag).MagCoeffs = mag(:,i);
            Coeffs_AllYs(count_mag).DurCha = durchange(:,:,i);

            Coeffs_AllYs(count_mag).PreChaTstart = t_start(i);
            Coeffs_AllYs(count_mag).PreChaTend = t_end(i);
            Coeffs_AllYs(count_mag).PreChaCoeffs = coefs(:,:,i);
            Coeffs_AllYs(count_mag).PreChaRMSE = rmse(:,i);
            try
                % same posistion to get the post change model
                if pos(i) == pos(i+1)
                    Coeffs_AllYs(count_mag).PostChaTstart = t_start(i+1);
                    Coeffs_AllYs(count_mag).PostChaTend = t_end(i+1);
                    Coeffs_AllYs(count_mag).PostChaCoeffs = coefs(:,:,i+1);
                    Coeffs_AllYs(count_mag).PostChaRMSE = rmse(:,i+1);
                end
            catch
%                     fprintf('Wa%s \r',geotif_file);
                    Coeffs_AllYs(count_mag).PostChaTstart = 0;
                    Coeffs_AllYs(count_mag).PostChaTend = 0;
                    Coeffs_AllYs(count_mag).PostChaCoeffs = zeros(size(Coeffs_AllYs(count_mag).PreChaTstart));
                    Coeffs_AllYs(count_mag).PostChaRMSE = zeros(size(Coeffs_AllYs(count_mag).PreChaRMSE));
            end
        end
    end
    if savemat
        % save part of them locally if too large
        if count_mag >= 100000 % 200, 000 objects (~ 1G )
            for i_yr = 1: length(all_yrs)
                yr = all_yrs(i_yr);
                ids_yr = find([Coeffs_AllYs.Year]==yr);
                if ~isempty(ids_yr)
                    if length(all_yrs) == 1
                        DisturbanceCoeffs = Coeffs_AllYs;
                    else
                        % for each year saving one record
                        DisturbanceCoeffs = Coeffs_AllYs(ids_yr);
                    end
                    filepath_mat = fullfile(outputFolder, [filename_distcoeffs, '_',num2str(yr),'_part', num2str(part_identifier),'.mat']);
                    save([filepath_mat, '.part'], 'DisturbanceCoeffs', '-v7.3');
                    movefile([filepath_mat, '.part'], filepath_mat);
                    clear DisturbanceCoeffs ids_yr filepath_mat;
                end  
            end
        
% % %             for i_yr = 1: length(all_yrs)
% % %                 yr = all_yrs(i_yr);
% % %                 if length(all_yrs) == 1
% % %                     ids_yr = find([Coeffs_AllYs.Year]==yr);
% % %                     if ~isempty(ids_yr)
% % %                         DisturbanceCoeffs = Coeffs_AllYs;
% % %                         save(fullfile(outputFolder, [filename_distcoeffs, '_',num2str(yr),'_part', num2str(part_identifier),'.mat']),...
% % %                             'DisturbanceCoeffs', '-v7.3');
% % %                         clear DisturbanceCoeffs;
% % %                     end
% % %                 else
% % %                     % for each year saving one record
% % %                     ids_yr = find([Coeffs_AllYs.Year]==yr);
% % %                     if ~isempty(ids_yr)
% % %                         DisturbanceCoeffs = Coeffs_AllYs(ids_yr);
% % %                         save(fullfile(outputFolder, [filename_distcoeffs, '_',num2str(yr),'_part', num2str(part_identifier),'.mat']),...
% % %                             'DisturbanceCoeffs', '-v7.3');
% % %                         clear ids_yr DisturbanceCoeffs;
% % %                     end
% % %                 end
% % %             end
            % clear record
            Coeffs_AllYs = struct('POS',[]);
            count_mag = 0;
            part_identifier = part_identifier + 1;
        end
    end
end

if savemat
    % save part of them locally if too large
    if count_mag > 0 % if have more, still save them locally
        for i_yr = 1: length(all_yrs)
            yr = all_yrs(i_yr);
            ids_yr = find([Coeffs_AllYs.Year]==yr);
            if ~isempty(ids_yr)
                if length(all_yrs) == 1
                    DisturbanceCoeffs = Coeffs_AllYs;
                else
                    % for each year saving one record
                    DisturbanceCoeffs = Coeffs_AllYs(ids_yr);
                end
                filepath_mat = fullfile(outputFolder, [filename_distcoeffs, '_',num2str(yr),'_part', num2str(part_identifier),'.mat']);
                save([filepath_mat, '.part'], 'DisturbanceCoeffs', '-v7.3');
                movefile([filepath_mat, '.part'], filepath_mat);
                   
                clear DisturbanceCoeffs ids_yr filepath_mat;
            end  
        end
        % Empty memeroy
        clear Coeffs_AllYs count_mag part_identifier;
    end
end

% save disturbance image
geotif_obj = GRIDobj(geotif_file);
geotif_obj.name =  geotif_obj.name(1:end-7);
for i_yr = 1: length(all_yrs)
    yr = all_yrs(i_yr);
    geotif_obj.Z = LandDistMap(:,:,i_yr);
    GRIDobj2geotiff(geotif_obj, fullfile(outputFolder, [filename_distmap, '_',num2str(yr),'.tif']));
end
clear geotif_obj LandDistMap;

end

function dist_type=label_dist_type_only(curr_cft,t_c,vec,next_cft)
% This function is used to provde distubance year and disturbance type 
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
nir = vec(4);
c_nir = curr_cft(2,4);
n_nir = next_cft(2,4);

vis = vec(3);
c_vis = curr_cft(2,3);
n_vis = next_cft(2,3);

swir = vec(5);
c_swir = curr_cft(2,5);
n_swir = next_cft(2,5);

if nir > t_c && vis < -t_c && swir < -t_c
    if n_nir > abs(c_nir) && n_vis < -abs(c_vis) && n_swir < -abs(c_swir)
        dist_type = 2; % aforestation
    else
        dist_type = 1; % regrowth
    end
else
    dist_type = 3; % land disturbance
end
end