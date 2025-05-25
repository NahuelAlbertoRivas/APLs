<#
.SYNOPSIS
    Script para operar con matrices (trasponer o producto escalar).
.DESCRIPTION
    Este script lee un archivo de entrada donde contiene la matriz y de acuerdo a la operacion que se desee realizar (trasponer o producto escalar)
    se genera un archivo de salida que contiene la matriz resultante

.PARAMETER Matriz
    Ruta al archivo que contiene la matriz
.PARAMETER Separador
    Carater que separa los elementos de la matriz. No puede ser numero ni "-"
.PARAMETER Trasponer
    Si se incluye este parametro, la matriz será traspuesta
.PARAMETER Producto
    Indica el valor del producto que debe aplicarse a la matriz ingresada
.EXAMPLE
    .\Ejercicio2.ps1 -matriz MatrizEntrada.txt -separador "#" -producto 4
    .\Ejercicio2.ps1 -matriz MatrizEntrada -separador '|' -trasponer


#>

# GRUPO 2
# INTEGRANTES
# AGUIRRE, SEBASTIAN HERNAN
# DE LA CRUZ, LEANDRO ARIEL
# JUCHANI CALLAMULLO, JAVIER ANDRES
# LOIOTILE, JUAN CRUZ
# RIVAS, NAHUEL ALBERTO

param(
[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
[Alias("-matriz")]
[string]$matriz,





[ValidateNotNullOrEmpty()]
[Alias("-producto") ]
[single]$producto,

[ValidateNotNullOrEmpty()]
[Alias("-trasponer") ]
[switch]$trasponer,


[Parameter(Mandatory=$true)]
[ValidateScript({
if (! $_ ){
  Write-Output 'Por favor especificar el caracter separador, debe estar entre comillas ("")'
}
elseif ($_ -eq "-" -or $_ -match  '^-?\d+$' ){
   throw 'El separador no puede ser "-" ni un número'
   $false
   }
    else{
    $true}

})]
[ValidateNotNullOrEmpty()]
[Alias("-separador") ]
[string]$separador
)

if (! $matriz )
{
    Write-Output "Por favor, especificar un archivo matriz con -m o --matriz, no puede ser vacío"
    exit 1
}

if (! $separador )
{
  Write-Output "Por favor, especificar un separador distinto de - o números, no puede ser vacío"
    exit 1
}


if ($trasponer -and $producto) {
    Write-Output  "Error: No puedes usar -trasponer y -separador al mismo tiempo."
    exit 0
}

if (! $trasponer -and ! $producto) {
    Write-Output  "Error: Debe seleccionar que tipo de operacion se debe realizar"
    exit 0
}



if(! (Test-Path $matriz))
{
    Write-Host "El archivo NO existe."
    exit 1
}

$ContenidoMatriz=Get-Content $matriz
if ($ContenidoMatriz -eq $null){
    Write-Output "Archivo Vacio"
    exit 1
}

$salida=@{}

##Obtengo el directorio origen del archivo ingresado
$directorio= Get-ChildItem -Path $matriz | Select-Object Directory

$directorio= $directorio.Directory.FullName

##Obtengo el nombre del archivo 
$nombreArchivoMatriz=[System.IO.Path]::GetFileName($Matriz)


function Trasponer(){

$columna=0
$Cantfilas= (Get-Content $matriz).Count 

 foreach ($valor in Get-Content $matriz)
    {
     $i=0;
      ##Separo la linea por el separador ingresado
     $separado= $valor -split "\$separador"
  
    ##Comparo cantidad de filas con la cantidad de elementos por fila
     #if ($Cantfilas.CompareTo(($separado.Length))){
      #    Write-Output "La matriz no es cuadrada"
       #   exit 0
        #  }
     foreach ($fila in $separado)
        {            
        if($fila   -match '^-?\d+(\.\d+)?$'){##Evaluo si es un numero 
    
             if($columna -eq 0 ){
                 $salida[$i]+= $fila  
             }else
                {
                 $salida[$i]+= "$separador"+$fila
                }
            }
            else{
                Write-Output "ERROR: La matriz contiene valores no numericos"
                exit 1
            }
         $i+= 1;
        }
     $columna=1
    }
    # Ordeno las claves de manera descendente
    $ClavesOrdenadas = $salida.Keys | Sort-Object
    # En el caso de que haya un archivo con el mismo nombre de salida, se elimina
    if (Test-Path ("$directorio"+"\salida."+"$nombreArchivoMatriz")){
        rm ("$directorio"+"\salida."+"$nombreArchivoMatriz")
    }

   
    foreach ($key in $ClavesOrdenadas) {
       $value = $salida[$key]
        $value >> ("$directorio"+"\salida."+"$nombreArchivoMatriz")
    }
    Write-Output "Archivo de salida generado correctamente"
}

function ProductoEscalar(){
## PRODUCTO ESCALAR
    $Matproducto=@()
       
     $CantElmxFil=0 
    foreach ($valor in Get-Content $matriz)

    {
        $filaSalida=$null
        $primerseparador=1
        
        $Filaseparada= $valor -split "\$separador"
       
        if($CantElmxFil -eq 0){
            $CantElmxFil=1
            $validadordeMatriz=$Filaseparada.Length
        }

        #Verificamos que la matriz contenga la misma cantidad de elementos por fila
        if($Filaseparada.Length  -ne $validadordeMatriz ){
        Write-Output "La matriz esta incompleta y/o mal formada"
         exit 1 
        }
        

        foreach ($fila in $Filaseparada)
        {

         
        if($fila   -match '^-?\d+(\.\d+)?$'){ 
            #Utilizamos el metodo [math]::Round para poder redondear el producto en caso de que sea decimal
            if($primerseparador -eq 1)
            {
                 $filaSalida+= [string](([math]::Round(([single]$fila * $producto),2)))
                $primerseparador=0
            }
            else
                {                     
                $filaSalida+=[string]"$separador"+(([math]::Round(([single]$fila * $producto),2)))
                }
        }
        else
        {
          Write-Output  "ERROR: La matriz contiene valores no numericos"
          Exit 1
        }
        }


      $Matproducto += $filaSalida

    }

$Matproducto> ("$directorio"+"\salida."+"$nombreArchivoMatriz")
Write-Output "Archivo de salida generado correctamente"
}



if ($trasponer -eq $true -and !$producto){
    Trasponer}
    elseif($producto){
    ProductoEscalar
    }

