#!/bin/bash
#SBATCH -J Stack
#SBATCH -p quanah
#SBATCH -o arraystack-%A_%a.out
#SBATCH -e arraystack-%A_%a.err
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -t 2:00:00
#SBATCH -a 1-200:1

#The variable $SLURM_ARRAY_TASK_ID is the ID for this task. 
#The variable $SLURM_ARRAY_TASK_MIN is the ID for the first task. 
#The variable $SLURM_ARRAY_TASK_MAX is the ID for the last task. 
cd /home/kes20012/COLD_v2/
module load matlab/R2020a
matlab -nodisplay -singleCompThread -r "batchStackLandatARD2Line($SLURM_ARRAY_TASK_ID, $SLURM_ARRAY_TASK_MAX); exit"


#The variable $SLURM_ARRAY_JOB_ID is the ID for the entire array job
#The variable $SLURM_JOB_ID is the ID for each job in the array 
echo "Array Job ID: $SLURM_ARRAY_JOB_ID"
echo "Job ID: $SLURM_JOB_ID" 
echo "Task ID: $SLURM_ARRAY_TASK_ID" 
echo "First or last: $position"
