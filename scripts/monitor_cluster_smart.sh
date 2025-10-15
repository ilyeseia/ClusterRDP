#!/usr/bin/env bash
# ==================================================
# سكربت مراقبة Cluster RDP Smart
# ==================================================

CLUSTER_SIZE=3
JSON_FILE=".cluster_status_smart.json"

echo "🔍 Starting Smart Cluster Monitoring..."

while true; do
  echo "💡 Checking VMs status at $(date)..."

  for i in $(seq 1 $CLUSTER_SIZE); do
    VM_NAME="RDP-VM$i"

    if ! docker ps --format '{{.Names}}' | grep -q "$VM_NAME"; then
      echo "⚠ $VM_NAME is down! Recreating..."
      ./scripts/create_rdp_vm_smart.sh $i
    else
      TS_IP=$(docker exec $VM_NAME powershell -Command "& 'C:\Program Files\Tailscale\tailscale.exe' ip -4" | grep '^100\.' | head -n1)
      if [ ! -f $JSON_FILE ]; then
        echo "{}" > $JSON_FILE
      fi
      jq --arg name "$VM_NAME" --arg ip "$TS_IP" '.[$name]=$ip' $JSON_FILE > tmp.json && mv tmp.json $JSON_FILE
    fi
  done

  echo "📋 Current Cluster Status:"
  cat $JSON_FILE | jq

  sleep 900  # تحقق كل 15 دقيقة (اختبار)
done
