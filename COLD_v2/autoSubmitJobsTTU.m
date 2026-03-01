% This is to submit the job for each Landsat ARD Tile
addpath(pwd);
% ARDTiles = globalsets.getARDTiles('cold');
% ARDTiles = {'h004v009','h004v010','h014v009', 'h015v008', 'h016v008'};
ARDTiles = {'h014v009'};
totalcores = 13;
clusterName = 'quanah'; % quanah nocona 
sure2submit = true; % do not check the status

FolderJobs = 'HPCCJobsCOLD';
FileJobs = 'autoRunCOLD.sh';
path_job = fullfile(FolderJobs, FileJobs);
fid_in = fopen(path_job,'a+');
shfile=fscanf(fid_in,'%c',inf);

FileJobsReady = 'autoRunCOLDReady.sh';
path_job_ready = fullfile(FolderJobs, FileJobsReady);
curpath = pwd;
% have to CD the job folder
cd(fullfile(curpath, FolderJobs));
for iARD = 1: length(ARDTiles)
    
    hv_name = ARDTiles{iARD};
    %% examine the tiles are in being processed
    if ~sure2submit & contains(shfile, hv_name)
        fprintf('Job for %s has been submited in the past\r', hv_name);
        continue;
    else
        fprintf('Submitting Jobs for %s with %d cores\r', hv_name, totalcores);
    end
% % %     %% create the record of remaining rows
% % %     % calculate the rows without CCD results ahead of time
% % %     nrows = 5000;
% % %     dir_tsfit = fullfile(globalsets.PathCOLD, hv_name, globalsets.FolderTSFit);
% % %     irows = [];
% % %     for irow = 1: nrows
% % %         if ~isfile(fullfile(dir_tsfit, ['record_change',sprintf('%d',irow),'.mat']))
% % %             irows = [irows; irow];
% % %         end
% % %     end
% % %     recordfile = fullfile(globalsets.PathCOLD, hv_name, ...
% % %         [globalsets.FilenameRecordRemainRows, '.mat']);
% % %     %% in TTU, we do not need create the .mat ahead of time, because when mutiple cores read the same file, occurs may come
% % %     if isfile(recordfile)
% % %         delete(recordfile);
% % %         fprintf('Finished deleting the record file for the remain rows for %s\r', hv_name);
% % %     end
%     save(recordfile,'irows');
%     fprintf('Finished updating the record file for the remain rows for %s\r', hv_name);
    
    %% create the job file and submit it.
    shfile_ready = strrep(shfile, 'TileName', hv_name);
    shfile_ready = strrep(shfile_ready, 'ClusterName', clusterName);
    shfile_ready = strrep(shfile_ready, 'TotalCores', num2str(totalcores));
    shfile_ready = strrep(shfile_ready, '%', '%%'); % print %
    %open file identifier
    fid = fopen(FileJobsReady,'w');
    fprintf(fid, shfile_ready);
    fclose(fid);
    commandStr = sprintf('sbatch %s', FileJobsReady);
    system(commandStr);
%     fprintf('Job for %s has been submited successfully\r', hv_name);
%     fprintf(fid_in, ['\n# ', hv_name]);
    
    pause(10);
end
% come back
cd(curpath)
fclose all;