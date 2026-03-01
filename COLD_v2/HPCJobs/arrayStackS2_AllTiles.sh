#!/bin/bash
#SBATCH --partition=general
#SBATCH --account=zhz18039
#SBATCH --ntasks 1
#SBATCH --mem-per-cpu=10G
#SBATCH --array 1-200
#SBATCH --output stack_S2_T8TXM.out
#SBATCH --mail-type END
#SBATCH --mail-user kexin.song@uconn.edu

# preprocessing funtions: 
# batchStackLandatARD2Line

cd /home/kes20012/COLD_v2/
module load matlab
matlab -nodisplay -nosplash -singleCompThread -r "batchStackS2ARD2Line('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX, 'ARDTiles','18TXM','resolution',10);exit"
#matlab -nodisplay -nosplash -singleCompThread -r "batchStackS2ARD2Line('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX, 'ARDTiles','15RXQ','resolution',20);exit"
#matlab -nodisplay -nosplash -singleCompThread -r "batchStackS2ARD2Line('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX, 'ARDTiles','14SPJ','resolution',10);exit"
#matlab -nodisplay -nosplash -singleCompThread -r "batchStackS2ARD2Line('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX, 'ARDTiles','13TCF','resolution',10);exit"
#matlab -nodisplay -nosplash -singleCompThread -r "batchStackS2ARD2Line('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX, 'ARDTiles','10SFG','resolution',20);exit"

#matlab -nodisplay -nosplash -singleCompThread -r "batchStackS2ARD2Line('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX, 'ARDTiles','14SPJ','resolution',20);exit"
#matlab -nodisplay -nosplash -singleCompThread -r "batchStackS2ARD2Line('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX, 'ARDTiles','13TCF','resolution',20);exit"
exit
