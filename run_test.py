#!/usr/bin/env python3
"""
run_test.py - Comprehensive fuzz testing for run.py

This module provides extensive fuzz testing coverage for the run.py script,
testing edge cases, invalid inputs, and error conditions to ensure robustness.
"""

import unittest
from unittest.mock import Mock, patch, MagicMock
import subprocess
import json
import sys
import tempfile
import os
from pathlib import Path
import string
import random
from typing import List, Dict, Any, Generator
import logging

# Import the modules under test
from run import (
    DevShellConfig,
    DevShellData,
    DevShellExtractor,
    NixError,
    create_parser,
    main,
    PACKAGE_MAPPINGS,
    SKIP_PACKAGES,
    RE_VERSION,
    RE_HASH,
)


class FuzzTestGenerator:
    """Generates various types of fuzz test data."""

    @staticmethod
    def random_string(
        length: int = None, charset: str = None
    ) -> str:
        """Generate random string with optional length and character set."""
        if length is None:
            length = random.randint(0, 100)
        if charset is None:
            charset = (
                string.ascii_letters
                + string.digits
                + string.punctuation
            )
        return "".join(
            random.choice(charset)
            for _ in range(length)
        )

    @staticmethod
    def malformed_paths() -> (
        Generator[str, None, None]
    ):
        """Generate malformed file paths."""
        paths = [
            "",  # Empty
            " ",  # Whitespace only
            "\n",  # Newline only
            "\t",  # Tab only
            "//",  # Double slash
            "\\",  # Backslash
            ":",  # Colon only
            "*",  # Wildcard
            "?",  # Question mark
            "|",  # Pipe
            "<",  # Less than
            ">",  # Greater than
            '"',  # Quote
            "'",  # Single quote
            "/dev/null/../../../etc/passwd",  # Path traversal
            "file:///etc/passwd",  # Absolute file URI
            "../../../../../../etc/passwd",  # Relative path traversal
            "\x00",  # Null byte
            "a" * 1000,  # Very long path
            "con",  # Windows reserved name
            "aux",  # Windows reserved name
            "..",  # Parent directory
            ".",  # Current directory
            "~",  # Home directory
            "$HOME",  # Environment variable
            "${PWD}",  # Environment variable with braces
            "`ls`",  # Command injection attempt
            "$(ls)",  # Command substitution
            ";ls;",  # Command separator
            "&&ls",  # Command chaining
            "||ls",  # Command chaining
            "|ls",  # Pipe
            "&ls",  # Background command
        ]
        for path in paths:
            yield path

    @staticmethod
    def malformed_json() -> (
        Generator[str, None, None]
    ):
        """Generate malformed JSON strings."""
        jsons = [
            "",  # Empty
            "{",  # Unclosed brace
            "}",  # Unmatched brace
            "[",  # Unclosed bracket
            "]",  # Unmatched bracket
            '{"key":}',  # Missing value
            '{"key"}',  # Missing colon and value
            '{key: "value"}',  # Unquoted key
            "{'key': 'value'}",  # Single quotes
            '{"key": "value",}',  # Trailing comma
            '{"key": undefined}',  # Undefined value
            '{"key": NaN}',  # NaN value
            '{"key": Infinity}',  # Infinity value
            '{"\\u0000": "null byte"}',  # Null byte in key
            '{"": "empty key"}',  # Empty key
            json.dumps(
                {"key": "a" * 10000}
            ),  # Very long value
            "\x00",  # Null byte
            "null",  # Valid JSON but unexpected
            "true",  # Valid JSON but unexpected
            "false",  # Valid JSON but unexpected
            "123",  # Valid JSON but unexpected
        ]
        for j in jsons:
            yield j

    @staticmethod
    def system_strings() -> (
        Generator[str, None, None]
    ):
        """Generate various system strings."""
        systems = [
            "",  # Empty
            "invalid-system",  # Invalid format
            "x86_64",  # Missing OS
            "linux",  # Missing architecture
            "windows-x86_64",  # Unsupported OS
            "x86_64-windows",  # Wrong order
            "aarch64-unknown-linux-gnu",  # Too specific
            "wasm32-wasi",  # Unusual target
            "\x00",  # Null byte
            "a" * 100,  # Very long
            "x86_64-linux-"
            + "a" * 50,  # Long suffix
            "i686-linux",  # 32-bit
            "armv7l-linux",  # ARM
            "powerpc64le-linux",  # PowerPC
            "riscv64-linux",  # RISC-V
        ]
        for system in systems:
            yield system

    @staticmethod
    def shell_names() -> (
        Generator[str, None, None]
    ):
        """Generate various shell names."""
        names = [
            "",  # Empty
            " ",  # Whitespace
            "\n",  # Newline
            "\t",  # Tab
            ".",  # Dot
            "..",  # Double dot
            "/",  # Slash
            "\\",  # Backslash
            "shell with spaces",  # Spaces
            "shell-with-dashes",  # Dashes
            "shell_with_underscores",  # Underscores
            "SHELL",  # Uppercase
            "123",  # Numbers only
            "shell123",  # Mixed
            "shell.name",  # Dot in name
            "shell@name",  # At symbol
            "shell#name",  # Hash symbol
            "shell$name",  # Dollar symbol
            "shell%name",  # Percent symbol
            "shell&name",  # Ampersand
            "shell*name",  # Asterisk
            "shell|name",  # Pipe
            "shell<>name",  # Angle brackets
            "\x00",  # Null byte
            "a" * 100,  # Very long
        ]
        for name in names:
            yield name

    @staticmethod
    def derivation_paths() -> (
        Generator[str, None, None]
    ):
        """Generate various derivation paths."""
        paths = [
            "",  # Empty
            "/nix/store/",  # No hash or name
            "/nix/store/invalid",  # Invalid format
            "/nix/store/abcd1234-package",  # Short hash
            "/nix/store/abcdefgh12345678abcdefgh12345678-",  # No package name
            "/nix/store/aBcDeFgH12345678aBcDeFgH12345678-package",  # Mixed case hash
            "/nix/store/abcdefgh12345678abcdefgh12345678-package-1.0",  # With version
            "/nix/store/abcdefgh12345678abcdefgh12345678-package.drv",  # Derivation
            "/usr/bin/package",  # Not in nix store
            "package",  # No path
            "/nix/store/abcdefgh12345678abcdefgh12345678-"
            + "a" * 200,  # Very long name
            "/nix/store/abcdefgh12345678abcdefgh12345678-páckage",  # Unicode
            "/nix/store/abcdefgh12345678abcdefgh12345678-pack age",  # Space in name
            "/nix/store/abcdefgh12345678abcdefgh12345678-pack\x00age",  # Null byte
        ]
        for path in paths:
            yield path


