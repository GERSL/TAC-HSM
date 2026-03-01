function HTCondorStackHLSLine(varargin)
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
    addParameter(p,'task', 1); % 1st task
    addParameter(p,'ntasks', 1); % single task to compute
    addParameter(p,'ARDTiles',[]);
    
    % request user's input
    parse(p,varargin{:});
    task = p.Results.task;
    ntasks = p.Results.ntasks;
    ARDTiles = p.Results.ARDTiles;
    ARDTiles = {ARDTiles};
    

    %% Five site for testing new classification of land cover land use.
%     ARDTiles = {'18TXL'};
%     ARDTiles = {'18TYL'};
%     ARDTiles = {'18TXM'};
%     ARDTiles = {'18TYM'};
    
    %% Locate to the HLS dataset
%     path_ard = ;
    %% Locate to the working folder, in which all outputing data can be found
%     path_working = ;

    %% For each HLS tile
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
        stackHLSLine(folderpath_ard, folderpath_out, ...
             'check', true,'nsubrow', 10, 'msg', false, 'task', task ,'ntasks', ntasks);
    end
end
