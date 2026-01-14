# Microbiome Metabarcoding Workflow for 16S, ITS, and RBCL  

**Part 0: Set-up Qiime2**  

Download forward reads from dropbox (.fastq)  
If provided by the sequencing company, I1 and I2 are index files. R1 are forward and R2 are reverse reads. We are working with single end reads with only forward paths to increase sequencing depth.  

Set up Apptainer within the ‘scratch’ directory- This is where all commands should be run from.  Qiime is now a module that you can load and run in Apptainer (like an environment/container within your linux environment). Run within the working directory and not as a submitted job. The build step only needs to be done once. 

Load the apptainer module 

```apptainer build qiime2-2021.11.sif docker://quay.io/qiime2/core:2021.11```

An option will pop up asking you to pick a module. Type “1” and press enter. 

**Part 1: Import demultiplexed files**
	
When importing single-end reads you will need: 

1. A manifest file (.tsv or .txt) containing sample identifiers (first column) with absolute paths for forward (second column) reads 	with sequence and quality data (FASTQ). May bootstrap metadata on as well. To get a quick list of all sequence file names go to that 	directory and run ‘ls > ../log.txt’.
   
2. A batch file (.sh) containing your qiime command (see below). Note that you can change the time and memory request to suit the 		load of file import (check how much memory was used after your job is done so you can change for next time).  
	
3. A directory containing all the sequencing files you want to import. Using qiime tools import, import and demultiplex the files 		with *Import_Demuliplex_1.sh*. Note we are using single end reads and the Phred value is 33. 

*Import_Demuliplex_1.sh* 

```
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
```

If you need to import paired-end reads instead of single-end check out the tutorial here:https://docs.qiime2.org/2023.9/tutorials/importing/.  

**Part 2: Visualize sequence quality**  

Visualize the results file (.qzv) to get the sequence quality with *Visualize_2.sh*.  

*Visualize_2.sh*  

```
#!/bin/bash
#SBATCH --account=def-sanrehan
#SBATCH --time=00:05:00
#SBATCH --mem=7GB


module load StdEnv/2020 gcc/9.3.0 apptainer


apptainer run -B /scratch/UserID:/temp -B /lustre06/project/6048691/UserID/Directorywithseqfiles/Directorywithseqfiles qimme2.sif qiime demux summarize \
--i-data /temp/reads_files/InputFileName.qza \
--output-dir /temp/OutputFileName.qzv
```

View this file using https://view.qiime2.org/. Determine where to truncate each sequence depending on where there is a drop in quality in the graph under the Interactive Quality Plot tab. If you need help figuring out where to truncate (removing the ‘tail’ of the sequence reading right -> left) and/or trim (removing the ‘head’ of the sequence reading left -> right) see the tutorial at https://docs.qiime2.org/2023.9/tutorials/moving-pictures/.

**Part 3: Trim and truncate sequences**  

Run the DADA2 plugin to truncate and/or trim sequences based on the plot created from the prior step with *DADA2_trim_3.sh*. Note: If you are merging files (like if you did a meta-analysis with multiple datasets or are combining sequencing runs) merge files after this step. Tutorial: https://docs.qiime2.org/2023.9/tutorials/fmt/

*DADA2_trim_3.sh*  

```
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
```
**Part 4: Produce data summary**  

Generate the FeatureTable and FeatureData summary with *Feature_Summary_4.sh* (Note: command ‘feature-table summarize’ is not necessary unless using the Qiime2 program for stats or for generating plots).

*Feature_Summary_4.sh*

```
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
```

Visualize OutputFile_dada2.qzv at https://view.qiime2.org/ and download sequences as a fasta file. This will be used for sequence classification. 


**Part 5: Classification with BLAST**  

The main 3 options when classifying sequences are BLAST, SILVA, and UNITE. We use BLAST because results are largely consistent across databases and BLAST is the most user-friendly. 

__BLAST__  

Using the faSplit utility, divide the sequences.fasta file downloaded in the prior step  into 10 (adjust as necessary) smaller files that will speed up the BLAST search. The new files will be seq(00-09).fa. This code can be run directly and does not require a batch script. 

```
module load kentutils
faSplit sequence sequences.fasta 10 seq
```

The sequences can now be BLASTed against the built-in database or a new database can be downloaded from NCBI. To use the available database, run *BLAST_database_search_5.sh*. 

*BLAST_database_search_5.sh*

```
#!/bin/bash
#SBATCH --account=def-sanrehan # The account to use
#SBATCH --time=24:00:00 # The duration in HH:MM:SS format of ea
#SBATCH --cpus-per-task=1
#SBATCH --mem=64G # The memory per core for each task in the array
#SBATCH --array=0-8


module load StdEnv/2023 gcc/12.3 blast+/2.14.1


blastn -outfmt "7 qseqid qacc sseqid sacc pident length mismatch gapopen staxids sscinames scomnames" -max_hsps 1 -max_target_seqs 1 -perc_identity 80 \
-db /cvmfs/ref.mugqic/genomes/blast_db/nt -query filename.seq0${SLURM_ARRAY_TASK_ID}.fa -out filename.ref.${SLURM_ARRAY_TASK_ID}

```

Combine the reference sequence files from the array using this command in scratch. This file can be viewed to see which OTUs match which microbial taxa. Save this file and proceed to the next step to export your sequences that correspond with this file!

```
cat seq.ref.{0..9} > seq.ref
```


**Part 6: Export data**  

Use *Export_data_6.sh* to export theOutputFileTable-dada2.qza. 

```
#!/bin/bash
#SBATCH --account=def-sanrehan
#SBATCH --time=00:10:00
#SBATCH --mem=1G


module load StdEnv/2020 gcc/9.3.0 apptainer


apptainer run -B /scratch/mkc206:/temp -B /lustre06/project/6048691/mkc206/MetaData:/MetaData qimme2.sif qiime tools export \
--input-path /temp/quality_files/OutputFileTable-dada2.qza
--output-path /temp/exported-feature-table
```  

Next, set up your env-biom environment (only needs to be done once). 

```
module load python/3.10.2
virtualenv env-biom
source env-biom/bin/activate
pip install -no-index --upgrade pip
pip install --no-index biom_format
```

Now transform the .biom file in the new directory to a text file. Run the following to open your env-biom environment.  

```
source env-biom/bin/activate
```

You may now use *Biom_convert_7.sh* to convert a .biom file to a text file.

```
#!/bin/bash
#SBATCH --account=def-sanrehan
#SBATCH --time=00:10:00
#SBATCH --mem=1G


module load StdEnv/2023 gcc/12.3 r-bundle-bioconductor/3.18


biom convert -i newtable.biom -o new.biomtable.txt --to-tsv
```

This file can now be used to match OTU IDs to corresponding samples in excel or R.  


The quickest way to combine files is to open the seq.ref file in excel, use find and replace to remove everything other than OTU query and taxa names, and split text-to-columns. Next, copy and paste the query ID and taxa name columns to the new.biomtable.txt file in excel (seperate text-to-columns in this file if needed). Finally, use VLOOKUP in a new column to match OTU IDs to their taxa names. You now have a table of taxa IDs and sample names!

