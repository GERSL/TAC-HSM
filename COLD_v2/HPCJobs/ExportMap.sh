#!/bin/bash
#SBATCH --partition=EpycPriority
#SBATCH --account=zhz18039
#SBATCH --ntasks 1
#SBATCH --array 1-1
#SBATCH --output CCDCMapT18TYM.out
#SBATCH --mail-user=kexin.song@uconn.edu


cd /home/kes20012/COLD_v2/Export/
module load matlab/2019b
matlab -nodisplay -nosplash -singleCompThread -r "exportChangeMap('/shared/cn450/Kexin/COLDTIFResults/18TYM/');exit"

