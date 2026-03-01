function batchStackHLSv2Block(varargin)
%% This is an example of stacking HLS version 2 data for mutilple tiles
%
% EXAMPLE OF USE:
%
%   > See arrayStackARDxxxx.sh in the folder <JobsToStack>, which request a
%   total of 100 cores to process stacking at parallel
%
% 
% AUTHOR(s): Shi Qiu, Kexin Song
% DATE: Feb. 8, 2021
% COPYRIGHT @ GERSLab

    folderpath_mfile = fileparts(mfilename('fullpath'));
    addpath(folderpath_mfile);
    addpath(fullfile(folderpath_mfile, 'Stack'));  
    
    p = inputParser;
    addParameter(p,'task', 1); % 1st task
    addParameter(p,'ntasks', 1); % single task to compute
    addParameter(p,'ARDTiles',[]);
    addParameter(p,'resolution',30); 

    % request user's input
    parse(p,varargin{:});
    task = p.Results.task;
    ntasks = p.Results.ntasks;
    ARDTiles = p.Results.ARDTiles;
    ARDTiles = {ARDTiles};
    resolution = p.Results.resolution;

    %% Five site for testing new classification of land cover land use.
    ARDTiles = {'18TXM'};
%     ARDTiles = {'10SFG'};
    % ARDTiles = {'13TCF'};
    % ARDTiles = {'14SPJ'};
    % ARDTiles = {'15RXQ'};
    % resolution = 60;
    sensor = 'HLS';
    
    %% Locate to the HLS dataset
    path_ard = globalsets.PathHLSv2;
    
    %% Locate to the working folder, in which all outputing data can be found
    % path_working = globalsets.PathCOLDHLSv2;
    % TODO: update the path working to /scratch
    path_working = '/scratch/zhz18039/kes20012/ProjectInsectDisturbance/COLDHLSResults';

    %% For each HLS tile
    for iARD = 1: length(ARDTiles)
        % switch to a certain Landsat ARD tile
       tile_name = ARDTiles{iARD};
        % display
        fprintf('Start to stack ARD Tile %s\n', tile_name);
        
        % switch to the final destination
%         folderpath_ard =  fullfile(path_ard, tile_name);
        folderpath_ard =  fullfile(path_ard);
        % switch to the outputing folder <StackData>
        if resolution==30
            folderpath_out = fullfile(path_working, tile_name, 'StackData10');
        else
            folderpath_out = fullfile(path_working, tile_name, 'StackData10_60m');
        end
        
        % triger the function of stacking Landsat ARD into multiple row
        % dataset with BIP format
        stackHLSv2Line(folderpath_ard, folderpath_out, ...
             'check', true,'nsubrow', 10, 'msg',true, 'task', task ,'ntasks', ntasks,...
             'sensor', sensor,'tilename',tile_name,'resolution', resolution);
    end
end
