#!/usr/bin/env bash
set -e
echo "🔍 Starting Smart Cluster Monitoring..."

VM_NAMES=("RDP-VM1" "RDP-VM2" "RDP-VM3")

while true; do
  echo "💡 Checking VMs status at $(date)..."
  for VM in "${VM_NAMES[@]}"; do
    if ! docker ps --format '{{.Names}}' | grep -q "$VM"; then
      echo "⚠ $VM is down! Recreating..."
      ./scripts/create_rdp_vm_smart.sh "${VM:7:1}"
    else
      echo "✅ $VM is running."
    fi
  done
  sleep 300  # Check every 5 minutes
done
