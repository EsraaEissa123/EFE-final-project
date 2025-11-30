# Network Security Policies 🛡️

## Overview
We use **Kubernetes NetworkPolicies** to implement a "Zero Trust" security model. By default, all traffic is blocked, and we only allow specific communication paths required for the application to function.

## Implemented Policies

### 1. Default Deny All (`default-deny.yaml`)
**Behavior:** Blocks ALL ingress (incoming) and egress (outgoing) traffic for all pods in the `vprofile` namespace.
**Why:** This establishes a secure baseline. If a new pod is added, it is isolated by default until explicitly allowed.

### 2. Allow vProfile Traffic (`allow-vprofile.yaml`)
This policy explicitly allows the following connections:

| Source | Destination | Port | Protocol | Purpose |
|--------|-------------|------|----------|---------|
| `vproapp` (Tomcat) | `vprodb` (MySQL) | 3306 | TCP | Database queries |
| `vproapp` (Tomcat) | `vprocache` (Memcached) | 11211 | TCP | Caching |
| `vproapp` (Tomcat) | `vpromq` (RabbitMQ) | 5672 | TCP | Message Queue |
| Any Pod | DNS Server | 53 | UDP | Service Discovery |

## How to Verify
To check active policies:
```bash
kubectl get networkpolicies -n vprofile
```

To test isolation (example):
```bash
# Try to connect to DB from a random pod (should fail)
kubectl run test-pod --image=busybox --restart=Never -- nc -zv vprodb-service 3306
# Output: Operation timed out
```
