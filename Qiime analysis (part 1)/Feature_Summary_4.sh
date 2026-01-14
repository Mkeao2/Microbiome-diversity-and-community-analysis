#!/bin/bash
#SBATCH --account=def-sanrehan
#SBATCH --time=00:20:00
#SBATCH --mem=5G


module load StdEnv/2020 gcc/9.3.0 apptainer


apptainer run -B /scratch/mkc206:/temp -B /lustre06/project/6048691/mkc206/MetaDataDirectory :/MetaDataDirectory qimme2.sif qiime feature-table summarize \
--i-table OutputFileTable-dada2.qza \
--o-visualization OutputFileTable-dada2.qzv \
--m-sample-metadata-file sample-metadata.tsv


apptainer run -B /scratch/mkc206:/temp -B /lustre06/project/6048691/mkc206/MetaDataDirectory :/MetaDataDirectory qimme2.sif qiime feature-table tabulate-seqs \
--i-data OutputFile_dada2.qza \
--o-visualization OutputFile_dada2.qzv \ 


apptainer run -B /scratch/mkc206:/temp -B /lustre06/project/6048691/mkc206/MetaData:/MetaData qimme2.sif qiime metadata tabulate \
--m-input-file OutputFileStats-dada2.qza
--o-visualization OutputFileStats-dada2.qzv