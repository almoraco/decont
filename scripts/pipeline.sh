#!/bin/bash
# Script para el curso de bioinformática
# que "descontamina" los datos de un experimentos de small-RNA secuqncing

#last updated: 13-04-2025 10:10

#Descarga de los archivos escritos en data/urls
# comprobando que no existen ya
#y usando wget para descargarlos

while read url; do
    # Comprobar si el archivo ya existe
    filename=$(basename "$url")
    if [ -f "data/$filename" ]; then
        echo "El archivo $filename ya existe. Saltando descarga."
    else
    # Descargar el archivo
        echo "Descargando $url..."
        wget "$url" -P data --show-progress
    fi
done < data/urls


# Download the contaminants fasta file, uncompress it, and
# filter to remove all small nuclear RNAs

URL="https://bioinformatics.cnio.es/data/courses/decont/contaminants.fasta.gz"
UNCOMPRESS_OPTION="yes"
EXCLUDE_WORD="small nuclear RNA" # para excluir small nuclear RNAs
       
bash scripts/download.sh "$URL" res "$UNCOMPRESS_OPTION" "$EXCLUDE_WORD"


# Index the contaminants file
bash scripts/index.sh res/contaminants.fasta res

# Merge the samples into a single file
for sid in $(<list_of_sample_ids>) #TODO
do
    bash scripts/merge_fastqs.sh data out/merged $sid
done

# TODO: run cutadapt for all merged files
# cutadapt -m 18 -a TGGAATTCTCGGGTGCCAAGG --discard-untrimmed \
#     -o <trimmed_file> <input_file> > <log_file>

# TODO: run STAR for all trimmed files
for fname in out/trimmed/*.fastq.gz
do
    # you will need to obtain the sample ID from the filename
    sid=#TODO
    # mkdir -p out/star/$sid
    # STAR --runThreadN 4 --genomeDir res/contaminants_idx \
    #    --outReadsUnmapped Fastx --readFilesIn <input_file> \
    #    --readFilesCommand gunzip -c --outFileNamePrefix <output_directory>
done 

# TODO: create a log file containing information from cutadapt and star logs
# (this should be a single log file, and information should be *appended* to it on each run)
# - cutadapt: Reads with adapters and total basepairs
# - star: Percentages of uniquely mapped reads, reads mapped to multiple loci, and to too many loci
# tip: use grep to filter the lines you're interested in
