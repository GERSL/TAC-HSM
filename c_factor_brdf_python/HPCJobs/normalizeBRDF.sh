#!/bin/bash
#SBATCH -J NormalizeBRDFL5
#SBATCH --partition=general
#SBATCH --account=zhz18039
#SBATCH --mem-per-cpu=10G
#SBATCH --constraint='epyc128'
#SBATCH --ntasks=1
#SBATCH --array 1-200
#SBATCH -o log/%A_%a.out
#SBATCH -e log/%A_%a.err
#SBATCH --mail-type END
#SBATCH --mail-user kexin.song@uconn.edu


. "/home/kes20012/miniconda3/etc/profile.d/conda.sh"  # startup conda
conda activate BRDF_HLS

echo $SLURMD_NODENAME # display the node name
cd /home/kes20012/c_factor_brdf_python/
python normalizeBRDF_L5_2000_2013.py --ci=$SLURM_ARRAY_TASK_ID --cn=$SLURM_ARRAY_TASK_MAX
