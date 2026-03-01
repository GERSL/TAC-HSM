function batchExportTSDensity(varargin)

%  This shows the time series density (number of non-zero & clear observations) for each pixel.
    addpath('/home/kes20012/COLD_v2/');
    addpath('/home/kes20012/COLD_v2/CCD/');

    p = inputParser;
    addParameter(p,'task', 1); % 1st task
    addParameter(p,'ntasks', 1); % single task to compute
    addParameter(p,'ARDTiles',[]);
    addParameter(p,'msg', true); % not to display info

    % request user's input
    parse(p,varargin{:});
    task = p.Results.task;
    ntasks = p.Results.ntasks;
    msg = p.Results.msg;
    ARDTiles = p.Results.ARDTiles;
    ARDTiles = {ARDTiles};

    % or define tiles here
    ARDTiles = {'18TYM'};

    % The COLD function will process the stacking line data.
    for iARD = 1: length(ARDTiles)
        hv_name = ARDTiles{iARD};
       
        fprintf('Start to calculate time series density for %s\n', hv_name);
%         folderpath_tilecold = fullfile(globalsets.PathCOLDFusion,hv_name);   % Fused image  
        folderpath_tilecold = fullfile(globalsets.PathCOLD, hv_name);          % bicubic image (baseline)
        exportTSDensity(folderpath_tilecold,...
            'task', task ,'ntasks', ntasks,'msg',true)  % skx: change 'onceread' to false

    end
end

