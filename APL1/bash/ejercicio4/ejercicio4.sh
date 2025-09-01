#!/bin/bash

#                       GRUPO 2
# INTEGRANTES
#   AGUIRRE, SEBASTIAN HERNAN
#   DE LA CRUZ, LEANDRO ARIEL
#   JUCHANI CALLAMULLO, JAVIER ANDRES
#   LOIOTILE, JUAN CRUZ
#   RIVAS, NAHUEL ALBERTO

# Requiere inotify-tools para ejecutar

if ! command -v inotifywait >/dev/null 2>&1; then
    echo "Error: el script requiere 'inotify-tools' (comando 'inotifywait')."
    echo "Instalalo con: sudo apt install inotify-tools"
    exit 1
fi

ayuda() {
    echo "Para poder ejecutar correctamente el script, por favor especificar los siguientes parámetros:
         -d | --directorio ./ruta_monitoreo
         -b | --backup ./ruta_backup
         -k | --kill
         -c | --cantidad 5
         Solo se puede usar rutas a directorios existentes.
         
Ejemplos

[Iniciarlo]
./ejercicio4v3.sh -d ../downloads -b ../backups -c 3

[Detenerlo]
./ejercicio4v3.sh -d ../downloads -k"
}

CANT_DEFAULT=3
PID_FILE="/tmp/monitores.pid"
KILL_FLAG=false
touch "$PID_FILE"

manejadorSigTerm() {
    echo "$0 : Proceso terminado (SIGTERM)."
    trap "kill 0" EXIT
    exit 0
}

manejadorSigInt() {
    echo "$0 : Proceso terminado (SIGINT)."
    trap "kill 0" EXIT
    exit 0
}

trap manejadorSigTerm SIGTERM
trap manejadorSigInt SIGINT

finalizar_daemon() {
    if [[ -z "$DIR_MONITOR" ]]; then
        echo "Debe especificar una ruta con -d o --directorio para finalizar el monitoreo."
        exit 1
    fi

    DIR_MONITOR_ABS=$(realpath "$DIR_MONITOR")
    LINEA=$(grep -E "^[0-9]+:$DIR_MONITOR_ABS\$" "$PID_FILE")

    if [[ -z "$LINEA" ]]; then
        echo "No se encontró un daemon para la ruta '$DIR_MONITOR_ABS'."
        exit 1
    fi

    PID=$(echo "$LINEA" | cut -d':' -f1)

    if kill -0 "$PID" 2>/dev/null; then
        kill -s SIGTERM "$PID"
        echo "Proceso $PID para '$DIR_MONITOR_ABS' finalizado."
    else
        echo "Proceso $PID ya no está activo."
    fi

    sed -i "\|^$PID:$DIR_MONITOR_ABS\$|d" "$PID_FILE"
}

ordenar_archivo() {
    local ARCHIVO="$1"
    if [[ -f "$ARCHIVO" ]]; then
        EXTENSION="${ARCHIVO##*.}"
        if [[ "$ARCHIVO" == "$EXTENSION" ]]; then
            EXTENSION_MAYUS="SIN_EXTENSION"
        else
            EXTENSION_MAYUS=$(echo "$EXTENSION" | tr '[:lower:]' '[:upper:]')
        fi
        SUBDIR="$DIR_MONITOR_ABS/$EXTENSION_MAYUS"
        mkdir -p "$SUBDIR"
        mv "$ARCHIVO" "$SUBDIR/"
        echo "Archivo movido a: $SUBDIR/"
    fi
}

