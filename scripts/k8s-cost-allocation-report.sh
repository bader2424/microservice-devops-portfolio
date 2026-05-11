#!/usr/bin/env bash
set -euo pipefail

INSTANCE_HOURLY_COST="${INSTANCE_HOURLY_COST:-0}"
HOURS_PER_MONTH="${HOURS_PER_MONTH:-730}"

echo "Kubernetes lightweight cost allocation report"
echo "This estimates namespace share using requested CPU and memory."
echo "Set INSTANCE_HOURLY_COST to your EC2 hourly price for rough monthly estimates."
echo

echo "Current node and workload usage:"
kubectl get nodes
kubectl top nodes || true
kubectl top pods -A || true

echo
echo "Resource requests by namespace:"
kubectl get pods -A -o json | jq -r '
  .items[]
  | .metadata.namespace as $ns
  | .spec.containers[]?
  | [
      $ns,
      (.resources.requests.cpu // "0"),
      (.resources.requests.memory // "0")
    ]
  | @tsv
' | awk '
function cpu_to_m(cpu) {
  if (cpu ~ /m$/) { sub(/m$/, "", cpu); return cpu + 0 }
  return (cpu + 0) * 1000
}
function mem_to_mi(mem) {
  if (mem ~ /Ki$/) { sub(/Ki$/, "", mem); return (mem + 0) / 1024 }
  if (mem ~ /Mi$/) { sub(/Mi$/, "", mem); return mem + 0 }
  if (mem ~ /Gi$/) { sub(/Gi$/, "", mem); return (mem + 0) * 1024 }
  return 0
}
{
  ns=$1
  cpu[ns]+=cpu_to_m($2)
  mem[ns]+=mem_to_mi($3)
  total_cpu+=cpu_to_m($2)
  total_mem+=mem_to_mi($3)
}
END {
  printf "%-25s %12s %14s %12s\n", "NAMESPACE", "CPU_MCORES", "MEMORY_MI", "SHARE_%"
  for (ns in cpu) {
    share = 0
    if (total_cpu + total_mem > 0) {
      share = ((cpu[ns] / (total_cpu ? total_cpu : 1)) + (mem[ns] / (total_mem ? total_mem : 1))) / 2 * 100
    }
    printf "%-25s %12.0f %14.0f %11.2f%%\n", ns, cpu[ns], mem[ns], share
  }
}'

echo
if [ "${INSTANCE_HOURLY_COST}" != "0" ]; then
  nodes=$(kubectl get nodes --no-headers | wc -l)
  monthly=$(awk -v n="${nodes}" -v h="${INSTANCE_HOURLY_COST}" -v m="${HOURS_PER_MONTH}" 'BEGIN { printf "%.2f", n*h*m }')
  echo "Rough EC2 worker-node monthly estimate: ${nodes} nodes * ${INSTANCE_HOURLY_COST}/hour * ${HOURS_PER_MONTH}h = USD ${monthly}"
else
  echo "Set INSTANCE_HOURLY_COST, for example INSTANCE_HOURLY_COST=0.10, to estimate monthly worker-node cost."
fi