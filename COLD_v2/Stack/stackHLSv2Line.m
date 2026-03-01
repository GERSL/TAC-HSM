function stackHLSv2Line(folderpath_ard, folderpath_stack, varargin)
%STACKS2ARD2LINE This function is to stack HLS ARD time series
% into few row data with BIP format. Running time is estimated to ~0.25
% mins per HLS ARD.
%
% INPUT:
%
%   folderpath_ard:         Locate to Sentinel-2 ARD-BRDF folder that have all the
%                           surface reflectance ('T*.tif'). Usually we have
%                           hundreds or thousands of Landsat images.
%
%   folderpath_stack:       Locate to output folder where the stack data
%                           will be stored by lines (rows).
%
%   task (optional):        Task ID of parallel computation
%
%   ntasks (optional):      Total number of tasks of parallel computation
%
%   clear (optional):       Percentage of clear pixels (uint: %). The image
%                           with < this value will be not processed.
%                           (default value: 0 for stacking all the images in the ARD folder)
%
%   nsubrow (optional):     Number of seperated lines (rows) (default value
%                           : 10)
%
%   orbitpath (optional):   Orbit path of Landsat ('single' or 'all').
%                           'single' means generate the single Landsat path
%                           layer with geotiff format. 'all' means not to
%                           do that. (default value: single)
%
%   msg (optional)          [false/true] Display processing status (default
%                           value: false)
%
%   check (optional):       [false/true] Check the existing files, and if
%                           exist, this function will skip to process it
%                           (default value: false). Note the default
%                           "false" will let the process not to SCAN all
%                           the already stack files or folders, and this
%                           will be more efficient. However, if one more
%                           time stacking process needed, please set it as
%                           "true" for avoiding to stack the already exist
%                           data.
%
%
% RETURN:
%
%   null
%
% REFERENCE(S):
%
%   null
%
% EXAMPLE OF USE:
%
%   > To stack Landsat ARD at task # 1/20
%
%   stackLandsatARD2Line('/lustre/scratch/qiu25856/DataLandsatARD/CONUS/h029v005', '/lustre/scratch/qiu25856/TestGERSToolbox/h029v005/StackData', 'task', 1 ,'ntasks', 20)
%
%   > To stack Landsat ARD at task # 1/20 one more time. then, the check as
%   true is recommanded.
%
%   stackLandsatARD2Line('/lustre/scratch/qiu25856/DataLandsatARD/CONUS/h029v005', '/lustre/scratch/qiu25856/TestGERSToolbox/h029v005/StackData', 'task', 1 ,'ntasks', 20 , 'check', true)
%
% 
% AUTHOR(s): Shi Qiu
% DATE: Feb. 5, 2021
% COPYRIGHT @ GERSLab


    % add the matlab search path of GRIDobj
    addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'GRIDobj'));
    addpath('/home/kes20012/HLS stack code');
    
    % test path
%     folderpath_ard = '/shared/cn450/DataHLSv1.4/18TYM/';
%     folderpath_ard = '/gpfs/sharedfs1/zhulab/Su/HLS20/18TXM';
%     folderpath_stack = '/shared/cn451/COLDHLSv2Results/18TXM/StackData10';
%     folderpath_stack = '/scratch/kes20012/S2_stack_fusion_single/T18TYL/';
    
    %% Have user's inputs
    % requried
    if isempty(folderpath_ard)
        warning('No HLS ARD folder input!');
        return;
    end
    if isempty(folderpath_stack)
        warning('No stack folder input!');
        return;
    end
    
    % optional
    p = inputParser;
    addParameter(p,'clear', 0); % dedault as 0 , that will stack all the images in the input folder
    addParameter(p,'nsubrow', 10); % default rows per file (optional)
    addParameter(p,'orbitpath', 'single'); % to create single path layer
    addParameter(p,'task', 1); % 1st task
    addParameter(p,'ntasks', 1); % single task to compute
    addParameter(p,'msg', false); % not to display info
    addParameter(p,'check', false); % not to scan history data; but once more time, please set as true, and if exist, just skip
    addParameter(p,'sensor', 'L30');
    addParameter(p,'tilename',[]);
    addParameter(p,'resolution', 30);  % default is 30m.

    % request user's input
    parse(p,varargin{:});
    
    clr_pct_min = p.Results.clear;
    nrowsper = p.Results.nsubrow;
    task = p.Results.task;
    ntasks = p.Results.ntasks;
    msg = p.Results.msg;
    checkexist = p.Results.check;
    sensor = p.Results.sensor;
    tilename = p.Results.tilename;
    resolution = p.Results.resolution;

    % char will be better understood for users
    switch lower(p.Results.orbitpath)
        case 'single'
            singlepath = true;
        case 'all'
            singlepath = false;
    end

    msg = 'True';
