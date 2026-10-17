<#
=============================================================================
 restaurar_bd.ps1 - Restaura la base de datos de Control de Accesos
 desde cero, ejecutando todos los scripts SQL en el orden correcto.

 Uso (desde la raiz del repo, en PowerShell):
   .\restaurar_bd.ps1 -Database accesos_piloto
   .\restaurar_bd.ps1 -Database accesos_piloto -Crear          # crea la base si no existe
   .\restaurar_bd.ps1 -Database accesos_piloto -SoloRutinas    # re-aplica solo procedimientos y funciones
   .\restaurar_bd.ps1 -Database accesos_piloto -SoloPruebas    # solo corre las pruebas
   .\restaurar_bd.ps1 -Database accesos_piloto -SinPruebas     # restaura sin correr pruebas

 Parametros opcionales: -DbUser (postgres), -DbHost (localhost), -Port (5432),
                        -Psql (ruta de psql.exe si no esta en el PATH)

 Orden (se descubre solo; los scripts nuevos se incluyen sin editar esto):
   A. Tablas y datos : archivos NN_*.sql de Docs_Modulos\*\00_BD, por numero NN
   B. Rutinas        : SP_GOVERNANCE_*; luego SP_CAF_* de hitos 00-02 (sin SOLICITUD);
                       luego SP_CAF_SOLICITUD_BASE_ALL; luego el resto de SP_CAF_*
   C. Pruebas        : PRUEBAS_*.sql (terminan en ROLLBACK, no dejan datos)

 Los scripts NN_ se ejecutan UNA sola vez por base: usa una base vacia.
 Si una base ya tiene el modulo, el script se detiene y te lo dice.
 Se detiene en el primer error. Archivo escrito solo en ASCII a proposito
 (PowerShell 5.1 lee mal los acentos de un .ps1 sin BOM).
=============================================================================
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Database,
    [string]$DbUser = 'postgres',
    [string]$DbHost = 'localhost',
    [int]$Port = 5432,
    [string]$Psql = '',
    [switch]$Crear,
    [switch]$SoloRutinas,
    [switch]$SoloPruebas,
    [switch]$SinPruebas
)

$ErrorActionPreference = 'Stop'
$RepoRoot = $PSScriptRoot
$Modulos = Join-Path $RepoRoot 'Docs_Modulos'
if (-not (Test-Path $Modulos)) {
    throw "No encuentro la carpeta Docs_Modulos junto a este script ($RepoRoot). Ejecutalo desde la raiz del repo."
}

# ---- 1. Localizar psql ------------------------------------------------------
if (-not $Psql) {
    $cmd = Get-Command psql -ErrorAction SilentlyContinue
    if ($cmd) { $Psql = $cmd.Source }
    else {
        $cand = Get-ChildItem 'C:\Program Files\PostgreSQL\*\bin\psql.exe' -ErrorAction SilentlyContinue |
                Sort-Object FullName -Descending | Select-Object -First 1
        if ($cand) { $Psql = $cand.FullName }
    }
}
if (-not $Psql -or -not (Test-Path $Psql)) {
    throw "No encuentro psql.exe. Pasa su ruta con -Psql 'C:\Program Files\PostgreSQL\18\bin\psql.exe'"
}

# ---- 2. Clave y codificacion -----------------------------------------------
if (-not $env:PGPASSWORD) {
    $sec = Read-Host "Clave de PostgreSQL para '$DbUser'" -AsSecureString
    $env:PGPASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec))
}
$env:PGCLIENTENCODING = 'UTF8'
$conn = @('-h', $DbHost, '-p', "$Port", '-U', $DbUser)

