.PHONY: deploy clear kill-ports create-secrets start restart

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

# Delete Kubernetes secrets if they exist
delete-secrets:
	@echo "$(YELLOW)Deleting Kubernetes secrets...$(NC)"
	@kubectl delete secret wayfarer-secrets --ignore-not-found --namespace=$(WAYFARER_NAMESPACE)
	@kubectl delete secret wayfarer-postgres-secret --ignore-not-found --namespace=$(WAYFARER_NAMESPACE)
	@kubectl delete secret wayfarer-pgadmin-secret --ignore-not-found --namespace=$(WAYFARER_NAMESPACE)
	@echo "$(GREEN)All Wayfarer secrets deleted from $(WAYFARER_NAMESPACE)!$(NC)"

# Step to create Kubernetes secrets from .env file (For core services)
create-wayfarer-secrets:
	@echo "$(YELLOW)Creating Kubernetes secret 'wayfarer-secrets' from .env file...$(NC)"
	@kubectl delete secret wayfarer-secrets --ignore-not-found --namespace=$(WAYFARER_NAMESPACE)
	@kubectl create secret generic wayfarer-secrets \
		--from-env-file=.env \
		--namespace=$(WAYFARER_NAMESPACE)
	@echo "$(GREEN)Secret 'wayfarer-secrets' created!$(NC)"

# Step to create PostgreSQL secrets
create-wayfarer-postgres-secret:
	@echo "$(YELLOW)Creating Kubernetes secret 'wayfarer-postgres-secret'...$(NC)"
	@kubectl delete secret wayfarer-postgres-secret --ignore-not-found --namespace=$(WAYFARER_NAMESPACE)
	@kubectl create secret generic wayfarer-postgres-secret \
		--from-literal=postgres-user="$$(grep -E '^POSTGRES_USER=' .env | cut -d '=' -f2-)" \
		--from-literal=password="$$(grep -E '^POSTGRES_PASSWORD=' .env | cut -d '=' -f2-)" \
		--from-literal=postgres-password="$$(grep -E '^POSTGRES_PASSWORD=' .env | cut -d '=' -f2-)" \
		--from-literal=postgres-database="$$(grep -E '^POSTGRES_DB=' .env | cut -d '=' -f2-)" \
		--namespace=$(WAYFARER_NAMESPACE)
	@echo "$(GREEN)Secret 'wayfarer-postgres-secret' created!$(NC)"

# Step to create pgAdmin secrets
create-wayfarer-pgadmin-secret:
	@echo "$(YELLOW)Creating Kubernetes secret 'wayfarer-pgadmin-secret'...$(NC)"
	@kubectl delete secret wayfarer-pgadmin-secret --ignore-not-found --namespace=$(WAYFARER_NAMESPACE)
	@kubectl create secret generic wayfarer-pgadmin-secret \
		--from-literal=email="$$(grep -E '^POSTGRES_ADMIN_USER=' .env | cut -d '=' -f2-)" \
		--from-literal=password="$$(grep -E '^POSTGRES_ADMIN_PASSWORD=' .env | cut -d '=' -f2-)" \
		--namespace=$(WAYFARER_NAMESPACE)
	@echo "$(GREEN)Secret 'wayfarer-pgadmin-secret' created!$(NC)"

# Combine all secrets creation commands
create-secrets: create-wayfarer-secrets create-wayfarer-postgres-secret create-wayfarer-pgadmin-secret
	@echo "$(GREEN)All secrets created successfully!$(NC)"

# Deploy Kafka, PostgreSQL, and pgAdmin using Helmfile
# Deploy Only Specific Resources (based on labels or services)
deploy-db:
	$(MAKE) create-wayfarer-postgres-secret create-wayfarer-pgadmin-secret
	@echo "$(YELLOW)Deploying PostgreSQL and pgAdmin...$(NC)"
	@helmfile -l group=db apply

deploy-messaging:
	@echo "📡 Deploying Messaging stack (Kafka)..."
	@helmfile -l group=messaging apply

deploy-core:
	$(MAKE) create-wayfarer-secrets
	@echo "$(YELLOW)Deploying Core Microservices (Gateway, Auth, Cart, Catalog)...$(NC)"
	@helmfile -l group=core apply

deploy-infra: clear deploy-db deploy-messaging
	@echo "✅ Infra stack deployed (DB + Kafka)."

deploy: clear deploy-db deploy-messaging deploy-core
	@echo "$(GREEN)All Wayfarer services deployed successfully!$(NC)"

# Start step to handle port forwarding in parallel and keep terminal live
start: kill-ports
	@echo "$(YELLOW)Starting all port forwarding in parallel...$(NC)"
	# Port forwarding for Kafka
	@kubectl port-forward svc/wayfarer-kafka $(KAFKA_LOCAL_PORT):$(KAFKA_PORT) -n $(WAYFARER_NAMESPACE) &
	# Port forwarding for PostgreSQL
	@kubectl port-forward svc/wayfarer-postgres-postgresql $(POSTGRES_LOCAL_PORT):$(POSTGRES_PORT) -n $(WAYFARER_NAMESPACE) &
	# Port forwarding for pgAdmin
	@kubectl port-forward svc/wayfarer-pgadmin-pgadmin4 8080:80 -n $(WAYFARER_NAMESPACE) &
	@wait

# Restart all deployments in the Wayfarer namespace
# This is useful for applying changes to the deployments without redeploying
restart:
	@echo "$(YELLOW)Restarting all deployments in $(WAYFARER_NAMESPACE)...$(NC)"
	@kubectl get deployments -n $(WAYFARER_NAMESPACE) -o name | xargs -I{} kubectl rollout restart {} -n $(WAYFARER_NAMESPACE)
	@echo "$(GREEN)All deployments restarted successfully in $(WAYFARER_NAMESPACE)!$(NC)"

# Cleanup step (destroy Helm releases and clean up PVCs)
clear:
	@echo "$(RED)Cleaning up Kafka, PostgreSQL, and pgAdmin releases and PVCs...$(NC)"
	helmfile -f $(HELMFILE) destroy
	kubectl delete pvc --all -n $(WAYFARER_NAMESPACE)
	kubectl delete secret wayfarer-secrets --namespace=$(WAYFARER_NAMESPACE) || true
	@echo "$(YELLOW)Waiting for all resources to be deleted...$(NC)"
	@echo "$(GREEN)Cleanup complete. Helm releases and PVCs removed.$(NC)"

# Kill background port forwarding process
kill-ports:
	@echo "Killing background port-forward processes..."
	@pkill -f "kubectl port-forward" || true
	@echo "$(GREEN)All port-forward processes killed!$(NC)"
