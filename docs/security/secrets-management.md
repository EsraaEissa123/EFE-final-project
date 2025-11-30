# Secrets Management 🔑

## Overview
Sensitive information such as database passwords and API keys must **never** be stored in plain text or committed to version control. We use **Kubernetes Secrets** to manage this data securely.

## Implementation

### 1. Storage
Secrets are stored in `k8s/secrets/vprofile-secrets.yaml`.
- **Type**: `Opaque`
- **Encoding**: Values are Base64 encoded.
- **Encryption**: In a production environment, these should be encrypted at rest in etcd.

### 2. Injection
Secrets are injected into containers as **Environment Variables**.
Example from `vproapp.yaml`:
```yaml
env:
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: vprofile-secrets
        key: DB_PASSWORD
```

### 3. Secrets List
The following secrets are managed:

| Secret Key | Description | Usage |
|------------|-------------|-------|
| `DB_USER` | Database Username | MySQL & App |
| `DB_PASSWORD` | Database Password | MySQL & App |
| `RMQ_USER` | RabbitMQ Username | RabbitMQ & App |
| `RMQ_PASSWORD` | RabbitMQ Password | RabbitMQ & App |

## Best Practices
1. **Never commit actual passwords** to Git. The values in `vprofile-secrets.yaml` are placeholders/defaults for this demo.
2. **Rotate Secrets**: Change passwords regularly.
3. **Least Privilege**: Only mount secrets to pods that absolutely need them.