iniciar_monitoreo() {
    for ARCHIVO in "$DIR_MONITOR_ABS"/*; do
        if [[ -f "$ARCHIVO" ]]; then
            ordenar_archivo "$ARCHIVO"
        fi
    done

    CONTADOR=0
    while read -r ARCHIVO; do
        echo "Se escribió un nuevo archivo: $ARCHIVO"
        ordenar_archivo "$ARCHIVO"
        ((CONTADOR++))
        echo "Cantidad de archivos movidos: $CONTADOR"

        if (( CONTADOR >= CANT_BACKUP )); then
            TIMESTAMP=$(date +%Y%m%d%H%M%S)
            ARCHIVO_BACKUP="$DIR_BACKUP_ABS/backup_${TIMESTAMP}_$RANDOM.tar.gz"
            tar -czf "$ARCHIVO_BACKUP" -C "$DIR_MONITOR_ABS" .
            echo "Backup creado: $ARCHIVO_BACKUP"
            CONTADOR=0
        fi
    done < <(inotifywait -m -e close_write,moved_to --format '%w%f' "$DIR_MONITOR_ABS")
}

# PARÁMETROS
options=$(getopt -o d:b:c:kh --long help,directorio:,backup:,cantidad:,kill -- "$@" 2>/dev/null)
if [ "$?" != "0" ]; then
    echo 'Opciones incorrectas'
    exit 1
fi
eval set -- "$options"

while true; do
    case "$1" in 
        -d | --directorio) DIR_MONITOR="$2"; shift 2 ;;
        -b | --backup) DIR_BACKUP="$2"; shift 2 ;;
        -c | --cantidad) CANT_BACKUP="$2"; shift 2 ;;
        -k | --kill) KILL_FLAG=true; shift ;;
        -h | --help) ayuda; exit 0 ;;
        --) shift; break ;;
        *) echo "Error de opciones"; exit 1 ;;
    esac
done

if $KILL_FLAG; then
    finalizar_daemon
    exit 0
fi

# VALIDACIONES
if [[ -z "$DIR_MONITOR" ]]; then
    echo "Debe especificar un directorio con -d o --directorio"
    exit 1
fi

DIR_MONITOR_ABS=$(realpath "$DIR_MONITOR")
if [[ ! -d "$DIR_MONITOR_ABS" ]]; then
    echo "El directorio '$DIR_MONITOR_ABS' no existe."
    exit 1
fi

if [[ -z "$DIR_BACKUP" ]]; then
    echo "Debe especificar un directorio de backup con -b o --backup"
    exit 1
fi

DIR_BACKUP_ABS=$(realpath "$DIR_BACKUP")
if [[ ! -d "$DIR_BACKUP_ABS" ]]; then
    echo "El directorio '$DIR_BACKUP_ABS' no existe."
    exit 1
fi

if [[ -z "$CANT_BACKUP" ]]; then
    CANT_BACKUP=$CANT_DEFAULT
fi

if ! [[ "$CANT_BACKUP" =~ ^[0-9]+$ ]]; then
    echo "La cantidad (-c) debe ser un número entero positivo."
    exit 1
fi

# VERIFICACIÓN DE PID EXISTENTE
LINEA_EXISTENTE=$(grep -E "^[0-9]+:$DIR_MONITOR_ABS\$" "$PID_FILE")
if [[ -n "$LINEA_EXISTENTE" ]]; then
    PID_EXISTENTE=$(echo "$LINEA_EXISTENTE" | cut -d':' -f1)
    if kill -0 "$PID_EXISTENTE" 2>/dev/null; then
        echo "Ya hay un daemon ejecutándose para '$DIR_MONITOR_ABS' (PID: $PID_EXISTENTE)"
        exit 1
    else
        sed -i "\|^[0-9]\+:$DIR_MONITOR_ABS\$|d" "$PID_FILE"
    fi
fi

# Lanzar daemon con nohup
nohup bash -c "$(declare -f iniciar_monitoreo ordenar_archivo); DIR_MONITOR_ABS='$DIR_MONITOR_ABS'; DIR_BACKUP_ABS='$DIR_BACKUP_ABS'; CANT_BACKUP=$CANT_BACKUP; iniciar_monitoreo" > nohup.out 2>&1 &

PID_DAEMON=$!
echo "$PID_DAEMON:$DIR_MONITOR_ABS" >> "$PID_FILE"
echo "Daemon iniciado para '$DIR_MONITOR_ABS' (PID: $PID_DAEMON)"
