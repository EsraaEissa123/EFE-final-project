# vProfile App - Kubernetes Deployment with Ansible & Ingress

**Team 3 - DevOps Final Project**

## 📋 Project Overview

This project deploys the **vProfile** multi-tier Java web application to a production-grade Kubernetes cluster on AWS using declarative infrastructure automation:

- **Kubernetes** (kubeadm) on 3 AWS EC2 instances (1 master, 2 workers)
- **Ansible** for complete automation (cluster provisioning, application deployment, ingress setup)
- **Nginx Ingress Controller** for external access via NodePort
- **Calico CNI** for networking
- **Docker & ECR** for containerization and registry
- **Jenkins** for CI/CD pipelines

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    AWS EC2 Infrastructure                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ k8s-master   │  │ k8s-worker1  │  │ k8s-worker2  │          │
│  │ 35.175.187   │  │ 98.92.254    │  │ 13.222.145   │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│              Kubernetes Cluster (Calico CNI)                     │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Nginx Ingress Controller (NodePort 30890)               │   │
│  │         ↓                                                 │   │
│  │  vProfile App (Tomcat) - 3 replicas                      │   │
│  │         ↓                                                 │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐               │   │
│  │  │  MySQL   │  │Memcached │  │ RabbitMQ │               │   │
│  │  │(StatefulSet)│ (Deployment)│(Deployment)│              │   │
│  │  └──────────┘  └──────────┘  └──────────┘               │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## 🌟 Key Features

- ✅ **Fully Automated Deployment**: End-to-end automation using Ansible playbooks
- ✅ **High Availability**: 3-node cluster with replicated application pods
- ✅ **Ingress Routing**: Nginx Ingress Controller for HTTP/HTTPS traffic management
- ✅ **Persistent Storage**: StatefulSets with PersistentVolumeClaims for MySQL
- ✅ **Service Discovery**: Kubernetes DNS for inter-service communication
- ✅ **Container Registry**: AWS ECR for Docker image storage
- ✅ **Declarative Configuration**: All infrastructure and application configs in YAML

## 🚀 Getting Started

### Prerequisites

**Local Machine:**
- Ansible 2.9+
- kubectl
- AWS CLI configured
- SSH key at `~/.ssh/vprofile-key.pem`

**AWS Requirements:**
- 3 EC2 instances (Ubuntu 22.04, t2.medium or larger)
- Security groups with required ports open (see [AWS Security Groups Guide](docs/aws-security-groups.md))
- ECR repository for Docker images

### Required Ports

See detailed port configuration in [`docs/aws-security-groups.md`](docs/aws-security-groups.md).

**Master Node:**
- SSH (22), Kubernetes API (6443), etcd (2379-2380), Kubelet (10250), NodePort range (30000-32767)

**Worker Nodes:**
- SSH (22), Kubelet (10250), NodePort range (30000-32767)

---

## 📦 Deployment Steps

### 1. Update Instance IPs

Update the inventory file with your AWS EC2 public IPs:

```bash
vim ansible/inventory/hosts
```

Example:
```ini
[master]
k8s-master ansible_host=35.175.187.112 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/vprofile-key.pem

[workers]
k8s-worker1 ansible_host=98.92.254.125 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/vprofile-key.pem
k8s-worker2 ansible_host=13.222.145.86 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/vprofile-key.pem
```

Also update `instances.txt` for reference.

### 2. Prepare Kubernetes Nodes

Install Docker, kubeadm, kubelet, and kubectl on all nodes:

```bash
cd ansible
ansible-playbook playbooks/prepare-nodes.yml
```

**What this does:**
- Installs Docker and Kubernetes components
- Configures system settings (swap off, kernel modules)
- Sets up prerequisites for cluster initialization

### 3. Initialize Kubernetes Cluster

Bootstrap the Kubernetes cluster on the master node:

```bash
ansible-playbook playbooks/kubeadm-init.yml
```

**What this does:**
- Initializes the master node with kubeadm
- Installs Calico CNI
- Joins worker nodes to the cluster
- Copies kubeconfig to your local machine

### 4. Build and Push Docker Image

Build the vProfile application Docker image and push to ECR:

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <your-ecr-repo>

# Build and tag
docker build -t vprofileapp:latest .
docker tag vprofileapp:latest <your-ecr-repo>/vprofileapp:latest

# Push to ECR
docker push <your-ecr-repo>/vprofileapp:latest
```

Update the image reference in `k8s/deployments/vproapp-dep.yaml` with your ECR image URI.

### 5. Deploy Application to Kubernetes

Apply all Kubernetes manifests:

```bash
# Create namespace
kubectl create namespace vprofile

# Create secrets for image pull
kubectl create secret docker-registry ecr-secret \
  --docker-server=<your-ecr-repo> \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1) \
  -n vprofile

