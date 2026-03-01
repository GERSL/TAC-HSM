#!/bin/bash
#SBATCH --partition=general
#SBATCH --account=zhz18039
#SBATCH --ntasks 1
#SBATCH --array 1-250
#SBATCH --output stack_L30_All_60m.out

# preprocessing funtions: 
# batchStackLandatARD2Line

cd /home/kes20012/COLD_v2/
module load matlab
matlab -nodisplay -nosplash -singleCompThread -r "batchStackHLSLine('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX,'resolution',60);exit"
# matlab -nodisplay -nosplash -singleCompThread -r "batchStackHLSLine('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX, 'ARDTiles','15RXQ','resolution',60);exit"
# matlab -nodisplay -nosplash -singleCompThread -r "batchStackHLSLine('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX, 'ARDTiles','18TXM','resolution',60);exit"
# matlab -nodisplay -nosplash -singleCompThread -r "batchStackHLSLine('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX, 'ARDTiles','14SPJ','resolution',60);exit"
# matlab -nodisplay -nosplash -singleCompThread -r "batchStackHLSLine('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX, 'ARDTiles','13TCF','resolution',60);exit"
# matlab -nodisplay -nosplash -singleCompThread -r "batchStackHLSLine('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX, 'ARDTiles','10SFG','resolution',60);exit"
exit
