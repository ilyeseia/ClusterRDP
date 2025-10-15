#!/usr/bin/env bash
CLUSTER_SIZE=3
JSON_FILE=".cluster_status.json"

echo "🔍 Monitoring cluster (Smart)..."

while true; do
  for i in $(seq 1 $CLUSTER_SIZE); do
    VM_NAME="RDP-VM$i"
    if ! docker ps --format '{{.Names}}' | grep -q "$VM_NAME"; then
      echo "⚠ $VM_NAME is down! Recreating..."
      ./create_rdp_vm.sh $i
    fi
  done

  echo "💡 Current Cluster Status:"
  cat $JSON_FILE | jq

  sleep 600  # تحقق كل 10 دقائق
done
