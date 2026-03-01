function batchStackHLSResampleLine(varargin)
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
%     ARDTiles = {'h003v010','h007v003','h015v009','h021v015', 'h029v005'}; 
%     ARDTiles = {'18TXL'};
    ARDTiles = {'14SPJ'};    % ,'13TCF' 10SFG
%     ARDTiles = {'15RXQ'};
    %% Locate to the Sentinel-2 ARD dataset
    path_ard = '/shared/cn450/DataHLSv1.4/14SPJ_resample/';%globalsets.PathS2ARD;
    %% Locate to the working folder, in which all outputing data can be found
    path_working = '/scratch/zhz18039/kes20012/COLDHLSResampleResults/14SPJ/';%globalsets.PathCOLDS2;

    %% For each Landsat ARD tile
    for iARD = 1: length(ARDTiles)
        % switch to a certain Landsat ARD tile
       tile_name = ARDTiles{iARD};
        % display
        fprintf('Start to stack ARD Tile %s\n', tile_name);
        
        % switch to the final destination
%         folderpath_ard =  fullfile(path_ard, tile_name);
        folderpath_ard = path_ard;
        % switch to the outputing folder <StackData>
%         folderpath_out = fullfile(path_working, tile_name, 'StackData10');
        folderpath_out = fullfile(path_working,'StackData10');
%         folderpath_out = fullfile(path_working,tile_name,'StackDataSingleOrbit');
        
        % triger the function of stacking Landsat ARD into multiple row
        % dataset with BIP format
        stackHLSResampleLine(folderpath_ard, folderpath_out, ...
            'orbitpath', 'all', 'check', true, ...
            'nsubrow', 10, 'msg', true, 'task', task ,'ntasks', ntasks);
    end
end
