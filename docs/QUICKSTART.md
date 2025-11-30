# Quick Start Guide

## Complete Deployment Steps

Follow these steps in order to deploy vProfile to Kubernetes.

### Prerequisites Checklist
- [ ] 3 EC2 instances running (Ubuntu 22.04)
- [ ] Security groups configured
- [ ] SSH access verified
- [ ] Ansible installed locally
- [ ] kubectl installed locally
- [ ] AWS ECR access configured
- [ ] Jenkins server ready (optional for CI/CD)

---

## Phase 1: Infrastructure Setup

```bash
# 1. Launch 3 EC2 instances
# Follow: docs/setup-guides/01-aws-infrastructure.md

# 2. Update inventory with your IPs
vim ansible/inventory/hosts

# 3. Test connectivity
cd ansible
ansible all -i inventory/hosts -m ping
```

**Expected**: All nodes respond with `pong`

---

## Phase 2: Node Provisioning

```bash
# Install dependencies and configure all nodes for Kubernetes
ansible-playbook -i inventory/hosts playbooks/prepare-nodes.yml

# This will:
# - Update all packages
# - Disable swap
# - Install containerd
# - Install kubead, kubelet, kubectl
# - Configure kernel modules
# - Reboot nodes
```

**Duration**: ~15-20 minutes
**Expected**: All nodes ready for K8s installation

---

## Phase 3: Kubernetes Cluster Setup

```bash
# Initialize cluster on master and join workers
ansible-playbook -i inventory/hosts playbooks/kubeadm-init.yml

# This will:
# - Initialize master node
# - Install Calico CNI
# - Join worker nodes
# - Verify cluster status
```

**Duration**: ~10-15 minutes
**Expected**: 3-node cluster in Ready state

### Verify Cluster

```bash
# SSH to master
ssh -i ~/.ssh/k8s-key.pem ubuntu@<MASTER_IP>

# Check nodes
kubectl get nodes

# Expected output:
# NAME          STATUS   ROLES           AGE   VERSION
# k8s-master    Ready    control-plane   5m    v1.28.x
# k8s-worker1   Ready    <none>          4m    v1.28.x
# k8s-worker2   Ready    <none>          4m    v1.28.x
```

---

## Phase 4: Build vProfile Docker Image

```bash
# 1. Build the image locally
docker build -t vprofile-app:v1 .

# 2. Test locally (optional)
docker run -d -p 8080:8080 vprofile-app:v1
curl http://localhost:8080

# 3. Update ECR registry in global.yml
vim ansible/vars/global.yml
# Replace: REPLACE_WITH_AWS_ACCOUNT_ID with your AWS account ID

# 4. Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <ECR_REGISTRY>

# 5. Create ECR repository
aws ecr create-repository --repository-name vprofile-app --region us-east-1

# 6. Tag and push
docker tag vprofile-app:v1 <ECR_REGISTRY>/vprofile-app:latest
docker push <ECR_REGISTRY>/vprofile-app:latest
```

---

## Phase 5: Deploy vProfile Application

```bash
# 1. Update deployment with ECR registry
vim k8s/deployments/vproapp.yaml
# Replace: REPLACE_WITH_ECR_REGISTRY with your ECR URL

# 2. Deploy complete stack
ansible-playbook -i inventory/hosts playbooks/deploy-vprofile.yml

# This will deploy:
# - MySQL database
# - Memcached
# - RabbitMQ
# - vProfile application
# - All services
# - NetworkPolicies
```

**Duration**: ~10 minutes
**Expected**: All pods running

### Verify Deployment

```bash
# SSH to master
ssh -i ~/.ssh/k8s-key.pem ubuntu@<MASTER_IP>

# Check pods
kubectl get pods -n vprofile

# Expected: All pods in Running status

# Check services
kubectl get svc -n vprofile

# Get NodePort
kubectl get svc vproapp-service -n vprofile
```

### Access Application

```
URL: http://<ANY_NODE_IP>:30001
```

---

## Phase 6: Setup Monitoring

```bash
# Deploy Prometheus + Grafana
ansible-playbook -i inventory/hosts playbooks/monitoring.yml

# Access Grafana
URL: http://<ANY_NODE_IP>:30080
Username: admin
Password: (shown in playbook output)
```

---

## Phase 7: CI/CD with Jenkins (Optional)

### Setup Jenkins

1. **Install Required Plugins**
   - Docker Pipeline
   - Ansible
   - AWS ECR
   - Git

2. **Configure Credentials**
   - AWS credentials (ID: aws-ecr-credentials)
   - SSH key for K8s master (ID: k8s-master-ssh)

3. **Create CI Pipeline**
   - New Item → Pipeline
   - Pipeline script from SCM
   - Script Path: `jenkins/Jenkinsfile-CI`

4. **Create CD Pipeline**
   - New Item → Pipeline
   - Pipeline script from SCM
   - Script Path: `jenkins/Jenkinsfile-CD`

### Run Pipelines

```bash
# Trigger CI pipeline (builds and pushes to ECR)
# Trigger CD pipeline (deploys to K8s)
```

---

## Common Commands

### Check cluster status
```bash
kubectl get nodes
kubectl get pods -A
kubectl get svc -A
```

### View vProfile logs
```bash
kubectl logs -n vprofile -l app=vproapp -f
```

### Scale application
```bash
kubectl scale deployment vproapp -n vprofile --replicas=5
```

### Restart deployment
```bash
kubectl rollout restart deployment/vproapp -n vprofile
```

### Check NetworkPolicies
```bash
kubectl get networkpolicies -n vprofile
kubectl describe networkpolicy default-deny-all -n vprofile
```

---

## Troubleshooting

### Pods not starting
```bash
kubectl describe pod <POD_NAME> -n vprofile
kubectl logs <POD_NAME> -n vprofile
```

### Cannot access application
```bash
# Check service
kubectl get svc vproapp-service -n vprofile

# Check if pods are ready
kubectl get pods -n vprofile

# Test from inside cluster
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- curl http://vproapp-service.vprofile.svc.cluster.local
```

### Database connection issues
```bash
# Check MySQL pod
kubectl logs -n vprofile <MYSQL_POD_NAME>

# Verify secrets
kubectl get secret vprofile-secrets -n vprofile -o yaml
```

---

## Cleanup

### Delete application
```bash
kubectl delete namespace vprofile
```

### Destroy cluster
```bash
# On master
kubeadm reset

# On workers
kubeadm reset
```

### Terminate EC2 instances
```bash
aws ec2 terminate-instances --instance-ids i-xxx i-yyy i-zzz
```

---

## Next Steps

- Review monitoring dashboards in Grafana
- Set up alerts in Prometheus
- Configure Ingress for domain access
- Implement backup strategy
- Security hardening review
