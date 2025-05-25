<#
.SYNOPSIS
Este script procesa archivos CSV de temperaturas agrupados por fecha y ubicación cardinal,
generando un informe en formato JSON.

.DESCRIPTION
Este script procesa archivos de texto, contando la cantidad de ocurrencias
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

.PARAMETER -d
Directorio donde se encuentran los archivos -fuente de datos-. (Obligatorio)

.PARAMETER -directorio
Directorio donde se encuentran los archivos -fuente de datos-. (Obligatorio)

.PARAMETER -a
Extensiones de los archivos que interesa relevar. (Obligatorio)

.PARAMETER -archivo
Extensiones de los archivos que interesa relevar. (Obligatorio)

.PARAMETER -p
Expresión/es de interés. (Obligatorio)

.PARAMETER -pantalla
Expresión/es de interés. (Obligatorio)

.EXAMPLE
./ejercicio3.ps1 -p 'if#else#return 0#while' -d "./datos_ejercicio3" -a "c h txt"

.EXAMPLE
./ejercicio3.ps1 -p 'if#else#return 0#i in' -d ./datos_ejercicio3 -a "c h txt"

.EXAMPLE
./ejercicio3.ps1 -palabras 'if#else#return 0#i in#;' -d ./datos_ejercicio3 -a "c h txt"

.EXAMPLE
./ejercicio3.ps1 -archivos "c h txt" -p 'if#else#return 0#i in#;' -directorio ./datos_ejercicio3
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

    [Parameter(Mandatory=$true)]
    [Alias("palabras")]
    [string]$p,
    [Parameter(Mandatory=$true)]
    [Alias("archivos")]
    [string]$a
)

# Parseamos extensiones y palabras
$exts = $a -split '\s+'
$expList = $p -split '#'

# Inicialización para el contador de ocurrencias
$resultado = @{}
foreach ($exp in $expList) {
    $resultado[$exp] = 0
}

# BÚSQUEDA DE ARCHIVOS Y PROCESAMIENTO (UNO A UNO)

$archivos = Get-ChildItem -Path $Directorio -Recurse -File | Where-Object {
    $exts -contains $_.Extension.TrimStart('.')
}

foreach ($archivo in $archivos) {
    Get-Content $archivo.FullName | ForEach-Object {
        $linea = $_
        foreach ($exp in $expList) {
            $resultado[$exp] += ([regex]::Matches($linea, $exp)).Count
        }
    }
}

# SALIDA A PANTALLA

$resultado.GetEnumerator() | Sort-Object Name | ForEach-Object {
    Write-Output "$($_.Key): $($_.Value)"
}