class TestDevShellConfig(unittest.TestCase):
    """Test DevShellConfig dataclass with fuzz inputs."""

    def test_config_creation_with_fuzz_inputs(
        self,
    ):
        """Test DevShellConfig creation with various fuzz inputs."""
        for (
            flake_path
        ) in FuzzTestGenerator.malformed_paths():
            with self.subTest(
                flake_path=repr(flake_path)
            ):
                # Should not raise exception during creation
                config = DevShellConfig(
                    flake_path=flake_path
                )
                self.assertEqual(
                    config.flake_path, flake_path
                )

    def test_config_with_extreme_values(self):
        """Test config with extreme parameter values."""
        # Very long strings
        long_string = "a" * 10000
        config = DevShellConfig(
            flake_path=long_string,
            system=long_string,
            shell_name=long_string,
            output_file=long_string,
            format=long_string,  # Will be validated later
        )
        self.assertEqual(
            len(config.flake_path), 10000
        )

    def test_config_with_special_characters(self):
        """Test config with special characters."""
        special_chars = "\x00\x01\x02\xff\u0000\u00ff\u2603\U0001f600"
        config = DevShellConfig(
            flake_path=special_chars
        )
        self.assertEqual(
            config.flake_path, special_chars
        )


class TestDevShellData(unittest.TestCase):
    """Test DevShellData dataclass with fuzz inputs."""

    def test_data_creation_with_fuzz_lists(self):
        """Test DevShellData creation with fuzzed list inputs."""
        # Generate various list combinations
        for _ in range(100):
            build_inputs = [
                FuzzTestGenerator.random_string()
                for _ in range(
                    random.randint(0, 20)
                )
            ]
            native_inputs = [
                FuzzTestGenerator.random_string()
                for _ in range(
                    random.randint(0, 20)
                )
            ]
            prop_inputs = [
                FuzzTestGenerator.random_string()
                for _ in range(
                    random.randint(0, 20)
                )
            ]

            data = DevShellData(
                build_inputs=build_inputs,
                native_build_inputs=native_inputs,
                propagated_build_inputs=prop_inputs,
                shell_hook=FuzzTestGenerator.random_string(),
                system=FuzzTestGenerator.random_string(),
                flake_path=FuzzTestGenerator.random_string(),
            )

            # Test to_dict conversion
            dict_result = data.to_dict()
            self.assertIsInstance(
                dict_result, dict
            )
            self.assertEqual(
                dict_result["build_inputs"],
                build_inputs,
            )

    def test_data_with_empty_lists(self):
        """Test DevShellData with empty lists."""
        data = DevShellData(
            build_inputs=[],
            native_build_inputs=[],
            propagated_build_inputs=[],
            shell_hook="",
            system="",
            flake_path="",
        )
        dict_result = data.to_dict()
        self.assertEqual(
            len(dict_result["build_inputs"]), 0
        )


