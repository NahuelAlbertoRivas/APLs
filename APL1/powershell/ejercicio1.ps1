<#
.SYNOPSIS
Este script procesa archivos CSV de temperaturas agrupados por fecha y ubicación cardinal,
generando un informe en formato JSON.

.DESCRIPTION
Este script:
- Lee archivos .csv en un directorio
- Agrupa temperaturas por fecha y ubicación
- Calcula mínimo, máximo y promedio por fecha
- Exporta o muestra el resultado en formato JSON

Para poder ejecutar correctamente el script, por favor especificar los siguientes parámetros:
         -d | -- directorio ./ruta_datos                    (indicar la ruta donde se encuentren los archivos con datos a procesar)
         -a | --archivo nombre_archivo.json  ó   -p         (indicar UNA salida en particular, por archivo ó directo a pantalla)

.PARAMETER -d
Directorio donde se encuentran los archivos CSV -fuente de datos-. (Obligatorio)

.PARAMETER -directorio
Directorio donde se encuentran los archivos CSV -fuente de datos-. (Obligatorio)

.PARAMETER -a
Archivo donde se guardará la salida JSON. No puede combinarse con -p, -pantalla o -archivo.

.PARAMETER -archivo
Archivo donde se guardará la salida JSON. No puede combinarse con -p, -pantalla o -a.

.PARAMETER -p
Muestra la salida JSON por pantalla. No puede combinarse con -a, -archivo o -pantalla.

.PARAMETER -pantalla
Muestra la salida JSON por pantalla. No puede combinarse con -a, -archivo o -p.

.EXAMPLE
.\ejercicio1.ps1 -d "./datos_ejercicio1" -a salida.json

.EXAMPLE
.\ejercicio1.ps1 -d ./datos_ejercicio1 -p

.EXAMPLE
.\ejercicio1.ps1 -d ./datos_ejercicio1 -archivo salida.json

.EXAMPLE
.\ejercicio1.ps1 -d ./datos_ejercicio1 -pantalla
#>

#                       GRUPO 2
# INTEGRANTES
#   AGUIRRE, SEBASTIAN HERNAN
#   DE LA CRUZ, LEANDRO ARIEL
#   JUCHANI CALLAMULLO, JAVIER ANDRES
#   LOIOTILE, JUAN CRUZ
#   RIVAS, NAHUEL ALBERTO

# RECEPCIÓN DE PARÁMETROS

param (
    [Parameter(Mandatory=$true)]
    [ValidateScript({
        if (-not (Test-Path $_)) {
            throw "El directorio especificado '$_' no existe. Por favor, revisá la ruta"
        }
        return $true
    })]

    [ALias("directorio")]
    [string]$d,
    # No establecemos que uno u otro (-p y -a), ni tampoco ambos al mismo tiempo, sean obligatorios porque requiere una lógica más detallada
    [Alias("archivo")]
    [string]$a,
    [Alias("pantalla")]
    [switch]$p
)

# VALIDACIONES EXTRA DE PARÁMETROS

if ($a -and $p) {
    Write-Error "No se puede usar -a y -p (o -archivo y -pantalla, en ninguna combinación posible) al mismo tiempo"
    exit 1
}

if (-not $a -and -not $p) {
    Write-Error "Por favor, especificar -a ó -p (ó -archivo ó -pantalla) para elegir la salida"
    exit 1
}

# Creamos una estructura para recopilar los datos de las temperaturas por fecha y ubicación cardinal (mínimo, máximo y promedio)
$temps = @{}

# PROCESAMIENTO DE ARCHIVOS - LECTURA DE REGISTROS

Get-ChildItem -Path $d -Filter *.csv | ForEach-Object {
    $archivo = $_.FullName

    # Leectura línea a línea
    Get-Content $archivo | ForEach-Object {
        $linea = $_.Trim()
        if (-not $linea) { return }

        $partes = $linea -split "," # establecemos el separador
        if ($partes.Count -lt 5) { return }

        $ubicacion = $partes[3].Trim()
        $temperatura = $partes[4].Trim()
        $fecha = $partes[1].Trim()

        if (-not ($ubicacion -and $temperatura -match '^[-]?\d+(\.\d+)?$')) {
            return
        }

        # Inicializamos las estructuras en primera instancia
        if (-not $temps.ContainsKey($fecha)) {
            $temps[$fecha] = @{}
        }

        if (-not $temps[$fecha].ContainsKey($ubicacion)) { # si no existía registro de tal fecha y ubicación, por defecto el nuevo registro será mín y máx
            $temps[$fecha][$ubicacion] = @{
                Min = [double]::Parse($temperatura)
                Max = [double]::Parse($temperatura)
                Sum = [double]::Parse($temperatura)
                Count = 1
            }
        } else {
            $entry = $temps[$fecha][$ubicacion]
            $tempVal = [double]::Parse($temperatura)

            if ($tempVal -lt $entry.Min) { $entry.Min = $tempVal }
            if ($tempVal -gt $entry.Max) { $entry.Max = $tempVal }

            $entry.Sum += $tempVal
            $entry.Count += 1
        }
    }
}

# FORMATEO DEL JSON

$resultado = @{
    fechas = @()
}

foreach ($fecha in $temps.Keys) {
    $datosUbicaciones = @{}
    foreach ($ubicacion in $temps[$fecha].Keys) {
        $data = $temps[$fecha][$ubicacion]
        $prom = [math]::Round($data.Sum / $data.Count, 1)

        $datosUbicaciones[$ubicacion] = @{
            Min = $data.Min
            Max = $data.Max
            Promedio = $prom
        }
    }

    $resultado.fechas += @{ $fecha = $datosUbicaciones }
}

# CONVERSIÓN A JSON

$json = $resultado | ConvertTo-Json -Depth 10

# SALIDA

if ($p) {
    Write-Output $json
} else {
    Set-Content -Path $a -Value $json -Encoding UTF8
}
