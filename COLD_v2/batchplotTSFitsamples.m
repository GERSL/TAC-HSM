function batchplotTSFitsamples(varargin)
    
    addpath(fullfile(pwd));
    addpath(fullfile(pwd, 'Validate'));

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
    
    
    %% can also be defined here
%     ARDTiles = globalsets.getARDTiles('stack');
%     ARDTiles = {'h029v005'}; %% new england area
%     ARDTiles = {'18TYM'};
    
    %% run COLD one by one Landsat ARD
    % The COLD function will process the stacking line data.
    for iARD = 1: length(ARDTiles)
        hv_name = ARDTiles{iARD};
       
        fprintf('Start to detect change for %s\n', hv_name);
        folderpath_tilecold = fullfile(globalsets.PathCOLDFusion,hv_name);   % Fused image  
%         folderpath_tilecold = fullfile(globalsets.PathCOLD, hv_name);          % bicubic image (baseline)
        folderpath_csv = fullfile("/shared/cn449/Kexin/Samples/", hv_name);
        plotTSFitsamples(folderpath_tilecold, folderpath_csv,...
            'task', task ,'ntasks', ntasks)  % skx: change 'onceread' to false

    end
end
