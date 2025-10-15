$CLUSTER_SIZE = 3
$JSON_FILE = ".cluster_status_smart.json"
$MAX_CYCLES = 2  # عدد الدورات للاختبار السريع
$cycle = 0

Write-Host "🔍 Starting Smart Cluster Monitoring (Quick Test)..."

while ($cycle -lt $MAX_CYCLES) {
    Write-Host "💡 Checking VMs status at $(Get-Date)..."

    for ($i=1; $i -le $CLUSTER_SIZE; $i++) {
        $VM_NAME = "RDP-VM$i"
        $containerExists = docker ps --format '{{.Names}}' | Select-String $VM_NAME

        if (-not $containerExists) {
            Write-Host "⚠ $VM_NAME is down! Recreating..."
            ./scripts/create_rdp_vm_smart.sh $i
        } else {
            $TS_IP = docker exec $VM_NAME powershell -Command "& 'C:\Program Files\Tailscale\tailscale.exe' ip -4" | Select-String '^100\.' | Select-Object -First 1
            if (-not (Test-Path $JSON_FILE)) { '{}' | Out-File $JSON_FILE }
            $json = Get-Content $JSON_FILE | ConvertFrom-Json
            $json[$VM_NAME] = $TS_IP
            $json | ConvertTo-Json | Set-Content $JSON_FILE
        }
    }

    Write-Host "📋 Current Cluster Status:"
    Get-Content $JSON_FILE

    $cycle++
    Start-Sleep -Seconds 5  # تأخير قصير بين الدورات لتجربة سريعة
}

Write-Host "✅ Quick Monitoring Test Completed."
