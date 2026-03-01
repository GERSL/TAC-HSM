%test path
folder_ARD = '/gpfs/sharedfs1/zhulab/Kexin/ARD_Fusion_BRDF/18TYM/';
ARDfiles = dir(fullfile(folder_ARD,'*18TYM*'));
folder_TOA = '/gpfs/sharedfs1/zhulab/Kexin/S2_CT_TOA/2015';
% years = {'2015',}
% for i = 1: length(ARDfiles)
L2Afiles = dir(fullfile(folder_TOA,'*18TYM*'));
for i = 1: length(L2Afiles)
    L2Afilename = split(L2Afiles(i).name,'_');
    orbit = L2Afilename(5);
    if orbit == 'R011'
        % find S2 images with 'R011' and copy the corresponding ARD to a
        % new directory
    else
        continue
    end
end
    

% IMGfiles = dir(fullfile(ARDfiles(1).folder,ARDfiles(1).name,'*10m.tif'));
%     IMG = geotiffread(fullfile(IMGfiles(1).folder,IMGfiles(1).name));
% info1 = geotiffinfo(fullfile(IMGfiles(end).folder,IMGfiles(end).name));