# Nota: las consultas no llevan comillas dobles (PowerShell 5.1 las pierde al llamar a psql).
function Invoke-Sql([string]$db, [string]$sql) {
    $r = & $Psql @conn -d $db -At -v ON_ERROR_STOP=1 -c $sql
    if ($LASTEXITCODE -ne 0) { throw "Fallo la consulta en '$db': $sql" }
    return ($r -join "`n").Trim()
}
function Invoke-File([System.IO.FileInfo]$f) {
    Write-Host ("  > " + $f.Directory.Parent.Name + "\" + $f.Name) -ForegroundColor Cyan
    & $Psql @conn -d $Database -v ON_ERROR_STOP=1 -q -f $f.FullName
    if ($LASTEXITCODE -ne 0) {
        throw "ERROR en $($f.FullName). Revisa el mensaje de arriba. El proceso se detuvo aqui."
    }
}

# ---- 3. Descubrir archivos --------------------------------------------------
$todos = Get-ChildItem $Modulos -Recurse -Filter '*.sql' |
         Where-Object { $_.Directory.Name -eq '00_BD' }
function HitoNum($f) {
    $m = [regex]::Match($f.Directory.Parent.Name, '^HITO_(\d+)')
    if ($m.Success) { return [int]$m.Groups[1].Value } else { return 99 }
}
$tablas  = @($todos | Where-Object { $_.Name -match '^\d{2}_' } | Sort-Object Name)
$gov     = @($todos | Where-Object { $_.Name -like 'SP_GOVERNANCE_*' } | Sort-Object Name)
$cafA    = @($todos | Where-Object { $_.Name -like 'SP_CAF_*' -and $_.Name -notlike 'SP_CAF_SOLICITUD*' -and (HitoNum $_) -le 2 } | Sort-Object Name)
$base    = @($todos | Where-Object { $_.Name -eq 'SP_CAF_SOLICITUD_BASE_ALL.sql' })
$cafB    = @($todos | Where-Object { $_.Name -like 'SP_CAF_*' -and $_.Name -ne 'SP_CAF_SOLICITUD_BASE_ALL.sql' -and
                                     ($_.Name -like 'SP_CAF_SOLICITUD*' -or (HitoNum $_) -ge 3) } |
            Sort-Object @{Expression = { HitoNum $_ }}, Name)
$pruebas = @($todos | Where-Object { $_.Name -like 'PRUEBAS_*' } | Sort-Object @{Expression = { HitoNum $_ }}, Name)

# Scripts que NO se ejecutarian por estar fuera de una carpeta 00_BD: se avisa antes de empezar.
$fuera = @(Get-ChildItem $Modulos -Recurse -Filter '*.sql' |
           Where-Object { $_.Directory.Name -ne '00_BD' -and ($_.Name -match '^\d{2}_' -or $_.Name -like 'SP_*' -or $_.Name -like 'PRUEBAS_*') })
if ($fuera.Count -gt 0) {
    $msg = "Hay scripts fuera de una carpeta 00_BD; el restaurador los ignoraria y la base quedaria incompleta. Muevelos a la carpeta 00_BD de su hito:"
    foreach ($f in $fuera) { $msg += "`n  - " + $f.FullName.Substring($RepoRoot.Length + 1) }
    throw $msg
}

# Archivos repetidos (mismo nombre en dos carpetas, o dos scripts con el mismo numero NN):
# se detecta ANTES de tocar la base de datos.
$dup = @($todos | Group-Object Name | Where-Object { $_.Count -gt 1 })
$dup += @($tablas | Group-Object { $_.Name.Substring(0, 2) } | Where-Object { $_.Count -gt 1 })
if ($dup.Count -gt 0) {
    $msg = "Hay archivos repetidos en Docs_Modulos. Deja una sola copia de cada uno (la que esta en la carpeta de su hito) y vuelve a ejecutar:"
    foreach ($g in $dup) { $msg += "`n  - " + (($g.Group | ForEach-Object { $_.FullName.Substring($RepoRoot.Length + 1) }) -join "  <>  ") }
    throw $msg
}

if (-not $SoloPruebas -and -not $SoloRutinas -and $tablas.Count -eq 0) { throw 'No encontre scripts NN_*.sql.' }
Write-Host ("Encontrados: {0} scripts de tablas, {1} de rutinas, {2} de pruebas." -f $tablas.Count, ($gov.Count + $cafA.Count + $base.Count + $cafB.Count), $pruebas.Count)
if (-not $SoloPruebas -and $base.Count -ne 1) { throw 'Falta SP_CAF_SOLICITUD_BASE_ALL.sql (o esta duplicado).' }

# ---- 4. Base de datos -------------------------------------------------------
$existe = Invoke-Sql 'postgres' "SELECT count(*) FROM pg_database WHERE datname = '$Database'"
if ($existe -eq '0') {
    if ($Crear) {
        if ($Database -cnotmatch '^[a-z_][a-z0-9_]*$') { throw "Para -Crear usa un nombre en minusculas, sin espacios (ej. accesos_piloto)." }
        Write-Host "Creando base '$Database'..." -ForegroundColor Yellow
        Invoke-Sql 'postgres' "CREATE DATABASE $Database ENCODING 'UTF8'" | Out-Null
    } else {
        throw "La base '$Database' no existe. Crea una vacia o usa -Crear."
    }
}
$ver = Invoke-Sql $Database 'SHOW server_version_num'
if ([int]$ver -lt 140000) { throw "Se requiere PostgreSQL 14 o superior (version detectada: $ver)." }

$yaHay = Invoke-Sql $Database "SELECT count(*) FROM pg_namespace WHERE nspname IN ('CAF_GOVERNANCE','TRIANONSATELITAL_CAF_PRODD')"
if (-not $SoloRutinas -and -not $SoloPruebas) {
    if ($yaHay -ne '0') {
        throw "La base '$Database' ya tiene los schemas del modulo. Los scripts de tablas se ejecutan una sola vez: usa una base vacia, o -SoloRutinas / -SoloPruebas."
    }
} elseif ($yaHay -eq '0') {
    throw "La base '$Database' no tiene los schemas del modulo. Corre primero la restauracion completa."
}

# ---- 5. Ejecutar ------------------------------------------------------------
$t0 = Get-Date
if (-not $SoloRutinas -and -not $SoloPruebas) {
    Write-Host "`n== A. Tablas y datos iniciales ==" -ForegroundColor Green
    foreach ($f in $tablas) { Invoke-File $f }
}
if (-not $SoloPruebas) {
    Write-Host "`n== B. Procedimientos y funciones ==" -ForegroundColor Green
    foreach ($f in ($gov + $cafA + $base + $cafB)) { Invoke-File $f }
}
if (-not $SinPruebas) {
    Write-Host "`n== C. Pruebas ==" -ForegroundColor Green
    foreach ($f in $pruebas) { Invoke-File $f }
}

# ---- 6. Resumen -------------------------------------------------------------
$sqlRes = "SELECT n.nspname || ': ' || (SELECT count(*) FROM information_schema.tables t WHERE t.table_schema = n.nspname AND t.table_type = 'BASE TABLE') || ' tablas, ' || (SELECT count(*) FROM pg_proc p WHERE p.pronamespace = n.oid) || ' rutinas' FROM pg_namespace n WHERE n.nspname IN ('CAF_GOVERNANCE','TRIANONSATELITAL_CAF_PRODD') ORDER BY 1"
Write-Host "`n== Resultado ==" -ForegroundColor Green
Write-Host (Invoke-Sql $Database $sqlRes)
Write-Host ("Base '{0}' lista en {1:N0} s." -f $Database, ((Get-Date) - $t0).TotalSeconds) -ForegroundColor Green
Write-Host "Esperado a hoy (Hito 2 escritura): 11 + 24 tablas y 59 + 65 rutinas; pruebas 65, 143, 43 y 186 en OK."
