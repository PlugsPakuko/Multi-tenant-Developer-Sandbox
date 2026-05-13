# ==========================================
# Student Sandbox Automation Script (Windows Native)
# ==========================================

$RELEASE = "sandbox"
$CHART = "./helm"
$MON_NS = "monitoring"
$MON_CHART = "prometheus-community/kube-prometheus-stack"
$GRAFANA_PASS = "prom-operator" # Defined as a variable for consistency

function Setup-Repo {
    Write-Host "🌐 Adding Prometheus Community Repo..." -ForegroundColor Cyan
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update
}

function Clean-System {
    Write-Host "`n🗑️ Uninstalling Everything..." -ForegroundColor Yellow
    helm uninstall $RELEASE 2>$null
    helm uninstall monitoring -n $MON_NS 2>$null
    Write-Host "🧹 Cleaning up PVCs..." -ForegroundColor Yellow
    kubectl delete pvc --all -A 2>$null
    Write-Host "✨ System cleaned." -ForegroundColor Green
}

function Install-System {
    Setup-Repo
    Write-Host "`n🏗️ Creating Monitoring Namespace..." -ForegroundColor Cyan
    kubectl create namespace $MON_NS 2>$null
    
    Write-Host "📦 Installing Prometheus & Grafana Stack..." -ForegroundColor Cyan
    # Explicitly enabling Grafana and setting the admin password
    helm upgrade --install monitoring $MON_CHART `
        -n $MON_NS `
        --create-namespace `
        --set grafana.enabled=true `
        --set grafana.adminPassword=$GRAFANA_PASS
    
    Write-Host "📦 Applying Prometheus CRDs..." -ForegroundColor Cyan
    kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml
    
    Write-Host "☸️ Installing Student Workloads..." -ForegroundColor Cyan
    if (Test-Path $CHART) {
        helm upgrade --install $RELEASE $CHART 
    } else {
        Write-Host "⚠️ Local Helm chart not found at $CHART. Skipping workload install." -ForegroundColor Yellow
    }
    
    Write-Host "`n✅ Everything is up! Check status with: .\run.ps1 status" -ForegroundColor Green
}

function Show-Status {
    Write-Host "`n=== Student Pods ===" -ForegroundColor Cyan
    kubectl get pods -A | findstr "student"
    Write-Host "`n=== Monitoring Pods (Prometheus/Grafana) ===" -ForegroundColor Cyan
    kubectl get pods -n $MON_NS
}

function Open-Dashboard {
    Write-Host "`n📊 Locating Grafana Service..." -ForegroundColor Magenta
    
    # 1. Find the service name
    $svcName = kubectl get svc -n $MON_NS -l "app.kubernetes.io/name=grafana" --no-headers -o custom-columns=":metadata.name" | Select-Object -First 1
    
    # 2. Automatically fetch the current password from the secret
    $encodedPass = kubectl get secret -n $MON_NS monitoring-grafana -o jsonpath="{.data.admin-password}" 2>$null
    if ($encodedPass) {
        $actualPass = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encodedPass))
    } else {
        $actualPass = "Check 'kubectl get secrets'"
    }

    if ($svcName) {
        Write-Host "🚀 Found Service: $svcName" -ForegroundColor Green
        Write-Host "🔗 URL:  http://localhost:3000" -ForegroundColor White
        Write-Host "🔑 User: admin" -ForegroundColor White
        Write-Host "🔑 Pass: $actualPass" -ForegroundColor White
        Write-Host "⌨️  Press Ctrl+C to stop port-forwarding." -ForegroundColor Gray
        
        kubectl port-forward svc/$svcName -n $MON_NS 3000:80
    } else {
        Write-Host "❌ Error: Grafana service not found. Run '.\run.ps1 install' first." -ForegroundColor Red
    }
}

# Command Switch
$command = $args[0]
switch ($command) {
    "redeploy"  { Clean-System; Install-System }
    "clean"     { Clean-System }
    "install"   { Install-System }
    "status"    { Show-Status }
    "dashboard" { Open-Dashboard }
    default {
        Write-Host "Usage: .\run.ps1 [install | clean | redeploy | status | dashboard]" -ForegroundColor Gray
    }
}