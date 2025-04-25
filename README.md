# Wayfarer Microservices Local Kubernetes Deployment

This guide explains how to deploy and manage the Wayfarer backend stack (Kafka, PostgreSQL, pgAdmin) locally using Kubernetes, Helmfile, and a `Makefile`.

---

## 🚀 Deployment

To clean up any previous resources and deploy everything fresh:

```bash
make redeploy
```

This will:

- Destroy previous Helm releases and PVCs  
- Deploy Kafka, PostgreSQL, and pgAdmin via Helmfile  
- Wait for all pods to be ready  

If everything is already deployed and you just want to start port forwarding:

```bash
make start
```

If `make start` gives any error for port forwarding then kill the existing port forwards before running `make start`

```bash
make kill-ports
```

---

## 🧩 pgAdmin Setup

1. Open [http://localhost:8080](http://localhost:8080) in your browser.

2. **Login credentials:**
   - **Email:** `<pgadmin username>`
   - **Password:** `<pgadmin password>`

3. After login, click **"Add New Server"** and fill in:

   **General:**
   - **Name:** `Wayfarer Postgres`

   **Connection:**
   - **Host name/address:** `wayfarer-postgres-postgresql`
   - **Port:** `5432`
   - **Username:** `<postgress username>`
   - **Password:** `<postgress password>`

---

## 🔎 Troubleshooting

### **If the deployment gets stuck:**
  - Check All pods : `kubectl get pods -n wayfarer`
  - Check Specific PODS: `kubectl describe pod <wayfarer-api-gateway-pod-name> -n wayfarer`
---

Happy developing! 🚀
