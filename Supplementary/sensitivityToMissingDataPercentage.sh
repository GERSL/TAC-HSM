#!/bin/bash
#SBATCH --job-name=sensitivity        # Job name
#SBATCH --output=logs/sensitivity.out # Standard output and error log
#SBATCH --error=logs/sensitivity.err  # Separate error log (optional)
#SBATCH --partition=general
##SBATCH --partition=priority
#SBATCH --account=zhz18039
##SBATCH --qos=zhz18039epyc
#SBATCH --ntasks 1
#SBATCH --array 1-1
#SBATCH --mail-type END
#SBATCH --mail-user kexin.song@uconn.edu

echo $SLURMD_NODENAME
cd /home/kes20012/ProjectTACValidation/Supplementary
module load matlab

#matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','biweekly','missing_data_pct',0.6);exit"
#matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','biweekly','missing_data_pct',0);exit"
#matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','biweekly','missing_data_pct',0.1);exit"
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','biweekly','missing_data_pct',0.2);exit"
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','biweekly','missing_data_pct',0.3);exit"
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','biweekly','missing_data_pct',0.4);exit"
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','biweekly','missing_data_pct',0.5);exit"
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','biweekly','missing_data_pct',0.7);exit"
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','biweekly','missing_data_pct',0.8);exit"
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','biweekly','missing_data_pct',0.9);exit"

#
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','monthly','missing_data_pct',0);exit"
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','monthly','missing_data_pct',0.1);exit"
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','monthly','missing_data_pct',0.2);exit"
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','monthly','missing_data_pct',0.3);exit"
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','monthly','missing_data_pct',0.4);exit"
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','monthly','missing_data_pct',0.5);exit"
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','monthly','missing_data_pct',0.6);exit"
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','monthly','missing_data_pct',0.7);exit"
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','monthly','missing_data_pct',0.8);exit"
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','monthly','missing_data_pct',0.9);exit"



matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','bimonthly','missing_data_pct',0);exit"
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','bimonthly','missing_data_pct',0.1);exit"
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','bimonthly','missing_data_pct',0.2);exit"
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','bimonthly','missing_data_pct',0.3);exit"
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','bimonthly','missing_data_pct',0.4);exit"
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','bimonthly','missing_data_pct',0.5);exit"
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','bimonthly','missing_data_pct',0.6);exit"
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','bimonthly','missing_data_pct',0.7);exit"
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','bimonthly','missing_data_pct',0.8);exit"
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','bimonthly','missing_data_pct',0.9);exit"
#
#
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','quarterly','missing_data_pct',0);exit"
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','quarterly','missing_data_pct',0.1);exit"
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','quarterly','missing_data_pct',0.2);exit"
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','quarterly','missing_data_pct',0.3);exit"
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','quarterly','missing_data_pct',0.4);exit"
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','quarterly','missing_data_pct',0.5);exit"
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','quarterly','missing_data_pct',0.6);exit"
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','quarterly','missing_data_pct',0.7);exit"
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','quarterly','missing_data_pct',0.8);exit"
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "sensitivityToMissingDataPercentage('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX','composite_interval','quarterly','missing_data_pct',0.9);exit"
#







