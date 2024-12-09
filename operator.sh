
namespace="kube-system"



function install_operator {
    helm install --wait --generate-name -n ${namespace} --create-namespace nvidia/gpu-operator
}

function install_time_slicing {
    kubectl -n ${namespace} apply -f time-slicing-config-all.yaml
    kubectl patch clusterpolicies.nvidia.com/cluster-policy -n ${namespace} --type merge -p '{"spec": {"devicePlugin": {"config": {"name": "time-slicing-config-all", "default": "any"}}}}'
    kubectl rollout restart -n ${namespace} daemonset/nvidia-device-plugin-daemonset
}

function update_time_slicing {
    kubectl -n ${namespace} apply -f time-slicing-config-all.yaml
    kubectl rollout restart -n ${namespace} daemonset/nvidia-device-plugin-daemonset
}

function install_mig {
    kubectl label nodes -l nvidia.com/gpu.present=true nvidia.com/mig.config=all-1g.20gb --overwrite
}

function verify {
    kubectl get node -l nvidia.com/gpu.present=true -o yaml  | fgrep -e gpu.count: -e gpu.replicas: -e gpu.product: -e nvidia.com/gpu: -e nvidia.com/gpu.shared:
}

function verify_mig {
    kubectl -n ${namespace} exec ds/nvidia-container-toolkit-daemonset -- chroot /run/nvidia/driver nvidia-smi -L
}

function workload {
    kubectl -n ${namespace} exec ds/nvidia-container-toolkit-daemonset -- chroot /run/nvidia/driver nvidia-smi
}


op=$1
${op}