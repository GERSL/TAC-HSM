#!/bin/bash
#SBATCH --partition=EpycPriority
#SBATCH --account=zhz18039
#SBATCH --ntasks 1
#SBATCH --array 1-1
#SBATCH --output MagMapT18.out

# cd /home/shq19004/Code/COLD_v2/
cd /home/kes20012/COLD_v2/Export/
module load matlab/2019b
matlab -nodisplay -nosplash -singleCompThread -r "ShowDistMagMaps('ARDTiles',{'18TYM','18TYL','18TXL'});exit"