class TestNixError(unittest.TestCase):
    """Test NixError exception with fuzz inputs."""

    def test_nix_error_with_fuzz_messages(self):
        """Test NixError with various message formats."""
        for _ in range(50):
            message = (
                FuzzTestGenerator.random_string()
            )
            with self.subTest(
                message=repr(message)
            ):
                error = NixError(message)
                self.assertEqual(
                    str(error), message
                )
                self.assertIsInstance(
                    error, Exception
                )


class TestDevShellExtractor(unittest.TestCase):
    """Test DevShellExtractor with comprehensive fuzz testing."""

    def setUp(self):
        """Set up test fixtures."""
        self.config = DevShellConfig(
            flake_path=".",
            verbose=False,
            quiet=True,
        )
        self.extractor = DevShellExtractor(
            self.config
        )

    def test_nix_eval_json_with_malformed_expressions(
        self,
    ):
        """Test nix_eval_json with malformed Nix expressions."""
        malformed_exprs = [
            "",  # Empty
            "{",  # Unclosed brace
            "invalid.attr",  # Invalid attribute
            "{ = }",  # Invalid syntax
            'builtins.throw "error"',  # Throws error
            "rec { x = x; }",  # Infinite recursion attempt
            "import /etc/passwd",  # File that doesn't exist/invalid
            "a" * 1000,  # Very long expression
            "\x00",  # Null byte
            '{ "\\u0000" = true; }',  # Null in JSON
        ]

        for expr in malformed_exprs:
            with self.subTest(expr=repr(expr)):
                with self.assertRaises(NixError):
                    self.extractor.nix_eval_json(
                        expr
                    )

    @patch("subprocess.check_output")
    def test_nix_eval_json_with_mocked_failures(
        self, mock_check_output
    ):
        """Test nix_eval_json with various subprocess failures."""
        error_messages = [
            "is not available on the requested hostPlatform",
            "No commit found for SHA",
            "is not tracked by Git",
            "permission denied",
            "command not found",
            "killed",
            "",  # Empty error
        ]

        for error_msg in error_messages:
            with self.subTest(
                error_msg=error_msg
            ):
                mock_check_output.side_effect = (
                    subprocess.CalledProcessError(
                        1, "nix", stderr=error_msg
                    )
                )
                with self.assertRaises(NixError):
                    self.extractor.nix_eval_json(
                        "test"
                    )

    def test_drv_to_pkgname_with_fuzz_paths(self):
        """Test drv_to_pkgname with fuzzed derivation paths."""
        for (
            drv_path
        ) in FuzzTestGenerator.derivation_paths():
            with self.subTest(
                drv_path=repr(drv_path)
            ):
                # Should not raise exception
                result = (
                    self.extractor.drv_to_pkgname(
                        drv_path
                    )
                )
                if result is not None:
                    self.assertIsInstance(
                        result, str
                    )

    def test_drv_to_pkgname_edge_cases(self):
        """Test drv_to_pkgname with specific edge cases."""
        test_cases = [
            ("", None),  # Empty input
            (
                "/nix/store/abcdefgh12345678abcdefgh12345678-dx",
                None,
            ),  # Should be skipped
            (
                "/nix/store/abcdefgh12345678abcdefgh12345678-lint",
                None,
            ),  # Should be skipped
            (
                "/nix/store/abcdefgh12345678abcdefgh12345678-rust-default-1.0",
                "rustc",
            ),  # Mapping
            (
                "/nix/store/abcdefgh12345678abcdefgh12345678-go_1.20",
                "go",
            ),  # Mapping
        ]

        for drv_path, expected in test_cases:
            with self.subTest(
                drv_path=drv_path,
                expected=expected,
            ):
                result = (
                    self.extractor.drv_to_pkgname(
                        drv_path
                    )
                )
                self.assertEqual(result, expected)

    def test_drv_to_pkgname_none_input(self):
        """Test drv_to_pkgname with None input."""
        # The function should handle None gracefully
        try:
            result = (
                self.extractor.drv_to_pkgname(
                    None
                )
            )
            self.assertIsNone(result)
        except (AttributeError, TypeError):
            # These exceptions are acceptable for None input
            pass

    def test_uniq_preserve_order_with_fuzz_inputs(
        self,
    ):
        """Test uniq_preserve_order with various input sequences."""
        test_sequences = [
            [],  # Empty
            [None],  # Single None
            [None, None, None],  # Multiple Nones
            ["a", None, "b", None, "c"],  # Mixed
            ["a", "a", "a"],  # Duplicates
            [
                str(i) for i in range(1000)
            ],  # Large sequence
            [
                "",
                " ",
                "\t",
                "\n",
            ],  # Whitespace variations
            [
                "\x00",
                "\x01",
                "\x02",
            ],  # Control characters
        ]

        for seq in test_sequences:
            with self.subTest(seq=repr(seq)):
                result = self.extractor.uniq_preserve_order(
                    seq
                )
                self.assertIsInstance(
                    result, list
                )
                # Check that all items are strings (Nones filtered out)
                for item in result:
                    self.assertIsInstance(
                        item, str
                    )

    @patch("subprocess.check_output")
    def test_get_current_system_failure(
        self, mock_check_output
    ):
        """Test get_current_system with subprocess failure."""
        mock_check_output.side_effect = (
            subprocess.CalledProcessError(
                1, "nix"
            )
        )
        with self.assertRaises(NixError):
            self.extractor.get_current_system()

    @patch.object(
        DevShellExtractor, "nix_eval_json"
    )
    def test_discover_devshells_with_malformed_json(
        self, mock_nix_eval
    ):
        """Test discover_devshells with malformed JSON responses."""
        for (
            malformed_json
        ) in FuzzTestGenerator.malformed_json():
            with self.subTest(
                json_str=repr(malformed_json)
            ):
                mock_nix_eval.return_value = (
                    malformed_json
                )
                # Should handle JSON decode errors gracefully
                try:
                    result = self.extractor.discover_devshells(
                        "test"
                    )
                    self.assertIsInstance(
                        result, dict
                    )
                except json.JSONDecodeError:
                    # This is acceptable behavior
                    pass

    @patch.object(
        DevShellExtractor, "nix_eval_json"
    )
    def test_find_devshell_attr_with_fuzz_inputs(
        self, mock_nix_eval
    ):
        """Test find_devshell_attr with various inputs."""
        # Mock nix_eval_json to always fail (no devShell found)
        mock_nix_eval.side_effect = NixError(
            "not found"
        )

        for (
            flake
        ) in FuzzTestGenerator.malformed_paths():
            for (
                system
            ) in (
                FuzzTestGenerator.system_strings()
            ):
                for (
                    shell_name
                ) in (
                    FuzzTestGenerator.shell_names()
                ):
                    with self.subTest(
                        flake=repr(flake),
                        system=repr(system),
                        shell_name=repr(
                            shell_name
                        ),
                    ):
                        with self.assertRaises(
                            NixError
                        ):
                            self.extractor.find_devshell_attr(
                                flake,
                                system,
                                shell_name,
                            )

    def test_format_nix_output_with_fuzz_data(
        self,
    ):
        """Test format_nix_output with fuzzed DevShellData."""
        for _ in range(50):
            # Generate random DevShellData
            data = DevShellData(
                build_inputs=[
                    FuzzTestGenerator.random_string(
                        20
                    )
                    for _ in range(
                        random.randint(0, 10)
                    )
                ],
                native_build_inputs=[
                    FuzzTestGenerator.random_string(
                        20
                    )
                    for _ in range(
                        random.randint(0, 10)
                    )
                ],
                propagated_build_inputs=[
                    FuzzTestGenerator.random_string(
                        20
                    )
                    for _ in range(
                        random.randint(0, 10)
                    )
                ],
                shell_hook=FuzzTestGenerator.random_string(
                    100
                ),
                system=FuzzTestGenerator.random_string(
                    20
                ),
                flake_path=FuzzTestGenerator.random_string(
                    50
                ),
            )

            with self.subTest(iteration=_):
                # Should not raise exception
                result = self.extractor.format_nix_output(
                    data
                )
                self.assertIsInstance(result, str)
                self.assertIn(
                    "pkgs.mkShell", result
                )

    def test_format_json_output_with_fuzz_data(
        self,
    ):
        """Test format_json_output with fuzzed data."""
        for _ in range(20):
            data = DevShellData(
                build_inputs=[
                    FuzzTestGenerator.random_string()
                    for _ in range(
                        random.randint(0, 5)
                    )
                ],
                native_build_inputs=[],
                propagated_build_inputs=[],
                shell_hook=FuzzTestGenerator.random_string(),
                system=FuzzTestGenerator.random_string(),
                flake_path=FuzzTestGenerator.random_string(),
            )

            with self.subTest(iteration=_):
                result = self.extractor.format_json_output(
                    data
                )
                # Should be valid JSON
                parsed = json.loads(result)
                self.assertIsInstance(
                    parsed, dict
                )

    def test_format_yaml_output_availability(
        self,
    ):
        """Test YAML output format availability."""
        data = DevShellData(
            build_inputs=["test"],
            native_build_inputs=[],
            propagated_build_inputs=[],
            shell_hook="",
            system="x86_64-linux",
            flake_path=".",
        )

        try:
            result = (
                self.extractor.format_yaml_output(
                    data
                )
            )
            self.assertIsInstance(result, str)
        except NixError as e:
            # YAML not available is acceptable
            self.assertIn(
                "YAML support not available",
                str(e),
            )


