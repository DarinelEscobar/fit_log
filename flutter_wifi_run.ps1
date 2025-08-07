$ip = "192.168.100.144"
$port = "5555"
Write-Host "Intentando conectar a ${ip}:${port} ..." -ForegroundColor Cyan

# Verifica si el dispositivo ya está conectado
$connected = adb devices | Select-String "${ip}:${port}"

if (-not $connected) {
    adb connect "${ip}:${port}" | Out-Null
    Start-Sleep -Seconds 1
    $checkAgain = adb devices | Select-String "${ip}:${port}"
    if ($checkAgain) {
        Write-Host " Dispositivo conectado por WiFi" -ForegroundColor Green
    } else {
        Write-Host " No se pudo conectar al dispositivo en $ip" -ForegroundColor Red
        Write-Host ""
        Write-Host " Asegúrate de tener activado 'Wireless debugging' en tu teléfono (Developer Options > Wireless debugging)" -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host " Ya está conectado por WiFi" -ForegroundColor Green
}

Write-Host ''
Write-Host ' Ejecutando flutter run ...' -ForegroundColor Yellow

flutter run

# En PowerShell, ejecútalo con:
# powershell
# ./flutter_wifi_run.ps1

# Asegúrate de tener activado 'Wireless debugging' en tu teléfono (Developer Options > Wireless debugging)
# Y si es Android 11 o superior, empareja el dispositivo antes con: adb pair <ip:port>
# También asegúrate de haber autorizado la depuración en el dispositivo cuando se conecte
# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
