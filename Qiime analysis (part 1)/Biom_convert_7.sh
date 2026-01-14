#!/bin/bash
#SBATCH --account=def-sanrehan
#SBATCH --time=00:10:00
#SBATCH --mem=1G


module load StdEnv/2023 gcc/12.3 r-bundle-bioconductor/3.18


biom convert -i newtable.biom -o new.biomtable.txt --to-tsv