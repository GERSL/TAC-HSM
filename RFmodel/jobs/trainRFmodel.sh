#!/bin/bash
#SBATCH -J trainRFmodel
#SBATCH --partition=general
##SBATCH --partition=priority
#SBATCH --account=zhz18039
##SBATCH --qos=zhz18039epyc
#SBATCH --ntasks 1
#SBATCH --array 1-196
#SBATCH -o log/%x-out-%A_%4a.out
#SBATCH -e log/%x-err-%A_%4a.err
#SBATCH --mail-type END
#SBATCH --mail-user kexin.song@uconn.edu

echo $SLURMD_NODENAME
cd /home/kes20012/ProjectTACValidation/RFmodel
module load matlab

matlab -nojvm -nodisplay -nosplash -singleCompThread -r "trainRFmodel('ci',$SLURM_ARRAY_TASK_ID, 'cn',$SLURM_ARRAY_TASK_MAX');exit"