# Deploy database (StatefulSet)
kubectl apply -f k8s/secrets/
kubectl apply -f k8s/configmaps/
kubectl apply -f k8s/deployments/vprodb-dep.yaml

# Deploy backend services
kubectl apply -f k8s/deployments/vprocache01-dep.yaml
kubectl apply -f k8s/deployments/vpromq01-dep.yaml

# Deploy application
kubectl apply -f k8s/deployments/vproapp-dep.yaml

# Create services
kubectl apply -f k8s/services/
```

### 6. Install Nginx Ingress Controller

Use Ansible to install the Nginx Ingress Controller:

```bash
ansible-playbook playbooks/install-ingress.yml
```

**What this does:**
- Deploys Nginx Ingress Controller (v1.8.2) in `ingress-nginx` namespace
- Exposes controller via NodePort (HTTP: 30890, HTTPS: 31950)
- Waits for controller pods to be ready

### 7. Configure Ingress Resource

Update your kubectl config to point to the correct master IP:

```bash
kubectl config set-cluster kubernetes --server=https://<master-public-ip>:6443 --insecure-skip-tls-verify=true
```

Apply the ingress resource:

```bash
kubectl apply -f k8s/ingress/vpro-ingress.yaml
```

Verify ingress is created:

```bash
kubectl get ingress -n vprofile
kubectl describe ingress vpro-ingress -n vprofile
```

---

## 🌐 Accessing the Application

### Option 1: Using Domain Name (Recommended)

1. **Add to `/etc/hosts`** on your local machine:
   ```bash
   echo "<worker-node-ip> vprofile.local" | sudo tee -a /etc/hosts
   # Example: echo "98.92.254.125 vprofile.local" | sudo tee -a /etc/hosts
   ```

2. **Access the application**:
   ```
   http://vprofile.local:30890/
   ```

### Option 2: Using Worker Node IP Directly

Access using any worker node's public IP with the NodePort:

```bash
curl -H "Host: vprofile.local" http://<worker-ip>:30890/
```

Example:
```bash
curl -H "Host: vprofile.local" http://98.92.254.125:30890/
```

### Expected Response

The application will redirect you to the login page:
```
HTTP/1.1 302
Location: http://vprofile.local/login
```

---

## 📁 Project Structure

```
.
├── ansible/
│   ├── ansible.cfg              # Ansible configuration
│   ├── inventory/
│   │   └── hosts                # EC2 instance inventory
│   ├── playbooks/
│   │   ├── prepare-nodes.yml    # Install K8s prerequisites
│   │   ├── kubeadm-init.yml     # Initialize K8s cluster
│   │   └── install-ingress.yml  # Deploy Nginx Ingress
│   └── vars/
│       └── k8s-vars.yml         # Kubernetes variables
├── k8s/
│   ├── deployments/             # Application deployments
│   │   ├── vproapp-dep.yaml     # Tomcat application
│   │   ├── vprodb-dep.yaml      # MySQL database
│   │   ├── vprocache01-dep.yaml # Memcached
│   │   └── vpromq01-dep.yaml    # RabbitMQ
│   ├── services/                # Kubernetes services
│   │   ├── vproapp-service.yaml
│   │   ├── vprodb-service.yaml
│   │   ├── vprocache-service.yaml
│   │   └── vpromq-service.yaml
│   ├── ingress/
│   │   └── vpro-ingress.yaml    # Ingress routing configuration
│   ├── configmaps/              # Application configuration
│   └── secrets/                 # Sensitive data
├── docker/
│   └── Dockerfile               # vProfile app containerization
├── src/                         # Java application source code
├── docs/                        # Comprehensive documentation
│   ├── aws-security-groups.md   # AWS security configuration
│   ├── QUICKSTART.md            # Quick deployment guide
│   └── setup-guides/            # Detailed setup instructions
├── instances.txt                # Current EC2 instance IPs
└── README.md                    # This file
```

---

## 🔍 Verification & Testing

### Check Cluster Health

```bash
# Verify nodes are ready
kubectl get nodes

# Check all pods
kubectl get pods -A

# Verify application pods
kubectl get pods -n vprofile
```

### Check Ingress Status

```bash
# View ingress resources
kubectl get ingress -n vprofile

# Detailed ingress information
kubectl describe ingress vpro-ingress -n vprofile

# Check ingress controller logs
kubectl logs -n ingress-nginx deployment/ingress-nginx-controller
```

### Test Connectivity

```bash
# From local machine
curl -H "Host: vprofile.local" http://<worker-ip>:30890/ -I

