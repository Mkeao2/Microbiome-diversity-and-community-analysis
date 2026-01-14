#!/bin/bash
#SBATCH --account=def-sanrehan
#SBATCH --time=00:05:00
#SBATCH --mem=7GB


module load StdEnv/2020 gcc/9.3.0 apptainer


apptainer run -B /scratch/UserID:/temp -B /lustre06/project/6048691/UserID/Directorywithseqfiles/Directorywithseqfiles qimme2.sif qiime demux summarize \
--i-data /temp/reads_files/InputFileName.qza \
--output-dir /temp/OutputFileName.qzv