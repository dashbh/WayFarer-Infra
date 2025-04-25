.PHONY: deploy cleanup kill-port-forward create-secrets start

# Define namespaces, Helmfile path, and ports to forward
WAYFARER_NAMESPACE=wayfarer
WAYFARER_SERVICES = wayfarer-api-gateway wayfarer-auth wayfarer-catalog wayfarer-cart

HELMFILE=helmfile.yaml

# Kafka Ports
KAFKA_PORT=9092
KAFKA_LOCAL_PORT=9092

# PostgreSQL Ports
POSTGRES_PORT=5432
POSTGRES_LOCAL_PORT=5432

# pgAdmin Ports
PGADMIN_PORT=80
PGADMIN_LOCAL_PORT=8080

# Colors
GREEN = \033[0;32m
YELLOW = \033[0;33m
RED = \033[0;31m
NC = \033[0m  # No Color

# Define the path to helmfile.yaml
HELMFILE := helmfile.yaml

# Step to create Kubernetes Secret from .env file
create-secrets:
	@echo "$(YELLOW)Creating Kubernetes secret from .env file...$(NC)"
	@kubectl delete secret wayfarer-secrets --ignore-not-found --namespace=$(WAYFARER_NAMESPACE)
	@kubectl delete secret wayfarer-postgres-secret --ignore-not-found --namespace=$(WAYFARER_NAMESPACE)
	@kubectl delete secret wayfarer-pgadmin-secret --ignore-not-found --namespace=$(WAYFARER_NAMESPACE)
	@echo "$(YELLOW)All Wayfarer secrets deleted from $(WAYFARER_NAMESPACE)!$(NC)"

	@kubectl create secret generic wayfarer-secrets \
		--from-env-file=.env \
		--namespace=$(WAYFARER_NAMESPACE)

	@kubectl create secret generic wayfarer-postgres-secret \
	--from-literal=postgres-user="$$(grep -E '^POSTGRES_USER=' .env | cut -d '=' -f2-)" \
	--from-literal=password="$$(grep -E '^POSTGRES_PASSWORD=' .env | cut -d '=' -f2-)" \
	--from-literal=postgres-password="$$(grep -E '^POSTGRES_PASSWORD=' .env | cut -d '=' -f2-)" \
	--from-literal=postgres-database="$$(grep -E '^POSTGRES_DB=' .env | cut -d '=' -f2-)" \
	--namespace=$(WAYFARER_NAMESPACE)

	@kubectl create secret generic wayfarer-pgadmin-secret \
	--from-literal=email="$$(grep -E '^POSTGRES_ADMIN_USER=' .env | cut -d '=' -f2-)" \
	--from-literal=password="$$(grep -E '^POSTGRES_ADMIN_PASSWORD=' .env | cut -d '=' -f2-)" \
	--namespace=$(WAYFARER_NAMESPACE)

	@echo "$(GREEN)Secret wayfarer-secrets created!$(NC)"
	@echo "$(GREEN)Secret wayfarer-postgres-secret created!$(NC)"
	@echo "$(GREEN)Secret wayfarer-pgadmin-secret created!$(NC)"

# Deploy Kafka, PostgreSQL, and pgAdmin using Helmfile
deploy:
	$(MAKE) create-secrets
	@echo "$(GREEN)Deploying Kafka, PostgreSQL, and pgAdmin using Helmfile...$(NC)"
	helmfile -f $(HELMFILE) sync

	@echo "$(YELLOW)Waiting for services to be ready...$(NC)"

	# Wait for Kafka (StatefulSet)
	@kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=kafka -n $(WAYFARER_NAMESPACE) --timeout=180s || true
	@echo "$(GREEN)Kafka is ready!$(NC)"

	# Wait for PostgreSQL (StatefulSet)
	@kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=postgresql -n $(WAYFARER_NAMESPACE) --timeout=180s || true
	@echo "$(GREEN)PostgreSQL is ready!$(NC)"

	# Wait for pgAdmin (Deployment)
	@kubectl wait --for=condition=available deployment -l app.kubernetes.io/name=pgadmin4 -n $(WAYFARER_NAMESPACE) --timeout=180s || true
	@echo "$(GREEN)pgAdmin is ready!$(NC)"

	# Wait for all WayFarer Deployments
	@for svc in $(WAYFARER_SERVICES); do \
		kubectl wait --for=condition=available deployment -l app=$$svc -n wayfarer --timeout=180s || true; \
		echo "$(GREEN)$$svc is ready!$(NC)"; \
	done

	@echo "$(GREEN)All Deployments are complete run make start to initiate port forwarding$(NC)"

# Start step to handle port forwarding in parallel and keep terminal live
start:
	@echo "$(YELLOW)Starting all port forwarding in parallel...$(NC)"
	# Port forwarding for Kafka
	@kubectl port-forward svc/wayfarer-kafka $(KAFKA_LOCAL_PORT):$(KAFKA_PORT) -n $(WAYFARER_NAMESPACE) &
	# Port forwarding for PostgreSQL
	@kubectl port-forward svc/wayfarer-postgres-postgresql $(POSTGRES_LOCAL_PORT):$(POSTGRES_PORT) -n $(WAYFARER_NAMESPACE) &
	# Port forwarding for pgAdmin
	@kubectl port-forward svc/wayfarer-pgadmin-pgadmin4 8080:80 -n $(WAYFARER_NAMESPACE) &
	@wait

# Cleanup step (destroy Helm releases and clean up PVCs)
cleanup:
	@echo "$(RED)Cleaning up Kafka, PostgreSQL, and pgAdmin releases and PVCs...$(NC)"
	helmfile -f $(HELMFILE) destroy
	kubectl delete pvc --all -n $(WAYFARER_NAMESPACE)
	kubectl delete secret wayfarer-secrets --namespace=$(WAYFARER_NAMESPACE) || true
	@echo "$(YELLOW)Waiting for all resources to be deleted...$(NC)"
	@echo "$(GREEN)Cleanup complete. Helm releases and PVCs removed.$(NC)"

# Reset step (combines cleanup and redeploy)
redeploy: cleanup deploy
	@echo "$(GREEN)Reset and deploy complete!$(NC)"

# Kill background port forwarding process
kill-ports:
	@echo "Killing background port-forward processes..."
	@pkill -f "kubectl port-forward"
	@echo "$(GREEN)All port-forward processes killed!$(NC)"
