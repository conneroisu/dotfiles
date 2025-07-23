#!/usr/bin/env python3
"""
run_test_simple.py - Basic verification tests for run.py

This is a simple test runner to verify core functionality works.
"""

import unittest
import sys
import os
from unittest.mock import Mock, patch

# Add current directory to path to import run.py
sys.path.insert(
    0, os.path.dirname(os.path.abspath(__file__))
)

from run import (
    DevShellConfig,
    DevShellData,
    DevShellExtractor,
    NixError,
    create_parser,
    RE_VERSION,
    RE_HASH,
    PACKAGE_MAPPINGS,
    SKIP_PACKAGES,
)


class TestBasicFunctionality(unittest.TestCase):
    """Test basic functionality to ensure the module works."""

    def test_config_creation(self):
        """Test DevShellConfig can be created."""
        config = DevShellConfig(flake_path=".")
        self.assertEqual(config.flake_path, ".")
        self.assertEqual(
            config.shell_name, "default"
        )
        self.assertFalse(config.verbose)

    def test_data_creation(self):
        """Test DevShellData can be created and converted to dict."""
        data = DevShellData(
            build_inputs=["pkg1", "pkg2"],
            native_build_inputs=["native1"],
            propagated_build_inputs=[],
            shell_hook="echo hello",
            system="x86_64-linux",
            flake_path=".",
        )

        self.assertEqual(
            len(data.build_inputs), 2
        )
        self.assertEqual(
            data.system, "x86_64-linux"
        )

        # Test to_dict conversion
        data_dict = data.to_dict()
        self.assertIsInstance(data_dict, dict)
        self.assertEqual(
            data_dict["system"], "x86_64-linux"
        )

    def test_nix_error(self):
        """Test NixError exception works."""
        error = NixError("test message")
        self.assertEqual(
            str(error), "test message"
        )
        self.assertIsInstance(error, Exception)

    def test_extractor_creation(self):
        """Test DevShellExtractor can be created."""
        config = DevShellConfig(
            flake_path=".", quiet=True
        )
        extractor = DevShellExtractor(config)
        self.assertIsNotNone(extractor.config)
        self.assertIsNotNone(extractor.logger)

    def test_drv_to_pkgname_basic(self):
        """Test basic derivation to package name conversion."""
        config = DevShellConfig(
            flake_path=".", quiet=True
        )
        extractor = DevShellExtractor(config)

        # Test cases
        test_cases = [
            ("", None),
            (
                "/nix/store/abcdefgh12345678abcdefgh12345678-hello-1.0",
                "hello",
            ),
            (
                "/nix/store/abcdefgh12345678abcdefgh12345678-python3-3.11.0",
                "python3",
            ),
            (
                "/nix/store/abcdefgh12345678abcdefgh12345678-dx",
                None,
            ),  # Should be skipped
            (
                "/nix/store/abcdefgh12345678abcdefgh12345678-rust-default",
                "rustc",
            ),  # Mapping
        ]

        for drv_path, expected in test_cases:
            with self.subTest(drv_path=drv_path):
                result = extractor.drv_to_pkgname(
                    drv_path
                )
                self.assertEqual(result, expected)

    def test_uniq_preserve_order(self):
        """Test unique preservation of order."""
        config = DevShellConfig(
            flake_path=".", quiet=True
        )
        extractor = DevShellExtractor(config)

        # Test with duplicates and None values
        input_seq = [
            "a",
            "b",
            None,
            "a",
            "c",
            None,
            "b",
        ]
        result = extractor.uniq_preserve_order(
            input_seq
        )

        self.assertEqual(result, ["a", "b", "c"])

        # Test with empty list
        self.assertEqual(
            extractor.uniq_preserve_order([]), []
        )

        # Test with all None
        self.assertEqual(
            extractor.uniq_preserve_order(
                [None, None]
            ),
            [],
        )

    def test_regex_patterns(self):
        """Test regex patterns work as expected."""
        # Test version regex
        self.assertIsNotNone(
            RE_VERSION.match("1.0")
        )
        self.assertIsNotNone(
            RE_VERSION.match("123abc")
        )
        self.assertIsNone(
            RE_VERSION.match("abc123")
        )
        self.assertIsNone(RE_VERSION.match(""))

        # Test hash regex - should match exactly 32 lowercase hex chars
        self.assertIsNotNone(
            RE_HASH.fullmatch(
                "abcdef1234567890abcdef1234567890"
            )
        )
        self.assertIsNone(
            RE_HASH.fullmatch(
                "ABCDEF1234567890ABCDEF1234567890"
            )
        )  # Uppercase
        self.assertIsNone(
            RE_HASH.fullmatch("abcdef123")
        )  # Too short
        self.assertIsNone(
            RE_HASH.fullmatch(
                "abcdef1234567890abcdef1234567890x"
            )
        )  # Too long
        self.assertIsNone(
            RE_HASH.fullmatch("")
        )  # Empty

    def test_package_mappings(self):
        """Test package mappings are valid."""
        self.assertIsInstance(
            PACKAGE_MAPPINGS, dict
        )
        self.assertGreater(
            len(PACKAGE_MAPPINGS), 0
        )

        # Test some known mappings
        self.assertIn(
            "rust-default", PACKAGE_MAPPINGS
        )
        self.assertEqual(
            PACKAGE_MAPPINGS["rust-default"],
            "rustc",
        )

    def test_skip_packages(self):
        """Test skip packages set is valid."""
        self.assertIsInstance(SKIP_PACKAGES, set)
        self.assertGreater(len(SKIP_PACKAGES), 0)

        # Test some known skip packages
        self.assertIn("dx", SKIP_PACKAGES)
        self.assertIn("lint", SKIP_PACKAGES)

    def test_argument_parser(self):
        """Test argument parser creation."""
        parser = create_parser()
        self.assertIsNotNone(parser)

        # Test parsing valid arguments
        args = parser.parse_args(["test-flake"])
        self.assertEqual(
            args.flake_path, "test-flake"
        )
        self.assertEqual(
            args.shell_name, "default"
        )
        self.assertFalse(args.verbose)

        # Test with options
        args = parser.parse_args(
            [
                "--verbose",
                "--shell-name",
                "custom",
                "test-flake",
            ]
        )
        self.assertTrue(args.verbose)
        self.assertEqual(
            args.shell_name, "custom"
        )

    def test_format_nix_output(self):
        """Test Nix output formatting."""
        config = DevShellConfig(
            flake_path=".", quiet=True
        )
        extractor = DevShellExtractor(config)

        data = DevShellData(
            build_inputs=["hello", "world"],
            native_build_inputs=["gcc"],
            propagated_build_inputs=[],
            shell_hook="echo 'Welcome'",
            system="x86_64-linux",
            flake_path=".",
        )

        output = extractor.format_nix_output(data)

        self.assertIn("pkgs.mkShell", output)
        self.assertIn("hello world gcc", output)
        self.assertIn("echo 'Welcome'", output)
        self.assertIn("x86_64-linux", output)

    def test_format_json_output(self):
        """Test JSON output formatting."""
        config = DevShellConfig(
            flake_path=".", quiet=True
        )
        extractor = DevShellExtractor(config)

        data = DevShellData(
            build_inputs=["test"],
            native_build_inputs=[],
            propagated_build_inputs=[],
            shell_hook="",
            system="x86_64-linux",
            flake_path=".",
        )

        output = extractor.format_json_output(
            data
        )

        # Should be valid JSON
        import json

        parsed = json.loads(output)
        self.assertEqual(
            parsed["system"], "x86_64-linux"
        )
        self.assertEqual(
            parsed["build_inputs"], ["test"]
        )


