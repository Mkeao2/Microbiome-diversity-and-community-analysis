#!/bin/bash
#SBATCH --account=def-sanrehan # The account to use
#SBATCH --time=24:00:00 # The duration in HH:MM:SS format of ea
#SBATCH --cpus-per-task=1
#SBATCH --mem=64G # The memory per core for each task in the array
#SBATCH --array=0-8


module load StdEnv/2023 gcc/12.3 blast+/2.14.1


blastn -outfmt "7 qseqid qacc sseqid sacc pident length mismatch gapopen staxids sscinames scomnames" -max_hsps 1 -max_target_seqs 1 -perc_identity 80 \
-db /cvmfs/ref.mugqic/genomes/blast_db/nt -query filename.seq0${SLURM_ARRAY_TASK_ID}.fa -out filename.ref.${SLURM_ARRAY_TASK_ID}
