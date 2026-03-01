function batchStackLandatARD2Line(task, tasks)
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


    if ~exist('task', 'var')
        task = 1;
    end
    if ~exist('tasks', 'var')
        tasks = 1;
    end
    
    %% Five site for testing new classification of land cover land use.
    ARDTiles = {'h003v010','h007v003','h015v009','h021v015', 'h029v005'}; 
%     ARDTiles = {'T18TXM','T18TXL','T18TYM','T18TYL'};
    % ARDTiles = {'18TXM'};
    %% Locate to the Landsat ARD dataset
    path_ard = globalsets.PathLandsatARD;
    % path_ard = globalsets.PathS2ARD;
    %% Locate to the working folder, in which all outputing data can be found
    path_working = globalsets.PathCOLD;

    %% For each Landsat ARD tile
    for iARD = 1: length(ARDTiles)
        % switch to a certain Landsat ARD tile
       tile_name = ARDTiles{iARD};
        % display
        fprintf('Start to stack ARD Tile %s\n', tile_name);
        
        % switch to the final destination
        folderpath_ard =  fullfile(path_ard, tile_name);
        % switch to the outputing folder <StackData>
        folderpath_out = fullfile(path_working, tile_name, 'StackData');
        
        % triger the function of stacking Landsat ARD into multiple row
        % dataset with BIP format
        stackS2ARD2Line(folderpath_ard, folderpath_out, ...
            'orbitpath', 'single', 'check', true, ...
            'nsubrow', 20, 'task', task ,'ntasks', tasks);
    end
end
