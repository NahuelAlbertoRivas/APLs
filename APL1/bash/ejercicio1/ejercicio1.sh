#!/bin/bash

#                       GRUPO 2
# INTEGRANTES
#   AGUIRRE, SEBASTIAN HERNAN
#   DE LA CRUZ, LEANDRO ARIEL
#   JUCHANI CALLAMULLO, JAVIER ANDRES
#   LOIOTILE, JUAN CRUZ
#   RIVAS, NAHUEL ALBERTO

# Requiere: jq para armar el JSON

# VALIDACIÓN DE DEPENDENCIAS

command -v jq >/dev/null 2>&1 || { echo >&2 "Se requiere 'jq'. Instalalo y volvé a intentar"; exit 1; }

ayuda() {
    echo $'Este script procesa archivos CSV de temperaturas agrupados por fecha y ubicación cardinal,
generando un informe en formato JSON. En resumen:
- Lee archivos .csv en un directorio
- Agrupa temperaturas por fecha y ubicación
- Calcula mínimo, máximo y promedio de temperaturas por fecha
- Exporta o muestra el resultado en formato JSON\n
Para poder ejecutar correctamente el script, por favor especificar los siguientes parámetros:
         -d | -- directorio ./ruta_datos                (PARÁMETRO OBLIGATORIO. Indicar la ruta donde se encuentren los archivos fuente con datos)
         -a | --archivo nombre_archivo.json  ó   -p     (PARÁMETRO OBLIGATORIO. Indicar UNA salida en particular, por archivo ó directo a pantalla)

Ejemplos

./ejercicio1.sh -d "./datos_ejercicio1" -a salida.json

./ejercicio1.sh -d ./datos_ejercicio1 -p

./ejercicio1.sh -d "./datos_ejercicio1" --archivo salida.json

./ejercicio1.sh --pantalla -d ./datos_ejercicio1'
}

TO_SCREEN=false
OUTPUT_FILE=""
DIR=""


# RECEPCIÓN DE PARÁMETROS

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help)
            ayuda
            exit 0
            ;;
        -d|--directorio)
            DIR="$2"
            shift
            ;;
        -a|--archivo)
            OUTPUT_FILE="$2"
            shift
            ;;
        -p|--pantalla)
            TO_SCREEN=true
            ;;
        *)
            echo "Opción desconocida: $1. Por favor, reingresar una elección existente"
            ayuda
            exit 1
            ;;
    esac
    shift
done

# VALIDACIONES DE PARÁMETROS

if [[ -z "$DIR" ]] 
then
    echo "Por favor, especificar el directorio con -d o --directorio"
    exit 1
fi

if [[ -n "$OUTPUT_FILE" && "$TO_SCREEN" == true ]]
then
    echo "Por favor, especificar si se quiere salida por archivo (-a ruta.json ó -archivo ruta.json) ó directo a pantalla (-p), no es viable ambas al mismo tiempo"
    exit 1
fi

if [[ ! -d "$DIR" ]] 
then
    echo "Por favor, asegurate de que el directorio '$DIR' exista"
    exit 1
fi

if [[ -z "$OUTPUT_FILE" && "$TO_SCREEN" == false ]]
then
    echo "Por favor, especificar si se quiere salida por archivo (-a ruta.json ó -archivo ruta.json) ó directo a pantalla (-p ó -pantalla)"
    exit 1
fi

# LECTURA DE REGISTROS

declare -A temps
declare -a fechas_orden

agregar_valor() {
    local fecha="$1"
    local ubi="$2"
    local temp="$3"
    local count=0
    local min
    local max
    local prom

    if [[ -z "${temps[$fecha]}" ]]; then
        temps["$fecha"]='{}'
        fechas_orden+=("$fecha")  # Guardamos orden de fechas
    fi

    if [[ "$(echo "${temps[$fecha]}" | jq -r "has(\"$ubi\")")" == "true" ]]; then
        valor_min_actual=$(echo "${temps[$fecha]}" | jq -r ".$ubi.Min")
        valor_max_actual=$(echo "${temps[$fecha]}" | jq -r ".$ubi.Max")
        suma_acumulada=$(echo "$temp + $(echo "${temps[$fecha]}" | jq -r ".$ubi.Promedio * $(echo "${temps[$fecha]}" | jq -r ".$ubi.Count")")" | bc)
        count=$(echo "$(echo "${temps[$fecha]}" | jq -r ".$ubi.Count") + 1" | bc)

        # En caso de nuevo mínimo
        if (( $(echo "$temp < $valor_min_actual" | bc -l) )); then
            min=$temp
        else
            min=$valor_min_actual
        fi

        # En caso de nuevo máximo
        if (( $(echo "$temp > $valor_max_actual" | bc -l) )); then
            max=$temp
        else
            max=$valor_max_actual
        fi

        prom=$(echo "scale=2; $suma_acumulada / $count" | bc)
    else
        prom=$temp
        count=1
        min=$temp
        max=$temp
    fi

    temps["$fecha"]=$(echo "${temps[$fecha]}" | jq --arg ubi "$ubi" --argjson min "$min" --argjson max "$max" --argjson prom "$prom" --argjson count "$count" \
        '. + {($ubi): {"Min": $min, "Max": $max, "Promedio": $prom, "Count": $count}}')
}

# PROCESAMIENTO DE ARCHIVOS
for archivo in "$DIR"/*.csv; do
    [[ -f "$archivo" ]] || continue

    sed -i 's/\r$//' "$archivo"

    while IFS=',' read -r id fecha_reg hora ubi temp; do
        # Cambiar formato fecha '/' a '-'
        fecha_reg=$(echo "$fecha_reg" | sed 's|/|-|g')
        temp=$(echo "$temp" | sed 's/[[:space:]]//g' | sed 's/\.$//')

        if [[ -z "$ubi" || -z "$temp" ]] || ! echo "$temp" | grep -qE '^-?[0-9]+(\.[0-9]+)?$'; then
            continue
        fi

        agregar_valor "$fecha_reg" "$ubi" "$temp"
    done < "$archivo"
done

salida_json() {

  # FORMATEO DEL JSON  
  json='{ "fechas": {'

  total_fechas=${#fechas_orden[@]}
  contador=0
  # Recorrer cada fecha y agregar sus datos
  for fecha in "${fechas_orden[@]}"; do
    json+="\"$fecha\": "
    
    json+=$(echo "${temps[$fecha]}" | jq 'with_entries(.value |= {Min, Max, Promedio})')

    contador=$((contador + 1))
    if [[ $contador -lt $total_fechas ]]
    then
      json+=","
    fi
  done

  json+="} }"

  echo "$json" | jq .
}

# SALIDA
if [[ "$TO_SCREEN" == true ]] 
then
    salida_json
elif [[ -n "$OUTPUT_FILE" ]]
then
    salida_json > "$OUTPUT_FILE"
    echo "Archivo JSON generado en: $OUTPUT_FILE"
fi
