#!/bin/bash

# This script should merge all files from a given sample (the sample id is
# provided in the third argument ($3)) into a single file, which should be
# stored in the output directory specified by the second argument ($2).
#
# The directory containing the samples is indicated by the first argument ($1).

#last updated: 13-04-2025 12:05

# Verificar que se proporcionaron los argumentos necesarios
if [ $# -ne 3 ]; then
    echo "Uso: $0 <directorio_entrada> <directorio_salida> <id_muestra>"
    exit 1
fi

# Argumentos de variables:
INPUT_DIR=$1
OUTPUT_DIR=$2
SAMPLE_ID=$3

# Verificar que el directorio de entrada existe
if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: El directorio de entrada '$INPUT_DIR' no existe."
    exit 1
fi

# Crear el directorio de salida si no existe
mkdir -p "$OUTPUT_DIR"

# Nombre del archivo de salida
OUTPUT_FILE="${OUTPUT_DIR}/${SAMPLE_ID}_merged.fastq"

# Buscar todos los archivos que comienzan con el ID de muestra especificado
echo "Buscando archivos para la muestra $SAMPLE_ID"
FILES=$(find "$INPUT_DIR" -type f -name "${SAMPLE_ID}*.fastq.gz")

# Si no se encontraron archivos, buscar archivos sin compresión
if [ -z "$FILES" ]; then
    FILES=$(find "$INPUT_DIR" -type f -name "${SAMPLE_ID}*.fastq")
    
    # Si aún no hay archivos, salir
    if [ -z "$FILES" ]; then
        echo "No se encontraron archivos para la muestra $SAMPLE_ID"
        exit 1
    fi
    
    # Para archivos .fastq (sin comprimir)
    echo "Combinando archivos en $OUTPUT_FILE"
    > "$OUTPUT_FILE" # Crear/limpiar el archivo de salida
    
    for file in $FILES; dopiar el archivo de salida
    
    for file in $FILES; do
        echo "Procesando archivo comprimido: $file"
        zcat "$file" >> "$OUTPUT_FILE"
    done
fi

# Informar sobre el proceso
echo "Se han combinado los archivos de la muestra $SAMPLE_ID en $OUTPUT_FILE"
echo "Proceso de combinación completado."
        echo "Procesando archivo: $file"
        cat "$file" >> "$OUTPUT_FILE"
    done
else
    # Para archivos .fastq.gz (comprimidos)
    echo "Combinando archivos comprimidos en $OUTPUT_FILE"
    > "$OUTPUT_FILE" # Crear/limpiar el archivo de salida
    
    for file in $FILES; do
        echo "Procesando archivo comprimido: $file"
        zcat "$file" >> "$OUTPUT_FILE"
    done
fi

# Informar sobre el proceso
echo "Se han combinado los archivos de la muestra $SAMPLE_ID en $OUTPUT_FILE"
echo "Proceso de combinación completado."