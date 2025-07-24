#!/usr/bin/env python3
"""
run.py – snapshot any flake's devShell into a standalone mkShell

This script extracts a Nix flake's development shell configuration and generates
a standalone shell.nix file that can be used without the original flake.

Usage:
    ./run.py [OPTIONS] <flake-path-or-url> [system]

Options:
    -h, --help              Show this help message
    -v, --verbose           Enable verbose output
    -q, --quiet            Suppress diagnostic messages
    -o, --output FILE      Write output to file instead of stdout
    --shell-name NAME      Specify devShell name (default: default)
    --format FORMAT        Output format: nix (default), json, yaml
    --no-shell-hook        Exclude shellHook from output
    --separate-inputs      Separate buildInputs, nativeBuildInputs, etc.

Examples:
    ./run.py .                           # Use current directory
    ./run.py github:nixos/nixpkgs        # Use remote flake
    ./run.py . x86_64-linux             # Specify system
    ./run.py --shell-name container .    # Use specific devShell
    ./run.py -o devshell.nix .          # Write to file
    ./run.py --format json .            # Export as JSON
"""
from __future__ import annotations

import argparse
import json
import logging
import re
import subprocess
import sys
import textwrap
from pathlib import Path
from typing import (
    Dict,
    Iterable,
    List,
    Optional,
    Set,
    Union,
    Any,
)
from dataclasses import dataclass, asdict

# Optional YAML support
try:
    import yaml

    YAML_AVAILABLE = True
except ImportError:
    YAML_AVAILABLE = False


# Constants
RE_VERSION = re.compile(r"^\d")  # first component that *starts* with a digit
RE_HASH = re.compile(r"^[0-9a-z]{32}$")  # /nix/store/<hash>-...

# Package name mappings for common patterns
PACKAGE_MAPPINGS = {
    "rust-default": "rustc",
    "rust-analyzer-preview": "rust-analyzer",
    "nodejs-dev": "nodejs",
    "go_1": "go",  # Handle go_1.xx versions
}

# Packages to skip (custom scripts that don't exist in nixpkgs)
SKIP_PACKAGES = {"dx", "lint"}


@dataclass
class DevShellConfig:
    """Configuration for devShell extraction."""

    flake_path: str
    system: Optional[str] = None
    shell_name: str = "default"
    verbose: bool = False
    quiet: bool = False
    output_file: Optional[str] = None
    format: str = "nix"
    include_shell_hook: bool = True
    separate_inputs: bool = False
    impure: bool = False


@dataclass
class DevShellData:
    """Extracted devShell data."""

    build_inputs: List[str]
    native_build_inputs: List[str]
    propagated_build_inputs: List[str]
    shell_hook: str
    system: str
    flake_path: str

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
        return asdict(self)


class NixError(Exception):
    """Exception raised for Nix-related errors."""

    pass


