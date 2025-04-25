# 🔍 Kubernetes Debugging & Monitoring Cheat Sheet

This guide provides a collection of commonly used `kubectl` commands to check the status of your applications, services, and overall cluster health.

---

## 📦 Pods

### List all pods in a namespace
```bash
kubectl get pods -n <namespace>
```

### Get detailed pod information
```bash
kubectl describe pod <pod-name> -n <namespace>
```

### Get pod logs
```bash
kubectl logs <pod-name> -n <namespace>
```

### Tail logs of a pod (for real-time updates)
```bash
kubectl logs -f <pod-name> -n <namespace>
```

### Get logs from a specific container in a pod
```bash
kubectl logs <pod-name> -c <container-name> -n <namespace>
```

---

## ⚙️ Deployments

### List all deployments
```bash
kubectl get deployments -n <namespace>
```

### Describe a deployment
```bash
kubectl describe deployment <deployment-name> -n <namespace>
```

---

## 🚢 Services

### List all services
```bash
kubectl get svc -n <namespace>
```

### Describe a specific service
```bash
kubectl describe svc <service-name> -n <namespace>
```

---

## 🔐 Secrets & ConfigMaps

### List all secrets
```bash
kubectl get secrets -n <namespace>
```

### View secret contents (base64-decoded)
```bash
kubectl get secret <secret-name> -n <namespace> -o jsonpath="{.data.<key>}" | base64 -d
```

### List all config maps
```bash
kubectl get configmap -n <namespace>
```

---

## 🛠️ Other Helpful Commands

### Check events in a namespace
```bash
kubectl get events -n <namespace> --sort-by='.metadata.creationTimestamp'
```

### List all Helm releases
```bash
helm list -n <namespace>
```

### Delete a stuck pod
```bash
kubectl delete pod <pod-name> --grace-period=0 --force -n <namespace>
```

### Port-forward a service or pod
```bash
kubectl port-forward svc/<service-name> <local-port>:<target-port> -n <namespace>
```

---

## 📁 Namespaces

### List all namespaces
```bash
kubectl get namespaces
```

### Set default namespace for kubectl
```bash
kubectl config set-context --current --namespace=<namespace>
```

---

### ✅ Tip:
You can add `-o wide` to most `kubectl get` commands to get more info, like IPs and nodes.

Feel free to copy and paste this into a `README.md` or your personal DevOps playbook!
