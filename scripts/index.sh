#!/bin/bash
#last updated: 10-04-2025 16:00

# This script should index the genome file specified in the first argument ($1),
# creating the index in a directory specified by the second argument ($2).

# The STAR command is provided for you. You should replace the parts surrounded
# by "<>" and uncomment it.

# STAR --runThreadN 4 --runMode genomeGenerate --genomeDir <outdir> \
# --genomeFastaFiles <genomefile> --genomeSAindexNbases 9

# Verificación de argumentos
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Error: Faltan argumentos."
    echo "Usage: $0 <genome_file> <output_directory>"
    exit 1
fi

GENOME_FILE=$1
OUTPUT_DIR=$2

# Verificar que el archivo del genoma existe
if [ ! -f "$GENOME_FILE" ]; then
    echo "Error: El archivo de genoma '$GENOME_FILE' no existe."
    exit 1
fi

# Crear el directorio de salida si no existiera
mkdir -p "$OUTPUT_DIR"

echo "Indexando el genoma $GENOME_FILE en el directorio $OUTPUT_DIR..."

# Ejecutar el comando STAR para indexar el genoma
STAR --runThreadN 6 --runMode genomeGenerate --genomeDir "$OUTPUT_DIR" \
     --genomeFastaFiles "$GENOME_FILE" --genomeSAindexNbases 9

# Verificar si el comando se ejecutó correctamente
if [ $? -eq 0 ]; then
    echo "Indexación completada con éxito en $OUTPUT_DIR"
else
    echo "Error: La indexación ha fallado."
    exit 1
fi

