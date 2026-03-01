#!/bin/bash
#SBATCH --partition=general
#SBATCH --account=zhz18039
#SBATCH --ntasks 1
#SBATCH --array 1-100
#SBATCH --output stack_HLS2.0_HLS_T18TYM.out
#SBATCH --mail-type ALL
#SBATCH --mail-user kexin.song@uconn.edu

# preprocessing funtions: 
# batchStackLandatARD2Line

cd /home/kes20012/COLD_v2/
module load matlab

#matlab -nodisplay -nosplash -singleCompThread -r "batchStackHLSv2Line('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX,'ARDTiles','18TXM','resolution',60);exit"

#matlab -nodisplay -nosplash -singleCompThread -r "batchStackHLSv2Line('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX,'ARDTiles','14SPJ','resolution',60);exit"
#matlab -nodisplay -nosplash -singleCompThread -r "batchStackHLSv2Line('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX,'ARDTiles','15RXQ','resolution',60);exit"
#matlab -nodisplay -nosplash -singleCompThread -r "batchStackHLSv2Line('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX,'ARDTiles','10SFG','resolution',60);exit"
#matlab -nodisplay -nosplash -singleCompThread -r "batchStackHLSv2Line('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX,'ARDTiles','13TCF','resolution',60);exit"
matlab -nodisplay -nosplash -singleCompThread -r "batchStackHLSv2Line('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX,'ARDTiles','18TYM','resolution',30,'sensor','HLS');exit"
exit