# Expected: HTTP 302 redirect to /login
```

---

## 🛠️ Troubleshooting

### Issue: Cannot SSH to Instances

**Problem:** `Connection timed out` when running Ansible playbooks

**Solution:**
1. Verify EC2 instances are running in AWS Console
2. Check security group allows SSH (port 22) from your IP
3. Update `ansible/inventory/hosts` with current public IPs
4. Verify SSH key permissions: `chmod 400 ~/.ssh/vprofile-key.pem`

### Issue: kubectl Connection Timeout

**Problem:** `kubectl` commands timeout or fail

**Solution:**
```bash
# Update kubeconfig with current master IP
kubectl config set-cluster kubernetes --server=https://<current-master-ip>:6443 --insecure-skip-tls-verify=true

# Verify connection
kubectl get nodes
```

### Issue: Ingress Webhook Validation Timeout

**Problem:** Error creating ingress: `failed calling webhook "validate.nginx.ingress.kubernetes.io"`

**Solution:**
```bash
# Delete the validating webhook (safe for development)
kubectl delete validatingwebhookconfigurations ingress-nginx-admission

# Retry ingress creation
kubectl apply -f k8s/ingress/vpro-ingress.yaml
```

### Issue: Pods in ImagePullBackOff

**Problem:** Application pods cannot pull image from ECR

**Solution:**
```bash
# Recreate ECR secret with fresh credentials
kubectl delete secret ecr-secret -n vprofile

kubectl create secret docker-registry ecr-secret \
  --docker-server=<your-ecr-repo> \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1) \
  -n vprofile

# Restart pods
kubectl rollout restart deployment vproapp -n vprofile
```

### Issue: Database Connection Errors

**Problem:** Application cannot connect to MySQL

**Solution:**
1. Verify database pod is running: `kubectl get pods -n vprofile -l app=vprodb`
2. Check database service: `kubectl get svc -n vprofile vprodb-service`
3. Verify database credentials in secrets: `kubectl get secret db-secret -n vprofile -o yaml`
4. Check application logs: `kubectl logs -n vprofile <vproapp-pod-name>`

See the full [AWS Security Groups Guide](docs/aws-security-groups.md) for port configuration details.

---

## 📊 Current Deployment Status

- ✅ 3-node Kubernetes cluster operational
- ✅ Calico CNI networking configured
- ✅ vProfile app running with 3 replicas
- ✅ MySQL database deployed as StatefulSet
- ✅ Memcached and RabbitMQ services active
- ✅ Nginx Ingress Controller installed (NodePort 30890/31950)
- ✅ Ingress routing configured for `vprofile.local`
- ✅ Application accessible via ingress

---

## 📖 Additional Documentation

Explore the [`docs/`](docs/) folder for detailed guides:

- **[AWS Security Groups Configuration](docs/aws-security-groups.md)** - Required port configurations
- **[Quick Start Guide](docs/QUICKSTART.md)** - Fast deployment walkthrough
- **[Arabic Project Guide](docs/ARABIC_PROJECT_GUIDE.md)** - دليل المشروع بالعربية
- **[Detailed Execution Guide (Arabic)](docs/DETAILED_EXECUTION_GUIDE_AR.md)** - دليل التنفيذ المفصل

---

## 🎯 Next Steps

1. **Set up monitoring**: Deploy Prometheus and Grafana for cluster monitoring
2. **Implement CI/CD**: Configure Jenkins pipelines for automated deployments
3. **Add SSL/TLS**: Configure HTTPS with cert-manager and Let's Encrypt
4. **Network Policies**: Implement NetworkPolicies for pod-to-pod security
5. **Load Balancer**: Replace NodePort with AWS LoadBalancer for production
6. **Backup Strategy**: Implement automated backups for MySQL StatefulSet

---

## 💡 Tips & Best Practices

- Always update `ansible/inventory/hosts` and `instances.txt` when instance IPs change
- Use ECR for production image storage (included in AWS Free Tier)
- Keep secrets encrypted and never commit to Git
- Use `kubectl get events -n vprofile` to debug deployment issues
- Monitor pod resource usage: `kubectl top pods -n vprofile`
- For production, use persistent volumes with EBS for database storage

---

## 👥 Team 3

**DevOps Engineering - Final Project 2025**

This project demonstrates:
- Infrastructure as Code (IaC) with Ansible
- Container orchestration with Kubernetes
- Ingress traffic management
- Declarative application deployment
- Cloud-native architecture on AWS

---

## 📝 License

Educational project for DevOps training purposes.

---

## 🔗 Quick Links

- **Application URL**: `http://vprofile.local:30890/`
- **Ingress Controller**: `http://<worker-ip>:30890/`
- **Kubernetes Dashboard**: (To be configured)
- **Monitoring**: (To be configured)

**Note**: Replace `<worker-ip>` with any of your worker node public IPs (98.92.254.125 or 13.222.145.86)
