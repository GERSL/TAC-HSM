#!/bin/bash
#SBATCH --partition general
#SBATCH --exclude=cn373
#SBATCH --ntasks 1
#SBATCH --array 1-50
#SBATCH --output savesamples_18TXM.out

# preprocessing funtions: 
# batchStackLandatARD2Line

cd /home/kes20012/COLD_v2/
module load matlab/2019b
matlab -nodisplay -nosplash -singleCompThread -r "batchSaveSampleTS('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX, 'ARDTiles','18TXM','sensor','HLS');exit"
exit
