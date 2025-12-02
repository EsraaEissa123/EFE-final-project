# Read-Only Root Filesystem Implementation

## 📋 Overview

This document explains the implementation of `readOnlyRootFilesystem: true` security hardening across all vProfile application deployments.

---

## 🔒 Security Benefits

Enabling read-only root filesystem provides several security advantages:

1. **Prevents Runtime Modifications**: Attackers cannot modify binaries or configuration files at runtime
2. **Limits Attack Surface**: Reduces the ability to install malicious software or backdoors
3. **Compliance**: Meets security best practices and compliance requirements (CIS Benchmarks)
4. **Immutable Infrastructure**: Enforces immutable container principles

---

## ✅ Implementation Status

### 1. vProfile Application (Tomcat)

**File**: `k8s/deployments/vpro_app.yaml`

**Status**: ✅ Implemented with volume mounts

**Configuration**:
```yaml
securityContext:
  readOnlyRootFilesystem: true

volumeMounts:
  - name: tomcat-temp
    mountPath: /usr/local/tomcat/temp
  - name: tomcat-work
    mountPath: /usr/local/tomcat/work
  - name: tomcat-logs
    mountPath: /usr/local/tomcat/logs

volumes:
  - name: tomcat-temp
    emptyDir: {}
  - name: tomcat-work
    emptyDir: {}
  - name: tomcat-logs
    emptyDir: {}
```

**Rationale**: Tomcat requires write access to:
- `/usr/local/tomcat/temp` - Temporary files during request processing
- `/usr/local/tomcat/work` - JSP compilation and servlet work directory
- `/usr/local/tomcat/logs` - Application and access logs

**Solution**: Mount `emptyDir` volumes for these directories, allowing writes while keeping the root filesystem read-only.

---

### 2. Memcached

**File**: `k8s/deployments/vpro_cache.yaml`

**Status**: ✅ Implemented without volume mounts

**Configuration**:
```yaml
securityContext:
  readOnlyRootFilesystem: true
```

**Rationale**: Memcached stores all data in memory and doesn't require filesystem writes for normal operation.

**Solution**: Simple read-only filesystem without additional volumes.

---

### 3. RabbitMQ

**File**: `k8s/deployments/vpro_mq.yaml`

**Status**: ✅ Implemented with volume mount

**Configuration**:
```yaml
securityContext:
  readOnlyRootFilesystem: true

volumeMounts:
  - name: rabbitmq-data
    mountPath: /var/lib/rabbitmq

volumes:
  - name: rabbitmq-data
    emptyDir: {}
```

**Rationale**: RabbitMQ requires write access to `/var/lib/rabbitmq` for:
- Message queue persistence
- Mnesia database files
- Node metadata

**Solution**: Mount `emptyDir` volume for data directory.

---

### 4. MySQL Database

**File**: `k8s/deployments/vpro_db.yaml`

**Status**: ⚠️ Cannot implement (by design)

**Current Configuration**:
```yaml
# readOnlyRootFilesystem NOT enabled
volumeMounts:
  - name: mysql-data
    mountPath: /var/lib/mysql
  - name: init-db
    mountPath: /docker-entrypoint-initdb.d
```

**Rationale**: MySQL requires extensive filesystem access:
- `/var/lib/mysql` - Database files
- `/tmp` - Temporary tables and sort operations
- `/var/run/mysqld` - Socket files
- Various other directories for initialization scripts

**Decision**: Keep filesystem writable for MySQL. The database already has:
- Proper volume mounts for data persistence
- Security context with `runAsNonRoot: true`
- Capabilities dropped
- Resource limits

**Note**: For production, consider using managed database services (RDS) instead of self-hosted MySQL in containers.

---

## 📊 Security Compliance Summary

| Component | Read-Only FS | Volume Mounts | Security Score |
|-----------|--------------|---------------|----------------|
| vProfile App | ✅ Yes | 3 (temp, work, logs) | ⭐⭐⭐⭐⭐ |
| Memcached | ✅ Yes | 0 (none needed) | ⭐⭐⭐⭐⭐ |
| RabbitMQ | ✅ Yes | 1 (data) | ⭐⭐⭐⭐⭐ |
| MySQL | ❌ No | 2 (data, init) | ⭐⭐⭐⭐ |

**Overall Security Posture**: Excellent (3/4 components with read-only filesystem)

---

## 🧪 Testing & Validation

### Verify Read-Only Filesystem

Test that containers cannot write to the root filesystem:

```bash
# Test vProfile app
kubectl exec -n vprofile deployment/vproapp -- touch /test.txt
# Expected: touch: cannot touch '/test.txt': Read-only file system

# Test memcached
kubectl exec -n vprofile deployment/vprocache -- touch /test.txt
# Expected: touch: cannot touch '/test.txt': Read-only file system

# Test RabbitMQ
kubectl exec -n vprofile deployment/vpromq -- touch /test.txt
# Expected: touch: cannot touch '/test.txt': Read-only file system
```

### Verify Writable Volumes

Test that mounted volumes are writable:

```bash
# Test Tomcat temp directory
kubectl exec -n vprofile deployment/vproapp -- touch /usr/local/tomcat/temp/test.txt
# Expected: Success (no error)

# Test RabbitMQ data directory
kubectl exec -n vprofile deployment/vpromq -- touch /var/lib/rabbitmq/test.txt
# Expected: Success (no error)
```

---

## 🔍 Troubleshooting

### Issue: Application Fails to Start

**Symptom**: Pods crash or fail health checks after enabling read-only filesystem

**Diagnosis**:
```bash
kubectl logs -n vprofile deployment/vproapp
kubectl describe pod -n vprofile <pod-name>
```

**Common Causes**:
1. Application tries to write to unmounted directory
2. Missing volume mount for required writable path
3. Incorrect permissions on mounted volumes

**Solution**:
1. Identify the directory requiring write access from logs
2. Add appropriate `volumeMount` and `volume` configuration
3. Use `emptyDir` for temporary data or `persistentVolumeClaim` for persistent data

### Issue: Permission Denied Errors

**Symptom**: Logs show "Permission denied" errors

**Solution**:
```yaml
# Ensure fsGroup is set correctly
securityContext:
  fsGroup: 1001  # Match the container user ID
```

---

## 📚 References

- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
- [NIST Container Security Guide](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-190.pdf)

---

## ✅ Compliance Checklist

- [x] Read-only root filesystem enabled for application containers
- [x] Appropriate volume mounts for writable directories
- [x] EmptyDir volumes used for temporary data
- [x] Security context configured with runAsNonRoot
- [x] All capabilities dropped
- [x] Resource limits defined
- [x] Health probes configured
- [x] Documentation updated

---

**Last Updated**: 2025-12-01  
**Implemented By**: Team 3 DevOps  
**Security Level**: Production-Ready ✅
