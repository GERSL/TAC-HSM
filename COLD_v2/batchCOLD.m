function batchCOLD(varargin)
    
    addpath(fullfile(pwd));
    addpath(fullfile(pwd, 'CCD'));

    p = inputParser;
    addParameter(p,'task', 1); % 1st task
    addParameter(p,'ntasks', 1); % single task to compute
    addParameter(p,'ARDTiles',[]);
    % addParameter(p,'doTIF',true);
    
    % request user's input
    parse(p,varargin{:});
    task = p.Results.task;
    ntasks = p.Results.ntasks;
    ARDTiles = p.Results.ARDTiles;
    ARDTiles = {ARDTiles};
    % doTIF = p.Results.doTIF;
    
    
    %% can also be defined here
%     ARDTiles = globalsets.getARDTiles('stack');
    % ARDTiles = {'18TXM'};
    
    %% run COLD one by one Landsat ARD
    % The COLD function will process the stacking line data.
    for iARD = 1: length(ARDTiles)
        hv_name = ARDTiles{iARD};
       
        fprintf('Start to detect change for %s\n', hv_name);
%         folderpath_tilecold = fullfile(globalsets.PathCOLDS2, hv_name);          % bicubic image (baseline)
        % folderpath_tilecold = fullfile(globalsets.PathCOLDHLS10, hv_name);          % HLS 10-m image 
        folderpath_tilecold = fullfile(globalsets.PathCOLDHLSv2, hv_name); % HLS v2 
%         folderpath_HLS = fullfile(globalsets.PathCOLDHLS,hv_name);
% 
        % COLDTIF(folderpath_tilecold,...
        %     'onceread', false, 'delstack', false, 'orbitpath','all',...
        %     'cprob',0.99,'conse',6, 'mask',true,'doTIF',doTIF, ...
        %     'task', task ,'ntasks', ntasks)  % skx: change 'onceread' to false
%         COLD(folderpath_tilecold, ...
%             'onceread', false, 'delstack', false, 'orbitpath','all',...
%             'cprob',0.99,'conse',6,'mask',true, ...
%             'task', task ,'ntasks', ntasks)  % skx: change 'onceread' to false
        COLDHLS(folderpath_tilecold, ...
            'onceread', false, 'delstack', false, 'orbitpath','all',...
            'cprob',0.99,'conse',6, ...
            'task', task ,'ntasks', ntasks,'sensorname','HLS')  % skx: change 'onceread' to false

    end
end
