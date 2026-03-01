#!/bin/bash
#SBATCH --partition=EpycPriority
#SBATCH --account=zhz18039
#SBATCH --exclude=cn[66-69,341,345-353,373,383],gpu[07-10]
#SBATCH --ntasks 1
#SBATCH --array 1-20
#SBATCH --output COLD_T15RXQ_doTIF.out
#SBATCH --mail-type ALL
#SBATCH --mail-user kexin.song@uconn.edu

cd /home/kes20012/COLD_v2/
module load matlab/2020b
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "batchCOLD('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX, 'ARDTiles','15RXQ','doTIF',true);exit"