class DevShellExtractor:
    """Extracts devShell configurations from Nix flakes."""

    def __init__(self, config: DevShellConfig):
        self.config = config
        self.logger = self._setup_logging()

    def _setup_logging(self) -> logging.Logger:
        """Set up logging based on configuration."""
        logger = logging.getLogger(__name__)

        if self.config.quiet:
            logger.setLevel(logging.ERROR)
        elif self.config.verbose:
            logger.setLevel(logging.DEBUG)
        else:
            logger.setLevel(logging.INFO)

        # Remove existing handlers
        for handler in logger.handlers[:]:
            logger.removeHandler(handler)

        # Add stderr handler
        handler = logging.StreamHandler(sys.stderr)
        formatter = logging.Formatter("%(levelname)s: %(message)s")
        handler.setFormatter(formatter)
        logger.addHandler(handler)

        return logger

    def nix_eval_json(
        self,
        expr: str,
        *,
        impure: bool = None,
        use_expr: bool = False,
    ) -> str:
        """Run `nix eval --json <expr>` and return the raw JSON string."""
        cmd = ["nix", "eval", "--json"]
        if impure is None:
            impure = self.config.impure
        if impure:
            cmd.append("--impure")
        if use_expr:
            cmd.extend(["--expr", expr])
        else:
            cmd.append(expr)

        try:
            result = subprocess.check_output(
                cmd,
                text=True,
                stderr=subprocess.PIPE,
            )
            return result
        except subprocess.CalledProcessError as e:
            stderr_text = (
                e.stderr
                if isinstance(e.stderr, str)
                else (e.stderr.decode() if e.stderr else str(e))
            )

            # Check for common issues and provide helpful messages
            if "is not available on the requested hostPlatform" in stderr_text:
                platform_error = "Package not available on this platform (Darwin/macOS). This flake may be Linux-only."
                raise NixError(f"Platform incompatibility: {platform_error}")
            elif (
                "No commit found for SHA" in stderr_text and "github.com" in stderr_text
            ):
                raise NixError(
                    f"Invalid remote flake reference - may be treating local path as remote URL: {stderr_text}"
                )
            elif "is not tracked by Git" in stderr_text:
                raise NixError(
                    f"Git tracking issue: Files need to be added to git. Use 'git add' to track the flake files."
                )
            else:
                raise NixError(f"Nix evaluation failed: {stderr_text}")

    def get_current_system(self) -> str:
        """Get the current system string."""
        try:
            return subprocess.check_output(
                [
                    "nix",
                    "eval",
                    "--raw",
                    "--impure",
                    "--expr",
                    "builtins.currentSystem",
                ],
                text=True,
            ).strip()
        except subprocess.CalledProcessError as e:
            raise NixError(f"Failed to detect current system: {e}")

    def drv_to_pkgname(self, drv_path: str) -> Optional[str]:
        """
        Convert a derivation path to a plain package name.

        Returns None for packages that should be skipped.
        """
        if not drv_path:
            return None

        # /nix/store/<hash>-<n>.drv  →  <n>
        stem = Path(drv_path).stem
        parts: List[str] = stem.split("-")

        # Drop the leading store hash if present.
        if parts and RE_HASH.fullmatch(parts[0]):
            parts = parts[1:]

        if not parts:
            return None

        # Special handling for known package patterns
        name_str = "-".join(parts)

        # Check direct mappings first
        for (
            pattern,
            replacement,
        ) in PACKAGE_MAPPINGS.items():
            if name_str.startswith(pattern):
                return replacement

        # Check skip list
        if any(name_str.startswith(skip) for skip in SKIP_PACKAGES):
            return None

        # Walk until the first component that *starts* with a digit => version boundary.
        name_parts: List[str] = []
        for p in parts:
            if RE_VERSION.match(p):
                break
            name_parts.append(p)

        result = "-".join(name_parts) if name_parts else stem

        # Skip if result is in skip list
        if result in SKIP_PACKAGES:
            return None

        return result

    def uniq_preserve_order(self, seq: Iterable[Optional[str]]) -> List[str]:
        """Remove duplicates while preserving order, filtering out None values."""
        seen: Set[str] = set()
        out: List[str] = []
        for item in seq:
            if item is not None and item not in seen:
                seen.add(item)
                out.append(item)
        return out

    def discover_devshells(self, flake: str) -> Dict[str, List[str]]:
        """Discover available devShells in a flake."""
        try:
            devshells_json = self.nix_eval_json(f"{flake}#devShells or {{}}")
            devshells = json.loads(devshells_json)

            result = {}
            if devshells:
                for (
                    system,
                    shells,
                ) in devshells.items():
                    if isinstance(shells, dict):
                        result[system] = list(shells.keys())
                    else:
                        result[system] = []

            return result
        except NixError:
            return {}

    def find_devshell_attr(
        self,
        flake: str,
        system: str,
        shell_name: str,
    ) -> str:
        """Find the correct devShell attribute path."""
        # Try modern flake structure first
        attr_base = f'devShells."{system}".{shell_name}'
        try:
            self.logger.debug(f"Trying: {flake}#{attr_base}")
            self.nix_eval_json(f"{flake}#{attr_base}")
            return attr_base
        except NixError as e:
            self.logger.debug(f"Modern devShell not found: {e}")

        # Try legacy format if looking for default
        if shell_name == "default":
            attr_base = "devShell"
            try:
                self.logger.debug(f"Trying legacy: {flake}#{attr_base}")
                self.nix_eval_json(f"{flake}#{attr_base}")
                return attr_base
            except NixError as e:
                self.logger.debug(f"Legacy devShell not found: {e}")

        # If we get here, no devShell was found
        available = self.discover_devshells(flake)
        if available:
            self.logger.error("Available devShells:")
            for sys, shells in available.items():
                self.logger.error(f"  {sys}: {', '.join(shells)}")

        raise NixError(
            f"No devShell '{shell_name}' found for system '{system}' in {flake}"
        )

    def extract_devshell_data(
        self,
        flake: str,
        system: str,
        shell_name: str,
    ) -> DevShellData:
        """Extract all devShell data from a flake."""
        attr_base = self.find_devshell_attr(flake, system, shell_name)

        # Extract attributes separately
        attrs = {}

        # Build inputs (required)
        try:
            self.logger.debug("Extracting buildInputs...")
            build_inputs_json = self.nix_eval_json(f"{flake}#{attr_base}.buildInputs")
            attrs["buildInputs"] = json.loads(build_inputs_json)
        except NixError:
            attrs["buildInputs"] = []

        # Native build inputs (optional)
        try:
            self.logger.debug("Extracting nativeBuildInputs...")
            native_inputs_json = self.nix_eval_json(
                f"{flake}#{attr_base}.nativeBuildInputs"
            )
            attrs["nativeBuildInputs"] = json.loads(native_inputs_json)
        except NixError:
            attrs["nativeBuildInputs"] = []

        # Propagated build inputs (optional)
        try:
            self.logger.debug("Extracting propagatedBuildInputs...")
            prop_inputs_json = self.nix_eval_json(
                f"{flake}#{attr_base}.propagatedBuildInputs"
            )
            attrs["propagatedBuildInputs"] = json.loads(prop_inputs_json)
        except NixError:
            attrs["propagatedBuildInputs"] = []

        # Shell hook (optional)
        shell_hook = ""
        if self.config.include_shell_hook:
            try:
                self.logger.debug("Extracting shellHook...")
                shell_hook_json = self.nix_eval_json(f"{flake}#{attr_base}.shellHook")
                shell_hook = json.loads(shell_hook_json)
            except NixError:
                shell_hook = ""

        # Convert derivation paths to package names
        all_build_inputs = [self.drv_to_pkgname(d) for d in attrs["buildInputs"]]
        all_native_inputs = [self.drv_to_pkgname(d) for d in attrs["nativeBuildInputs"]]
        all_prop_inputs = [
            self.drv_to_pkgname(d) for d in attrs["propagatedBuildInputs"]
        ]

        return DevShellData(
            build_inputs=self.uniq_preserve_order(all_build_inputs),
            native_build_inputs=self.uniq_preserve_order(all_native_inputs),
            propagated_build_inputs=self.uniq_preserve_order(all_prop_inputs),
            shell_hook=shell_hook,
            system=system,
            flake_path=flake,
        )

    def format_nix_output(self, data: DevShellData) -> str:
        """Format devShell data as Nix code."""
        if self.config.separate_inputs:
            # Generate separate input lists
            build_inputs_str = self._format_package_list(
                data.build_inputs,
                "buildInputs",
            )
            native_inputs_str = self._format_package_list(
                data.native_build_inputs,
                "nativeBuildInputs",
            )
            prop_inputs_str = self._format_package_list(
                data.propagated_build_inputs,
                "propagatedBuildInputs",
            )

            inputs_section = f"""
          {build_inputs_str}
          {native_inputs_str}
          {prop_inputs_str}"""
        else:
            # Combine all inputs
            all_inputs = (
                data.build_inputs
                + data.native_build_inputs
                + data.propagated_build_inputs
            )
            all_inputs = self.uniq_preserve_order(all_inputs)
            inputs_section = f"""
          buildInputs = with pkgs; [
            {textwrap.fill(" ".join(all_inputs), width=80, initial_indent="", subsequent_indent="    ")}
          ];"""

        shell_hook_section = ""
        if data.shell_hook:
            shell_hook_section = f"""
          shellHook = ''{data.shell_hook}'';"""
        elif not self.config.include_shell_hook:
            shell_hook_section = """
          # shellHook excluded by user request"""
        else:
            shell_hook_section = """
          # No shellHook defined"""

        return textwrap.dedent(
            f"""
        {{ pkgs ? import <nixpkgs> {{ system = "{data.system}"; }} }}:

        pkgs.mkShell {{{inputs_section}{shell_hook_section}
        }}
        """
        ).lstrip()

    def _format_package_list(self, packages: List[str], attr_name: str) -> str:
        """Format a list of packages for Nix output."""
        if not packages:
            return f"{attr_name} = [ ];"

        if len(packages) == 1:
            return f"{attr_name} = with pkgs; [ {packages[0]} ];"

        return f"""{attr_name} = with pkgs; [
            {textwrap.fill(" ".join(packages), width=80, initial_indent="", subsequent_indent="    ")}
          ];"""

    def format_json_output(self, data: DevShellData) -> str:
        """Format devShell data as JSON."""
        return json.dumps(data.to_dict(), indent=2)

    def format_yaml_output(self, data: DevShellData) -> str:
        """Format devShell data as YAML."""
        if not YAML_AVAILABLE:
            raise NixError(
                "YAML support not available. Install PyYAML: pip install PyYAML"
            )
        return yaml.dump(
            data.to_dict(),
            default_flow_style=False,
        )

    def extract_and_format(self) -> str:
        """Main extraction and formatting logic."""
        # Determine system
        system = self.config.system or self.get_current_system()

        # Normalize flake path to handle relative paths correctly
        flake_path = self.config.flake_path
        if not flake_path.startswith(
            (
                "./",
                "/",
                "git+",
                "github:",
                "gitlab:",
                "sourcehut:",
                "file:",
            )
        ):
            # If it's a bare relative path like 'templates/go-shell', prefix with './'
            flake_path = f"./{flake_path}"

        self.logger.info(f"Analyzing flake: {flake_path}")
        self.logger.info(f"Target system: {system}")
        self.logger.info(f"DevShell name: {self.config.shell_name}")

        # Extract data
        data = self.extract_devshell_data(
            flake_path,
            system,
            self.config.shell_name,
        )

        total_packages = (
            len(data.build_inputs)
            + len(data.native_build_inputs)
            + len(data.propagated_build_inputs)
        )
        self.logger.info(f"Successfully extracted {total_packages} packages")

        # Format output
        if self.config.format == "json":
            return self.format_json_output(data)
        elif self.config.format == "yaml":
            return self.format_yaml_output(data)
        else:  # nix format
            return self.format_nix_output(data)


def create_parser() -> argparse.ArgumentParser:
    """Create command line argument parser."""
    parser = argparse.ArgumentParser(
        description="Extract Nix flake devShell into standalone configuration",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    %(prog)s .                           # Use current directory
    %(prog)s github:nixos/nixpkgs        # Use remote flake  
    %(prog)s . x86_64-linux             # Specify system
    %(prog)s --shell-name container .    # Use specific devShell
    %(prog)s -o devshell.nix .          # Write to file
    %(prog)s --format json .            # Export as JSON
        """,
    )

    parser.add_argument(
        "flake_path",
        help="Path or URL to the flake",
    )
    parser.add_argument(
        "system",
        nargs="?",
        help="Target system (auto-detected if not specified)",
    )

    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Enable verbose output",
    )
    parser.add_argument(
        "-q",
        "--quiet",
        action="store_true",
        help="Suppress diagnostic messages",
    )
    parser.add_argument(
        "-o",
        "--output",
        metavar="FILE",
        help="Write output to file instead of stdout",
    )

    parser.add_argument(
        "--shell-name",
        default="default",
        help="Specify devShell name (default: default)",
    )
    format_choices = ["nix", "json"]
    if YAML_AVAILABLE:
        format_choices.append("yaml")
    parser.add_argument(
        "--format",
        choices=format_choices,
        default="nix",
        help="Output format (default: nix)",
    )
    parser.add_argument(
        "--no-shell-hook",
        action="store_true",
        help="Exclude shellHook from output",
    )
    parser.add_argument(
        "--separate-inputs",
        action="store_true",
        help="Separate buildInputs, nativeBuildInputs, etc.",
    )
    parser.add_argument(
        "--impure",
        action="store_true",
        help="Use --impure for Nix evaluation (helps with Git-aware flakes)",
    )

    return parser


def main() -> int:
    """Main entry point."""
    parser = create_parser()
    args = parser.parse_args()

    # Create configuration
    config = DevShellConfig(
        flake_path=args.flake_path,
        system=args.system,
        shell_name=args.shell_name,
        verbose=args.verbose,
        quiet=args.quiet,
        output_file=args.output,
        format=args.format,
        include_shell_hook=not args.no_shell_hook,
        separate_inputs=args.separate_inputs,
        impure=args.impure,
    )

    try:
        # Extract and format
        extractor = DevShellExtractor(config)
        output = extractor.extract_and_format()

        # Write output
        if config.output_file:
            with open(config.output_file, "w") as f:
                f.write(output)
            if not config.quiet:
                print(
                    f"Output written to {config.output_file}",
                    file=sys.stderr,
                )
        else:
            print(output)

        return 0

    except NixError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print("Interrupted", file=sys.stderr)
        return 130
    except Exception as e:
        print(
            f"Unexpected error: {e}",
            file=sys.stderr,
        )
        if config.verbose:
            import traceback

            traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