class TestFuzzInputs(unittest.TestCase):
    """Test with some fuzz inputs to ensure robustness."""

    def test_config_with_unusual_inputs(self):
        """Test config creation with unusual but valid inputs."""
        unusual_inputs = [
            "",  # Empty string
            " " * 100,  # Many spaces
            "a" * 1000,  # Very long string
            "./test/../test",  # Path with traversal
            "github:user/repo",  # Remote flake
        ]

        for flake_path in unusual_inputs:
            with self.subTest(
                flake_path=flake_path
            ):
                config = DevShellConfig(
                    flake_path=flake_path
                )
                self.assertEqual(
                    config.flake_path, flake_path
                )

    def test_drv_to_pkgname_with_unusual_paths(
        self,
    ):
        """Test derivation path parsing with unusual inputs."""
        config = DevShellConfig(
            flake_path=".", quiet=True
        )
        extractor = DevShellExtractor(config)

        unusual_paths = [
            "",  # Empty
            "not-a-store-path",  # Invalid format
            "/nix/store/invalid",  # Missing hash format
            "/nix/store/abcdefgh12345678abcdefgh12345678-",  # Empty name
            "/nix/store/abcdefgh12345678abcdefgh12345678-package-with-many-dashes-1.0.0",
        ]

        for path in unusual_paths:
            with self.subTest(path=path):
                # Should not crash
                result = extractor.drv_to_pkgname(
                    path
                )
                # Result can be None or string
                self.assertIn(
                    type(result),
                    [type(None), str],
                )

    def test_uniq_preserve_order_stress(self):
        """Stress test unique preservation with many items."""
        config = DevShellConfig(
            flake_path=".", quiet=True
        )
        extractor = DevShellExtractor(config)

        # Create a large list with many duplicates and None values
        large_list = []
        for i in range(1000):
            if i % 10 == 0:
                large_list.append(None)
            else:
                large_list.append(
                    f"item-{i % 50}"
                )  # Create duplicates

        result = extractor.uniq_preserve_order(
            large_list
        )

        # Should have unique items only, no None values
        self.assertEqual(
            len(set(result)), len(result)
        )  # All unique
        self.assertNotIn(
            None, result
        )  # No None values
        self.assertLessEqual(
            len(result), 50
        )  # At most 50 unique items


if __name__ == "__main__":
    print(
        "Running basic verification tests for run.py..."
    )
    unittest.main(verbosity=2)
