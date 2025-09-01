<#
.SYNOPSIS
Este script procesa archivos de texto, contando la cantidad de ocurrencias
de determinadas palabras o expresiones de inter�s (las cuales deben ser detalladas en un array),
indicando a su vez las extensiones de los archivos en las que aquellas podr�an encontrarse

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
          - directorio ./ruta_datos                     (PARÁMETRO OBLIGATORIO. Indicar la ruta donde se encuentren los archivos fuente con datos)
          - palabras "exp 1#...#exp N"                  (PARÁMETRO OBLIGATORIO. Indicar la/s expresión/es de interés, en el segundo caso separadas por #)
          - archivos "[extensión1] ... [extensiónN]"     (PARÁMETRO OBLIGATORIO. Indicar la/s extensión/es de interés, en el segundo caso separadas por un espacio)



.PARAMETER -directorio
Directorio donde se encuentran los archivos -fuente de datos-. (Obligatorio)


.PARAMETER -archivo
Extensiones de los archivos que interesa relevar. (Obligatorio)

.EXAMPLE
./ejercicio3.ps1 -palabras 'if#else#return#while' -directorio "./datos_ejercicio3" -archivos "c h txt"

.EXAMPLE
./ejercicio3.ps1 -palabras 'if#else#return#in' -directorio ./datos_ejercicio3 -archivos "c h txt"

.EXAMPLE
./ejercicio3.ps1 -palabras 'if#else#return#in#;' -directorio ./datos_ejercicio3 -archivos "c h txt"

.EXAMPLE
./ejercicio3.ps1 -archivos "c h txt" -palabras 'if#else#return#i#;' -directorio ./datos_ejercicio3
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

   
   [string[]]$directorio,

    [Parameter(Mandatory=$true)]
    [string[]]$palabras,

    [Parameter(Mandatory=$true)]
    [string[]]$archivos
)

# Parseamos las palabras y extensiones
$expList = $palabras -split '#'  
$exts = $archivos -split '\s+' 

$resultado = @{}
$resultado = New-Object 'System.Collections.Hashtable' -ArgumentList ( [System.StringComparer]::Ordinal )
foreach ($exp in $expList) {
    $resultado[$exp] = 0
}


# Filtramos los archivos dentro del o los directorios con las extensiones ingresadas
$archivosExt = Get-ChildItem -Path $directorio -Recurse -File | Where-Object {
    $ext = $_.Extension.TrimStart('.')
    $exts -contains $ext
}

# Verificar si se encontraron archivos
if ($archivosExt.Count -eq 0) {
    Write-Error "No se encontraron archivos con las extensiones especificadas."
    return
}


# Procesamiento de archivos
foreach ($archivo in $archivosExt) {
          
        Get-Content $archivo.FullName | ForEach-Object {
        $linea = $_
        foreach ($exp in $expList) {
        # Dividimos la l�nea usando espacios, y luego contamos las veces que aparece la palabra exacta
        $palabras = $linea.Split(' ', [StringSplitOptions]::RemoveEmptyEntries)
     
        $contador = ($palabras | Where-Object { [String]::Equals($_, $exp, [StringComparison]::Ordinal) }).Count
       
        $resultado[$exp] += $contador
    }
}
        
} 

Write-Output "Resultado de coincidencias por palabra"
$resultado.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
 
    Write-Output "$($_.Key): $($_.Value)"
}