<#
.SYNOPSIS
    Regenera Docs_BD/ desde la base PostgreSQL del piloto (version PowerShell de generar_docs_bd.sh).

.DESCRIPTION
    Produce, por schema: <SCHEMA>_01_TABLAS_CONSOLIDADO.sql y <SCHEMA>_03_PROCEDIMIENTOS_CONSOLIDADO.sql,
    mas 00_INVENTARIO_GLOBAL.md. Mismo formato que la version bash.
    Docs_BD es la fuente de verdad: se regenera tras CADA despliegue y nunca se edita a mano.
    No guarda la contrasena en ningun archivo. Nada se escribe hasta que las consultas de TODOS
    los schemas terminaron bien: una base equivocada o un error no dejan archivos a medias.

.PARAMETER Base
    Nombre de la base de datos (por ejemplo accesos_piloto).

.PARAMETER Usuario
    Usuario de PostgreSQL. Por defecto postgres.

.PARAMETER Servidor
    Servidor. Por defecto localhost.

.PARAMETER Puerto
    Puerto. Por defecto 5432.

.PARAMETER RutaBin
    Carpeta donde estan psql.exe y pg_dump.exe, si no estan en el PATH
    (por ejemplo "C:\Program Files\PostgreSQL\18\bin").

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\generar_docs_bd.ps1 -Base accesos_piloto

.EXAMPLE
    .\generar_docs_bd.ps1 -Base accesos_piloto -Usuario postgres -RutaBin "C:\Program Files\PostgreSQL\18\bin"
