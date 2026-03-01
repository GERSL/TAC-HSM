function accumulateChangeMap(folderpath_cold, years, varargin)
% ACCUMULATECHANGEMAP This is to create the accumulated change map based on
% the yearly change maps in the folder <ChangeMap>
%
% INPUT:
%
%   folderpath_cold:        Locate to COLD working folder, in which the
%                           change folder <TSFitLine> is necessery, and
%                           this folder was created by <COLD.m>.
%
%   years:                  [Array] The years of change map. 
%
%   ctype (optional):       {'all', 'regrowth', 'disturbance'} which change type?
%
%   minsize (optional):     Mininum size of change object in each year.(default value is 1). 
%
%   msg (optional):         [false/true] Display processing status (default
%                           value: false)
% 
%
% OUTPUT:
%
% accuchangemap_ctype_yyyy_yyyy.tif in folder <ChangeMap> (ctype means the change type and yyyy means the year)
% uint16
% pixel value: xdoy (x indicates the type of change, and doy indicates DOY) 
% x's range is between 1 to 3
% 1 => regrowth break
% 2 => aforestation break
% 3 => land disturbance
%
% i.e., 1002 means the regrowth break occured in the 2nd day
%
%
% REFERENCE(S):
%
%   Zhu, Zhe, et al. "Continuous monitoring of land disturbance based on
%   Landsat time series." Remote Sensing of Environment 238 (2020): 111116.
%
% EXAMPLE OF USE:
%
%   > To export change maps between 1985 and 2019 (without labling change type).
%
%     exportChangeMap('/lustre/scratch/qiu25856/TestGERSToolbox/h029v005/',
%     [1985:2019])
% 
% AUTHOR(s): Zhe Zhu and Shi Qiu
% DATE: Feb. 7, 2021
% COPYRIGHT @ GERSLab


addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'GRIDobj'));
% folderpath_cold = '/shared/cn450/Sentinel-2/COLDResults/18TXM/';
folderpath_cold = '/shared/cn450/Kexin/COLDTIFResults/15RXQ/';
Years = [2015:2021];
for iyear = 2021
    
    years = 2013:iyear;
 
    % optional
    p = inputParser;
    addParameter(p,'minsize', 1); % all size change object
    addParameter(p,'ctype', 'disturbance'); % default change type is disturbance
    addParameter(p,'msg', false); % not to display info
    parse(p,varargin{:});
    minsize = p.Results.minsize;
    msg = p.Results.msg;
    ctype = p.Results.ctype;

    tic
    [~, foldername_working] = fileparts(folderpath_cold);
    if msg
        fprintf('Start to accumulate change maps with %s change between %d and %d for %s\r\n', ctype, min(years), max(years), foldername_working);
    end

    % mapfolder = fullfile(folderpath_cold, 'ChangeMap_t=1day_robustfit');
    mapfolder = '/gpfs/scratchfs1/zhz18039/kes20012/COLDHLS10Results/18TXM/Change_Map/CONSE_6_changeProb_0.95/';
%     mapfolder = fullfile(folderpath_cold, 'CCDCMap_t=1day_robustfit');
% %     % mapfolder = fullfile(folderpath_cold, 'ChangeMapConse4');
%     mapfolder = fullfile(folderpath_cold, 'CCDCMap_9bands');

    accmap_outfilepath = fullfile(mapfolder, ...
        sprintf('%s_%s_%d_%d.tif', 'accuchangemap', ctype, min(years), max(years)));

    accMapGridobj = [];

    %% typedoy data first
    distmap_name = 'changemap_typedoy';
    yearlymaps = dir(fullfile(mapfolder, 'changemap_typedoy_*.tif')); % this has all values
    if isempty(yearlymaps)
        distmap_name = 'changemap_doy';
        yearlymaps = dir(fullfile(mapfolder, 'changemap_doy_*.tif')); % this has no change type info
    end

    %% Check files are ready
    if isempty(yearlymaps)
        fprintf('No yearly change maps at %s!\r\n', mapfolder);
        return;
    else
        years_nomap = [];
        for imap = 1: length(years)
            yr = years(imap);
            yearlymap_filepath = fullfile(mapfolder, [distmap_name, '_', num2str(yr),'.tif']);
            if ~isfile(yearlymap_filepath)
                years_nomap = [years_nomap; yr];
            end
        end
        if ~isempty(years_nomap)
            fprintf('No yearly change maps for Years %d!\r', years_nomap);
            return;
        end
    end

    %% Calculate the accumulated map
    for imap = 1: length(years)
        yr = years(imap);
        if msg
            fprintf('Accumulating the change map for year %d\r', yr);
        end
        yearlymap_filepath = fullfile(mapfolder, [distmap_name, '_', num2str(yr),'.tif']);
        if isempty(accMapGridobj)
%             load(fullfile(folderpath_cold, 'metadata.mat'));
%             accMapGridobj = metadata.GRIDobj;
            accMapGridobj = GRIDobj(yearlymap_filepath); % first map gives to trget map
            % select which change type
            switch ctype
                case 'regrowth' % 1000
                    accMapGridobj.Z(accMapGridobj.Z>1000) = 0; % exclude aforest and disturbance
                case 'disturbance' % 3000
                    accMapGridobj.Z(accMapGridobj.Z<2000) = 0; % exclude regrowth
            end

            mask_changmap = accMapGridobj.Z >0& accMapGridobj.Z < 9999;

            if minsize > 1
                mask_changmap = mask_changmap & bwareaopen(mask_changmap, minsize, 8); % remove small objects with 8-conn
            end
            accMapGridobj.Z(mask_changmap) = yr;
            accMapGridobj.Z(~mask_changmap) = 9999; % label as 9999 for the removed pixels. 
            clear yearlymap_filepath mask_changmap;
            continue;
        end
        yearlymap = GRIDobj(yearlymap_filepath);

        % select which change type
        switch ctype
    %         case 'all' % do not need to select
            case 'regrowth' % 1000
                yearlymap.Z(yearlymap.Z>1000) = 0; % exclude aforest and disturbance
    %         case 'afforest' % 2000 % that will be included into disturbance
            case 'disturbance' % 3000
                yearlymap.Z(yearlymap.Z<2000) = 0; % exclude regrowth
        end

        mask_changmap = yearlymap.Z >0& yearlymap.Z < 9999;

        if minsize > 1
            mask_changmap = mask_changmap & bwareaopen(mask_changmap, minsize, 8);  % remove small objects with 8-conn
        end
        accMapGridobj.Z(mask_changmap) = yr;
        clear yearlymap yearlymap_filepath mask_changmap;
    end
    accMapGridobj.Z = uint16(accMapGridobj.Z);
    % save out
    GRIDobj2geotiff(accMapGridobj, accmap_outfilepath);
    % % % save out as a folder
    % % if ~isempty(outputfolder)
    % %     copyfile(accmap_outfilepath, outputfolder);
    % % end


    if msg
        fprintf('Finished accumluting change maps for %s with %0.2f mins\r\n', foldername_working, toc/60); 
    end
end
end


