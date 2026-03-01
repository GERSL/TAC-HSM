function batchStackHLSLine(varargin)
%% This is an example of stacking data for mutilple tiles
%
% EXAMPLE OF USE:
%
%   > See arrayStackARDxxxx.sh in the folder <JobsToStack>, which request a
%   total of 100 cores to process stacking at parallel
%
% 
% AUTHOR(s): Shi Qiu
% DATE: Feb. 8, 2021
% COPYRIGHT @ GERSLab

    folderpath_mfile = fileparts(mfilename('fullpath'));
    addpath(folderpath_mfile);
    addpath(fullfile(folderpath_mfile, 'Stack'));  
    
    p = inputParser;
    addParameter(p,'task', 1);          % 1st task
    addParameter(p,'ntasks', 1);        % single task to compute
    addParameter(p,'ARDTiles',[]);
    addParameter(p,'resolution',30);    % stack 30 m HLS or 60 m resampled HLS
    
    % request user's input
    parse(p,varargin{:});
    task = p.Results.task;
    ntasks = p.Results.ntasks;
    ARDTiles = p.Results.ARDTiles;
    ARDTiles = {ARDTiles};
    resolution = p.Results.resolution;
    

    %% Five site for testing new classification of land cover land use.
    % ARDTiles = {'18TXM'};
%     ARDTiles = {'18TYL'};
%     ARDTiles = {'18TYM'};
%     ARDTiles = {'10SFG','13TCF','14SPJ','15RXQ','18TXM'};  % '14SPJ','15RXQ'};
    % resolution = 60;
    
    %% Locate to the HLS dataset
    path_ard = globalsets.PathHLS;
    %% Locate to the working folder, in which all outputing data can be found
    path_working = globalsets.PathCOLDHLS;

    %% For each HLS tile
    for iARD = 1: length(ARDTiles)
        % switch to a certain Landsat ARD tile
       tile_name = ARDTiles{iARD};
        % display
        fprintf('Start to stack ARD Tile %s\n', tile_name);
        
        % switch to the final destination
        folderpath_ard =  fullfile(path_ard, tile_name);
        % switch to the outputing folder <StackData>
        if resolution==30
            folderpath_out = fullfile(path_working, tile_name, 'StackData10');
%             folderpath_out = fullfile(path_working, tile_name, 'StackData10_30m');
        else
            folderpath_out = fullfile(path_working, tile_name, 'StackData10_60m');
        end
        
        % triger the function of stacking Landsat ARD into multiple row
        % dataset with BIP format
%         stackHLSLine(folderpath_ard, folderpath_out, ...
%              'check', true,'nsubrow', 10, 'msg', true, 'task', task ,'ntasks', ntasks,'sensor','L30');
        stackHLSLine(folderpath_ard, folderpath_out, ...
             'check', true, 'nsubrow', 10, ...
             'msg', true, 'task', task ,'ntasks', ntasks,...
             'sensor', 'L30', 'resolution', resolution);
    end
end
