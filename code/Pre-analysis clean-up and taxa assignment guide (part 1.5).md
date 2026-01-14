**Statistical Analysis in RStudio**

__Import data__  
  Metadata (.tsv or .txt)  
  Table (.qza)  
  Tree (.qza)  
  Taxonomy (.txt or .qza)  
  
__Create phyloseq object__  
  Using qza_to_phyloseq or merge_phyloseq to combine your .qza and .txt files  
  
__Identify and remove contaminants, blanks, etc.__  
  Run the isContaminant function to check for contaminants  
  Check for tag jumping of other contaminants and proportionally remove relative to the counts present in the blanks  
  
__Compute prevalence and abundance and remove any taxa not meeting minimum counts__  
  
__Assign taxa names to OTU IDS.__   
  
# Note that you have to download everything needed for taxizedb before these steps, which can take awhile! 

#Table1 is a wide dataset with OTU, genus or family name ('tax'), and all samples with occurence data. 
#This gives you taxa names/numbers for your rows and makes a list of unique IDs. 
taxnames <- name2taxid(Table1$tax, db="ncbi", out_type = "summary")

#Gets all other taxonomic rank info for your names. 
taxa <- classification(taxnames$id, db="ncbi")

#Changes from a classification object to a data frame/ table
taxa_wide <- lapply(taxa, function(x) {
  tidyr::pivot_wider(
    x[,1:2],
    names_from = rank,
    values_from = name,
    values_fn = function(x) paste(x, collapse = "|"))
})

tbl <- dplyr::bind_rows(taxa_wide)

#make wide data long
bacteria <- melt(bact)
bacteria0 <- bacteria

#remove character strings that you don't want - for example, the word "uncultured". We do 
#this rather than removing the whole row because we still want to keep the genus name following
#this string. 

bacteria0$sci.name <- gsub("uncultured","",as.character(bacteria$sci.name))

#remove spaces at the beginning of rows we removed "uncultured" from

bacteria0.5 <- bacteria0
bacteria0.5$sci.name <- trimws(bacteria0.5$sci.name, "l")

#split names column into multiple columns, remove all but first. Make sure you have enough new columns that additional pieces/rows are not discarded.
#This makes it so that species from the same genera can be combined into one sample count. 

bacteria1 <- bacteria0.5 %>% separate(sci.name, c('Genus', 'Species', 'X1', 'X2', 'X3', 'X4', 'X5', 'X6', 'X7', 'X8', 'X9', 'X10', 'X11'))

# Drop all name columns except genus  
bacteria2 <- bacteria1[-c(2:13)]   

# get rid of rows with non-fungi or bacteria names by getting code list from google doc 
#(https://docs.google.com/spreadsheets/d/18_1GHXJD3wkQfKAMQJlB0gQbviydswj9-WXNdj1pANc/edit#gid=1489075112)
#first make list of unique genera, then upload .txt file to NCBI taxonomy to get quick list of everything in the wrong kingdom. 
list_samples <- unique(bacteria2$Genus)
unique_genera <- as.data.frame(list_samples)
write.csv2(unique_genera, "unique_genera.txt")

# example sequence: 
bacteria2=bacteria2[!grepl("organism",bacteria2$Genus),]

#group samples by sample name (variable) and then sum values for each sample.
bacteria3 <- bacteria2 %>% group_by(variable) %>% mutate(Total_Sample_Reads = sum(value))

#group samples by sample name (variable) and genus, then sum values to get total for each genus in a sample.
bacteria4 <- bacteria3 %>% group_by(variable, Genus) %>% mutate(Sample_genus_reads = sum(value))

#bring forward samples with more than 500 reads and genera with more than 0 reads
bacteria5 <- bacteria4[bacteria4$Total_Sample_Reads > 500, ]
bacteria6 <- bacteria5[bacteria5$value > 0, ]

#get proportion of each genus per sample
bacteria7 <- bacteria6 %>% mutate(Proportion = Sample_genus_reads/Total_Sample_Reads)

#bring forward proportions over .01
bacteria8 <- bacteria7[bacteria7$Proportion > .01, ]

#check sample number to see if any were lost, can also check unique genera to 
#make sure nothing weird made it through the filter. If genera that need to be removed show up
# GO BACK TO STEP 0 TO REMOVE!! Must re-run code after removal or read counts will be funky. 

Prune_samples to remove any blanks, unwanted taxa, etc.
