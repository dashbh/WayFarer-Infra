
# 🚀 Wayfarer Microservices – Local Kubernetes Deployment Guide

This guide helps you set up the **Wayfarer** backend (Kafka, PostgreSQL, pgAdmin, and microservices) locally using **Kubernetes**, **Helmfile**, and a `Makefile`.

---

## ⚙️ Prerequisites

Ensure you have the following installed:

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (with Kubernetes enabled)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/)

---

## 📦 Environment Setup

1. **Copy the `.env.template`** to `.env` and update the values:

```bash
cp .env.template .env
```

Update the following environment variables in `.env`:

- `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`
- `POSTGRES_ADMIN_USER`, `POSTGRES_ADMIN_PASSWORD`
- Any other required values...

---

## ✅ Quickstart Summary

```bash
cp .env.template .env         # 1. Setup your .env
make clear                    # 2. Cleanup if needed
make deploy                   # 3. Deploy all services
make start                    # 4. Port-forward for local access
```

---

## 🛠️ Common Makefile Commands

| Command            | Description                                               |
|--------------------|-----------------------------------------------------------|
| `make deploy`      | Deploys all Helm charts (Kafka, PostgreSQL, etc.)         |
| `make clear`       | Deletes Helm releases, PVCs, and secrets                  |
| `make deploy-infra`| Deploys only infra Helm charts (Kafka, PostgreSQL, etc.)  |
| `make start`       | Starts port-forwarding for services (e.g., pgAdmin)       |
| `make kill-ports`  | Stops all existing port-forward processes                 |
| `make restart`     | quick restart (useful for config/secret updates)          |

---

## 🧩 pgAdmin Setup

1. Open [http://localhost:8080](http://localhost:8080)

2. **Login:**
   - Email: _From `POSTGRES_ADMIN_USER`_
   - Password: _From `POSTGRES_ADMIN_PASSWORD`_

3. **Add New Server:**
   - **General → Name:** `Wayfarer Postgres`
   - **Connection:**
     - Host: `wayfarer-postgres-postgresql`
     - Port: `5432`
     - Username: _From `POSTGRES_USER`_
     - Password: _From `POSTGRES_PASSWORD`_

---

## 🔍 Debugging & Troubleshooting

### Check all running pods:

```bash
kubectl get pods -n wayfarer
```

### Inspect a specific pod:

```bash
kubectl describe pod <pod-name> -n wayfarer
```

### View logs from a pod:

```bash
kubectl logs <pod-name> -n wayfarer
```

### Restart a pod (delete, it auto-recreates):

```bash
kubectl delete pod <pod-name> -n wayfarer
```

### Delete all secrets (with label):

```bash
kubectl delete secret -l owner=wayfarer -n wayfarer
```

---

## 📚 Resources

- [📘 Kubernetes CLI Cheatsheet](./kubectl-cheatsheet.md)

---

Happy Hacking! 🚀
