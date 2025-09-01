<#
.SYNOPSIS
    Consulta información nutricional de frutas por nombre o ID utilizando una API pública.

.DESCRIPTION
    Este script permite consultar frutas usando su nombre o ID a través de la API de Fruityvice.
    La información recuperada incluye el nombre, género, calorías, grasa, azúcar, carbohidratos y proteína.
    Para optimizar las consultas, los resultados se almacenan temporalmente en caché local.

.PARAMETER id
    Lista de identificadores numéricos de frutas a consultar.

.PARAMETER name
    Lista de nombres de frutas a consultar.

.EXAMPLE
    .\ejercicio5.ps1 -id 6,9
    Consulta las frutas con ID 6 y 9.

.EXAMPLE
    .\ejercicio5.ps1 -name "banana","apple"
    Consulta la información nutricional de banana y apple por nombre.

.NOTES
    El script usa caché temporal en /tmp/cache_ej5
    Los resultados se eliminan al finalizar la ejecución.

.LINK
    https://www.fruityvice.com/
#>

# GRUPO 2
# INTEGRANTES
# AGUIRRE, SEBASTIAN HERNAN
# DE LA CRUZ, LEANDRO ARIEL
# JUCHANI CALLAMULLO, JAVIER ANDRES
# LOIOTILE, JUAN CRUZ
# RIVAS, NAHUEL ALBERTO

param (
    [int[]]$id,
    [string[]]$name
)

# Directorio común de caché
$CACHE_DIR = "/tmp/cache_ej5"





try {
    # Crear el directorio de caché si no existe
    if (-not (Test-Path -Path $CACHE_DIR)) {
        New-Item -ItemType Directory -Path $CACHE_DIR | Out-Null
    }

    # Procesar por nombre
    if ($name) {
        foreach ($fruta in $name) {
            if ($fruta -match '^\d+$') {
            Write-Output "Error: Pasaste un número como nombre (NOMBRE: '$fruta')."
            continue
            }
            $fruta = $fruta.ToLower()
            $archivo_cache = Join-Path -Path $CACHE_DIR -ChildPath "${fruta}_respuesta.json"
            
            
            if (Test-Path -Path $archivo_cache) {
                $http_code = 200
                $data = Get-Content -Path $archivo_cache | ConvertFrom-Json
            } else {
                try {
                    $response = Invoke-WebRequest "https://www.fruityvice.com/api/fruit/$fruta" -Method Get -ErrorAction Stop
                    $http_code = $response.StatusCode
                    $response.Content | Set-Content -Path $archivo_cache
                    $data = $response.Content | ConvertFrom-Json
                } catch {
                    if ($_.Exception.Response.StatusCode -eq 404) {
                        Write-Output "Error: La fruta '$fruta' no se encontró (Nombre no válido)."
                    } elseif ($_.Exception.Response.StatusCode -eq 500) {
                        Write-Output "Error: Hubo un problema con el servidor de la API."
                    } else {
                        Write-Output "Error: Código HTTP inesperado al consultar '$fruta'."
                    }
                    continue
                }
            }

            if ($http_code -eq 200) {
                Write-Output "id: $($data.id)"
                Write-Output "name: $($data.name)"
                Write-Output "genus: $($data.genus)"
                Write-Output "calories: $($data.nutritions.calories)"
                Write-Output "fat: $($data.nutritions.fat)"
                Write-Output "sugar: $($data.nutritions.sugar)"
                Write-Output "carbohydrates: $($data.nutritions.carbohydrates)"
                Write-Output "protein: $($data.nutritions.protein)"
                Write-Output ""
            }
        }
    }

    # Procesar por ID
    if ($id) {
        foreach ($id_consulta in $id) {
            $archivo_cache = Join-Path -Path $CACHE_DIR -ChildPath "${id_consulta}_respuesta.json"

            if (Test-Path -Path $archivo_cache) {
                $http_code = 200
                $data = Get-Content -Path $archivo_cache | ConvertFrom-Json
            } else {
                try {
                    $response = Invoke-WebRequest "https://www.fruityvice.com/api/fruit/$id_consulta" -Method Get -ErrorAction Stop
                    $http_code = $response.StatusCode
                    $response.Content | Set-Content -Path $archivo_cache
                    $data = $response.Content | ConvertFrom-Json
                } catch {
                    if ($_.Exception.Response.StatusCode -eq 404) {
                        Write-Output "Error: El ID '$id_consulta' no se encontró (Nombre no válido)."
                    } elseif ($_.Exception.Response.StatusCode -eq 500) {
                        Write-Output "Error: Hubo un problema con el servidor de la API."
                    } else {
                        Write-Output "Error: Código HTTP inesperado al consultar '$id_consulta'."
                    }
                    continue
                }
            }

            if ($http_code -eq 200) {
                Write-Output "id: $($data.id)"
                Write-Output "name: $($data.name)"
                Write-Output "genus: $($data.genus)"
                Write-Output "calories: $($data.nutritions.calories)"
                Write-Output "fat: $($data.nutritions.fat)"
                Write-Output "sugar: $($data.nutritions.sugar)"
                Write-Output "carbohydrates: $($data.nutritions.carbohydrates)"
                Write-Output "protein: $($data.nutritions.protein)"
                Write-Output ""
            }
        }
    }

}catch {
    Write-Output "Ocurrió un error inesperado: $_"
}