%     tileNameHLS = 'T18TYM';
    tileNameHLS = tilename; %['T' folderpath_ard(end-4:end)];

    %% constant parameter    
    nbands = 7; % 6 spectral bands (R,G,NNIR,SWIR2,SWIR2) + Fmask QA band

    %% Filter for HLS folders
     imgPath1 = folderpath_ard;
     imgDir1  = dir(folderpath_ard);
     yeardoy = [];
     hdfHLS = [];
     hdfFolder = [];
     for k = 1:length(imgDir1)
        if(isequal(imgDir1(k).name,'.')||... 
                isequal(imgDir1(k).name,'..')||...
                ~imgDir1(k).isdir)                
            continue;
        end
        imgPath2 = [imgPath1 imgDir1(k).name '/']; 
        imgDir2 = dir(imgPath2);
        for j = 1:length(imgDir2)
            if(isequal(imgDir2(j).name,'.')||...
                    isequal(imgDir2(j).name,'..')||...
                    ~imgDir2(j).isdir)
                continue;
            end

            imgPath3 = [imgPath2 imgDir2(j).name '/'];
            imgPath4 = [imgPath3 tileNameHLS(1:2) '/' tileNameHLS(3) '/' tileNameHLS(4) '/' tileNameHLS(5)];
            imgsHLS = dir(fullfile(imgPath4,'HLS.*v2.0'));
            hdfFolder = [hdfFolder;vertcat(imgsHLS.folder)];
%             % e.g., name HLS.L30.T18TYM.2018001.v1.4.hdf
            if strcmp(sensor,'HLS')
                imgsHLS = regexpi({imgsHLS.name}, ['HLS.(L30|S30).T', tileNameHLS,'.(\w*).(\w*).(\w*)','.v2.0'], 'match');
            elseif strcmp(sensor,'L30')
                imgsHLS = regexpi({imgsHLS.name}, ['HLS.(L30).T', tileNameHLS,'.(\w*).(\w*).(\w*)','.v2.0'], 'match');
            elseif strcmp(sensor,'S30')
                imgsHLS = regexpi({imgsHLS.name}, ['HLS.(S30).T', tileNameHLS,'.(\w*).(\w*).(\w*)','.v2.0'], 'match');
            end          
            imgsHLS = [imgsHLS{:}];
            if isempty(imgsHLS)
%                 return;
                  continue; % ks: change return to continue to process L30 only
            end
            imgsHLS = vertcat(imgsHLS{:}); 
            hdfHLS = [hdfHLS;imgsHLS];
            yeardoy = [yeardoy;str2num(imgsHLS(:, 16:22))];
        end
            % sort according to yeardoy
            [~, sort_order] = sort(yeardoy);
            hdfHLS = hdfHLS(sort_order,:);
            hdfFolder = hdfFolder(sort_order,:);
            % number of HLS images
            numHLSImage = size(hdfHLS,1);
     end  %% end of k = 1:length(imgDir1)

    %% Optional: Check exist images the last row folder
    isexist = zeros([numHLSImage,1]);
    for i_img = 1:numHLSImage
        stackname = subFunStackDataName(hdfHLS(i_img,:));
        
        if checkexist
            % filepath_meta = fullfile(fileparts(folderpath_stack), 'metadata.mat');
            filepath_meta = fullfile(folderpath_stack, 'metadata.mat');
            if isfile(filepath_meta) % we must have the metadata first
                if ~exist('metadata', 'var')
                    load(filepath_meta); % only load once
                end
                irow = max(1: metadata.nsubrows: metadata.nrows); % the last row folder
                irow_end = min(irow + metadata.nsubrows -1, metadata.nrows);
                foldername_rowdata = subFunRowFolderName(irow, irow_end);
                rowdata_exist = dir(fullfile(folderpath_stack, foldername_rowdata, stackname));
                if ~isempty(rowdata_exist)
                    isexist(i_img)=1;
