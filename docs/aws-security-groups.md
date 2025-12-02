# AWS Security Group Configuration for Kubernetes Cluster

## Required Inbound Ports

### Master Node (k8s-master)
| Port/Range | Protocol | Source | Purpose |
|------------|----------|--------|---------|
| 22 | TCP | Your IP | SSH access |
| 6443 | TCP | Worker nodes + Your IP | Kubernetes API server |
| 2379-2380 | TCP | Master nodes | etcd server client API |
| 10250 | TCP | Master + Worker nodes | Kubelet API |
| 10251 | TCP | Master nodes | kube-scheduler |
| 10252 | TCP | Master nodes | kube-controller-manager |
| 30000-32767 | TCP | 0.0.0.0/0 | NodePort Services (including Ingress) |

### Worker Nodes (k8s-worker1, k8s-worker2)
| Port/Range | Protocol | Source | Purpose |
|------------|----------|--------|---------|
| 22 | TCP | Your IP | SSH access |
| 10250 | TCP | Master + Worker nodes | Kubelet API |
| 30000-32767 | TCP | 0.0.0.0/0 | NodePort Services (including Ingress) |

## How to Check Security Groups in AWS Console

1. **Go to EC2 Dashboard**
   - Navigate to AWS Console → EC2

2. **Select Your Instance**
   - Click on one of your instances (e.g., k8s-master)

3. **Check Security Groups**
   - In the instance details, look for "Security" tab
   - Click on the security group name

4. **Review Inbound Rules**
   - Check the "Inbound rules" tab
   - Verify all required ports are open

## How to Fix (If Ports Are Missing)

### Option 1: AWS Console
1. Click "Edit inbound rules"
2. Click "Add rule"
3. Add each missing port/range
4. Set source appropriately:
   - **SSH (22)**: Your IP only (for security)
   - **NodePort range (30000-32767)**: 0.0.0.0/0 (for public access)
   - **Internal ports**: Security group ID of the cluster

### Option 2: AWS CLI
```bash
# Get your security group ID
aws ec2 describe-instances --instance-ids i-xxxxx --query 'Reservations[0].Instances[0].SecurityGroups[0].GroupId'

# Add SSH rule (replace with your IP)
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxx \
  --protocol tcp \
  --port 22 \
  --cidr YOUR_IP/32

# Add NodePort range
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxx \
  --protocol tcp \
  --port 30000-32767 \
  --cidr 0.0.0.0/0

# Add Kubernetes API
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxx \
  --protocol tcp \
  --port 6443 \
  --cidr 0.0.0.0/0
```

## Current Issue

The connection timeout suggests that **port 22 (SSH)** is not accessible from your current IP address. This is the most critical port to fix first.

### Quick Fix
1. Go to AWS Console → EC2 → Security Groups
2. Find the security group attached to your instances
3. Edit inbound rules
4. Ensure port 22 is open to your IP (or 0.0.0.0/0 temporarily for testing)
5. Save the rules
6. Try connecting again

## Security Best Practices

1. **Restrict SSH**: Only allow SSH from your IP address, not 0.0.0.0/0
2. **Use Security Group References**: For internal communication, use security group IDs as source instead of CIDR blocks
3. **NodePort Range**: Keep 30000-32767 open to 0.0.0.0/0 only if you need public access to services
4. **Consider VPN**: For production, use a VPN instead of exposing SSH publicly
