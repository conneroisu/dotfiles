#!/usr/bin/env bash
set -euo pipefail

echo "=== K3s Service Verification ==="
echo

# Function to wait for a condition with timeout
wait_for_condition() {
    local description="$1"
    local command="$2"
    local timeout_seconds="${3:-60}"
    local check_interval="${4:-5}"
    
    echo "Waiting for: $description (timeout: ${timeout_seconds}s)"
    local elapsed=0
    
    while [ $elapsed -lt $timeout_seconds ]; do
        if eval "$command" >/dev/null 2>&1; then
            echo "✅ $description - Ready!"
            return 0
        fi
        echo "⏳ Still waiting... (${elapsed}s elapsed)"
        sleep $check_interval
        elapsed=$((elapsed + check_interval))
    done
    
    echo "❌ Timeout waiting for: $description"
    return 1
}

echo "1. Checking k3s service status..."
if systemctl is-active k3s >/dev/null 2>&1; then
    echo "✅ k3s service is active"
    systemctl status k3s --no-pager
else
    echo "❌ k3s service is not active"
    systemctl status k3s --no-pager || true
fi

echo -e "\n2. Checking if k3s is listening on port 6443..."
if wait_for_condition "k3s API server port 6443" "ss -tlnp | grep -q 6443" 30 2; then
    ss -tlnp | grep 6443
else
    echo "k3s may still be starting up. Check the logs below."
fi

echo -e "\n3. Checking kubectl connectivity..."
export KUBECONFIG="${KUBECONFIG:-/etc/rancher/k3s/k3s.yaml}"
if wait_for_condition "kubectl node connectivity" "kubectl get nodes" 45 3; then
    kubectl get nodes -o wide
else
    echo "kubectl connectivity failed. Check k3s service status."
fi

echo -e "\n4. Checking k3s cluster info..."
kubectl cluster-info 2>/dev/null || echo "Cluster info not available - k3s may still be initializing"

echo -e "\n5. Checking k3s pods..."
kubectl get pods -A 2>/dev/null || echo "Unable to list pods - k3s may still be starting"

echo -e "\n6. Checking recent k3s logs..."
journalctl -u k3s -n 20 --no-pager

echo -e "\n=== Verification Complete ==="
echo "💡 If any checks failed, k3s may still be starting up."
echo "💡 Wait a few minutes and run this script again if needed."