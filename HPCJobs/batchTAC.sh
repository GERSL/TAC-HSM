#!/bin/bash
#SBATCH --partition=general
##SBATCH --partition=priority
#SBATCH --account=zhz18039
##SBATCH --qos=zhz18039epyc
#SBATCH --ntasks 1
#SBATCH --array 1-200
#SBATCH --output batchTAC.out
#SBATCH --mail-type END
#SBATCH --mail-user kexin.song@uconn.edu

echo $SLURMD_NODENAME
cd /home/kes20012/ProjectTACValidation
module load matlab

#matlab -nojvm -nodisplay -nosplash -singleCompThread -r "runTAC_Landsat_allForestPixels('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','remove_outliers',1,'composite_interval','bimonthly');exit"

matlab -nojvm -nodisplay -nosplash -singleCompThread -r "runTAC_Landsat_allSample('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','remove_outliers',1,'composite_interval','quarterly');exit"

#matlab -nojvm -nodisplay -nosplash -singleCompThread -r "runTAC_Landsat_allSample('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','remove_outliers',1,'composite_interval','bimonthly');exit"
#matlab -nojvm -nodisplay -nosplash -singleCompThread -r "runTAC_Landsat_allSample('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','remove_outliers',1,'composite_interval','monthly');exit"
#matlab -nojvm -nodisplay -nosplash -singleCompThread -r "runTAC_Landsat_allSample('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','remove_outliers',1,'composite_interval','biweekly');exit"








