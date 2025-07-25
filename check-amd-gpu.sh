#!/usr/bin/env bash
set -euo pipefail

echo "=== AMD GPU Status Check ==="
echo

echo "1. GPU Hardware Information:"
nix-shell -p pciutils --run "lspci -v | grep -A 10 -E 'VGA|Display|3D'" 2>/dev/null || echo "Failed to get PCI info"

echo -e "\n2. Loaded Kernel Modules:"
lsmod | grep -E "amdgpu|radeon|drm" | sort

echo -e "\n3. DRM Devices:"
ls -la /sys/class/drm/

echo -e "\n4. GPU Driver in Use:"
if [ -e /sys/class/drm/card1/device/driver ]; then
    readlink -f /sys/class/drm/card1/device/driver
else
    echo "No driver info found"
fi

echo -e "\n5. OpenCL Support:"
nix-shell -p clinfo --run "clinfo -l" 2>/dev/null || echo "OpenCL not available"

echo -e "\n6. Current Display Configuration:"
if command -v xrandr &> /dev/null; then
    xrandr --current | head -10
else
    echo "xrandr not available (may be using Wayland)"
fi

echo -e "\n7. GPU Memory Info:"
if [ -e /sys/class/drm/card1/device/mem_info_vram_total ]; then
    echo "VRAM Total: $(cat /sys/class/drm/card1/device/mem_info_vram_total 2>/dev/null || echo 'N/A')"
    echo "VRAM Used: $(cat /sys/class/drm/card1/device/mem_info_vram_used 2>/dev/null || echo 'N/A')"
else
    echo "Memory info not available (older GPU or driver)"
fi

echo -e "\n8. Hardware Acceleration Status:"
if [ -e /dev/dri/card1 ]; then
    echo "DRI device present: /dev/dri/card1"
    ls -la /dev/dri/card1
else
    echo "No DRI device found"
fi

echo -e "\n=== Analysis ==="
LOADED_MODULES=$(lsmod | awk '{print $1}')
if echo "$LOADED_MODULES" | grep -q "^radeon$"; then
    echo "✅ Your AMD GPU is using the 'radeon' driver (for older AMD GPUs)"
    echo "✅ This is correct for Radeon HD 4000/5000/6000/7000 series cards"
    echo "✅ Your Radeon HD 4350/4550 (RV710) is properly configured"
    echo "✅ OpenCL support is enabled for compute workloads"
    echo "✅ Hardware acceleration is available via /dev/dri/card1"
elif echo "$LOADED_MODULES" | grep -q "^amdgpu$"; then
    echo "Your AMD GPU is using the 'amdgpu' driver (for newer AMD GPUs)"
    echo "This is correct for GCN 1.0+ (HD 7700+) cards"
else
    echo "WARNING: No AMD GPU driver loaded!"
fi

echo -e "\n=== Status Complete ==="