#!/bin/bash

#                       GRUPO 2
# INTEGRANTES
#   AGUIRRE, SEBASTIAN HERNAN
#   DE LA CRUZ, LEANDRO ARIEL
#   JUCHANI CALLAMULLO, JAVIER ANDRES
#   LOIOTILE, JUAN CRUZ
#   RIVAS, NAHUEL ALBERTO

ayuda() {
    echo $'Este script procesa archivos de texto, contando la cantidad de ocurrencias
de determinadas palabras o expresiones de interés (las cuales deben ser detalladas en un array),
indicando a su vez las extensiones de los archivos en las que aquellas podrían encontrarse.
En resumen:
- Lee archivos (de extensiones previamente indicadas) a partir de un directorio dado
(de manera recursiva, es decir, mapea también subdirectorios contenidos) y va leyendo
línea a línea sus contenidos. Finalmente, para cada línea identifica coincidencias
con las palabras/expresiones de interés.
Para poder ejecutar correctamente el script, por favor especificar los siguientes parámetros:
         -d | -- directorio ./ruta_datos                     (PARÁMETRO OBLIGATORIO. Indicar la ruta donde se encuentren los archivos fuente con datos)
         -p | -- palabras "exp 1#...#exp N"                  (PARÁMETRO OBLIGATORIO. Indicar la/s expresión/es de interés, en el segundo caso separadas por #)
         -a | --archivos "[extensión1] ... [extensiónN]"     (PARÁMETRO OBLIGATORIO. Indicar la/s extensión/es de interés, en el segundo caso separadas por un espacio)

Ejemplos         

./ejercicio3.sh -p \'if#else#return 0#while\' -d "./datos_ejercicio3" -a "c h txt"

./ejercicio3.sh -p \'if#else#return 0#i in\' -d "./datos_ejercicio3" -a "c h txt"

./ejercicio3.sh -p "if#else#return 0#i in#;" -d ./datos_ejercicio3 -a \'c h txt\'

./ejercicio3.sh --archivos "c h txt" -p "if#else#return 0#i in#;" --directorio ./datos_ejercicio3'
}

# Recepción de params

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            ayuda
            exit 0
            ;;
        -d|--directorio)
            directorio="$2"
            shift 2
            ;;
        -p|--palabras)
            palabras="$2"
            shift 2
            ;;
        -a|--archivos)
            extensiones="$2"
            shift 2
            ;;
        *)
            echo "Opción desconocida: $1. Por favor, reingresar una elección existente"
            ayuda
            exit 1
            ;;
    esac
done

# VALIDACIONES DE PARÀMETROS

if [[ -z "$directorio" ]] 
then
    echo "Por favor, especificar el directorio con -d o --directorio"
    exit 1
fi

if [[ ! -d "$directorio" ]] then
    echo "Por favor, asegurate de que el directorio '$directorio' exista"
    exit 1
fi

if [[ -z "$directorio" || -z "$palabras" || -z "$extensiones" ]]
then
    echo "Por favor, revisar los parámetros obligatorios (NO pueden quedar vacíos)"
    ayuda
    exit 1
fi

# Find para filtrar dinámicamente archivos por las extensiones dadas
find_expr=""
for ext in $extensiones
do
    find_expr+=" -iname '*.$ext' -o"
done
find_expr="${find_expr::-3}"  # sacamos el último -o

# LECTURA, PROCESAMIENTO (LÌNEA A LÌNEA) Y SALIDA A PANTALLA

eval "find \"$directorio\" -type f \\( $find_expr \\) -print0" |
while IFS= read -r -d '' archivo
do
    awk -v palabras="$palabras" '
    BEGIN {
        split(palabras, lista, "#");
        for (i in lista) {
            exps[i] = lista[i];
            contador[lista[i]] = 0;
        }
    }
    {
        for (i in exps) {
            while (match($0, exps[i])) {
                contador[exps[i]]++;
                $0 = substr($0, RSTART + RLENGTH);
            }
        }
    }
    END {
        for (e in contador) {
            print e ": " contador[e];
        }
    }
    ' "$archivo"
done | awk -F: '
{
    palabra = $1
    gsub(/^ +| +$/, "", palabra)
    contador[palabra] += $2
}
END {
    for (p in contador) {
        print p ": " contador[p]
    }
}
' | sort