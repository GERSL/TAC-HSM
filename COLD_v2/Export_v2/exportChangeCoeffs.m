function exportChangeCoeffs(folderpath_cold, years, varargin)
% This function is used to reorganize the model coefficents to the change
% format, change: pre-change model, during change, and post-change model
% The change coefficents will be used for distance agent classification.
%
% INPUT:
%
%   folderpath_cold:        Locate to COLD working folder, in which the
%                           change folder <TSFitLine> is necessery, and
%                           this folder was created by <COLD.m>.
%
%   outpath (optional):     Locate the output folder's path.
%
%   msg (optional):         [false/true] Display processing status (default
%                           value: false)
%
% 
% AUTHOR(s): Shi Qiu
% DATE: Oct. 8, 2021
% COPYRIGHT @ GERSLab


% test tile
folderpath_cold = '/shared/cn451/Kexin/COLDHLSResults/18TXL/';
years = 2014:2021;

% optional
p = inputParser;
addParameter(p,'msg', false); % not to display info
addParameter(p,'outpath', []); % same as the input if empty
parse(p,varargin{:});
msg = p.Results.msg;
outpath = p.Results.outpath;
all_yrs = years;

[~, foldername_working] = fileparts(folderpath_cold);
if msg
   fprintf('Start to export annual change coeffs for %s\r\n', foldername_working);
end

folderpath_tsf = fullfile(folderpath_cold, 'TSFitLine');
% folderpath_tsf = fullfile(folderpath_cold, 'TSFitLine_HLS');  % ks: adjust for HLS 18TYM
if isempty(outpath)
    outputFolder = fullfile(folderpath_cold, 'ChangeCoeffs');
else
    outputFolder = fullfile(outpath,         'ChangeCoeffs'); % add folder <ChangeCoeffs
end
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

tic

%% get metadata
load(fullfile(folderpath_cold, 'metadata.mat'));

nbands = metadata.nbands; % 6 HLS bands + 1 QA band  % 7 Landsat bands + 1 QA band  


% cd to the folder for storing recored structure
% cd(v_input.name_rst);
records = dir(fullfile(folderpath_tsf,'record_change*.mat')); % folder names
num_line = size(records,1);

Coeffs_AllYs = struct('POS',[], 'Year',[]);
filename_distcoeffs = 'rec_changecoeffs'; % filename of the records
% Coeffs_AllYs(100000).POS = [];

count_mag = 0;
part_identifier = 1;
for line = 1:num_line
    % show processing status
    if msg
        if line/num_line < 1
            fprintf('Processing %.2f percent\r',100*(line/num_line));
        else
            fprintf('Processing %.2f percent\n',100*(line/num_line));
        end
    end
    % load one line of time series models
    load(fullfile(folderpath_tsf,records(line).name)); %#ok<LOAD>

    % Limit range to load data
% % % %     line_num = str2num(imf(line).name(14:end-4));
% % % %     if line_num > 1000
% % % %         continue;
% % % %     end
%     if 100*(line/num_line)< 47
%         continue;
%     end
    
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
    for i_chg = 1:min(length(ids_change), l_pos - 1) % -1: segment of time series will not have change record!
        i = ids_change(i_chg); % to locate the orginal ID
        break_year = yr_break(i_chg);
        break_doy = doy_break(i_chg);
        
        % give them to mat
        count_mag = count_mag + 1;
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
            % fprintf('Wa%s \r',geotif_file);
            Coeffs_AllYs(count_mag).PostChaTstart = 0;
            Coeffs_AllYs(count_mag).PostChaTend = 0;
            Coeffs_AllYs(count_mag).PostChaCoeffs = zeros(size(Coeffs_AllYs(count_mag).PreChaTstart));
            Coeffs_AllYs(count_mag).PostChaRMSE = zeros(size(Coeffs_AllYs(count_mag).PreChaRMSE));
        end
    end
    % save part of them locally if too large
    if count_mag >= 100000 % 200, 000 objects (~ 1G )
        for i_yr = 1: length(all_yrs)
            yr = all_yrs(i_yr);
            ids_yr = find([Coeffs_AllYs.Year]==yr);
            if ~isempty(ids_yr)
                if length(all_yrs) == 1
                    rec_changecoeffs = Coeffs_AllYs;
                else
                    % for each year saving one record
                    rec_changecoeffs = Coeffs_AllYs(ids_yr);
                end
                filepath_mat = fullfile(outputFolder, sprintf('%s_%04d_part%03d.mat', filename_distcoeffs, yr, part_identifier)); % name format: record_changecoeffs_yyyy_part001.mat
                save([filepath_mat, '.part'], 'rec_changecoeffs', '-v7.3');
                movefile([filepath_mat, '.part'], filepath_mat);
                clear rec_changecoeffs ids_yr filepath_mat;
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
        Coeffs_AllYs = struct('POS',[], 'Year',[]);
        count_mag = 0;
        part_identifier = part_identifier + 1;
    end
end

% save part of them locally if too large
if count_mag > 0 % if have more, still save them locally
    for i_yr = 1: length(all_yrs)
        yr = all_yrs(i_yr);
        ids_yr = find([Coeffs_AllYs.Year]==yr);
        if ~isempty(ids_yr)
            if length(all_yrs) == 1
                rec_changecoeffs = Coeffs_AllYs;
            else
                % for each year saving one record
                rec_changecoeffs = Coeffs_AllYs(ids_yr);
            end
            
            filepath_mat = fullfile(outputFolder, sprintf('%s_%04d_part%03d.mat', filename_distcoeffs, yr, part_identifier)); % name format: record_changecoeffs_yyyy_part001.mat
            save([filepath_mat, '.part'], 'rec_changecoeffs', '-v7.3');
            movefile([filepath_mat, '.part'], filepath_mat);

            clear rec_changecoeffs ids_yr filepath_mat;
        end  
    end
    % Empty memeroy
    clear Coeffs_AllYs count_mag part_identifier;
end

end