class TestArgumentParsing(unittest.TestCase):
    """Test command line argument parsing with fuzz inputs."""

    def setUp(self):
        """Set up test fixtures."""
        self.parser = create_parser()

    def test_parser_with_malformed_arguments(
        self,
    ):
        """Test parser with various malformed argument combinations."""
        malformed_args = [
            [],  # No arguments
            ["--invalid-flag"],  # Invalid flag
            [
                "--format",
                "invalid",
            ],  # Invalid format
            ["--output"],  # Missing output file
            [
                "--shell-name"
            ],  # Missing shell name
            [
                "flake",
                "system",
                "extra",
            ],  # Too many positional args
        ]

        for args in malformed_args:
            with self.subTest(args=args):
                with self.assertRaises(
                    SystemExit
                ):
                    self.parser.parse_args(args)

    def test_parser_with_edge_case_arguments(
        self,
    ):
        """Test parser with edge case arguments that should be accepted."""
        edge_case_args = [
            [
                ""
            ],  # Empty string argument (valid flake path)
            [
                " "
            ],  # Whitespace argument (valid flake path)
            [
                "\x00"
            ],  # Null byte (valid flake path)
            [
                "a" * 1000
            ],  # Very long argument (valid flake path)
            [
                "-q",
                "-v",
                ".",
            ],  # Conflicting flags with valid flake
        ]

        for args in edge_case_args:
            with self.subTest(args=args):
                try:
                    result = (
                        self.parser.parse_args(
                            args
                        )
                    )
                    # If parsing succeeds, verify basic structure
                    self.assertTrue(
                        hasattr(
                            result, "flake_path"
                        )
                    )
                except SystemExit:
                    # Some combinations may still be invalid, which is acceptable
                    pass

    def test_parser_with_valid_fuzz_inputs(self):
        """Test parser with valid but unusual inputs."""
        # Generate valid argument combinations
        for _ in range(100):
            flake_path = (
                FuzzTestGenerator.random_string(
                    50,
                    string.ascii_letters + "./",
                )
            )
            args = [flake_path]

            # Randomly add optional arguments
            if random.choice([True, False]):
                args.extend(["--verbose"])
            if random.choice([True, False]):
                args.extend(
                    [
                        "--shell-name",
                        FuzzTestGenerator.random_string(
                            20,
                            string.ascii_letters,
                        ),
                    ]
                )
            if random.choice([True, False]):
                args.extend(
                    [
                        "--format",
                        random.choice(
                            ["nix", "json"]
                        ),
                    ]
                )

            with self.subTest(args=args):
                try:
                    parsed = (
                        self.parser.parse_args(
                            args
                        )
                    )
                    self.assertEqual(
                        parsed.flake_path,
                        flake_path,
                    )
                except SystemExit:
                    # Some combinations may be invalid, which is fine
                    pass


