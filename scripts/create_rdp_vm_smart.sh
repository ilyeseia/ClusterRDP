#!/usr/bin/env bash
# ==================================================
# سكربت إنشاء VM ذكي حسب الرقم المعطى
# Usage: ./create_rdp_vm_smart.sh <VM_NUMBER>
# ==================================================

VM_NUMBER=$1
VM_NAME="RDP-VM${VM_NUMBER}"
JSON_FILE=".cluster_status_smart.json"

if [ -z "$VM_NUMBER" ]; then
  echo "❌ Usage: $0 <VM_NUMBER>"
  exit 1
fi

echo "🚀 Creating $VM_NAME..."

# مثال مبسط: إنشاء container كـ VM افتراضي (تعديل حسب حاجتك)
docker run -d --name $VM_NAME \
  --hostname $VM_NAME \
  -e TZ=Etc/UTC \
  mcr.microsoft.com/windows/servercore:ltsc2022 sleep infinity

# التأكد من أن Tailscale مثبت ومفعل داخل VM
echo "🔗 Starting Tailscale inside $VM_NAME..."
docker exec $VM_NAME powershell -Command "
  if (-not (Test-Path 'C:\Program Files\Tailscale\tailscale.exe')) {
    Invoke-WebRequest -Uri 'https://pkgs.tailscale.com/stable/tailscale-setup-latest-amd64.msi' -OutFile 'C:\Temp\tailscale.msi';
    Start-Process msiexec.exe -ArgumentList '/i C:\Temp\tailscale.msi /quiet /norestart' -Wait
  }
  & 'C:\Program Files\Tailscale\tailscale.exe' up --authkey=$env:TAILSCALE_AUTH_KEY --hostname=$env:VM_NAME --accept-dns=false
"

# الحصول على IP Tailscale
TS_IP=$(docker exec $VM_NAME powershell -Command "& 'C:\Program Files\Tailscale\tailscale.exe' ip -4" | grep '^100\.' | head -n1)

# تحديث JSON cluster status
if [ ! -f $JSON_FILE ]; then
  echo "{}" > $JSON_FILE
fi
jq --arg name "$VM_NAME" --arg ip "$TS_IP" '.[$name]=$ip' $JSON_FILE > tmp.json && mv tmp.json $JSON_FILE

echo "✅ $VM_NAME created with Tailscale IP: $TS_IP"
