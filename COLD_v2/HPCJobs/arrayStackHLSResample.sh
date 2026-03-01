#!/bin/bash
#SBATCH --partition=general
#SBATCH --account=zhz18039
#SBATCH --ntasks 2
#SBATCH --array 1-100
#SBATCH --output stack_T14SPJ.out
#SBATCH --mail-type ALL
#SBATCH --mail-user kexin.song@uconn.edu

# preprocessing funtions: 
# batchStackLandatARD2Line

cd /home/kes20012/COLD_v2/
module load matlab
matlab -nodisplay -nosplash -singleCompThread -r "batchStackHLSResampleLine('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX, 'ARDTiles','14SPJ');exit"
exit