class TestMainFunction(unittest.TestCase):
    """Test main function with comprehensive scenarios."""

    @patch("sys.argv")
    @patch.object(
        DevShellExtractor, "extract_and_format"
    )
    def test_main_with_successful_extraction(
        self, mock_extract, mock_argv
    ):
        """Test main function with successful extraction."""
        mock_argv.__getitem__ = (
            lambda self, key: ["run.py", "."][key]
        )
        mock_argv.__len__ = lambda self: 2
        mock_extract.return_value = "test output"

        with patch("sys.stdout.write"):
            result = main()
            self.assertEqual(result, 0)

    @patch("sys.argv")
    @patch.object(
        DevShellExtractor, "extract_and_format"
    )
    def test_main_with_nix_error(
        self, mock_extract, mock_argv
    ):
        """Test main function with NixError."""
        mock_argv.__getitem__ = (
            lambda self, key: ["run.py", "."][key]
        )
        mock_argv.__len__ = lambda self: 2
        mock_extract.side_effect = NixError(
            "test error"
        )

        result = main()
        self.assertEqual(result, 1)

    @patch("sys.argv")
    @patch.object(
        DevShellExtractor, "extract_and_format"
    )
    def test_main_with_keyboard_interrupt(
        self, mock_extract, mock_argv
    ):
        """Test main function with KeyboardInterrupt."""
        mock_argv.__getitem__ = (
            lambda self, key: ["run.py", "."][key]
        )
        mock_argv.__len__ = lambda self: 2
        mock_extract.side_effect = (
            KeyboardInterrupt()
        )

        result = main()
        self.assertEqual(result, 130)

    def test_main_with_invalid_arguments(self):
        """Test main function with invalid arguments."""
        # Save original argv
        original_argv = sys.argv
        try:
            # Set invalid arguments (no flake_path)
            sys.argv = ["run.py"]
            result = main()
            self.assertEqual(result, 1)
        finally:
            # Restore original argv
            sys.argv = original_argv


