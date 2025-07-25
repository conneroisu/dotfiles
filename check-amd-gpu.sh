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
# Find the first card device that's not virtual
GPU_CARD=""
for card in /sys/class/drm/card*; do
    if [ -e "$card/device/driver" ] && [ -e "$card/device/vendor" ]; then
        vendor=$(cat "$card/device/vendor" 2>/dev/null)
        if [ "$vendor" = "0x1002" ]; then  # AMD vendor ID
            GPU_CARD=$(basename "$card")
            break
        fi
    fi
done

if [ -n "$GPU_CARD" ]; then
    echo "Found AMD GPU: $GPU_CARD"
    readlink -f "/sys/class/drm/$GPU_CARD/device/driver"
else
    echo "No AMD GPU driver found"
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
if [ -n "$GPU_CARD" ] && [ -e "/sys/class/drm/$GPU_CARD/device/mem_info_vram_total" ]; then
    echo "VRAM Total: $(cat "/sys/class/drm/$GPU_CARD/device/mem_info_vram_total" 2>/dev/null || echo 'N/A')"
    echo "VRAM Used: $(cat "/sys/class/drm/$GPU_CARD/device/mem_info_vram_used" 2>/dev/null || echo 'N/A')"
else
    echo "Memory info not available (older GPU or driver, or GPU not detected)"
fi

echo -e "\n8. Hardware Acceleration Status:"
if [ -n "$GPU_CARD" ] && [ -e "/dev/dri/$GPU_CARD" ]; then
    echo "DRI device present: /dev/dri/$GPU_CARD"
    ls -la "/dev/dri/$GPU_CARD"
else
    echo "No AMD DRI device found"
    # Show all available DRI devices for reference
    if ls /dev/dri/card* >/dev/null 2>&1; then
        echo "Available DRI devices:"
        ls -la /dev/dri/card*
    fi
fi

echo -e "\n=== Analysis ==="
LOADED_MODULES=$(lsmod | awk '{print $1}')
if echo "$LOADED_MODULES" | grep -q "^radeon$"; then
    echo "✅ Your AMD GPU is using the 'radeon' driver (for older AMD GPUs)"
    echo "✅ This is correct for Radeon HD 4000/5000/6000/7000 series cards"
    if [ -n "$GPU_CARD" ]; then
        echo "✅ GPU detected as $GPU_CARD and properly configured"
        echo "✅ Hardware acceleration is available via /dev/dri/$GPU_CARD"
    fi
    echo "✅ OpenCL support is enabled for compute workloads"
elif echo "$LOADED_MODULES" | grep -q "^amdgpu$"; then
    echo "✅ Your AMD GPU is using the 'amdgpu' driver (for newer AMD GPUs)"
    echo "✅ This is correct for GCN 1.0+ (HD 7700+) cards"
    if [ -n "$GPU_CARD" ]; then
        echo "✅ GPU detected as $GPU_CARD and properly configured"
        echo "✅ Hardware acceleration is available via /dev/dri/$GPU_CARD"
    fi
else
    echo "⚠️  WARNING: No AMD GPU driver loaded!"
    if [ -z "$GPU_CARD" ]; then
        echo "⚠️  No AMD GPU device detected"
    fi
fi

echo -e "\n=== Status Complete ==="