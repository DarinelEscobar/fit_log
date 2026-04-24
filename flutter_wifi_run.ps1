$ip = "192.168.0.252"
$port = "34595"
Write-Host "Intentando conectar a ${ip}:${port} ..." -ForegroundColor Cyan

$secureJdkRoot = Join-Path $env:USERPROFILE '.jdks'
$preferredJavaHome = Join-Path $secureJdkRoot 'jdk-17.0.12'

$desiredJavaHomes = @(
    $preferredJavaHome,
    "C:\Program Files\Java\jdk-17"
)
$resolvedJavaHome = $null
foreach ($candidate in $desiredJavaHomes) {
    if (Test-Path $candidate) {
        $resolvedJavaHome = $candidate
        break
    }
}

$currentJavaExe = if ($env:JAVA_HOME) { Join-Path $env:JAVA_HOME 'bin\java.exe' } else { $null }
$currentJavaVersion = $null
if ($currentJavaExe -and (Test-Path $currentJavaExe)) {
    $versionOutput = & $currentJavaExe -version 2>&1
    if ($versionOutput) {
        $match = [regex]::Match(($versionOutput -join "`n"), 'version\s+"(?<major>\d+)')
        if ($match.Success) {
            $currentJavaVersion = [int]$match.Groups['major'].Value
        }
    }
}

if (-not $currentJavaExe -or -not (Test-Path $currentJavaExe) -or $currentJavaVersion -ne 17) {
    if ($resolvedJavaHome) {
        $env:JAVA_HOME = $resolvedJavaHome
        $existingPathEntries = $env:Path -split ';' | Where-Object { $_ -and ($_ -ne "$env:JAVA_HOME\bin") }
        $env:Path = (@("$env:JAVA_HOME\bin") + $existingPathEntries) -join ';'
        Write-Host " JAVA_HOME ajustado a $env:JAVA_HOME" -ForegroundColor Cyan
        flutter config --jdk-dir "$env:JAVA_HOME" | Out-Null
    } else {
        Write-Host " No se encontró una instalación válida de JDK 17 en las rutas configuradas" -ForegroundColor Red
        Write-Host " Actualiza la lista desiredJavaHomes en flutter_wifi_run.ps1 o instala JDK 17" -ForegroundColor Yellow
        exit 1
    }
}

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