class TestRegexPatterns(unittest.TestCase):
    """Test regex patterns with fuzz inputs."""

    def test_version_regex_with_fuzz_strings(
        self,
    ):
        """Test RE_VERSION regex with various strings."""
        test_strings = [
            "",  # Empty
            "1",  # Single digit
            "a1",  # Letter then digit
            "1a",  # Digit then letter
            "10.5",  # Version-like
            "v1.0",  # With prefix
            "version-1.0",  # With prefix
            "\x001",  # With control character
            "🔢1",  # With emoji
        ]

        for s in test_strings:
            with self.subTest(string=repr(s)):
                # Should not raise exception
                match = RE_VERSION.match(s)
                if s and s[0].isdigit():
                    self.assertIsNotNone(match)
                else:
                    self.assertIsNone(match)

    def test_hash_regex_with_fuzz_strings(self):
        """Test RE_HASH regex with various strings."""
        # Generate test hashes
        valid_hash = "abcdefgh12345678abcdefgh12345678"  # 32 chars, valid
        invalid_hashes = [
            "",  # Empty
            "abc",  # Too short
            "a" * 31,  # 31 chars
            "a" * 33,  # 33 chars
            "ABCDEFGH12345678ABCDEFGH12345678",  # Uppercase
            "xbcdefgh12345678abcdefgh1234567x",  # Invalid char 'x' (not in [0-9a-f])
            "abcdefgh-12345678abcdefgh12345678",  # With dash
            "abcdefgh 12345678abcdefgh12345678",  # With space
        ]

        # Test valid hash
        self.assertIsNotNone(
            RE_HASH.fullmatch(valid_hash)
        )

        # Test invalid hashes
        for invalid_hash in invalid_hashes:
            with self.subTest(
                hash=repr(invalid_hash)
            ):
                self.assertIsNone(
                    RE_HASH.fullmatch(
                        invalid_hash
                    )
                )


