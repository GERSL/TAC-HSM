#!/bin/bash
#SBATCH --partition=EpycPriority
#SBATCH --account=zhz18039
#SBATCH --ntasks 1
#SBATCH --array 1-1
#SBATCH --output ChanageMagnitudeMap_18TYL.out
#SBATCH --mail-user=kexin.song@uconn.edu


cd /home/kes20012/COLD_v2/Export_v2/
module load matlab/2019b
matlab -nodisplay -nosplash -singleCompThread -r "exportChangeMagnitudeMap('/shared/cn451/Kexin/COLDHLSResults/18TYL/');exit"

