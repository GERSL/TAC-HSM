function batchStackS2ARD2Line(varargin)
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
    addParameter(p,'resolution',10);    % stack 10 m S2 or 20 m S2
    addParameter(p,'nsubrow',1);

    % request user's input
    parse(p,varargin{:});
    task = p.Results.task;
    ntasks = p.Results.ntasks;
    ARDTiles = p.Results.ARDTiles;
    ARDTiles = {ARDTiles};
    resolution = p.Results.resolution;
    nsubrow = p.Results.nsubrow;

    %% Five site for testing new classification of land cover land use.
    % ARDTiles = {'18TXL'};
    % resolution = 10;

    %% Locate to the Sentinel-2 ARD dataset
%     path_ard_tars = globalsets.PathLandsatARD;
    path_ard = globalsets.PathS2ARD;
    %% Locate to the working folder, in which all outputing data can be found
    path_working = globalsets.PathCOLDS2;

    %% For each Landsat ARD tile
    for iARD = 1: length(ARDTiles)
        % switch to a certain Landsat ARD tile
       tile_name = ARDTiles{iARD};
        % display
        fprintf('Start to stack ARD Tile %s\n', tile_name);
        
        % switch to the final destination
        folderpath_ard =  fullfile(path_ard, ['T',tile_name],'ARDBRDF_HLSAngle');
        % switch to the outputing folder <StackData>
        if resolution==10
            folderpath_out = fullfile(path_working, tile_name, sprintf('StackData%s',num2str(nsubrow)));
        else
            folderpath_out = fullfile(path_working, tile_name, sprintf('StackDat%s',num2str(nsubrow),'_20m'));
        end
%         folderpath_out = fullfile(path_working,tile_name,'StackDataSingleOrbit');
        
        % triger the function of stacking Landsat ARD into multiple row
        % dataset with BIP format
        stackS2ARD2Linev2(folderpath_ard, folderpath_out, ...
            'orbitpath', 'all', 'check', true, ...
            'nsubrow', nsubrow, 'msg', true, 'task', task ,'ntasks', ntasks,...
            'resolution',resolution);
    end
end
