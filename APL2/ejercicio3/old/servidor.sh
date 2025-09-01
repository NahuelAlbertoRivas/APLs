#!/bin/bash
#AGUIRRE, SEBASTIAN HERNAN - DE LA CRUZ, LEANDRO ARIEL - JUCHANI CALLAMULLO, JAVIER ANDRES - LOIOTILE, JUAN CRUZ - RIVAS, NAHUEL ALBERTO

ayuda() {
    echo 'Para poder ejecutar correctamente el script, por favor especificar los siguientes parámetros:
         -i | --impresiones NumEnteroPositivo    (Cantidad de archivos a imprimir)'
}


# RECEPCIÓN DE PARÁMETROS

options=$(getopt -o i:h --l help,impresiones: -- "$@" 2> /dev/null)
if [ "$?" != "0" ]
then
    echo 'Opciones incorrectas'
    exit 1
fi
eval set -- "$options"

while true
do
    case "$1" in
        -i | --impresiones)
            IMPRESIONES="$2"
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


if [[ ! $IMPRESIONES =~ ^[1-9]+$ ]]
then
    echo "Por favor, especificar una cantidad de impresiones Entera mayor a 0."
    exit 1
fi

if [[ -e "/tmp/impresiones.log" ]]
then
    rm /tmp/impresiones.log
fi

cont=0

while [ $cont -lt $IMPRESIONES ]
do
    #res=$(./servidor_escucha)
    res=$(./fifo_escucha "/tmp/cola_impresion")

    if [[ $? = 1 ]]
    then
        echo $res
        exit 1
    fi

    pid=$(cut -d: -f 1 <<< $res)
    path=$(cut -d: -f 2 <<< $res)

    echo "PID $pid imprimió el archivo '$path' el día $(date +%d/%m/%y) a las $(date +%H:%M:%S)" >> /tmp/impresiones.log
    cat "$path" >> /tmp/impresiones.log
    echo >> /tmp/impresiones.log

    #res=$(./servidor_escribe "$pid" "OK")
    servfifo=$(echo "/tmp/FIFO_$pid")
    res=$(./fifo_escribe "$servfifo" "OK")

    (( cont += 1 ))

done

rm /tmp/cola_impresion

