#!/bin/bash
# Script para el curso de bioinformática
# que "descontamina" los datos de un experimentos de small-RNA secuqncing

#last updated: 13-04-2025 11:58


# Definir archivo de log para la pipeline
# Se creará en la carpeta logs
mkdir -p logs
LOG_FILE="logs/pipeline_log.txt"

# Función para registrar mensajes en el archivo de log
log_message() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo "$1"
}

log_message "==== Iniciando pipeline de procesamiento ===="

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
log_message "Descargando los archivos fasta de los contaminantes"
URL="https://bioinformatics.cnio.es/data/courses/decont/contaminants.fasta.gz"
UNCOMPRESS_OPTION="yes"
EXCLUDE_WORD="small nuclear RNA" # para excluir small nuclear RNAs
       
bash scripts/download.sh "$URL" res "$UNCOMPRESS_OPTION" "$EXCLUDE_WORD"
log_message "Archivo de contaminantes descargado, descomprimido y filtrado"

# Index the contaminants file
log_message "Indexando archivo de contaminantes"
bash scripts/index.sh res/contaminants.fasta res/contaminants_idx
log_message "Indexado completado exitosamente"


# Merge the samples into a single file
for sid in $(<list_of_sample_ids>) #TODO
do
    bash scripts/merge_fastqs.sh data out/merged $sid
done

# TODO: run cutadapt for all merged files
cutadapt -m 18 -a TGGAATTCTCGGGTGCCAAGG --discard-untrimmed \
     -o <trimmed_file> <input_file> > <log_file>

# TODO: run STAR for all trimmed files
for fname in out/trimmed/*.fastq.gz
do
    # you will need to obtain the sample ID from the filename
    sid=#TODO
    mkdir -p out/star/$sid
    STAR --runThreadN 6 --genomeDir res/contaminants_idx \
        --outReadsUnmapped Fastx --readFilesIn <input_file> \
        --readFilesCommand gunzip -c --outFileNamePrefix <output_directory>
done 

# TODO: create a log file containing information from cutadapt and star logs
# (this should be a single log file, and information should be *appended* to it on each run)
# - cutadapt: Reads with adapters and total basepairs
# - star: Percentages of uniquely mapped reads, reads mapped to multiple loci, and to too many loci
# tip: use grep to filter the lines you're interested in
