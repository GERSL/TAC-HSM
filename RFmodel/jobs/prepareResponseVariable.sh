#!/bin/bash
#SBATCH -J prepareRFinput
#SBATCH --partition=general
##SBATCH --partition=priority
#SBATCH --account=zhz18039
##SBATCH --qos=zhz18039epyc
#SBATCH --ntasks 1
#SBATCH --array 1-294
#SBATCH -o log/%x-out-%A_%4a.out
#SBATCH -e log/%x-err-%A_%4a.err
#SBATCH --mail-type END
#SBATCH --mail-user kexin.song@uconn.edu

echo $SLURMD_NODENAME
cd /home/kes20012/ProjectTACValidation/RFmodel
module load matlab

matlab -nojvm -nodisplay -nosplash -singleCompThread -r "prepareResponseVariable('ci',$SLURM_ARRAY_TASK_ID, 'cn',$SLURM_ARRAY_TASK_MAX');exit"
#matlab -nojvm -nodisplay -nosplash -singleCompThread -r "prepareResponseVariableFieldSample('ci',$SLURM_ARRAY_TASK_ID, 'cn',$SLURM_ARRAY_TASK_MAX');exit"




