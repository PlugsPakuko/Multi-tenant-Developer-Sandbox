RELEASE  = sandbox
CHART    = ./helm

.PHONY: install upgrade clean status add remove

# Deploy all students from values.yaml
install:
	helm install $(RELEASE) $(CHART)
	@echo ""
	@kubectl get namespaces | grep student

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
	@kubectl get namespaces | grep student
	@echo ""
	@echo "=== Pods (all student ns) ==="
	@kubectl get pods --all-namespaces | grep student