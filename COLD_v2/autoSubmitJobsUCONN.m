% This is to submit the job for each Landsat ARD Tile
addpath(pwd);

ARDTiles = globalsets.getARDTiles('cold');

% ARDTiles = {'h004v009','h004v010','h014v009', 'h015v008', 'h016v008'};

FolderJobs = 'HPCJobsCOLD';
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

    %% create the record of remaining rows
    % calculate the rows without CCD results ahead of time
    nrows = 5000;
    dir_tsfit = fullfile(globalsets.PathCOLD, hv_name, globalsets.FolderTSFit);
    irows = [];
    for irow = 1: nrows
        if ~isfile(fullfile(dir_tsfit, ['record_change',sprintf('%d',irow),'.mat']))
            irows = [irows; irow];
        end
    end
    save(fullfile(globalsets.PathCOLD, hv_name, ...
        [globalsets.FilenameRecordRemainRows, '.mat']),'irows');
    
    
    %% create the job file and submit it.
    if contains(shfile, hv_name)
        fprintf('Job for %s has been submited in the past\r', hv_name);
        continue;
    end
    
    shfile_ready = strrep(shfile, 'TileName', hv_name);
    shfile_ready = strrep(shfile_ready, '\', '\\'); % print %
    %open file identifier
    fid = fopen(FileJobsReady,'w');
    fprintf(fid, shfile_ready);
    fclose(fid);
    commandStr = sprintf('sbatch %s', FileJobsReady);
    system(commandStr);
%     fprintf('Job for %s has been submited successfully\r', hv_name);
    fprintf(fid_in, ['\n# ', hv_name]);
    
    
    pause(5);
end
% come back
cd(curpath)
fclose(fid_in);