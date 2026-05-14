RELEASE      = sandbox
CHART        = ./helm
MON_NS       = monitoring
MON_CHART    = prometheus-community/kube-prometheus-stack
GRAFANA_PASS = admin123

.PHONY: install add remove clean status upgrade

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
	kubectl apply --server-side --force-conflicts -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml
	@echo "☸️ Installing Student Workloads..."
	@if [ -d "$(CHART)" ]; then \
		helm upgrade --install $(RELEASE) $(CHART); \
	else \
		echo "⚠️  Local Helm chart not found at $(CHART). Skipping workload install."; \
	fi

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
	@echo "Removing student, cluster-ops namespaces."

	kubectl delete ns monitoring
	@echo "Removing monitoring namespaces."

	@echo "Cleaned"
# Show current status
status:
	@echo "=== Namespaces ==="
	@kubectl get namespaces
	@echo ""
	@echo "=== Student Pods & Services ==="
	@kubectl get pods,svc -A | grep -E "student"
	@echo ""
	@echo "=== Monitoring ==="
	@kubectl get pods,svc -n monitoring | grep -E "grafana|prometheus|alertmanager" || true
	@echo ""
	@echo "=== Cluster-Ops CronJob ==="
	@kubectl get cronjob,job -n cluster-ops 2>/dev/null || echo "  (cluster-ops not deployed)"