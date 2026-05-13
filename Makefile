RELEASE  = student-sandbox
CHART    = ./helm
MON_NS   = monitoring

.PHONY: install upgrade clean status redeploy dashboard

# 1. ติดตั้งแบบครบวงจร (สร้างบ้านให้ Monitoring และลง CRDs ก่อนเสมอ)
install:
	@echo "🏗️ Creating Monitoring Namespace..."
	-kubectl create namespace $(MON_NS)
	@echo "📦 Applying Prometheus CRDs (Server-side)..."
	kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/main/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml
	@echo "☸️ Installing Helm Chart..."
	helm install $(RELEASE) $(CHART) --wait=false
	@echo "\n✅ Installation finished. Check status with 'make status'"

# 2. อัปเกรด (ใช้บ่อยเวลาแก้ values.yaml)
upgrade:
	@echo "🔄 Upgrading Helm Release..."
	helm upgrade $(RELEASE) $(CHART) --wait=false

# 3. ท่าไม้ตายล้างบาง (แก้ปัญหา Immutable PVC และค้างสถานะ Pending)
clean:
	@echo "🗑️ Uninstalling $(RELEASE)..."
	-helm uninstall $(RELEASE)
	@echo "🧹 Removing student PVCs (to avoid storage errors)..."
	-kubectl delete pvc --all -A
	@echo "✨ Clean up finished."

# 4. ปุ่มลัด Re-deploy (กดปุ่มเดียวจบทุกด่าน)
redeploy: clean install

# 5. เช็คสถานะแบบละเอียด
status:
	@echo "=== Namespaces ==="
	@kubectl get namespaces | grep -E 'student|monitoring' || echo "No namespaces found."
	@echo "\n=== Pods Status ==="
	@kubectl get pods -A | grep student || echo "No student pods running."
	@echo "\n=== Prometheus Rules ==="
	@kubectl get prometheusrule -n $(MON_NS) || echo "No rules found."

# 6. เปิด Grafana (กดแล้วเข้า localhost:3000 ได้เลย)
dashboard:
	@echo "📊 Opening Grafana on http://localhost:3000"
	@echo "User: admin | Pass: prom-operator"
	kubectl port-forward svc/monitoring-grafana -n $(MON_NS) 3000:80

# คงคำสั่งเดิมของนายไว้ (ถ้ายังมีสคริปต์ provision.sh อยู่)
add:
	@./provision.sh $(id)

remove:
	@./deprovision.sh $(id)