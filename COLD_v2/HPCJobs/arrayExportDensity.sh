#!/bin/bash
#SBATCH --partition=priority
#SBATCH --account=zhz18039
#SBATCH --ntasks 1
#SBATCH --array 1-36
#SBATCH --output exportTSdensity_18TXM.out
#SBATCH --mail-type ALL
#SBATCH --mail-user kexin.song@uconn.edu

echo $SLURMD_NODENAME
cd /home/kes20012/COLD_v2/
module load matlab
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "exportTSDensity('/shared/cn450/Kexin/COLDS2Results/18TXM/','task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX);exit"

