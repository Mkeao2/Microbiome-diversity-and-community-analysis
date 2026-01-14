#!/bin/bash
#SBATCH --account=def-sanrehan
#SBATCH --time=00:20:00
#SBATCH --mem=7GB


module load StdEnv/2020 gcc/9.3.0 apptainer


apptainer run -B /scratch/UserID:/temp -B /lustre06/project/6048691/UserID/Pathto:/SeqFilesDirectory qimme2.sif qiime tools import \
 --type 'SampleData[SequencesWithQuality]' \
 --input-path /temp/PathTo/ManifestFileName.tsv  \
 --output-path /temp/OutputFileName.qza \
 --input-format SingleEndFastqManifestPhred33V2
