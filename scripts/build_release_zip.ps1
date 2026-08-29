# SAFAR GCS - Automated Windows Release Packager with Dynamic Versioning
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  Building SAFAR GCS Windows Release...  " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# 0. Extract version from pubspec.yaml
$pubspec = Get-Content "pubspec.yaml" -Raw
$version = "1.0.0"
if ($pubspec -match "version:\s*([0-9]+\.[0-9]+\.[0-9]+)") {
    $version = $matches[1]
}
Write-Host "Detected SAFAR Version: v$version" -ForegroundColor Green

# 1. Run Flutter release build
flutter build windows --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed! Make sure Developer Mode is enabled in Windows Settings." -ForegroundColor Red
    exit $LASTEXITCODE
}

$releaseSource = "build\windows\x64\runner\Release"
$distDir = "dist"
$zipOutput = "$distDir\SAFAR_GCS_v${version}_Windows_x64.zip"

if (!(Test-Path $releaseSource)) {
    # Fallback to non-x64 runner folder if different
    $releaseSource = "build\windows\runner\Release"
}

if (Test-Path $releaseSource) {
    if (!(Test-Path $distDir)) {
        New-Item -ItemType Directory -Path $distDir | Out-Null
    }
    
    if (Test-Path $zipOutput) {
        Remove-Item -Force $zipOutput
    }
    
    Write-Host "Packaging portable ZIP into $zipOutput..." -ForegroundColor Yellow
    Compress-Archive -Path "$releaseSource\*" -DestinationPath $zipOutput -Force
    
    Write-Host "`nSUCCESS! Release ZIP created at:" -ForegroundColor Green
    Write-Host (Resolve-Path $zipOutput) -ForegroundColor Green
    Write-Host "`nYou can send this ZIP to your friend. They just need to extract and double-click the .exe to run!" -ForegroundColor Cyan
} else {
    Write-Host "Release folder not found at $releaseSource" -ForegroundColor Red
}
