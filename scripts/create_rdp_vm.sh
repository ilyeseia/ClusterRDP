#!/usr/bin/env bash
# usage: ./create_rdp_vm.sh 1
VM_INDEX=$1
VM_NAME="RDP-VM$VM_INDEX"
RDP_USER="RDP"
RDP_PASS="j9M5N4C.ur=]3gL"

echo "🔧 Creating $VM_NAME..."

# مثال باستخدام GitHub Codespaces / Docker لتمثيل VM
docker run -d --name $VM_NAME --hostname $VM_NAME mcr.microsoft.com/windows/servercore:ltsc2022 powershell -Command "
  # Enable RDP
  Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Value 0 -Force
  # Create user
  \$securePass = ConvertTo-SecureString '$RDP_PASS' -AsPlainText -Force
  if (-not (Get-LocalUser -Name '$RDP_USER' -ErrorAction SilentlyContinue)) {
    New-LocalUser -Name '$RDP_USER' -Password \$securePass -AccountNeverExpires
  } else {
    Set-LocalUser -Name '$RDP_USER' -Password \$securePass
  }
  Add-LocalGroupMember -Group 'Administrators' -Member '$RDP_USER'
  Add-LocalGroupMember -Group 'Remote Desktop Users' -Member '$RDP_USER'
  # Firewall
  netsh advfirewall firewall add rule name='RDP-Tailscale' dir=in action=allow protocol=TCP localport=3389
  Restart-Service -Name TermService -Force
"

echo "✅ $VM_NAME is ready."