#>
param(
    [Parameter(Mandatory = $true)][string]$Base,
    [string]$Usuario = 'postgres',
    [string]$Servidor = 'localhost',
    [int]$Puerto = 5432,
    [string]$RutaBin = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Todo lo que sale de psql y pg_dump se pide en UTF-8 y se lee como UTF-8 (nunca por la consola de Windows)
$env:PGCLIENTENCODING = 'UTF8'
$utf8 = New-Object System.Text.UTF8Encoding($false)

# --- Textos que van a los archivos: con codigos de caracter, para que no dependan del editor ---
$Punto = [string][char]0x00B7                       # punto medio
$IndiceTxt = ([string][char]0x00CD) + 'NDICE'       # INDICE con tilde
$FuncionTxt = 'funci' + ([string][char]0x00F3) + 'n' # funcion con tilde
$Bt = [string][char]96                              # acento grave (backtick)
$Q = [string][char]34                               # comilla doble

$Schemas = @('CAF_GOVERNANCE', 'TRIANONSATELITAL_CAF_PRODD')
$Salida = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$Fecha = (Get-Date).ToString('yyyy-MM-dd HH:mm', [System.Globalization.CultureInfo]::InvariantCulture)

# --- Herramientas de PostgreSQL ---
if ($RutaBin -ne '') { $env:PATH = $RutaBin + [System.IO.Path]::PathSeparator + $env:PATH }
$psqlCmd = Get-Command psql -ErrorAction SilentlyContinue
$dumpCmd = Get-Command pg_dump -ErrorAction SilentlyContinue
if (-not $psqlCmd -or -not $dumpCmd) {
    throw "No encuentro psql o pg_dump. Use -RutaBin con la carpeta bin de PostgreSQL, por ejemplo: -RutaBin 'C:\Program Files\PostgreSQL\18\bin'"
}
$psqlExe = $psqlCmd.Source
$dumpExe = $dumpCmd.Source

# --- Contrasena: se pide una vez y vive solo en esta sesion ---
if (-not $env:PGPASSWORD) {
    $seg = Read-Host -AsSecureString "Contrasena de PostgreSQL para el usuario $Usuario"
    $env:PGPASSWORD = (New-Object System.Net.NetworkCredential('', $seg)).Password
}

$conexion = "-h $Servidor -p $Puerto -U $Usuario -d $Base"

function Invoke-Nativo {
    param([string]$Exe, [string]$Argumentos)
    # Se pasa UNA sola cadena de argumentos: asi las comillas llegan tal cual en Windows PowerShell 5.1 y en 7
    $p = Start-Process -FilePath $Exe -ArgumentList $Argumentos -NoNewWindow -Wait -PassThru
    if ($p.ExitCode -ne 0) {
        throw "$([System.IO.Path]::GetFileName($Exe)) termino con error (codigo $($p.ExitCode)). Revise el mensaje de arriba."
    }
}

function Invoke-Consulta {
    # Ejecuta una consulta y devuelve el texto tal como lo escribe psql (psql escribe el archivo, no PowerShell)
    param([string]$Sql)
    if ($Sql.Contains($Q)) { throw 'La consulta no puede llevar comillas dobles.' }
    $tmp = [System.IO.Path]::GetTempFileName()
    try {
        Invoke-Nativo $psqlExe "$conexion -At -v ON_ERROR_STOP=1 -o $Q$tmp$Q -c $Q$Sql$Q"
        return [System.IO.File]::ReadAllText($tmp, $utf8)
    }
    finally { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
}

function Invoke-Dump {
    param([string]$Schema)
    $tmp = [System.IO.Path]::GetTempFileName()
    try {
        $nombre = '\' + $Q + $Schema + '\' + $Q   # llega a pg_dump como "SCHEMA" con comillas (respeta mayusculas)
        Invoke-Nativo $dumpExe "$conexion --schema-only --no-owner --no-privileges -n $nombre -f $Q$tmp$Q"
        $lineas = [System.IO.File]::ReadAllLines($tmp, $utf8)
    }
    finally { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
    # Equivale al grep -v y al sed de la version bash: sin SET, sin pg_catalog, sin \restrict, una sola linea en blanco seguida
    $sal = New-Object System.Collections.Generic.List[string]
    $antesBlanca = $false
    foreach ($l in $lineas) {
        if ($l -match '^(SET |SELECT pg_catalog|--$|\\restrict|\\unrestrict)') { continue }
        $blanca = ($l -match '^\s*$')
        if ($blanca -and $antesBlanca) { continue }
        $sal.Add($l)
        $antesBlanca = $blanca
    }
    return (($sal -join "`n") + "`n")
}

# --- 1. Reunir todo en memoria ---
$archivos = [ordered]@{}
$version = (Invoke-Consulta 'show server_version').Trim()
$inv = New-Object System.Text.StringBuilder
[void]$inv.Append("# Inventario global de Docs_BD`n`n")
[void]$inv.Append("Export del **$Fecha** $Punto base $Bt$Base$Bt $Punto motor PostgreSQL $version`n`n")
[void]$inv.Append("| Schema | Tablas | Funciones (lectura) | Procedimientos (escritura) |`n")
[void]$inv.Append("| --- | --: | --: | --: |`n")

foreach ($S in $Schemas) {
    Write-Host "Leyendo $S ..."
    $nt = [int](Invoke-Consulta "select count(*) from information_schema.tables where table_schema='$S' and table_type='BASE TABLE'").Trim()
    $nf = [int](Invoke-Consulta "select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='$S' and p.prokind='f'").Trim()
    $np = [int](Invoke-Consulta "select count(*) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='$S' and p.prokind='p'").Trim()
    if ($nt -eq 0) {
        throw "El schema $S no tiene tablas en la base '$Base'. Probablemente es la base equivocada: no se escribio ningun archivo."
    }

    # Tablas: indice + DDL (sin datos, sin duenos ni permisos)
    $t = New-Object System.Text.StringBuilder
    [void]$t.Append("-- Docs_BD $Punto $S $Punto TABLAS $Punto export $Fecha`n")
    [void]$t.Append("-- $IndiceTxt`n")
    [void]$t.Append((Invoke-Consulta "select '--  '||row_number() over (order by table_name)||'. '||table_name from information_schema.tables where table_schema='$S' and table_type='BASE TABLE' order by table_name"))
    [void]$t.Append("`n")
    [void]$t.Append((Invoke-Dump $S))
    $archivos["${S}_01_TABLAS_CONSOLIDADO.sql"] = $t.ToString()

    # Rutinas: indice + definicion de cada funcion y procedimiento
    $p = New-Object System.Text.StringBuilder
    [void]$p.Append("-- Docs_BD $Punto $S $Punto FUNCIONES Y PROCEDIMIENTOS $Punto export $Fecha`n")
    [void]$p.Append("-- $IndiceTxt`n")
    $indice = Invoke-Consulta "select '--  '||row_number() over (order by p.proname)||'. '||p.proname||case p.prokind when 'p' then ' (@proc@)' else ' (@func@)' end from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='$S' order by p.proname"
    $indice = $indice.Replace('(@proc@)', '(procedimiento)').Replace('(@func@)', "($FuncionTxt)")
    [void]$p.Append($indice)
    [void]$p.Append("`n")
    [void]$p.Append((Invoke-Consulta "select pg_get_functiondef(p.oid)||';'||chr(10) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='$S' order by p.proname"))
    $archivos["${S}_03_PROCEDIMIENTOS_CONSOLIDADO.sql"] = $p.ToString()

    [void]$inv.Append("| $Bt$S$Bt | $nt | $nf | $np |`n")
}
$archivos['00_INVENTARIO_GLOBAL.md'] = $inv.ToString()

# --- 2. Escribir (solo si todo salio bien) ---
foreach ($nombre in $archivos.Keys) {
    [System.IO.File]::WriteAllText((Join-Path $Salida $nombre), $archivos[$nombre], $utf8)
}
Write-Host ''
Write-Host (Get-Content -LiteralPath (Join-Path $Salida '00_INVENTARIO_GLOBAL.md') -Encoding UTF8 | Select-Object -Skip 4) -Separator "`n"
Write-Host ''
Write-Host "Docs_BD regenerado en $Salida ($Fecha)"
