
folderpath_mfile = fileparts(mfilename('fullpath'));
addpath(folderpath_mfile);
addpath(fullfile(folderpath_mfile, 'Clear'));
addpath(fullfile(folderpath_mfile, 'Export'));
addpath(fullfile(folderpath_mfile, 'Plot'));

ARDTiles = {'h029v005'}; %% new england area

folderpath_parentwork = globalsets.PathCOLD;

for iARD = 1: length(ARDTiles)
    hv_name = ARDTiles{iARD};
    folderpath_tilecold = fullfile(folderpath_parentwork, hv_name);
   
    %% Export change maps for mutiple years
%     exportChangeMap(folderpath_tilecold, [1985: 2019], 'msg', true);
%     
    %% Accumulate changes to display the most recent changes
%     accumulateChangeMap(folderpath_tilecold, [1985: 2019], 'ctype', 'disturbance', 'msg', true);
    
    %% Create synthetic image
%     createSyntheticImage(folderpath_tilecold, 2019, 7, 1, 'msg', true);
    
    %% Display time series for a cerain pixel
    % It is recommanded to download stacking data to local computer for displaying the time series
%     displaybands = { 'Blue', 'Green',  'Red'};
%     daterange =[datenummx(1984,1,1), datenummx(2015, 6, 1)];
%     plotTimeSeries('C:\Users\qsly0\Downloads\test_cold_v2\h029v005\', 2500, 9, 'displaybands', displaybands, 'daterange', daterange);

    %% Clear all the stack datset once change detection done
%     clearStackData(folderpath_tilecold, true);
    
end