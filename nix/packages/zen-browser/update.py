from typing import Any
import requests
import hashlib
import tempfile
import os


def get_latest_release() -> Any:
    """Fetch the latest release information from GitHub."""
    url = "https://api.github.com/repos/zen-browser/desktop/releases/latest"
    response = requests.get(url)
    response.raise_for_status()
    return response.json()


def download_and_hash(url: str):
    """Download a file and calculate its SHA256 hash using nix-prefetch-url."""
    import subprocess

    try:
        print(f"\nHashing URL: {url}")
        print("-" * 80)  # Separator line for better readability

        cmd = []
        if "dmg" in url:
            cmd = ["nix-prefetch-url", url]
        else:
            cmd = ["nix-prefetch-url", "--type", "sha256", "--unpack", url]

        result = subprocess.run(cmd, capture_output=True, text=True, check=True)

        # Extract hash from stdout
        hash_value = result.stdout.strip()

        # Print detailed report
        print(f"Status: Success")
        print(f"Command: nix-prefetch-url --type sha256 --unpack {url}")
        print(f"Hash value: {hash_value}")
        print(f"Full output:\n{result.stdout}")
        if result.stderr:
            print(f"Stderr output:\n{result.stderr}")
        print("-" * 80)  # Closing separator

        return f"sha256:{hash_value}"
    except subprocess.CalledProcessError as e:
        error_msg = f"Failed to fetch and hash URL: {e.stderr}"
        print(f"Status: Failed")
        print(f"Error message: {error_msg}")
        print("-" * 80)
        raise Exception(error_msg)


def update_version(content: str, version: str):
    """Update version using the version tag."""
    lines = content.split("\n")
    for i, line in enumerate(lines):
        if "#:version:" in line:
            # Update the next line that contains 'version ='
            for j in range(i + 1, len(lines)):
                if "version =" in lines[j]:
                    lines[j] = f'    version = "{version}";'
                    break
    return "\n".join(lines)


def update_hash(content: str, platform: str, hash_value: str):
    """Update hash for a specific platform using the sha256 tag."""
    lines = content.split("\n")
    in_platform_block = False

    for i, line in enumerate(lines):
        if f'"{platform}" = {{' in line:
            in_platform_block = True
        elif in_platform_block and "#:sha256:" in line:
            # Update the next line that contains 'sha256 ='
            for j in range(i + 1, len(lines)):
                if "sha256 =" in lines[j]:
                    lines[j] = f'        sha256 = "{hash_value}";'
                    break
            in_platform_block = False

    return "\n".join(lines)


def main():
    try:
        # Get latest release info
        release = get_latest_release()
        version = release["tag_name"]
        print(f"Latest version: {version}")

        # Platform mapping
        platforms = {
            "x86_64-linux": {"pattern": "linux-x86_64.tar.bz2"},
            "aarch64-linux": {"pattern": "linux-aarch64.tar.bz2"},
            "aarch64-darwin": {"pattern": "macos-aarch64.dmg"},
            "x86_64-darwin": {"pattern": "macos-x86_64.dmg"},
        }

        # Read the current flake.nix
        with open("flake.nix", "r") as f:
            content = f.read()

        # Update version
        content = update_version(content, str(version))

        # Calculate hashes and update each platform
        for platform, info in platforms.items():
            pattern = info["pattern"]
            asset = next((a for a in release["assets"] if pattern in a["name"]), None)

            if not asset:
                print(f"Warning: No matching asset found for {platform}")
                continue

            print(f"Calculating hash for {platform}...")
            hash_value = download_and_hash(asset["browser_download_url"])
            content = update_hash(content, platform, hash_value)

        # Write the updated content
        with open("flake.nix", "w") as f:
            _ = f.write(content)

        print("\nFlake.nix has been updated successfully!")
        print(f"New version: {version}")

    except requests.exceptions.RequestException as e:
        print(f"Error fetching data from GitHub: {e}")
    except Exception as e:
        print(f"An error occurred: {e}")


if __name__ == "__main__":
    main()