%                      if msg
%                         fprintf('\nAlready exist the %dth image (%s)\n', i_img,stackname);
%                     end
                end
            end
        end   % end of checkexist
    end
    hdfHLS = hdfHLS(~isexist,:);
    hdfFolder = hdfFolder(~isexist,:);
    numHLSImage = size(hdfHLS,1);
    if numHLSImage==0
        fprintf('Finish stacking!\n');
        return;
    else
        if msg
            fprintf('A total of %04d not processed HLS images at %s\r\n',numHLSImage, folderpath_ard);
        end
    end
    
    %% Assign stacking tasks to each core
    tasks_per = ceil(numHLSImage/ntasks);
    start_i = (task-1)*tasks_per + 1;
    end_i = min(task*tasks_per, numHLSImage);
    if msg
        fprintf('At task# %d/%d to process %d images\n', task, ntasks, end_i- start_i + 1);
    end
    % create a task folder, that will be uesed to store the divided row
    % data for all the images @ the currenr core
    folderpath_task = fullfile(folderpath_stack, sprintf('tmptaskfolder_%d_%d', task, ntasks));
    if ~isfolder(folderpath_task)
        mkdir(folderpath_task);
    end
    
    %% Start to stack the Sentinel-2 ARD from start_i th to end_i th
    tic % record all running time
    for i = start_i:end_i
        %% locate to a certain image
        imgName = hdfHLS(i,:);
        stackname = subFunStackDataName(imgName);
        %% Step 1. Write metadata
        % @ the 1st image at 1st task, to create a metadata to save, which
        % is to backup the geo info of the geotiff.
        if resolution ==30
            nrows = 3660;
            ncols = 3660; 
        else   % at 60 m resolution
            nrows = 3660/2;
            ncols = 3660/2; 
        end
        if task == 1 && i == 1
            % metaset generator
            if resolution==30
                geotiff = GRIDobj(fullfile('/shared/cn450/DataHLSv1.4/GeoTIFF/',[tileNameHLS(1:end) '.tif']));
            else
                geotiff = GRIDobj(fullfile('/shared/cn450/DataHLSv1.4/GeoTIFF/',[tileNameHLS(1:end) '_60m.tif']));
            end
            metadata = [];
            metadata.GRIDobj = geotiff;
            metadata.GRIDobj.Z = []; % set as [] for saving storage
            metadata.GRIDobj.name = []; % set as [] for saving storage
            metadata.tile = sprintf(tileNameHLS);
            metadata.nrows = nrows; % record of the row size
            metadata.ncols = ncols; % record of the column size.
            metadata.nbands = nbands; % record of the number of bands in stack data
            metadata.nsubrows = nrowsper; % record of the number of rows per file
            metadata.nimages = numHLSImage; % record of the total number of Landsat images
            metadata.cloudcover = 100 - clr_pct_min; % record of max percentage of cloud cover
            metadata.createtime = datestr(now); % record of the create time
            % save(fullfile(fileparts(folderpath_stack), 'metadata'), 'metadata'); % saveas metadata
            save(fullfile(folderpath_stack, 'metadata'), 'metadata'); % saveas metadata
        end
        %% Step 2. Read Surface Ref. and QA band
        try
