param(
  [int]$VM_NUMBER
)

if (-not $VM_NUMBER) {
    Write-Host "❌ Usage: $MyInvocation.MyCommand.Name <VM_NUMBER>"
    exit 1
}

$VM_NAME = "RDP-VM$VM_NUMBER"
$JSON_FILE = ".cluster_status_smart.json"

Write-Host "🚀 Creating $VM_NAME..."

# إنشاء container Windows
docker run -d --name $VM_NAME `
  --hostname $VM_NAME `
  -e TZ="Etc/UTC" `
  mcr.microsoft.com/windows/servercore:ltsc2022 sleep infinity

Write-Host "🔗 Starting Tailscale inside $VM_NAME..."
docker exec $VM_NAME powershell -Command "
if (-not (Test-Path 'C:\Program Files\Tailscale\tailscale.exe')) {
  Invoke-WebRequest -Uri 'https://pkgs.tailscale.com/stable/tailscale-setup-latest-amd64.msi' -OutFile 'C:\Temp\tailscale.msi';
  Start-Process msiexec.exe -ArgumentList '/i C:\Temp\tailscale.msi /quiet /norestart' -Wait
}
& 'C:\Program Files\Tailscale\tailscale.exe' up --authkey=$env:TAILSCALE_AUTH_KEY --hostname=$env:VM_NAME --accept-dns=false
"

# الحصول على IP Tailscale
$TS_IP = docker exec $VM_NAME powershell -Command "& 'C:\Program Files\Tailscale\tailscale.exe' ip -4" | Select-String '^100\.' | Select-Object -First 1

# تحديث JSON cluster status
if (-not (Test-Path $JSON_FILE)) { '{}' | Out-File $JSON_FILE }
$json = Get-Content $JSON_FILE | ConvertFrom-Json
$json[$VM_NAME] = $TS_IP
$json | ConvertTo-Json | Set-Content $JSON_FILE

Write-Host "✅ $VM_NAME created with Tailscale IP: $TS_IP"
