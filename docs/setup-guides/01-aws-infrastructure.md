# AWS Infrastructure Setup Guide

## Prerequisites
- AWS Account with appropriate permissions
- AWS CLI installed and configured
- SSH key pair access

## Step 1: Create EC2 Instances

### Launch Instances via AWS Console

1. **Navigate to EC2 Dashboard**
   - Go to AWS Console → EC2 → Instances → Launch Instance

2. **Configure Instance 1 (Master)**
   - **Name**: `k8s-master`
   - **AMI**: Ubuntu Server 22.04 LTS (64-bit x86)
   - **Instance Type**: `t2.medium` (2 vCPU, 4GB RAM)
   - **Key Pair**: Select or create new key pair
   - **Network Settings**: Create/select VPC
   - **Storage**: 20 GB gp3

3. **Configure Instance 2 (Worker 1)**
   - **Name**: `k8s-worker1`
   - **AMI**: Ubuntu Server 22.04 LTS
   - **Instance Type**: `t2.medium`
   - **Key Pair**: Same as master
   - **Network Settings**: Same VPC as master
   - **Storage**: 20 GB gp3

4. **Configure Instance 3 (Worker 2)**
   - **Name**: `k8s-worker2`
   - **AMI**: Ubuntu Server 22.04 LTS
   - **Instance Type**: `t2.medium`
   - **Key Pair**: Same as master
   - **Network Settings**: Same VPC as master
   - **Storage**: 20 GB gp3

## Step 2: Configure Security Group

### Create Security Group
Name: `k8s-cluster-sg`

### Inbound Rules

| Type | Protocol | Port Range | Source | Description |
|------|----------|------------|--------|-------------|
| SSH | TCP | 22 | My IP | SSH access |
| Custom TCP | TCP | 6443 | Security Group (self) | Kubernetes API |
| Custom TCP | TCP | 2379-2380 | Security Group (self) | etcd |
| Custom TCP | TCP | 10250 | Security Group (self) | Kubelet API |
| Custom TCP | TCP | 10251 | Security Group (self) | kube-scheduler |
| Custom TCP | TCP | 10252 | Security Group (self) | kube-controller |
| Custom TCP | TCP | 10255 | Security Group (self) | Read-only Kubelet |
| Custom TCP | TCP | 30000-32767 | 0.0.0.0/0 | NodePort Services |
| Custom TCP | TCP | 179 | Security Group (self) | Calico BGP |
| All ICMP | ICMP | All | Security Group (self) | Ping |

### Outbound Rules
- Allow all outbound traffic

## Step 3: Assign Security Group

1. Select all 3 instances
2. Actions → Security → Change Security Groups
3. Add `k8s-cluster-sg`
4. Save

## Step 4: Allocate Elastic IPs (Optional)

For stable IPs:
```bash
aws ec2 allocate-address --domain vpc
aws ec2 associate-address --instance-id i-xxx --allocation-id eipalloc-xxx
```

## Step 5: Note Instance Details

Create a file `instances.txt` with:
```
k8s-master: <MASTER_PUBLIC_IP> / <MASTER_PRIVATE_IP>
k8s-worker1: <WORKER1_PUBLIC_IP> / <WORKER1_PRIVATE_IP>
k8s-worker2: <WORKER2_PUBLIC_IP> / <WORKER2_PRIVATE_IP>
```

## Step 6: Test SSH Access

```bash
# Set correct permissions for SSH key
chmod 400 ~/.ssh/k8s-key.pem

# Test SSH to master
ssh -i ~/.ssh/k8s-key.pem ubuntu@<MASTER_PUBLIC_IP>

# Test SSH to workers
ssh -i ~/.ssh/k8s-key.pem ubuntu@<WORKER1_PUBLIC_IP>
ssh -i ~/.ssh/k8s-key.pem ubuntu@<WORKER2_PUBLIC_IP>
```

## Step 7: Update Ansible Inventory

Edit `ansible/inventory/hosts`:
```ini
[master]
k8s-master ansible_host=<MASTER_PUBLIC_IP> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/k8s-key.pem

[workers]
k8s-worker1 ansible_host=<WORKER1_PUBLIC_IP> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/k8s-key.pem
k8s-worker2 ansible_host=<WORKER2_PUBLIC_IP> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/k8s-key.pem
```

## Step 8: Verify Connectivity

```bash
cd ansible
ansible all -i inventory/hosts -m ping
```

Expected output:
```
k8s-master | SUCCESS => { "ping": "pong" }
k8s-worker1 | SUCCESS => { "ping": "pong" }
k8s-worker2 | SUCCESS => { "ping": "pong" }
```

## Cost Optimization Tips

1. **Stop instances when not in use**
   ```bash
   aws ec2 stop-instances --instance-ids i-xxx i-yyy i-zzz
   ```

2. **Use AWS Cost Explorer** to monitor spending

3. **Set up billing alerts** in AWS Budgets

4. **Terminate when project complete**
   ```bash
   aws ec2 terminate-instances --instance-ids i-xxx i-yyy i-zzz
   ```

## Troubleshooting

### Cannot SSH
- Check security group allows your IP
- Verify key permissions: `chmod 400 ~/.ssh/k8s-key.pem`
- Check public IP is correct

### Instances not in same VPC
- Recreate instances in same VPC
- Or configure VPC peering

### Security group issues
- Ensure all required ports are open
- Check source is set to security group itself for cluster communication

## Next Steps

Once infrastructure is ready, proceed to:
- **Phase 2**: Ansible Setup
- **Phase 3**: Node Provisioning
