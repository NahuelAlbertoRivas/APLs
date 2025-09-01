#AGUIRRE, SEBASTIAN HERNAN - DE LA CRUZ, LEANDRO ARIEL - JUCHANI CALLAMULLO, JAVIER ANDRES - LOIOTILE, JUAN CRUZ - RIVAS, NAHUEL ALBERTO

<#
.SYNOPSIS
  Para poder ejecutar correctamente el script, por favor seguir lo especificado en la sintaxis.

.DESCRIPTION
  Para poder ejecutar correctamente el script, por favor especificar los siguientes parámetros:
    -directorio ./ruta_monitoreo     (Ruta al directorio a monitorear)
    -backup ./ruta_backup            (Ruta al directorio donde se genera el backup)
    -kill                           (Detener el proceso de monitoreo)
    -cantidad 5                     (Cantidad de archivos a ordenar antes de generar un backup)

  Solo se pueden usar rutas a directorios existentes.

.EXAMPLE
  ./demonio.ps1 -directorio ../descargas -backup ../backup -cantidad 3

.EXAMPLE
  ./demonio.ps1 -directorio ../descargas -kill
#>
Param(
    [Parameter(Mandatory=$true, ParameterSetName="Crear")]
    [Parameter(Mandatory=$true, ParameterSetName="Eliminar")]
    [ValidateNotNullOrEmpty()]
    [string] $directorio,

    [Parameter(Mandatory=$true, ParameterSetName="Crear")]
    [ValidateNotNullOrEmpty()]
    [string] $backup,

    [Parameter(Mandatory=$true, ParameterSetName="Crear")]
    [int] $cantidad,

    [Parameter(Mandatory=$true, ParameterSetName="Eliminar")]
    [switch] $kill
)

$DIR_ARC_MON = "/tmp/ejercicio4"
if (-not (Test-Path $DIR_ARC_MON)) {
    New-Item -ItemType Directory -Path $DIR_ARC_MON -Force | Out-Null
}

$pidFile = Join-Path -Path $DIR_ARC_MON -ChildPath "monitores_ps.txt"

function ObtenerMonitores {
    if (Test-Path $pidFile) {
        Get-Content $pidFile | ForEach-Object {
            $parts = $_ -split '=', 2
            if ($parts.Count -eq 2) {
                [PSCustomObject]@{
                    Path = $parts[0]
                    JobId = [int]$parts[1]
                }
            }
        }
    } else {
        @()
    }
}

function GuardarMonitores($monitores) {
    $monitores | ForEach-Object {
        "$($_.Path)=$($_.JobId)"
    } | Set-Content $pidFile
}

function MatarProceso {
    $monitores = ObtenerMonitores
    $absDir = (Resolve-Path $directorio).Path
    $target = $monitores | Where-Object { $_.Path -eq $absDir }

    if ($target) {
        try {
            $job = Get-Job -Id $target.JobId -ErrorAction SilentlyContinue
            if ($job) {
                Stop-Job -Job $job
                Remove-Job -Job $job
                $monitores = $monitores | Where-Object { $_.Path -ne $absDir }
                GuardarMonitores $monitores
                Write-Host "Proceso para '$absDir' detenido correctamente."
            } else {
                Write-Host "No se encontró proceso activo para '$absDir'."
            }
        } catch {
            Write-Warning "Error al detener el proceso: $_"
        }
    } else {
        Write-Host "No existe proceso corriendo para '$absDir'."
    }
}

if ($kill) {
    MatarProceso
    exit
}

$directorio = (Resolve-Path $directorio).Path
$backup = (Resolve-Path $backup).Path

Write-Host "Monitorizando: $directorio"
Write-Host "Backup en: $backup"
Write-Host "Archivos por backup: $cantidad"

$existentes = ObtenerMonitores
if ($existentes | Where-Object { $_.Path -eq $directorio }) {
    Write-Host "Ya existe un proceso monitoreando '$directorio'."
    exit
}

Write-Host "Iniciando monitor en segundo plano..."

$job = Start-Job -ScriptBlock {
    param($directorio, $backup, $cantidad, $pidFile)

    function OrdenarArchivosExistentes {
        Get-ChildItem -Path $directorio -File | ForEach-Object {
            $archivo = $_.FullName
            $extension = $_.Extension.TrimStart('.').ToUpper()
            if (-not $extension) { $extension = "SIN_EXTENSION" }
            $subcarpeta = Join-Path $directorio $extension
            if (-not (Test-Path $subcarpeta)) {
                New-Item -ItemType Directory -Path $subcarpeta | Out-Null
            }
            Move-Item -Path $archivo -Destination $subcarpeta -Force
        }
    }

    function CrearBackup {
        $fecha = Get-Date -Format "yyyyMMdd_HHmmss"
        $nombre = "$(Split-Path $directorio -Leaf)_$fecha.zip"
        $destino = Join-Path $backup $nombre
        Compress-Archive -Path "$directorio/*" -DestinationPath $destino -Force
    }

    $monitores = @()
    if (Test-Path $pidFile) {
        $monitores = Get-Content $pidFile | ForEach-Object {
            $parts = $_ -split '=', 2
            if ($parts.Count -eq 2) {
                [PSCustomObject]@{ Path = $parts[0]; JobId = [int]$parts[1] }
            }
        }
    }
    $monitores += [PSCustomObject]@{ Path = $directorio; JobId = $PID }
    $monitores | ForEach-Object { "$($_.Path)=$($_.JobId)" } | Set-Content $pidFile

    $watcher = New-Object IO.FileSystemWatcher $directorio, "*"
    $watcher.IncludeSubdirectories = $false
    $watcher.EnableRaisingEvents = $true

    if (Get-EventSubscriber -SourceIdentifier archivoNuevo -ErrorAction SilentlyContinue) {
        Unregister-Event -SourceIdentifier archivoNuevo -Force
        Remove-Event -SourceIdentifier archivoNuevo -ErrorAction SilentlyContinue
    }

    Register-ObjectEvent -InputObject $watcher -EventName Created -SourceIdentifier archivoNuevo

    OrdenarArchivosExistentes

    $contador = 0
    while ($true) {
        $evento = Wait-Event -SourceIdentifier archivoNuevo
        $archivo = $evento.SourceEventArgs.FullPath

        if (-not (Test-Path $archivo -PathType Leaf)) {
            Remove-Event -SourceIdentifier archivoNuevo
            continue
        }

        $ext = [IO.Path]::GetExtension($archivo).TrimStart('.').ToUpper()
        if (-not $ext) { $ext = "SIN_EXTENSION" }
        $subcarpeta = Join-Path $directorio $ext
        if (-not (Test-Path $subcarpeta)) {
            New-Item -ItemType Directory -Path $subcarpeta | Out-Null
        }

        Move-Item -Path $archivo -Destination $subcarpeta -Force

        $contador++
        if ($contador -ge $cantidad) {
            CrearBackup
            $contador = 0
        }

        Remove-Event -SourceIdentifier archivoNuevo
    }

} -ArgumentList $directorio, $backup, $cantidad, $pidFile

$monitores = @(ObtenerMonitores)
$monitores += [PSCustomObject]@{ Path = $directorio; JobId = $job.Id }
GuardarMonitores $monitores

Write-Host "Monitor activo en segundo plano para '$directorio'."

