#!/usr/bin/env bash
# عدد الخوادم
CLUSTER_SIZE=3

echo "🔍 Monitoring cluster..."

while true; do
  ACTIVE_VMS=0
  for i in $(seq 1 $CLUSTER_SIZE); do
    VM_NAME="RDP-VM$i"
    echo "Checking $VM_NAME..."
    if docker ps --format '{{.Names}}' | grep -q "$VM_NAME"; then
      echo "✅ $VM_NAME is running"
      ACTIVE_VMS=$((ACTIVE_VMS+1))
    else
      echo "⚠ $VM_NAME is down! Recreating..."
      ./create_rdp_vm.sh $i
    fi
  done

  echo "💡 Active VMs: $ACTIVE_VMS / $CLUSTER_SIZE"
  sleep 600  # تحقق كل 10 دقائق
done
