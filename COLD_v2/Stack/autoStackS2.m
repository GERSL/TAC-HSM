function autoStackS2(varargin)
% autoStackS2 automatically stack all daily Sentinel-2 ARD in the
% current folder into CCDC format.
%
% Data Support
% -------------
%   The input data must be of class .tif or .img.
% 
% History
% ---------------
% Add ROI mask of pixel value > 0 will be considered as ROI. (10. Sept., 2020)
% Add taskID and taskTotalNum for parallel. (10. Sept., 2020)
% 
% Specific parameters
% ------------------------
%   'InDir'     Directory of input data.  Default is the path to
%                        the current folder.
%   'OutDir'    Directory of output data.  Default is the path to
%                        the current folder.
%   'ClrPixPer'  Percentage of mininum clear pixels 
%                        (non-ice/snow covered). Unit is %. Default is '20'.
%   
%   'ROIFilePath' File path of ROI image, in which pixel value > 0 will be
%                   considered as ROI
%
%   'TaskID'     Core ID. e.g., 1, 2, 3, 4, 5, ....
%   'TaskTotalNum' Total number of cores.
%
%   Note: TaskID and TasktotalNum would be used for processing data at
%   parallel model.
% 
%   Author:  Zhe Zhu (zhe#uconn.edu)
%            Shi Qiu (shi.qiu#uconn.edu)
%   Other contributers:
%            Junxue Zhang (MS student in UCONN)
%   Date: 10. Sept., 2020
% --------------------------
%   Author: Kexin Song (kexin.song#uconn.edu)
%   Date: 01/23/2021

%% add CCDC path
    addpath(pwd);
%% Get parameters from inputs
    % where the all Landsat zipped files are
    dir_cur = pwd;
    % where the output files are
    dir_out = '';
    % min clear pixel
    clr_pct_min = 20; % unit %
    % total number of bands
    nbands = 11;  % 2-blue, 3-greeen, 4-red, 5,6,7, 8-NIR, 8A, 11-SWIR1, 12-SWIR2, cfmask
    
    p = inputParser;
    p.FunctionName = 'prepParas';
    % optional
    % default values.
    addParameter(p,'InDir',dir_cur);
    addParameter(p,'OutDir',dir_out);
    if isempty(dir_out)
        dir_out = dir_cur;
    end
    addParameter(p,'ClrPixPer',clr_pct_min);
    
    addParameter(p,'ROIFilePath','');
    addParameter(p,'TaskID',1);
    addParameter(p,'TaskTotalNum',1);
    % request user's input
    parse(p,varargin{:});
    dir_cur=p.Results.InDir;
    dir_out=p.Results.OutDir;
    clr_pct_min=p.Results.ClrPixPer;
    
    % Pixel value: 1 is for processing, and 0 is background
    % filepath_roi = '/gpfs/scratchfs1/shq19004/ARD_CT/CT_3ARDMasks_5kmBufferBoundary/CTMask_029006.tif';
    filepath_roi = p.Results.ROIFilePath;
    taskID = p.Results.TaskID;
    taskTotalNum = p.Results.TaskTotalNum;
    

     %% test
     taskID = 1;
     taskTotalNum = 1;
%      dir_cur="/scratch/kes20012/S2_ARD_CT/test/";
     dir_out = "/scratch/kes20012/S2_stack_Fusion/T18TXL/";
% %      dir_out="/gpfs/sharedfs1/zhulab/Kexin/S2_CT_stack/T18TXL/";
%      filepath_roi="/gpfs/sharedfs1/zhulab/Kexin/ROWmask_CT/ROWmask_T18TXL.tif";
    
%% Filter for Sentinel-2 folders
    % get num of total folders start with "T18"
    imfs = dir(fullfile(dir_cur,'T18*'));
    % filter for Sentinel-2 ARD folders
    %ks
    imfs = regexpi({imfs.name}, 'T18(TXL|TXM|TYL|TYM)(\w*)', 'match');
    imfs = [imfs{:}];
    if isempty(imfs)
        
        warning('No images here!');
        return;
    end
    imfs = vertcat(imfs{:});
    % sort according to yeardoy
    yyyydoy = str2num(imfs(:,12:18));
    [~, sort_order] = sort(yyyydoy);
    imfs = imfs(sort_order, :);
    % number of folders start with "L"
    num_t = size(imfs,1);
    fprintf('A total of %d images will be prepared...\n',num_t);
    
    % Arrange cores
    tasks_per_core = ceil(num_t/taskTotalNum);
    i_start = (taskID - 1)*tasks_per_core +1;
    i_end = min(tasks_per_core*taskID, num_t);
    % Read ROI mask
    if ~isempty(filepath_roi)
        maskROI = imread(filepath_roi) > 0; % > 0
    else
        maskROI = [];
    end
    
    for i = i_start:i_end
        
        imf = imfs(i,:);
        doy = str2num(imf(12:18));
        % create _mtl folder
        n_mtl = imf([1:6,12:18,8:10]);  % e.g. 'T18TXL2020208S2A'
        n_img = dir(fullfile(dir_out,'T18*'));
        num_img = size(n_img,1);
        % check all folders we have
        % record exist or not
        rec_exist = 0;
        if num_img > 0
            for i_check = 1:num_img
                if n_img(i_check).isdir
                    % each image folder name
                    tmp_img = n_img(i_check).name;
                    tmp_zip = n_mtl;
                    if strcmp(tmp_img(1:16),tmp_zip(1:16))
                        outf = dir(fullfile(dir_out,tmp_img,[char(n_mtl),'_MTLstack']));
                        if ~isempty(outf)
                            rec_exist = 1;
                            break;
                        end
                    end
                end
            end
            % continue if the folder already exist
            if rec_exist > 0
                fprintf('%s exsit in stacked images folder\n',tmp_img);
                continue;
            end
        end
        
        %% Add cfmask to stack
        % read cfmask first to caculate clear pixel percet
        % extract cfmask (tif or envi)
        tif_cfmask = dir(fullfile(dir_cur,imf,'T*mask4*.tif'));
        % pick SR 2,3,4,8,11,12,5,6,7,8A, and fmask
        cfmask = geotiffread(fullfile(dir_cur,imf,tif_cfmask.name));
        % check clear pixels
        clr_pct = sum(cfmask(:)<=1)/sum(cfmask(:)<255);
        clr_pct = 100*clr_pct;
        if clr_pct < clr_pct_min % less than 20% clear observations
            % remove the tmp folder
            % fprintf('Clear observation less than 20 percent (%.2f) ...\n',clr_pct*100);
%             rmdir(fullfile(dir_out,n_tmp),'s');
            % fprintf('Clear pixels less than %.2f percent (%.2f) ...\n',clr_pct_min,clr_pct);
            fprintf('Clear pixels less than %.2f percent (%.2f) for %s\n',clr_pct_min,clr_pct,imf);
            continue;
        else
            if ~isempty(tif_cfmask) % tif format(tif_cfmask);
                % get projection information from geotiffinfo
                info = geotiffinfo(fullfile(dir_cur,imf,tif_cfmask.name));
                jidim = [info.SpatialRef.RasterSize(2),info.SpatialRef.RasterSize(1)];
                jiul = [info.SpatialRef.XLimWorld(1),info.SpatialRef.YLimWorld(2)];
                resolu = [info.PixelScale(1),info.PixelScale(2)];
                zc = info.Zone;
            end

            % prelocate image for the stacked image
            stack = zeros(jidim(2),jidim(1),nbands,'int16');
            
            % give mask to QA mask
            if ~isempty(maskROI)
                fprintf('Mask of ROI was used\n');
                cfmask(~maskROI) = 255; % label as 255 that will be discharged when running CCD
            end
            % give cfmask to the last band
            stack(:,:,end) = cfmask;
        end
        
        %% Add SRs to stack
        tif_B2 = dir(fullfile(dir_cur,imf,'T*B02*.tif'));
        tif_B3 = dir(fullfile(dir_cur,imf,'T*B03*.tif'));
        tif_B4 = dir(fullfile(dir_cur,imf,'T*B04*.tif'));
        tif_B8 = dir(fullfile(dir_cur,imf,'T*B08*.tif'));
        tif_B11 = dir(fullfile(dir_cur,imf,'T*B11*.tif'));
        tif_B12 = dir(fullfile(dir_cur,imf,'T*B12*.tif'));
        tif_B5 = dir(fullfile(dir_cur,imf,'T*B05*.tif'));
        tif_B6 = dir(fullfile(dir_cur,imf,'T*B06*.tif'));
        tif_B7 = dir(fullfile(dir_cur,imf,'T*B07*.tif'));
        tif_B8A = dir(fullfile(dir_cur,imf,'T*B8A*.tif'));
        try
            surf_b1 = geotiffread(fullfile(dir_cur,imf,tif_B2.name));
            stack(:,:,1) = surf_b1;
            surf_b2 = geotiffread(fullfile(dir_cur,imf,tif_B3.name));
            stack(:,:,2) = surf_b2;
            surf_b3 = geotiffread(fullfile(dir_cur,imf,tif_B4.name));
            stack(:,:,3) = surf_b3;
            surf_b4 = geotiffread(fullfile(dir_cur,imf,tif_B8.name));
            stack(:,:,4) = surf_b4;
            surf_b5 = geotiffread(fullfile(dir_cur,imf,tif_B11.name));
            stack(:,:,5) = surf_b5;
            surf_b6 = geotiffread(fullfile(dir_cur,imf,tif_B12.name));
            stack(:,:,6) = surf_b6;
            surf_b7 = geotiffread(fullfile(dir_cur,imf,tif_B5.name));
            stack(:,:,7) = surf_b7;
            surf_b8 = geotiffread(fullfile(dir_cur,imf,tif_B6.name));
            stack(:,:,8) = surf_b8;
            surf_b9 = geotiffread(fullfile(dir_cur,imf,tif_B7.name));
            stack(:,:,9) = surf_b9;
            surf_b10 = geotiffread(fullfile(dir_cur,imf,tif_B8A.name));
            stack(:,:,10) = surf_b10;
            clear surf_b1;
            clear surf_b2;
            clear surf_b3;
            clear surf_b4;
            clear surf_b5;
            clear surf_b6;
            clear surf_b7;
            clear surf_b8;
            clear surf_b9;
            clear surf_b10;
        catch me
            fprintf('SR file cannot be found in the %s \n',imf);
            continue;
        end
        %% if have ROI Mask, filter all pixels out of each indiviudal band
        if ~isempty(maskROI)
            for ib =1 : size(stack,3)-1
                band_tmp = stack(:,:,ib);
                band_tmp(~maskROI) = 0;
                stack(:,:,ib) = band_tmp;
                clear band_tmp;
            end
        end
        
        % name of new stacked bip image
        n_stack = [char(n_mtl),'_MTLstack'];
        % add directory
        n_dir = fullfile(dir_out,n_mtl);
        n_dir_isfolder = dir(n_dir);
        if isempty(n_dir_isfolder)
            mkdir(n_dir);
        end
        clear n_dir_isfolder;

        % write to images folder
        fprintf('Writing %s image ...\n',n_mtl);
        n_stack = fullfile(n_dir,n_stack);
%         [~,info] = rs_imread(filepath_roi);
%         rs_imwrite(n_stack,stack,info);
        enviwrite(n_stack,stack,'int16',resolu,jiul,'bip',zc);
        clear stack;
end