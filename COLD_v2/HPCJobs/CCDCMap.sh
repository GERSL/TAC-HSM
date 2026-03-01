#!/bin/bash
#SBATCH --partition general
#SBATCH --exclude=cn373
#SBATCH --ntasks 1
#SBATCH --array 1-1
#SBATCH --output CCDCMapT18TYM.out

# cd /home/shq19004/Code/COLD_v2/
cd /home/kes20012/COLD_v2/Export/
module load matlab/2019b
matlab -nodisplay -nosplash -singleCompThread -r "exportChangeMap;exit"

