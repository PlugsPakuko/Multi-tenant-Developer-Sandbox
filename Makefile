RELEASE      = sandbox
CHART        = ./helm
MON_NS       = monitoring
MON_CHART    = prometheus-community/kube-prometheus-stack
GRAFANA_PASS = prom-operator

.PHONY: install add remove clean status

install:
	@echo "🏗️ Creating Monitoring Namespace..."
	-kubectl create namespace $(MON_NS)

	@echo "📦 Installing Prometheus & Grafana Stack..."
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo update
	helm upgrade --install monitoring $(MON_CHART) \
		-n $(MON_NS) \
		--create-namespace \
		--set grafana.enabled=true \
		--set grafana.adminPassword=$(GRAFANA_PASS)
	@echo "📦 Applying Prometheus CRDs..."
	kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml
	@echo "☸️ Installing Student Workloads..."
	@if [ -d "$(CHART)" ]; then \
		helm upgrade --install $(RELEASE) $(CHART); \
	else \
		echo "⚠️  Local Helm chart not found at $(CHART). Skipping workload install."; \
	fi
	@echo "\n✅ Everything is up! Check status with: make status"

# Upgrade after any changes
upgrade:
	helm upgrade $(RELEASE) $(CHART)

# Add a single new student (usage: make add id=06)
add:
	@./provision.sh $(id)

# Remove a single student (usage: make remove id=06)
remove:
	@./deprovision.sh $(id)

# Tear everything down
clean:
	helm uninstall $(RELEASE)
	@echo "All student namespaces removed."

# Show current status
status:
	@echo "=== Namespaces ==="
	@kubectl get namespaces
	@echo ""
	@echo "=== Pods (all student ns) ==="
	@kubectl get pods,svc -A | grep -E "student|grafana"