param(
  [string]$Ip = $env:ADB_IP,
  [int]$Port = $(if ($env:ADB_PORT) { [int]$env:ADB_PORT } else { 5555 })
)

function Info($m){ Write-Host $m -ForegroundColor Cyan }
function Ok($m){ Write-Host $m -ForegroundColor Green }
function Warn($m){ Write-Host $m -ForegroundColor Yellow }
function Err($m){ Write-Host $m -ForegroundColor Red }

if (-not $Ip) {
  Warn "Falta la IP del teléfono. Usa: .\\flutter_wifi_run.ps1 -Ip 192.168.100.144"
  exit 1
}

if (-not (Get-Command adb -ErrorAction SilentlyContinue)) { Err "adb no encontrado"; exit 1 }
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { Warn "flutter no encontrado en PATH" }

# Reinicia servidor ADB
adb kill-server | Out-Null
adb start-server | Out-Null

# Detecta un dispositivo USB (ID que no contenga ':') para cambiarlo a tcpip 5555
$usbDevice = (
  adb devices 2>$null |
  Select-String 'device$' |
  ForEach-Object { ($_ -split "`t")[0] } |
  Where-Object { $_ -and ($_ -notmatch ':') -and ($_ -notmatch '^List of devices attached') }
) | Select-Object -First 1

if ($usbDevice) {
  Info "Dispositivo USB detectado: $usbDevice"
  Info "Cambiando a tcpip $Port ..."
  adb -s $usbDevice tcpip $Port | Out-Null
  Start-Sleep -Seconds 1
} else {
  Warn "No se detectó dispositivo USB. Intentaré conectar directo por Wi‑Fi."
}

# Conecta al IP:PORT (por defecto 5555)
$endpoint = "$($Ip):$Port"
Info "Conectando a $endpoint ..."
adb connect $endpoint | Out-Null
Start-Sleep -Seconds 1

# Verifica conexión
$isConnected = adb devices | Select-String "^$([regex]::Escape($endpoint))\s+device$"
if (-not $isConnected) {
  Err "No se pudo conectar a $endpoint"
  adb devices
  exit 1
}
Ok "Conectado: $endpoint"

if (Get-Command flutter -ErrorAction SilentlyContinue) {
  Write-Host ''
  Write-Host ' Ejecutando flutter pub get ...' -ForegroundColor Yellow
  flutter pub get

  Write-Host ' Ejecutando flutter run ...' -ForegroundColor Yellow
  flutter run -d $endpoint
}

# Uso
# 1) Conecta el teléfono por USB y acepta la huella RSA
# 2) Ejecuta: .\flutter_wifi_run.ps1 -Ip 192.168.100.144
#    (forzará tcpip 5555 y conectará a 192.168.100.144:5555)
# 3) Abre la app en el teléfono con flutter run
