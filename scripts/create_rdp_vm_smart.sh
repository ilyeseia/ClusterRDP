#!/usr/bin/env bash
set -e
VM_ID=$1
VM_NAME="RDP-VM${VM_ID}"

echo "🚀 Creating $VM_NAME..."

# Delete old container if exists
docker rm -f $VM_NAME 2>/dev/null || true

# Create new Ubuntu container
docker run -d --name $VM_NAME --hostname $VM_NAME \
  --privileged --network host \
  ubuntu:22.04 sleep infinity

# Install XRDP + Desktop + Tailscale inside container
docker exec -i $VM_NAME bash <<'EOF'
apt update -qq
apt install -y xrdp xfce4 xfce4-goodies dbus-x11 tailscale curl sudo
systemctl enable xrdp
service xrdp start
tailscale up --authkey=${TAILSCALE_AUTH_KEY} --hostname=$HOSTNAME --accept-dns=false || true
EOF

TS_IP=$(docker exec $VM_NAME tailscale ip -4 | grep '^100\.' || true)
echo "✅ $VM_NAME created with Tailscale IP: $TS_IP"

# Save info
jq -n --arg name "$VM_NAME" --arg ip "$TS_IP" '{name:$name, ip:$ip}' > "${VM_NAME}_info.json"
