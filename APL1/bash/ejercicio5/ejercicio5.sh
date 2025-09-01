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
command -v jq >/dev/null 2>&1 || { echo >&2 "Se requiere 'jq'. Instalalo y volvé a intentar."; exit 1; }



ayuda() {
    echo $'Este script permite consultar información nutricional de frutas desde la API de Fruityvice.
Opciones:
  -i, --id [ID]         Consultar fruta por ID. Se puede usar más de un ID separado por comas.
  -n, --name [NOMBRE]   Consultar fruta por nombre. Se puede usar más de un nombre separado por comas.
  -h, --help            Mostrar esta ayuda y salir.'
}

HAY_NOMBRE=false
HAY_ID=false

# Recepción de parámetros
options=$(getopt -o i:n:h --long help,id:,name: -- "$@" 2> /dev/null)
if [ "$?" != "0" ]; then
    echo 'Opciones incorrectas'
    exit 1
fi

eval set -- "$options"
while true; do
    case "$1" in
        -i | --id)
            INPUT_ID="$2"
            shift 2
            ;;
        -n | --name)
            INPUT_NOMBRE="$2"
            shift 2
            ;;
        -h | --help)
            ayuda
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Error: Opción inválida"
            exit 1
            ;;
    esac
done

# Validación de parámetros
if [ -n "$INPUT_ID" ]; then
    IFS=',' read -ra ID_ARRAY <<< "$INPUT_ID"
    HAY_ID=true
fi

if [ -n "$INPUT_NOMBRE" ]; then
    IFS=',' read -ra NOMBRE_ARRAY <<< "$INPUT_NOMBRE"
    HAY_NOMBRE=true
fi


es_numero() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

procesar_fruta() {
    local archivo_cache="$1"
    
    read -r id name genus calories fat sugar carbs protein < <(
        jq -r '[.id, .name, .genus, .nutritions.calories, .nutritions.fat, .nutritions.sugar, .nutritions.carbohydrates, .nutritions.protein] | @tsv' "$archivo_cache"
    )

    echo "id: $id,"
    echo "name: $name,"
    echo "genus: $genus,"
    echo "calories: $calories,"
    echo "fat: $fat,"
    echo "sugar: $sugar,"
    echo "carbohydrates: $carbs,"
    echo "protein: $protein"
    echo
}


#Crear cache
CACHE_DIR="/tmp/cache_ej5"
mkdir -p "$CACHE_DIR"

#Borrar cache
#trap "rm -rf '$CACHE_DIR'" EXIT


# Procesar por nombre
if [ "$HAY_NOMBRE" = true ]; then
    for NOMBRE in "${NOMBRE_ARRAY[@]}"; do
        NOMBRE=$(echo "$NOMBRE" | tr '[:upper:]' '[:lower:]')
        if es_numero "$NOMBRE"; then
            echo "Error: Pasaste un número como nombre (NOMBRE: '$NOMBRE')."
            continue
        fi
        
        archivo_cache="$CACHE_DIR/${NOMBRE}_respuesta.json"

        if [ -f "$archivo_cache" ]; then
            http_code=200
        else
            response=$(curl -s -w "%{http_code}" -o "$archivo_cache" "https://www.fruityvice.com/api/fruit/${NOMBRE}")
            http_code="${response: -3}"
        fi

        if [ "$http_code" -eq 200 ]; then
           procesar_fruta "$archivo_cache"
        else
            case $http_code in
                404)
                    echo "Error: La fruta '$NOMBRE' no se encontró (Nombre no válido)."
                    rm -f "$archivo_cache"
                    ;;
                500)
                    echo "Error: Hubo un problema con el servidor de la API."
                    rm -f "$archivo_cache"
                    ;;
                *)
                    echo "Error: Código HTTP inesperado al consultar '$NOMBRE': $http_code"
                    rm -f "$archivo_cache"
                    ;;
            esac
        fi
    done
fi

# Procesar por ID
if [ "$HAY_ID" = true ]; then
    for ID in "${ID_ARRAY[@]}"; do
        if ! es_numero "$ID"; then
            echo "Error: Pasaste un string como ID (ID: '$ID')."
            continue
        fi
        archivo_cache="$CACHE_DIR/${ID}_respuesta.json"

        if [ -f "$archivo_cache" ]; then
            http_code=200
        else
            response=$(curl -s -w "%{http_code}" -o "$archivo_cache" "https://www.fruityvice.com/api/fruit/${ID}")
            http_code="${response: -3}"
        fi

        if [ "$http_code" -eq 200 ]; then        
            procesar_fruta "$archivo_cache"
        else
            case $http_code in
                404)
                    echo "Error: La fruta con ID '$ID' no se encontró (ID no válido)."
                    rm -f "$archivo_cache"
                    ;;
                500)
                    echo "Error: Hubo un problema con el servidor de la API."
                    rm -f "$archivo_cache"
                    ;;
                *)
                    echo "Error: Código HTTP inesperado al consultar ID '$ID': $http_code"
                    rm -f "$archivo_cache"
                    ;;
            esac
        fi
    done
fi
