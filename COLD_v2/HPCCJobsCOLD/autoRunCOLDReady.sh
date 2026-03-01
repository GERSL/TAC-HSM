#!/bin/bash
#SBATCH -J h014v009
#SBATCH -p quanah
#SBATCH -o Dh014v009-%A_%a.out
#SBATCH -e h014v009-%A_%a.err
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -t 6:00:00
#SBATCH -a 1-500:1


module load matlab
matlab -nodisplay -singleCompThread -r "cd /home/qiu25856/COLDAuto_CONUS_AppendChangeInterval/; addpath('/home/qiu25856/COLDAuto_CONUS_AppendChangeInterval/'); batchRunCOLDCONUS($SLURM_ARRAY_TASK_ID, $SLURM_ARRAY_TASK_MAX, 'h014v009'); exit"
# keep this line to ensure newline

if [[ $SLURM_ARRAY_TASK_ID == $SLURM_ARRAY_TASK_MIN ]]; then 
	position="first" 
elif [[ $SLURM_ARRAY_TASK_ID == $SLURM_ARRAY_TASK_MAX ]]; then 
	position="last" 
else 
	position="neither" 
fi

#The variable $SLURM_ARRAY_JOB_ID is the ID for the entire array job
#The variable $SLURM_JOB_ID is the ID for each job in the array 
echo "Array Job ID: $SLURM_ARRAY_JOB_ID"
echo "Job ID: $SLURM_JOB_ID" 
echo "Task ID: $SLURM_ARRAY_TASK_ID" 
echo "First or last: $position"


# History ARD Tiles
# h002v009
# h002v010
# h002v011
# h003v009
# h003v010
# h003v011
# h004v009
# h004v010
# h004v011
# h006v002
# h006v003
# h006v004
# h007v002
# h007v003
# h007v004
# h028v004
# h028v005
# h028v006
# h029v004
# h029v005
# h029v006
# h030v004
# h030v005
# h030v006
# h008v002
# h008v003
# h008v004
# h020v013
# h020v014
# h020v015
# h021v013
# h021v014
# h021v015
# h022v013
# h022v014
# h022v015
# h006v002
# h006v003
# h008v004
# h020v013
# h020v015
# h021v014
# h021v015
# h022v013
# h022v014
# h014v008
# h014v010
# h015v008
# h015v009
# h015v010
# h016v008
# h016v009
# h016v010
# h020v016
# h021v016
# h022v016
# h020v016
# h020v016
# h020v016