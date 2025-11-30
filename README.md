# vProfile App - Kubernetes Deployment with Ansible & Jenkins

**Team 3 - DevOps Final Project**

## 📋 Project Overview

This project deploys the **vProfile** multi-tier Java web application to a production-grade Kubernetes cluster using:
- **Kubernetes** (kubeadm) on 3 AWS EC2 instances
- **Ansible** for complete automation (provisioning, deployment, monitoring)
- **Jenkins** for CI/CD pipelines
- **Secure deployment** with NetworkPolicies
- **Prometheus + Grafana** for monitoring

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    AWS EC2 Infrastructure                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ k8s-master   │  │ k8s-worker1  │  │ k8s-worker2  │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│              Kubernetes Cluster (Calico CNI)             │
│  ┌──────────────────────────────────────────────────┐   │
│  │  vProfile App (Tomcat)                            │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐       │   │
│  │  │  MySQL   │  │Memcached │  │ RabbitMQ │       │   │
│  │  └──────────┘  └──────────┘  └──────────┘       │   │
│  └──────────────────────────────────────────────────┘   │
│                                                          │
│  NetworkPolicies | Security Hardening | Monitoring      │
└─────────────────────────────────────────────────────────┘
                         │
                         ▼
              Jenkins CI/CD Pipeline
```

## 🚀 Getting Started

### Prerequisites
- 3 AWS EC2 instances (Ubuntu 22.04)
- Ansible installed locally
- AWS ECR access
- Jenkins server

### Quick Start

1. **Provision Infrastructure**
   ```bash
   # Update inventory with your EC2 IPs
   vim ansible/inventory/hosts
   ```

2. **Prepare Nodes**
   ```bash
   cd ansible
   ansible-playbook -i inventory/hosts playbooks/prepare-nodes.yml
   ```

3. **Bootstrap Kubernetes Cluster**
   ```bash
   ansible-playbook -i inventory/hosts playbooks/kubeadm-init.yml
   ```

4. **Deploy vProfile Application**
   ```bash
   ansible-playbook -i inventory/hosts playbooks/deploy-app.yml
   ```

5. **Setup Monitoring**
   ```bash
   ansible-playbook -i inventory/hosts playbooks/monitoring.yml
   ```

## 📁 Project Structure

```
.
├── ansible/
│   ├── inventory/          # Host inventory
│   ├── playbooks/          # Automation playbooks
│   └── vars/               # Variables and configs
├── k8s/
│   ├── deployments/        # K8s deployments
│   ├── services/           # K8s services
│   ├── network-policies/   # Security policies
│   ├── configmaps/         # Configuration
│   └── secrets/            # Sensitive data
├── docker/                 # Dockerfiles
├── jenkins/                # CI/CD pipelines
├── docs/                   # Documentation
└── src/                    # vProfile Java application
```

## ✅ Success Criteria

- [x] 3-node Kubernetes cluster operational
- [ ] vProfile app running securely
- [ ] NetworkPolicies enforced
- [ ] CI/CD pipelines functional
- [ ] Monitoring dashboard active
- [ ] Complete documentation

## 📖 Documentation

See the [docs/](docs/) folder for:
- Architecture diagrams
- Setup guides
- User manuals
- Troubleshooting

## 👥 Team 3

DevOps Engineering - Final Project 2025
