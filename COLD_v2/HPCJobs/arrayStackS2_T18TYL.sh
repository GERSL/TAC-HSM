#!/bin/bash
#SBATCH --partition=general
#SBATCH --account=zhz18039
#SBATCH --ntasks 1
#SBATCH --array 1-100
#SBATCH --mem-per-cpu 10G
#SBATCH --output stack_T18TYL.out
#SBATCH --mail-type ALL
#SBATCH --mail-user kexin.song@uconn.edu

# preprocessing funtions: 
# batchStackLandatARD2Line

cd /home/kes20012/COLD_v2/
module load matlab
matlab -nodisplay -nosplash -singleCompThread -r "batchStackS2ARD2Line('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX, 'ARDTiles','18TYL','resolution',10);exit"
exit
