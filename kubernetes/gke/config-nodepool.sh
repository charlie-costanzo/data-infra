GKE_NODEPOOL_NAMES=(
  'apps-v1'
)

declare -A GKE_NODEPOOL_NODE_COUNTS
GKE_NODEPOOL_NODE_COUNTS=(
  ['apps-v1']=1
)

declare -A GKE_NODEPOOL_NODE_LOCATIONS
GKE_NODEPOOL_NODE_LOCATIONS=(
  ['apps-v1']=$GKE_REGION-a,$GKE_REGION-b,$GKE_REGION-c
)

declare -A GKE_NODEPOOL_MACHINE_TYPES
GKE_NODEPOOL_MACHINE_TYPES=(
  ['apps-v1']=n1-standard-4
)