%             y_ref = zeros(nrows, ncols, nbands, 'int16'); %Ys
            if strcmp(imgName(5:7), 'S30')
                img = dir(fullfile(hdfFolder(i,:),imgName,'*.tif'));
                for i_img =1:length(img)-1
                    y_ref(:,:,i_img) = readgeoraster(fullfile(img(i_img).folder,img(i_img).name));
                end
                % adjust band order 
                b5 = y_ref(:,:,end-1);   % nnir
                b6 = y_ref(:,:,4);   % swir1
                b7 = y_ref(:,:,5);   % swir2
                y_ref(:,:,4) = b5;
                y_ref(:,:,5) = b6;
                y_ref(:,:,6) = b7;
                b2 = y_ref(:,:,1);
                b3 = y_ref(:,:,2);
                b4 = y_ref(:,:,3);
               
            elseif strcmp(imgName(5:7), 'L30')

                tif_B2 = dir(fullfile(hdfFolder(i,:),imgName,'HLS*B02*.tif'));   % Blue
                tif_B3 = dir(fullfile(hdfFolder(i,:),imgName,'HLS*B03*.tif'));   % Green
                tif_B4 = dir(fullfile(hdfFolder(i,:),imgName,'HLS*B04*.tif'));   % Red
                tif_B5 = dir(fullfile(hdfFolder(i,:),imgName,'HLS*B05*.tif'));   % NIR Narrow
                tif_B6 = dir(fullfile(hdfFolder(i,:),imgName,'HLS*B06*.tif'));   % SWIR 1
                tif_B7 = dir(fullfile(hdfFolder(i,:),imgName,'HLS*B07*.tif'));   % SWIR 2
                
                b2 = readgeoraster(fullfile(hdfFolder(i,:),imgName, tif_B2.name));
                b3 = readgeoraster(fullfile(hdfFolder(i,:),imgName, tif_B3.name));
                b4 = readgeoraster(fullfile(hdfFolder(i,:),imgName, tif_B4.name));
                b5 = readgeoraster(fullfile(hdfFolder(i,:),imgName, tif_B5.name));
                b6 = readgeoraster(fullfile(hdfFolder(i,:),imgName, tif_B6.name));
                b7 = readgeoraster(fullfile(hdfFolder(i,:),imgName, tif_B7.name));

                % perform PSF and upscaled to 60 m
                if resolution==60
                    pixEdge = [nrows, ncols];
                    b2 = imresize(imgaussfilt(b2,2), pixEdge,'bicubic');
                    b3 = imresize(imgaussfilt(b3,2), pixEdge,'bicubic');
                    b4 = imresize(imgaussfilt(b4,2), pixEdge,'bicubic');
                    b5 = imresize(imgaussfilt(b5,2), pixEdge,'bicubic');
                    b6 = imresize(imgaussfilt(b6,2), pixEdge,'bicubic');
                    b7 = imresize(imgaussfilt(b7,2), pixEdge,'bicubic');
                end
                
            end
            % convert pixel QA to fmask values
            cfmask = zeros(nrows,ncols);  % 0: clear land pixel
            img_Fmask = dir(fullfile(hdfFolder(i,:),imgName,'HLS*Fmask.tif'));
            cfmask0 = readgeoraster(fullfile(img_Fmask(1).folder,img_Fmask(1).name));
            if resolution==60
                cfmask0 = imresize(cfmask0,[nrows,ncols],'nearest');
            end
            cfmask(bitget(cfmask0,6) == 1) = 1;   % 1: clear water 
            cfmask(bitget(cfmask0,5) == 1) = 3;   % 3: snow
            cfmask(bitget(cfmask0,4) == 1) = 2;   % 2: cloud shadow
            cfmask(bitget(cfmask0,2) == 1) = 4;   % 4: cloud
            cfmask(bitget(cfmask0,1) == 1) = 4;   % 4: cirrus
            clear cfmask0;
            clr_pct = sum(cfmask(:)<=1)/sum(cfmask(:)<255);
            clr_pct = 100*clr_pct;
            if clr_pct < clr_pct_min
                fprintf('Clear observation less than %.2f percent (%.2f)\r\n', clr_pct_min, clr_pct);
            end
            
             %% Step 3. Stack all the bands together row by row into the temp foler of current task
            for irow = 1: nrowsper: nrows % total of 3660 rows
