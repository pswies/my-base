# Kubernetes: Production & Scaling

## Rolling updates & rollbacks

When you update a Deployment (new image tag, config change, etc.), Kubernetes does a **rolling update** by default — it brings up new pods before terminating old ones, so the app stays available.

Controlled by two fields in the Deployment spec:

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 0    # never kill an old pod before a new one is Ready
    maxSurge: 1          # allow 1 extra pod above desired count during rollout
```

`maxUnavailable: 0` + `maxSurge: 1` is the safest setting — zero downtime, but briefly runs one extra pod. For cost-sensitive or resource-tight clusters you might flip it: `maxUnavailable: 1, maxSurge: 0` — kills one before adding one.

Rollback is one command:
```bash
kubectl rollout undo deployment/my-app
kubectl rollout undo deployment/my-app --to-revision=3  # specific revision
kubectl rollout history deployment/my-app               # see revisions
```

Kubernetes stores the previous ReplicaSet (not deleted, just scaled to 0) so rollback is instant — no image pull needed.

---

## Blue/Green deployments

Blue/Green means running two full identical environments — one live (blue), one idle (green). You deploy to green, test it, then flip traffic by updating the Service selector. Rollback = flip the selector back.

```yaml
# Blue deployment: label version: blue
# Green deployment: label version: green

# Service points at blue:
selector:
  app: my-app
  version: blue

# To cut over: patch the service
kubectl patch service my-app -p '{"spec":{"selector":{"version":"green"}}}'
```

**Tradeoff:** Requires 2x the resources (both environments fully running). The payoff is instant, clean cutover and instant rollback. Common for risky releases or compliance requirements where you can't do a partial rollout.

---

## Canary deployments

Instead of an all-or-nothing switch, canary sends a small percentage of traffic to the new version, watches metrics, then gradually increases.

The simple Kubernetes-native approach uses replica ratio to split traffic:

```
my-app-stable:  9 replicas  → ~90% of traffic
my-app-canary:  1 replica   → ~10% of traffic
```

Both have `app: my-app` so the Service load-balances across all 10 pods. You shift traffic by scaling replicas.

This is coarse — you can't do "exactly 5%" without fractional pods. For precise percentage control you need a service mesh (Istio, Linkerd) or a traffic-aware ingress controller (NGINX with canary annotations, Argo Rollouts).

**Argo Rollouts** is the standard tool for sophisticated canary/blue-green — it adds a `Rollout` CRD that replaces Deployment and gives you declarative canary steps with automated analysis:

```yaml
steps:
  - setWeight: 10       # send 10% to canary
  - pause: {duration: 5m}
  - analysis: {...}     # query metrics, abort if error rate spikes
  - setWeight: 50
  - pause: {duration: 5m}
  - setWeight: 100
```

---

## High availability control plane

In production you run multiple control plane nodes (typically 3 or 5 — odd number for etcd quorum).

etcd uses the **Raft consensus algorithm** — it needs a majority (quorum) to commit writes. With 3 nodes it tolerates 1 failure. With 5 nodes it tolerates 2. Never run 2 or 4 — you don't gain fault tolerance over 1 and 3 respectively, but pay the resource cost.

The API server is stateless — you can run as many replicas as you want behind a load balancer. The scheduler and controller manager use **leader election** (via a Lease object in etcd) — multiple instances run but only one is active at a time, so you get HA without split-brain.

Managed Kubernetes (EKS, GKE, AKS) handles all of this for you — the control plane is fully managed and you never see or pay for the control plane nodes directly.

---

## Cluster upgrades

Kubernetes releases a new minor version roughly every 4 months. Support for a version lasts ~14 months (3 minor versions back). Staying current matters — falling behind makes upgrades riskier and cuts you off from security patches.

The standard upgrade sequence:

1. **Upgrade control plane first** — API server, scheduler, controller manager
2. **Upgrade node groups** — typically by rolling new nodes in and draining old ones
3. **Update manifests** for any deprecated APIs (Kubernetes occasionally removes old API versions)

`kubectl drain` gracefully evicts all pods from a node before you upgrade or replace it:
```bash
kubectl drain node-1 --ignore-daemonsets --delete-emptydir-data
# upgrade the node
kubectl uncordon node-1   # mark it schedulable again
```

In practice on managed Kubernetes: the control plane upgrade is one click / one API call. Node upgrades are done by updating the node pool version — the cloud provider handles drain/replace/uncordon. The main work is testing your workloads against the new version and handling API deprecations.
