#!/bin/bash
#SBATCH --partition general
#SBATCH --exclude=cn373
#SBATCH --ntasks 2
#SBATCH --array 1-200
#SBATCH --output plot_T18TYM.out

# cd /home/shq19004/Code/COLD_v2/
cd /home/kes20012/COLD_v2/
module load matlab/2019b
matlab -nodisplay -nosplash -singleCompThread -r "batchplotTSFitsamples('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX, 'ARDTiles','18TYM');exit"