%             for irow = 1: nrowsper:10
                % @ the current task, only parts of the images will be reconstructed
                irow_end = min(irow + nrowsper -1, nrows);

                % row data's foldername R0000100010, which means the row 00001 to 00010
                foldername_rowdata = subFunRowFolderName(irow, irow_end);
                folderpath_out = fullfile(folderpath_stack, foldername_rowdata);
                if ~isfolder(folderpath_out)
                    mkdir(folderpath_out);
                end

                % @ the 1st image at 1st task, to copt the metadata to each sub
                % row folder, that will be loaded for proceseesing further
                if task == 1 && i == 1
                    % copyfile(fullfile(fileparts(folderpath_stack), 'metadata.mat'),  fullfile(folderpath_stack, foldername_rowdata)); % saveas metadata
                    copyfile(fullfile(folderpath_stack, 'metadata.mat'),  fullfile(folderpath_stack, foldername_rowdata)); % saveas metadata
                end

                % if exsit, skip
                if isfile(fullfile(folderpath_out, stackname)) % ignore to check the file broken or not, since the row file is too small to write incorrectly (at least low possibly)
                    continue;
                end

                % as for a certain row data, the data will be in format of BIP
                % (data format)    [b1 b2 b3 b4 b5 b7 b6 qa b1 b2 b3 b4 b5 b7 b6 qa b1 b2 b3 b4 b5 b7 b6 qa .... b1 b2 b3 b4 b5 b7 b6 qa]
                % (index in array) [1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 .....] 
                linedata = zeros(length(irow: irow_end), ncols, nbands, 'uint16'); % nrowsper * 3660 cols * 7 bands
                linedata(:,:,1) = b2(irow: irow_end,:); % blue
                linedata(:,:,2) = b3(irow: irow_end,:); % green
                linedata(:,:,3) = b4(irow: irow_end,:); % red
                linedata(:,:,4) = b5(irow: irow_end,:); % nnir
                linedata(:,:,5) = b6(irow: irow_end,:); % swir1
                linedata(:,:,6) = b7(irow: irow_end,:); % swir2
                linedata(:,:,7) = cfmask(irow: irow_end,:); % qa
                multibandwrite(linedata, fullfile(folderpath_out, stackname), 'bip');
             end

             %% Step 4. Clear temp image folder once done
             if msg
                fprintf('Finished %0.2f percent at task# %d/%d with total %0.2f mins\n', ...
                    100*(1 + i - start_i)/(end_i - start_i + 1), task, ntasks, toc/60);
             end
% 
        catch me
            warning('Error for %s', imgName);
        end
    end      
%     end % end of processing all the images at the current task
    fclose('all'); % close the IO for reading .xml files
    rmdir(folderpath_task, 's'); % clear temp task folder once done
end


%% sub function of creating stack data name
function stackname = subFunStackDataName(imf)
    % i.e., T18TXL2020208S2A
    % i.e., LT50290051984251C1V01_012
    % LT5 means Landsat 5 TM
    % 029005 means the Landsat ARD tile h029v005
    % 1984 means the year of 1984
    % 251 means the DOY of 251
    % C1 means Landsat Collection 1
    % V01 means the Landsat ARD version V01
    % PPP means the path of the Landsat orbit.
%     yr = str2num(imf(12:19));
%     mm = str2num(imf(20:21));
%     dd = str2num(imf(22:23));
%     doy = datenummx(yr,mm,dd)-datenummx(yr,1,0);
    stackname = imf([9:14,16:22,5:7]);
%     stackname = [imf([1,2,4,9:14,16:19]),num2str(doy,'%03d'),imf([34,16,38:40])]; % Landsat Path will be given from .xml file later
end

%% sub function of creating row folder name
function foldername_rowdata = subFunRowFolderName(irow, irow_end)
    % row data's foldername R0000100010, which means the row 00001 to 00010
    foldername_rowdata = sprintf('R%05d%05d', irow, irow_end);
end

%% sub function of loading a certain band from the landsat data folder
function surf_b = subFunLoadSingleBand(imgfoler, imgname, specifyname)
    surf_b = geotiffread(fullfile(imgfoler, [imgname,'_' ,specifyname, '.tif']));
end