#!/bin/bash

# This script should download the file specified in the first argument ($1),
# place it in the directory specified in the second argument ($2),
# and *optionally*:
# - uncompress the downloaded file with gunzip if the third
#   argument ($3) contains the word "yes"
# - filter the sequences based on a word contained in their header lines:
#   sequences containing the specified word in their header should be **excluded**
#
# Example of the desired filtering:
#
#   > this is my sequence
#   CACTATGGGAGGACATTATAC
#   > this is my second sequence
#   CACTATGGGAGGGAGAGGAGA
#   > this is another sequence
#   CCAGGATTTACAGACTTTAAA
#
#   If $4 == "another" only the **first two sequence** should be output

# Comprobación de que hemos recibido los argumentos necesarios
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Error: Me faltan argumentos."
    echo "Usage: $0 <url> <output_directory> [uncompress_option] [exclude_word]"
    exit 1
fi

URL=$1
OUTPUT_DIR=$2
UNCOMPRESS=${3:-"no"}  # por defecto no descomprime
EXCLUDE_WORD=${4:-""}  # por defecto no excluye nada

# Crear el directorio de salida si no existe
mkdir -p $OUTPUT_DIR

# Get the filename from URL
FILENAME=$(basename $URL)
OUTPUT_FILE="$OUTPUT_DIR/$FILENAME"

# Descargar montrando el progreso
echo "Downloading $URL to $OUTPUT_FILE"
wget -q --show-progress $URL -O $OUTPUT_FILE

# Comprobación de que el archivo se ha descargado correctamente
if [ $? -ne 0 ]; then
        echo "Error: No se pudo descargar el archivo $URL"
        exit 1
fi

# Verificar MD5 sin tener que descargar el archivo .md5
echo "Verificando MD5 del archivo descargado..."
# Usar wget en lugar de curl para obtener el MD5
MD5_URL="${URL}.md5"
EXPECTED_MD5=$(wget -q -O - $MD5_URL | awk '{print $1}')
ACTUAL_MD5=$(md5sum $OUTPUT_FILE | awk '{print $1}')

if [ "$EXPECTED_MD5" = "$ACTUAL_MD5" ]; then
    echo "Verificación MD5 correcta: $ACTUAL_MD5"
else
    echo "Error: La verificación MD5 ha fallado."
    echo "Esperado: $EXPECTED_MD5"
    echo "Obtenido: $ACTUAL_MD5"
    exit 1
fi

# Descomprimir con gunzip
if [[ "$UNCOMPRESS" == "yes" ]]; then
    echo "Uncompressing $OUTPUT_FILE"
    # ¿Tenemos un archivo .gz?
    if [[ "$OUTPUT_FILE" == *.gz ]]; then
        gunzip -f $OUTPUT_FILE
        # Quitar .gz del nombre
        OUTPUT_FILE="${OUTPUT_FILE%.gz}"
    else
        echo "Warning: El archivo no tiene una extensión .gz pero has pedido que se descomprima!"
    fi
fi

# Si se ha especificado una palabra para excluir,
# filtramos las secuencias en el archivo FASTA
if [ ! -z "$EXCLUDE_WORD" ]; then
    echo "Excluyendo las secuencias con '$EXCLUDE_WORD' en el encabezado"
    TEMP_FILE="${OUTPUT_FILE}.temp"
    
    # Initialize variables
    CURRENT_HEADER=""
    SEQUENCE=""
    INCLUDE=true
    
    # Para leer el FASTA línea por línea y filtrar las secuencias
    while IFS= read -r line; do
        if [[ "$line" == ">"* ]]; then
            # Si ya hay una secuencia guardada del encabezado anterior y está permitida, imprímela
            if [ "$INCLUDE" = true ] && [ ! -z "$CURRENT_HEADER" ]; then
                echo "$CURRENT_HEADER" >> "$TEMP_FILE"
                echo "$SEQUENCE" >> "$TEMP_FILE"
            fi

            # Actualiza el encabezado actual
            CURRENT_HEADER="$line"

            # Comprueba si el encabezado contiene la palabra a excluir
            if [[ "$CURRENT_HEADER" == *"$EXCLUDE_WORD"* ]]; then
                INCLUDE=false
            else
                INCLUDE=true
            fi

            SEQUENCE=""
        else
            # Añade la línea a la secuencia actual
            SEQUENCE="${SEQUENCE}${line}"
        fi
    done < "$OUTPUT_FILE"
    
    # Process the last sequence if there is one
    if [ ! -z "$CURRENT_HEADER" ] && [ "$INCLUDE" = true ]; then
        echo "$CURRENT_HEADER" >> "$TEMP_FILE"
        echo "$SEQUENCE" >> "$TEMP_FILE"
    fi
    
    # Replace original with filtered file
    mv "$TEMP_FILE" "$OUTPUT_FILE"
    echo "Filtering complete."
fi

echo "Procesamiento de $FILENAME completado correctamente."