$defaultIp = "192.168.100.144"
$port = "5555"
$ip = $null

# 1. Verificar si ya estamos conectados por WiFi
$wifiDevice = adb devices | Select-String ":$port"

if ($wifiDevice) {
    $ip = ($wifiDevice -split "\s+")[0] -split ":" | Select-Object -First 1
    Write-Host "Dispositivo ya conectado por WiFi en ${ip}:${port}" -ForegroundColor Green
}
else {
    # 2. Intentar conectar a IP por defecto
    Write-Host "Intentando conectar al dispositivo en IP por defecto ${defaultIp}:${port}..." -ForegroundColor Cyan
    adb connect "${defaultIp}:${port}" | Out-Null
    Start-Sleep -Seconds 1

    $checkDefault = adb devices | Select-String "${defaultIp}:${port}"
    if ($checkDefault) {
        $ip = $defaultIp
        Write-Host " Conectado exitosamente a IP por defecto ${ip}" -ForegroundColor Green
    }
    else {
        # 3. Requiere conexión USB
        Write-Host " No se pudo conectar a la IP por defecto. Por favor conecta el dispositivo por USB." -ForegroundColor Yellow
        Start-Sleep -Seconds 2

        $usbConnected = adb devices | Select-String "device$"
        if (-not $usbConnected) {
            Write-Host " No se detectó dispositivo USB. Abandonando." -ForegroundColor Red
            exit 1
        }

        # 4. Reiniciar en modo TCP/IP y obtener IP real del dispositivo
        Write-Host " Dispositivo USB detectado. Activando ADB por WiFi..." -ForegroundColor Cyan
        adb tcpip $port | Out-Null
        Start-Sleep -Seconds 1

        $ipLine = adb shell ip route | Select-String "wlan0"
        if (-not $ipLine) {
            Write-Host " No se pudo obtener la IP desde el dispositivo." -ForegroundColor Red
            exit 1
        }

        $ip = ($ipLine -split "src ")[1] -split " " | Select-Object -First 1
        Write-Host " Obtenida IP: ${ip}. Intentando conexión..." -ForegroundColor Cyan

        adb connect "${ip}:${port}" | Out-Null
        Start-Sleep -Seconds 1

        $checkWifi = adb devices | Select-String "${ip}:${port}"
        if (-not $checkWifi) {
            Write-Host " Falló la conexión por WiFi a la IP obtenida (${ip})" -ForegroundColor Red
            exit 1
        }

        Write-Host " Dispositivo conectado por WiFi a ${ip}" -ForegroundColor Green
    }
}

# 5. Ejecutar Flutter
Write-Host ""
Write-Host " Ejecutando flutter run en ${ip} ..." -ForegroundColor Yellow
flutter run



# En PowerShell, ejecútalo con:

# powershell
# ./flutter_wifi_run.ps1

# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser