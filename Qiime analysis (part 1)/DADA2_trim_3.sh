#!/bin/bash
#SBATCH --account=def-sanrehan
#SBATCH --time=00:20:00
#SBATCH --mem=5G


module load StdEnv/2020 gcc/9.3.0 apptainer


apptainer run -B /scratch/mkc206:/temp -B /lustre06/project/6048691/mkc206/MetaData:/MetaData qimme2.sif qiime dada2 denoise-single \


--i-demultiplexed-seqs /temp/PathTo/InputFileName.qza \
--p-trunc-len 175 \
--p-trim-left 8 \
--o-representative-sequences /temp/PathTo/OutputFile_dada2.qza \
--o-table /temp/PathTo/OutputFileTable-dada2.qza \
--o-denoising-stats /temp/PathTo/OutputFileStats-dada2.qza \
--verbose