#!/bin/bash
#SBATCH --partition=general
#SBATCH --ntasks 1
#SBATCH --array 1-200
#SBATCH -o COLD_HLSv2_T18TXM.out
#SBATCH -e COLD_HLSv2_T18TXM.err
#SBATCH --mail-type END
#SBATCH --mail-user kexin.song@uconn.edu

cd /home/kes20012/COLD_v2/
module load matlab
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "batchCOLD('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX, 'ARDTiles','18TXM');exit"
# matlab -nojvm -nodisplay -nosplash -singleCompThread -r "batchCOLD('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX, 'ARDTiles','13TCF','doTIF',false);exit"

