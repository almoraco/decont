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
# Crear directorios necesarios
mkdir -p out/merged

# Extraer los IDs de muestra únicos de los archivos en data/
log_message "Extrayendo muestra únicas de los archivos en data/"
SAMPLE_IDS=$(ls data/*.fastq.gz 2>/dev/null | sed 's|data/||' | cut -d'-' -f1 | sort | uniq)

# Si no se encontraron archivos .fastq.gz, buscar .fastq
if [ -z "$SAMPLE_IDS" ]; then
    SAMPLE_IDS=$(ls data/*.fastq 2>/dev/null | sed 's|data/||' | cut -d'-' -f1 | sort | uniq)
fi

# Mostrar los IDs de muestra encontrados
log_message "IDs de muestra encontrados: $SAMPLE_IDS"

# Procesar cada ID de muestra
for sid in $SAMPLE_IDS
do
    log_message "Procesando muestra: $sid"
    bash scripts/merge_fastqs.sh data out/merged $sid
    
    # Ejecutar cutadapt (asumiendo que el script existe y funciona correctamente)
    log_message "Ejecutando cutadapt para la muestra $sid"
    CUTADAPT_LOG="logs/cutadapt_${sid}.log"
    # Ajusta la línea siguiente según cómo llames realmente a cutadapt
    cutadapt -a ADAPTER -o out/trimmed/${sid}_trimmed.fastq out/merged/${sid}_merged.fastq > "$CUTADAPT_LOG" 2>&1
    
    # Extraer información relevante de cutadapt y agregarla al archivo de log principal
    READS_WITH_ADAPTERS=$(grep "Reads with adapters" "$CUTADAPT_LOG" | awk '{print $4,$5,$6,$7}')
    TOTAL_BP=$(grep "Total basepairs processed" "$CUTADAPT_LOG" | awk '{print $4,$5}')
    log_message "Cutadapt - $sid - Reads with adapters: $READS_WITH_ADAPTERS"
    log_message "Cutadapt - $sid - Total basepairs: $TOTAL_BP"
    
    # Ejecutar STAR (asumiendo que el script existe y funciona correctamente)
    log_message "Ejecutando STAR para la muestra $sid"
    STAR_LOG="logs/star_${sid}.log"
    # Ajusta la línea siguiente según cómo llames realmente a STAR
    STAR --genomeDir reference_genome --readFilesIn out/trimmed/${sid}_trimmed.fastq --outFileNamePrefix out/aligned/${sid}_ > "$STAR_LOG" 2>&1
    
    # Extraer información relevante de STAR y agregarla al archivo de log principal
    UNIQUELY_MAPPED=$(grep "Uniquely mapped reads %" out/aligned/${sid}_Log.final.out | awk '{print $NF}')
    MULTI_MAPPED=$(grep "% of reads mapped to multiple loci" out/aligned/${sid}_Log.final.out | awk '{print $NF}')
    TOO_MANY_LOCI=$(grep "% of reads mapped to too many loci" out/aligned/${sid}_Log.final.out | awk '{print $NF}')
    log_message "STAR - $sid - Uniquely mapped reads: $UNIQUELY_MAPPED"
    log_message "STAR - $sid - Reads mapped to multiple loci: $MULTI_MAPPED"
    log_message "STAR - $sid - Reads mapped to too many loci: $TOO_MANY_LOCI"
done