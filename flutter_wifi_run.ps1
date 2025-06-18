$ip = "192.168.100.144"
$port = "5555"

Write-Host "🔌 Intentando conectar a $ip:$port ..." -ForegroundColor Cyan

# Verifica si el dispositivo ya está conectado
$connected = adb devices | Select-String "$ip:$port"

if (-not $connected) {
    adb connect "$ip:$port" | Out-Null
    Start-Sleep -Seconds 1
    $checkAgain = adb devices | Select-String "$ip:$port"
    if ($checkAgain) {
        Write-Host "✅ Dispositivo conectado por WiFi" -ForegroundColor Green
    } else {
        Write-Host "❌ No se pudo conectar al dispositivo en $ip" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "✅ Ya está conectado por WiFi" -ForegroundColor Green
}

# Corre Flutter
Write-Host "`n🚀 Ejecutando flutter run ..." -ForegroundColor Yellow
flutter run



# En PowerShell, ejecútalo con:

# powershell
# Copy
# Edit
# ./flutter_wifi_run.ps1
# o si te da error de ejecución, primero permite scripts con:

# powershell
# Copy
# Edit
# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser