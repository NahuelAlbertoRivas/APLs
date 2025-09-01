 #!/bin/bash

#                       GRUPO 2
# INTEGRANTES
#   AGUIRRE, SEBASTIAN HERNAN
#   DE LA CRUZ, LEANDRO ARIEL
#   JUCHANI CALLAMULLO, JAVIER ANDRES
#   LOIOTILE, JUAN CRUZ
#   RIVAS, NAHUEL ALBERTO


ayuda() {
    echo $'Para poder ejecutar correctamente el script, por favor especificar los siguientes parámetros:
         -m | -- matriz ./ruta_datos                (indicar la ruta donde se encuentren el archivo matriz)
         -s | --separador |                         (indicar el separador utilizado en la matriz)
         -t | --trasponer   (el archivo final tendrá la matriz traspuesta)
         -p | --producto 5     (el archivo final tendrá la matriz luego del producto escalar)
         NO se puede utilizar el parámetro -t y -p al mismo tiempo
Ejemplo 1: -m Matriz.txt -s "|" -t
Ejemplo 2: -m "/home/usuario/APL/matriz" --producto 2 --separador "$"
Ejemplo 3: --matriz MatrizIngreso.txt -p -.2
         '
}

# RECEPCIÓN DE PARÁMETROS
 
options=$(getopt -o m:p:s:th --l help,matriz:,producto:,separador:,trasponer -- "$@" 2> /dev/null)
if [ "$?" != "0" ] # equivale a:  if test "$?" != "0"
then
    echo 'Opciones incorrectas'
    exit 1
fi

eval set -- "$options"
while true
do
    case "$1" in 
        -m | --matriz) 
            INPUT_MAT="$2"
            shift 2
            ;;
        -p | --producto)
            VALOR_PROD="$2"
            shift 2
            ;;
        -t | --trasponer)
            TRASP=true
            shift
            ;;
        -s | --separador)
            SEPARA="$2"
            shift 2
            ;;
        -h | --help)
            ayuda
            exit 0
            ;;
        --) # case "--":
            shift
            break
            ;;
        *) # default: 
            echo "error"
            exit 1
            ;;
    esac
done

# VALIDACIONES DE PARÁMETROS

if [[ -z "$INPUT_MAT" ]] 
then
    echo "Por favor, especificar un archivo matriz con -m o --matriz, no puede ser vacío"
    exit 1
fi

if [[ ! -f "$INPUT_MAT" ]] 
then
    echo "Por favor, especificar un archivo matriz con -m o --matriz"
    exit 1
fi

# el separador no puede ser - ni números 
if [[ "$SEPARA" == "-" || "$SEPARA" =~ ^[0-9]+$ || ! -n "$SEPARA" ]] 
then
    echo "Por favor, especificar un separador distinto de - o números, no puede ser vacío"
    exit 1
fi

#se valida que producto y trasponer no se usen al mismo tiempo
if [[ -n "$VALOR_PROD" && "$TRASP" == true ]]
then
    echo "Por favor, especificar si se quiere hacer producto escalar (-p o --producto) o trasponer (-t o --trasponer), no es viable ambas al mismo tiempo"
    exit 1
fi

if [[ ! -n "$VALOR_PROD" && ! -n "$TRASP" ]]
then
    echo "Por favor, especificar si se quiere hacer producto escalar (-p o --producto) o trasponer (-t o --trasponer), se requiere uno de ellos"
    exit 1
fi

if [[ -n "$VALOR_PROD" && ! "$VALOR_PROD" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]
then
    echo "Por favor, especificar un número para el producto escalar (-p o --producto), no se aceptan otros valores"
    exit 1
fi
if [[ ! -s "$INPUT_MAT" ]];then
    echo "El archivo ingresado esta vacio"
    exit 1
fi

sed -i -e '$a\' "$INPUT_MAT"

# PROCESAMIENTO DE ARCHIVO

if [[ $TRASP == true ]]
then
#Trasponer matriz
matriz_transpuesta=()



cantFilas=$(wc -l < "$INPUT_MAT")


#Leemos linea a linea y guardamos en un array (param -a) LINE, cada fila es un array
        columna=0
        ElmxCelda=0
    while IFS="$SEPARA" read -r -a LINE 
    do
        #Validaciones de matriz
        
        cantCeldas=${#LINE[@]}
        if [ $ElmxCelda -eq 0 ]; then
             ElmxCelda=$cantCeldas
        fi
        #Verificamos que todas las filas contengan la misma cantidad de celdas
        if [ "$ElmxCelda" -ne "$cantCeldas" ];then
        echo "No es una matriz valida"
        exit 0
        fi

        i=0;
        #Recorremos el array
        for numero in "${LINE[@]}"; do
            #Validamos los valores dentro de la matriz
            i=$((i+1))
          if [[ ! "$numero" =~ ^-?[0-9]+([.][0-9]+)?$ ]];
            then
            
                echo "La matriz está mal formada, contiene valores no numéricos"
                exit 1
            elif [[ $columna == 0 ]]
                then
                   
                     matriz_transpuesta[$i]+=$numero
                     
                else
                    
                     matriz_transpuesta[$i]+=$SEPARA$numero

                fi
        done
        columna=1
    done < "$INPUT_MAT"
   #VERIFICAR PERMISOS SOBRE ESCRITURA
    nombreArchivo=$(basename "$INPUT_MAT")
    directorio=$(dirname "$INPUT_MAT")
    

    if [ -f $directorio/salida.$nombreArchivo ]
    then
        rm $directorio/salida.$nombreArchivo
    fi
    

    for valor in "${matriz_transpuesta[@]}"
    do
        echo "$valor" >> "$directorio/"salida."$nombreArchivo"
    done
    echo "Se realizo la traspuesta de la matriz ingresada"
else
##Procesamiento para producto escalar
    primerFila=0
    while IFS="$SEPARA" read -r -a LINE #algo
    do
        #Validaciones de matriz
        
        cantCeldas=${#LINE[@]}
        
        if [ $primerFila == 0 ]
        then
             cantCeldasXFila=${#LINE[@]}
           
        else

            if [[ $cantCeldas != $cantCeldasXFila  ]]
            then
                echo "La matriz está mal formada, no es cuadradada"
                exit 1
            fi
        fi
        resultado=()
        resultadoProducto=()
        i=0
        #Recorremos el array
        for numero in "${LINE[@]}"; do
            i=$((i+1))
            #Validamos los valores dentro de la matriz
           if [[ ! "$numero" =~ ^-?[0-9]+([.][0-9]+)?$ ]];
            then
                echo "La matriz está mal formada, hay valores no numéricos"
                exit 1
            fi
        
           resultado[$i]=$(echo "$numero * $VALOR_PROD" | bc -l)
        done

        echo "${resultado[*]}" | tr ' ' "$SEPARA" >> "matrizTemporal.txt"
        
    done < "$INPUT_MAT"


    echo "Se realizo el producto escalar de la matriz ingresada"

    nombreArchivo=$(basename "$INPUT_MAT")
    directorio=$(dirname "$INPUT_MAT")

    mv "matrizTemporal.txt"  "$directorio/""salida.""$nombreArchivo"
 fi