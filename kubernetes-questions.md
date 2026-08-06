# Kubernetes questions, easiest to hardest

## 1. What is the difference between a readiness probe and a liveness probe, and what happens when each one fails?

A failing readiness probe removes the Pod from Service endpoints so it stops receiving traffic,
but the container keeps running — it's a "not yet / not right now" signal. A failing liveness
probe makes the kubelet kill and restart the container, subject to the Pod's restart policy.
Confusing the two is a classic outage amplifier: a liveness probe on a dependency check turns a
slow downstream into a cluster-wide restart storm.

## 2. You run `kubectl delete pod` on a Pod managed by a Deployment, but a moment later the same number of Pods is back. Why?

Deleting the Pod only removes one instance; the ReplicaSet controller notices actual state
(n-1 Pods) no longer matches desired state (n replicas) and creates a replacement — that's
reconciliation, the core control-loop idea of Kubernetes. The new Pod has a new name and IP;
nothing "restarted." To actually remove workload capacity you change `spec.replicas` or delete
the owning Deployment, not the Pods.

## 3. A Pod is stuck in `Pending` and `kubectl describe pod` shows no events from the scheduler at all. What does the absence of scheduling events tell you?

No events means the scheduler never attempted to place the Pod — the problem sits before
scheduling, not in it. Typical causes: the Pod names a `schedulerName` that doesn't exist, the
scheduler itself is down, or an admission-time gate (e.g. `schedulingGates`) is holding the Pod
back. Had the scheduler tried and failed, you would see `FailedScheduling` events explaining
which predicates (resources, taints, affinity) rejected each node.

## 4. A container keeps restarting with `CrashLoopBackOff`, but its logs are empty. What are the likely causes and how do you get diagnostic output?

Empty logs usually mean the process died before writing anything: a bad entrypoint/command, a
missing binary or shared library, or a failing `postStart` hook killing the container. Check
`kubectl describe pod` for the exit code (127 = command not found, 137 = OOM/SIGKILL) and use
`kubectl logs --previous` to read the prior instance's output. If that's still empty, override
the command with `sleep` and exec in, or check events for image and hook failures.

## 5. Why can a Pod be evicted even though its memory usage never exceeded its memory limit?

Eviction is driven by node-level memory pressure, not per-container limits — the kubelet evicts
Pods when the node crosses its eviction thresholds. Victims are ranked by QoS class and by usage
relative to *requests*, so a `Burstable` Pod using more than it requested is a prime target even
while under its limit. A Pod with requests equal to limits (`Guaranteed` QoS) is evicted last,
which is why setting requests honestly matters more than setting limits.

## 6. During a rolling update with `maxUnavailable: 0` and `maxSurge: 1`, the rollout is stuck. The new Pod is `Running`. What is the most likely cause and why does the rollout not proceed?

A `Running` Pod is not a *ready* Pod — the Deployment controller only scales down an old
ReplicaSet Pod once the surge Pod passes its readiness probe, because `maxUnavailable: 0`
forbids dipping below full capacity. The most likely cause is a failing or never-succeeding
readiness probe (or a gated readiness condition, e.g. a `readinessGate`) on the new revision.
The rollout stays wedged until readiness is achieved or `progressDeadlineSeconds` marks it
failed — which still doesn't roll it back automatically.

## 7. During a rolling update, clients see connection errors for a few seconds even though the old Pods shut down "gracefully." Why does traffic still reach terminating Pods, and what is the standard fix?

Pod termination and endpoint removal are parallel, not sequential: the kubelet sends SIGTERM
while the EndpointSlice update is still propagating to every kube-proxy and load balancer, so
for a window the Pod is dying *and* still routable. The standard fix is a `preStop` sleep of a
few seconds plus an app that keeps serving in-flight requests after SIGTERM, giving the dataplane
time to converge before the listener closes. `terminationGracePeriodSeconds` must exceed
preStop + shutdown time, or the Pod gets SIGKILLed mid-drain.

## 8. A node goes down and a StatefulSet Pod on it stays `Terminating` forever instead of being rescheduled, while a Deployment's Pods move within minutes. Why the difference?

StatefulSets guarantee at-most-one Pod per identity, because two `pod-0`s could both mount the
same volume or split-brain a database — so the controller refuses to create a replacement until
it is *certain* the old one is gone. With the node unreachable, the kubelet can't confirm
termination, and the Pod hangs until the Node object is deleted, the Pod is force-deleted, or a
fencing mechanism intervenes. Deployments have no identity to protect, so they replace
unreachable Pods on suspicion alone.

## 9. A `PodDisruptionBudget` with `minAvailable: 2` protects a 2-replica Deployment. Why can a node drain now hang forever, and why does a node *crash* still take a Pod down anyway?

`kubectl drain` uses the Eviction API, which refuses any eviction that would violate the PDB —
with replicas equal to `minAvailable`, zero disruptions are allowed and the drain blocks
indefinitely. But PDBs only guard *voluntary* disruptions: a node crash, kernel panic, or
OOM kill bypasses the Eviction API entirely, so the budget offers no protection there. The fix
is capacity headroom (3 replicas with `minAvailable: 2`), not a stricter budget.

## 10. A NetworkPolicy selecting a Pod allows ingress only from Pods labeled `role: frontend`, yet the Pod is still reachable from a `kubectl port-forward` and from a node's kubelet health checks. Why?

`port-forward` traffic doesn't traverse the Pod network as normal Pod-to-Pod traffic — the API
server tunnels it to the kubelet, which connects from the node's own network namespace, and
node-originated traffic (including kubelet probes) is typically exempt or seen with the node IP,
which no `podSelector` matches. NetworkPolicy semantics also depend entirely on the CNI plugin
enforcing them — with a non-enforcing CNI the policy is silently inert. So "policy applied" never
implies "policy enforced"; verify with a test Pod, not with port-forward.

## 11. Two controllers repeatedly overwrite each other's changes to the same Deployment field, and `kubectl apply` starts reporting field conflicts. What mechanism is involved, and how should ownership be resolved?

This is Server-Side Apply's managed-fields conflict detection: every field in an object records
a manager, and an apply that touches a field owned by a different manager is rejected with a
conflict. The fix is to make ownership intentional — each controller should apply only the
fields it owns (removing contested fields from its applied manifest transfers ownership away),
rather than forcing with `--force-conflicts`, which just steals ownership and perpetuates the
fight. Classic example: HPA owns `spec.replicas`, so the Deployment's applier must omit
`replicas` entirely.
