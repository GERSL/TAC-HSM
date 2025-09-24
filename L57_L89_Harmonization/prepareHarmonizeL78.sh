#!/bin/bash
#SBATCH -J prepareL78data
#SBATCH --partition=general
#SBATCH --account=zhz18039
#SBATCH --mem-per-cpu=2G
#SBATCH --constraint='epyc128'
#SBATCH --ntasks=1
#SBATCH --array 1-100
#SBATCH -o log/%A_%a.out
#SBATCH -e log/%A_%a.err
#SBATCH --mail-type END
#SBATCH --mail-user kexin.song@uconn.edu


module load matlab

echo $SLURMD_NODENAME # display the node name

cd /home/kes20012/ProjectTACValidation/L57_L89_Harmonization
matlab -nojvm -nodisplay -nosplash -singleCompThread -r "prepareHarmonizeL78('task',$SLURM_ARRAY_TASK_ID, 'ntasks',$SLURM_ARRAY_TASK_MAX');exit"
