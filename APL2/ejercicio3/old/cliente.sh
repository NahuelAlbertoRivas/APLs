#!/bin/bash
#AGUIRRE, SEBASTIAN HERNAN - DE LA CRUZ, LEANDRO ARIEL - JUCHANI CALLAMULLO, JAVIER ANDRES - LOIOTILE, JUAN CRUZ - RIVAS, NAHUEL ALBERTO

ayuda() {
    echo 'Para poder ejecutar correctamente el script, por favor especificar los siguientes parámetros:
         -a | --archivo ./ruta_archivo     (Ruta al archivo a imprimir)'
}


# RECEPCIÓN DE PARÁMETROS

options=$(getopt -o a:h --l help,archivo: -- "$@" 2> /dev/null)
if [ "$?" != "0" ]
then
    echo 'Opciones incorrectas'
    exit 1
fi
eval set -- "$options"

while true
do
    case "$1" in
        -a | --archivo)
            ARCHIVO="$2"
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



if [[ -z "$ARCHIVO" ]]
then
    echo "Por favor, especificar el archivo a imprimir con -a o --archivo, no puede ser vacío."
    exit 1
fi

if [[ ! -e "$ARCHIVO" ]]
then
    echo "El archivo '$ARCHIVO' no existe. Por favor, especificar un archivo válido."
    exit 1
fi

#string(argv[1]) + ":" + string(argv[2])
#res=$(./cliente_escribe "$$" "$ARCHIVO")

line=$(echo "$$:$ARCHIVO")

res=$(./fifo_escribe "/tmp/cola_impresion" "$line")

if [[ $? = 1 ]]
then
    echo $res
    exit 1
fi

clififo=$(echo "/tmp/FIFO_$$")
#res=$(./cliente_escucha $$)
res=$(./fifo_escucha $clififo)

echo $res

if [[ $? = 1 ]]
then
    echo $res
    exit 1
fi

rm $clififo
