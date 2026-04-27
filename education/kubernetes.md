# Kubernetes Learning Roadmap

## 🟢 BASIC LEVEL

### 1. Container Fundamentals

* [x] Containers vs Virtual Machines
* [x] Images, registries
* [x] Docker basics (build, run, networking)
* [x] OCI concept

---

### 2. Kubernetes Architecture

* [x] Control plane components
* [x] Node components
* [x] API Server
* [x] etcd
* [x] Scheduler
* [x] Controller Manager
* [x] kubelet & kube-proxy

---

### 3. Core Kubernetes Objects

* [x] Pods
* [x] ReplicaSets
* [x] Deployments
* [x] Services
* [x] Namespaces

---

### 4. kubectl & YAML

* [x] Imperative vs declarative
* [x] YAML structure
* [x] kubectl commands
* [x] Labels & selectors
* [x] apply vs create vs replace
* [x] Server-side apply & field management

---

### 5. Networking Basics

* [x] Kubernetes networking model
* [x] Pod-to-Pod communication
* [x] CNI (Container Network Interface)
* [x] Service types (ClusterIP, NodePort, LoadBalancer)
* [x] DNS (CoreDNS)
* [x] Deep dive:

  * [x] Network namespaces
  * [x] veth pairs
  * [x] Linux bridge (cni0)
  * [x] Routing vs NAT
  * [x] MTU / PMTU / fragmentation
  * [x] Overlay vs direct routing
  * [x] L2 vs L3 vs L4 concepts

---

## 🟡 INTERMEDIATE LEVEL

### 6. Configuration & Secrets

* [x] ConfigMaps
* [x] Secrets
* [x] Environment variable injection
* [x] Volume mounts

---

### 7. Storage

* [x] Volumes
* [x] PersistentVolumes (PV)
* [x] PersistentVolumeClaims (PVC)
* [x] StorageClasses

---

### 8. Workload Patterns

* [x] StatefulSets
* [x] DaemonSets
* [x] Jobs
* [x] CronJobs

---

### 9. Ingress & Traffic Management

* [x] Ingress
* [x] Ingress Controllers
* [x] TLS
* [x] Routing rules

---

### 10. Resource Management

* [x] Requests & limits
* [x] QoS classes
* [x] Horizontal Pod Autoscaler (HPA)

---

## 🔴 ADVANCED LEVEL

### 11. Scheduling & Affinity

* [x] NodeSelector
* [x] Node affinity
* [x] Pod affinity / anti-affinity
* [x] Topology spread constraints

---

### 12. Security

* [x] RBAC
* [x] ServiceAccounts
* [x] NetworkPolicies
* [x] Pod Security Standards

---

### 13. Observability

* [x] Liveness & readiness probes
* [x] Metrics Server
* [x] Logging patterns
* [x] Monitoring architecture

---

### 14. Helm

* [x] Charts
* [x] Templates
* [x] Values
* [x] Release lifecycle

---

### 15. Operators & CRDs

* [x] Custom Resource Definitions (CRDs)
* [x] Controller pattern implementation
* [x] Operator model

---

### 16. Production & Scaling

* [ ] High availability control plane
* [ ] Rolling updates & rollbacks
* [ ] Blue/Green deployments
* [ ] Canary deployments
* [ ] Cluster upgrades

---

## 🧠 PERFORMANCE & SYSTEM DESIGN (SPECIAL TRACK)

### Networking Performance

* [x] MTU / PMTU tuning
* [x] Overlay vs direct routing
* [x] Serialization delay & jitter
* [x] Jumbo frames tradeoffs

### System-Level Optimization

* [ ] CPU pinning / isolation
* [ ] NUMA awareness
* [ ] IRQ / NIC tuning
* [ ] Kernel networking tuning

### Architecture Decisions

* [ ] Kubernetes vs bare metal tradeoffs
* [ ] When to avoid Service abstraction
* [ ] Designing low-latency communication paths

---

## ▶️ Current Progress

**Completed:** Basic Level (1–5), Subjects 6–15
**Next:** Production & Scaling (Subject 16)

---
