# =====================================================================
#  Compilador automatico - SuperMarket
#  Genera el APK listo para instalar en cualquier telefono Android.
#  Uso: doble clic en COMPILAR_APK.bat
# =====================================================================

$AppName = 'SuperMarket'
$Org     = 'com.supermarket'

$ErrorActionPreference = 'Continue'
Set-Location -Path $PSScriptRoot
$Host.UI.RawUI.WindowTitle = "Compilador $AppName"

function Step($n, $text) { Write-Host "`n[$n/6] $text" -ForegroundColor Cyan }
function Ok($text)       { Write-Host "      OK  $text" -ForegroundColor Green }
function Fail($text) {
    Write-Host "`n[ERROR] $text" -ForegroundColor Red
    Read-Host "`nPresiona Enter para salir"
    exit 1
}
function Invoke-Flutter([string[]]$argList) {
    & flutter @argList
    if ($LASTEXITCODE -ne 0) { Fail "Fallo el comando: flutter $($argList -join ' ')" }
}

Write-Host "=============================================" -ForegroundColor Yellow
Write-Host "   COMPILADOR AUTOMATICO DE $AppName"         -ForegroundColor Yellow
Write-Host "=============================================" -ForegroundColor Yellow

# 1. Verificar Flutter --------------------------------------------------
Step 1 'Verificando Flutter...'
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Fail ("Flutter no esta instalado o no esta en el PATH.`n" +
          "Instalalo desde https://docs.flutter.dev/get-started/install/windows`n" +
          "y luego ejecuta 'flutter doctor' para aceptar las licencias de Android.")
}
$ver = (& flutter --version | Select-Object -First 1)
Ok $ver

# 2. Generar carpeta android si no existe -------------------------------
Step 2 'Preparando proyecto Android...'
$manifest = Join-Path $PSScriptRoot 'android\app\src\main\AndroidManifest.xml'
if (-not (Test-Path $manifest)) {
    Invoke-Flutter @('create', '--org', $Org, '--project-name', 'super_app', '--platforms', 'android', '.')
    Ok 'Carpeta android creada'
} else {
    Ok 'Carpeta android ya existe'
}

# 3. Poner el nombre de la app -----------------------------------------
Step 3 "Asignando el nombre '$AppName'..."
$xml = [IO.File]::ReadAllText($manifest)
$xml = [regex]::Replace($xml, 'android:label="[^"]*"', "android:label=`"$AppName`"")
[IO.File]::WriteAllText($manifest, $xml)
Ok "Nombre bajo el icono: $AppName"

# 4. Dependencias -------------------------------------------------------
Step 4 'Descargando dependencias...'
Invoke-Flutter @('pub', 'get')
Ok 'Dependencias listas'

# 4b. Android 5.0+ y clave de firma propia (la crea la primera vez en firma\)
Write-Host '      Preparando Android 5.0+ y clave de firma propia...'
& dart run tool/preparar_android.dart $AppName
if ($LASTEXITCODE -ne 0) { Fail 'No se pudo preparar la firma / version minima de Android' }

# 5. Compilar -----------------------------------------------------------
Step 5 'Compilando APK (la primera vez puede tardar 5-10 minutos)...'
Invoke-Flutter @('build', 'apk', '--release')
Ok 'Compilacion terminada'

# 6. Copiar resultado ---------------------------------------------------
Step 6 'Guardando el APK...'
$src = Join-Path $PSScriptRoot 'build\app\outputs\flutter-apk\app-release.apk'
if (-not (Test-Path $src)) { Fail "No se encontro el APK en $src" }

$dist = Join-Path $PSScriptRoot 'APK'
New-Item -ItemType Directory -Force -Path $dist | Out-Null
$version = (Select-String -Path 'pubspec.yaml' -Pattern '^version:\s*([\d\.]+)').Matches[0].Groups[1].Value
$stamp   = Get-Date -Format 'yyyyMMdd-HHmm'
$dest    = Join-Path $dist "$AppName.apk"
$destVer = Join-Path $dist "$AppName-v$version-$stamp.apk"
Copy-Item $src $dest -Force
Copy-Item $src $destVer -Force
$sizeMb = [math]::Round((Get-Item $dest).Length / 1MB, 1)

Write-Host "`n=============================================" -ForegroundColor Green
Write-Host "   LISTO: $AppName.apk ($sizeMb MB)"          -ForegroundColor Green
Write-Host "   Carpeta: $dist"                             -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host "Pasa el APK al telefono (WhatsApp, cable o Drive) e instalalo."

Start-Process explorer.exe $dist
Read-Host "`nPresiona Enter para cerrar"
