#!/bin/bash
#SBATCH --account=def-sanrehan
#SBATCH --time=00:10:00
#SBATCH --mem=1G


module load StdEnv/2020 gcc/9.3.0 apptainer


apptainer run -B /scratch/mkc206:/temp -B /lustre06/project/6048691/mkc206/MetaData:/MetaData qimme2.sif qiime tools export \
--input-path /temp/quality_files/OutputFileTable-dada2.qza
--output-path /temp/exported-feature-table