#!/usr/bin/env bash
set -euo pipefail

echo "=== K3s Service Verification ==="
echo

echo "1. Checking k3s service status..."
systemctl status k3s --no-pager

echo -e "\n2. Checking if k3s is listening on port 6443..."
ss -tlnp | grep 6443 || echo "Port 6443 not listening yet"

echo -e "\n3. Checking kubectl connectivity..."
kubectl get nodes || echo "kubectl not ready yet"

echo -e "\n4. Checking k3s cluster info..."
kubectl cluster-info || echo "Cluster info not available yet"

echo -e "\n5. Checking k3s pods..."
kubectl get pods -A || echo "Unable to list pods"

echo -e "\n6. Checking recent k3s logs..."
journalctl -u k3s -n 20 --no-pager

echo -e "\n=== Verification Complete ==="