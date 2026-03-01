classdef globalsets
    properties (Constant)
        %% Sets for CCD ###################
        %% Paths
        % [Required] Directory of original Landsat ARD with .tar, including surface reflectance and brightness temperature
        PathLandsatARD = '/gpfs/sharedfs1/zhulab/Shi/LandsatARD/';
        % year 2015-2020
%         PathS2ARD = '/gpfs/sharedfs1/zhulab/ARCHIVE/Kexin/Sentinel-2/ARD_BRDF_SR/';
        % year 2020-2021
%         PathS2ARD = '/shared/cn450/Sentinel-2/ARD_b_BRDF_2020_2021/'; 
        % year 2022-2023
        % PathS2ARD = '/shared/cn450/Mari/Sentinel-2/ARD_noresample/';
        % for other tiles
        % PathS2ARD = '/shared/cn450/Sentinel-2/ARD_BRDF_b10m/';
        PathS2ARD = '/gpfs/sharedfs1/zhulab/Kexin/Sentinel-2/';
        PathS2ARDFusion = '/gpfs/sharedfs1/zhulab/Kexin/ARD_Fusion_BRDF_2015_2020/';
        % for other tiles
        PathHLS = '/shared/cn450/DataHLSv1.4/';
         % for T18TXM
        PathHLSv2 = '/gpfs/sharedfs1/zhulab/Kexin/DataHLSv2.0/';
        % PathHLSv2 = '/shared/cn450/DataHLSv2.0/';
       

        PathCOLDS2 = '/scratch/zhz18039/kes20012/COLDS2Results/';
        PathCOLDHLSv2 = '/gpfs/sharedfs1/zhulab/Kexin/COLDHLSv2Results/';
        PathCOLDHLS10 = '/shared/cn450/Kexin/COLDTIFResults/';
        
        
%         PathGeneralAccumuDistmap = '/lustre/scratch/qiu25856/COLDResults/AccumuDistMaps';
        
        %% Folders
        FolderTSFit = 'TSFitMap';
        FolderChangeMap = 'ChangeMap';
        FolderSyntheticImage = 'SyntheticImage';
        FolderMask = 'MaskImage';
        
        %% Filenames
        FilenameDistMap = 'DisturbanceMap';
        FilenameDistCoeffs = 'ChangeCoeffs';
        FilenameDistMapAccumul = 'DisturbanceAccumuMap';
        FilenameRecordRemainRows = 'RecordRemainRows';
        
        %% Input File
%         PathARDTiles = 'pendingARDTiles_Shi.txt';
        PathARDTiles = 'pendingARDTiles_Prepare.txt';
        %% Parameters
        Years = 2015:2020;
%         Years = 1985:2019;
        LandsatCollectionVersion = '01';
        %% End of sets for CCD ###################
    end
    methods (Static)
        function id_status = checkRequirementsToCCD(ARDTileName)
            id_status = 0;
            % Requirements:
            % 1) stack data ready?
            % 2) extent.tif and nooverlap.tif ready?
            if 5000 == length(dir(fullfile(globalsets.PathCOLD, ARDTileName, globalsets.FolderTSFit, 'record_change*.mat')))
                id_return = 9;
                return;
            end
            % check STACK ok or not
            if length(dir(fullfile(globalsets.PathLandsatARD, hv_name, 'L*_SR.tar'))) == ...
                  length(dir(fullfile(globalsets.PathCOLD, hv_name, 'L*')))
    %                                 fprintf('Skip: Finished stacking for ARD Tile %s\n', hv_name);
                idsmore = [idsmore; iARD];
            end
        end
        function [ARDTiles, ARDTilesDone] = getARDTiles(checkStatus)
            ARDTiles = textread(globalsets.PathARDTiles, '%s');
            if exist('checkStatus', 'var')
                idsmore = [];
                switch lower(checkStatus)
                    case 'stack'
                        for iARD = 1: length(ARDTiles)
                            hv_name = ARDTiles{iARD};
                            % check COLD ok or not
                            if 5000 == length(dir(fullfile(globalsets.PathCOLD, hv_name, globalsets.FolderTSFit, 'record_change*.mat')))
%                                 fprintf('Skip: Finished CCD for ARD Tile %s\n', hv_name);
                                idsmore = [idsmore; iARD];
                                continue;
                            end
                            % check STACK ok or not
                            if length(dir(fullfile(globalsets.PathLandsatARD, hv_name, 'L*_SR.tar'))) == ...
                                  length(dir(fullfile(globalsets.PathCOLD, hv_name, 'L*')))
%                                 fprintf('Skip: Finished stacking for ARD Tile %s\n', hv_name);
                                idsmore = [idsmore; iARD];
                                continue;
                            end
                        end
                    case 'cold'
                        % check COLD ok or not
                        for iARD = 1: length(ARDTiles)
                            hv_name = ARDTiles{iARD};
                            if 5000 == length(dir(fullfile(globalsets.PathCOLD, hv_name, globalsets.FolderTSFit, 'record_change*.mat')))
%                                 fprintf('Skip: Finished CCD for ARD Tile %s\n', hv_name);
                                idsmore = [idsmore; iARD];
                                continue;
                            end
                        end
                    case 'changemap'
                        % check COLD map ok or not
                        for iARD = 1: length(ARDTiles)
                            hv_name = ARDTiles{iARD};
                            if length(dir(fullfile(globalsets.PathCOLD, hv_name, globalsets.FolderChangeMap, 'DisturbanceMap*.tif'))) == length(globalsets.Years)
%                                 fprintf('Skip: Finished exporting change maps for ARD Tile %s\n', hv_name);
                                idsmore = [idsmore; iARD];
                                continue;
                            end
                        end
                    case 'changecoeffs'
                        for iARD = 1: length(ARDTiles)
                            hv_name = ARDTiles{iARD};
                            matfiles = dir(fullfile(globalsets.PathCOLD, hv_name, globalsets.FolderChangeMap, 'DisturbanceCoeffs*.mat'));
                            
                            if length(matfiles) > 0
                          %      fprintf('Skip: Finished exporting change maps for ARD Tile %s\n', hv_name);
                               idsmore = [idsmore; iARD];
                               continue;
                            end
                        end
                end
                % eleliminate the tile name we have finished already
                if ~isempty(idsmore)
                    ARDTilesDone = ARDTiles(idsmore);
                    ARDTiles(idsmore) = [];
                else
                    ARDTilesDone = [];
                end
            end
        end
    end
end

%% Old version
% We do not read paramters from text file for avoiding I/O issues from hundred of cores.
% function myset = getMyset(str_para)
% %GETMYSET read my sets from local text file
%     fid_in = fopen('mysets.txt','r');
%     mysets=fscanf(fid_in,'%c',inf);
%     fclose(fid_in);
%     mysets=mysets';
%     mysets=strread(mysets,'%s');
%     myset = mysets{strmatch(str_para,mysets)+2};
% end