class TestPackageMappings(unittest.TestCase):
    """Test package mappings with fuzz inputs."""

    def test_package_mappings_consistency(self):
        """Test that package mappings are consistent."""
        for (
            pattern,
            replacement,
        ) in PACKAGE_MAPPINGS.items():
            with self.subTest(
                pattern=pattern,
                replacement=replacement,
            ):
                self.assertIsInstance(
                    pattern, str
                )
                self.assertIsInstance(
                    replacement, str
                )
                self.assertGreater(
                    len(pattern), 0
                )
                self.assertGreater(
                    len(replacement), 0
                )

    def test_skip_packages_consistency(self):
        """Test that skip packages set is consistent."""
        for package in SKIP_PACKAGES:
            with self.subTest(package=package):
                self.assertIsInstance(
                    package, str
                )
                self.assertGreater(
                    len(package), 0
                )


class TestFileOperations(unittest.TestCase):
    """Test file operations with fuzz inputs."""

    def test_output_file_with_invalid_paths(self):
        """Test output file creation with invalid paths."""
        with tempfile.TemporaryDirectory() as temp_dir:
            config = DevShellConfig(
                flake_path=".",
                output_file=os.path.join(
                    temp_dir, "test.nix"
                ),
                quiet=True,
            )

            # Test with various invalid output paths
            invalid_paths = [
                "/dev/null/invalid",  # Can't create file under /dev/null
                "/root/test.nix",  # Permission denied (usually)
                "",  # Empty path
                "\x00",  # Null byte
            ]

            for invalid_path in invalid_paths:
                with self.subTest(
                    path=repr(invalid_path)
                ):
                    config.output_file = (
                        invalid_path
                    )
                    # The actual file writing happens in main(),
                    # so we just verify the config accepts it
                    self.assertEqual(
                        config.output_file,
                        invalid_path,
                    )


class TestConcurrencyAndStress(unittest.TestCase):
    """Test concurrent operations and stress scenarios."""

    def test_multiple_extractor_instances(self):
        """Test creating multiple extractor instances simultaneously."""
        configs = [
            DevShellConfig(
                flake_path=".", quiet=True
            )
            for _ in range(100)
        ]

        extractors = [
            DevShellExtractor(config)
            for config in configs
        ]

        # Verify all instances are independent
        for i, extractor in enumerate(extractors):
            with self.subTest(instance=i):
                self.assertIsInstance(
                    extractor.config,
                    DevShellConfig,
                )
                self.assertIsInstance(
                    extractor.logger,
                    logging.Logger,
                )

    def test_stress_package_name_conversion(self):
        """Stress test package name conversion with many inputs."""
        extractor = DevShellExtractor(
            DevShellConfig(
                flake_path=".", quiet=True
            )
        )

        # Generate many derivation paths
        for _ in range(1000):
            drv_path = f"/nix/store/{''.join(random.choices('0123456789abcdef', k=32))}-{FuzzTestGenerator.random_string(20, string.ascii_lowercase)}"
            with self.subTest(path=drv_path):
                result = extractor.drv_to_pkgname(
                    drv_path
                )
                if result is not None:
                    self.assertIsInstance(
                        result, str
                    )


if __name__ == "__main__":
    # Configure test output
    unittest.main(verbosity=2, buffer=True)
