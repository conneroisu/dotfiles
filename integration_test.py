#!/usr/bin/env python3
"""
integration_test.py - Full integration testing for run.py

Tests the complete run.py functionality with real flakes,
actual command-line execution, and end-to-end scenarios.
"""

import os
import sys
import subprocess
import tempfile
import json
from pathlib import Path


class IntegrationTester:
    """Full integration testing framework."""

    def __init__(self):
        self.results = {
            "real_flake_extraction": [],
            "command_line_execution": [],
            "output_format_validation": [],
            "error_scenario_handling": [],
            "template_compatibility": [],
        }
        self.script_path = (
            Path(__file__).parent / "run.py"
        )

    def test_real_flake_extraction(self):
        """Test extraction from real flakes in the repository."""
        print(
            "🔍 Testing real flake extraction..."
        )

        # Find actual flakes in the repository
        flake_paths = [
            ".",  # Root flake
            "./templates/go-shell",
            "./templates/rust-shell",
            "./templates/devshell",
        ]

        for flake_path in flake_paths:
            if not Path(flake_path).exists():
                continue

            try:
                # Test extraction with the script directly
                result = subprocess.run(
                    [
                        sys.executable,
                        str(self.script_path),
                        "--quiet",
                        "--format",
                        "json",
                        flake_path,
                    ],
                    capture_output=True,
                    text=True,
                    timeout=30,
                )

                if result.returncode == 0:
                    # Validate JSON output
                    try:
                        data = json.loads(
                            result.stdout
                        )
                        self.results[
                            "real_flake_extraction"
                        ].append(
                            {
                                "flake_path": flake_path,
                                "success": True,
                                "has_build_inputs": len(
                                    data.get(
                                        "build_inputs",
                                        [],
                                    )
                                )
                                > 0,
                                "has_system": "system"
                                in data,
                                "valid_json": True,
                            }
                        )
                    except json.JSONDecodeError:
                        self.results[
                            "real_flake_extraction"
                        ].append(
                            {
                                "flake_path": flake_path,
                                "success": False,
                                "error": "Invalid JSON output",
                                "output": result.stdout[
                                    :200
                                ],
                            }
                        )
                else:
                    self.results[
                        "real_flake_extraction"
                    ].append(
                        {
                            "flake_path": flake_path,
                            "success": False,
                            "returncode": result.returncode,
                            "error": result.stderr[
                                :200
                            ],
                        }
                    )

            except subprocess.TimeoutExpired:
                self.results[
                    "real_flake_extraction"
                ].append(
                    {
                        "flake_path": flake_path,
                        "success": False,
                        "error": "Timeout after 30 seconds",
                    }
                )
            except Exception as e:
                self.results[
                    "real_flake_extraction"
                ].append(
                    {
                        "flake_path": flake_path,
                        "success": False,
                        "error": str(e),
                    }
                )

        successful = len(
            [
                r
                for r in self.results[
                    "real_flake_extraction"
                ]
                if r.get("success", False)
            ]
        )
        print(
            f"   ✅ Successfully extracted from {successful}/{len(self.results['real_flake_extraction'])} flakes"
        )

    def test_command_line_execution(self):
        """Test various command-line argument combinations."""
        print(
            "🔍 Testing command-line execution..."
        )

        test_cases = [
            {
                "args": [".", "--format", "nix"],
                "description": "Basic Nix output",
            },
            {
                "args": [".", "--format", "json"],
                "description": "JSON output format",
            },
            {
                "args": [".", "--verbose"],
                "description": "Verbose mode",
            },
            {
                "args": [".", "--quiet"],
                "description": "Quiet mode",
            },
            {
                "args": [".", "--no-shell-hook"],
                "description": "No shell hook",
            },
            {
                "args": [
                    ".",
                    "--separate-inputs",
                ],
                "description": "Separate input types",
            },
            {
                "args": [
                    ".",
                    "--shell-name",
                    "default",
                ],
                "description": "Specific shell name",
            },
        ]

        with tempfile.NamedTemporaryFile(
            mode="w", suffix=".nix", delete=False
        ) as temp_file:
            temp_output = temp_file.name

        try:
            for test_case in test_cases:
                try:
                    args = (
                        [
                            sys.executable,
                            str(self.script_path),
                        ]
                        + test_case["args"]
                        + ["-o", temp_output]
                    )
                    result = subprocess.run(
                        args,
                        capture_output=True,
                        text=True,
                        timeout=20,
                    )

                    # Check if output file was created (for cases with -o flag)
                    output_created = (
                        Path(temp_output).exists()
                        and Path(temp_output)
                        .stat()
                        .st_size
                        > 0
                    )

                    self.results[
                        "command_line_execution"
                    ].append(
                        {
                            "description": test_case[
                                "description"
                            ],
                            "args": test_case[
                                "args"
                            ],
                            "success": result.returncode
                            == 0,
                            "returncode": result.returncode,
                            "output_created": output_created,
                            "stderr_length": (
                                len(result.stderr)
                                if result.stderr
                                else 0
                            ),
                        }
                    )

                    # Clean up output file for next test
                    if Path(temp_output).exists():
                        Path(temp_output).unlink()

                except subprocess.TimeoutExpired:
                    self.results[
                        "command_line_execution"
                    ].append(
                        {
                            "description": test_case[
                                "description"
                            ],
                            "success": False,
                            "error": "Timeout",
                        }
                    )
                except Exception as e:
                    self.results[
                        "command_line_execution"
                    ].append(
                        {
                            "description": test_case[
                                "description"
                            ],
                            "success": False,
                            "error": str(e),
                        }
                    )
        finally:
            # Clean up temp file
            if Path(temp_output).exists():
                Path(temp_output).unlink()

        successful = len(
            [
                r
                for r in self.results[
                    "command_line_execution"
                ]
                if r.get("success", False)
            ]
        )
        print(
            f"   ✅ {successful}/{len(test_cases)} command-line scenarios succeeded"
        )

    def test_output_format_validation(self):
        """Test and validate different output formats."""
        print(
            "🔍 Testing output format validation..."
        )

        formats = ["nix", "json"]

        for format_type in formats:
            try:
                result = subprocess.run(
                    [
                        sys.executable,
                        str(self.script_path),
                        "--quiet",
                        "--format",
                        format_type,
                        ".",
                    ],
                    capture_output=True,
                    text=True,
                    timeout=15,
                )

                if (
                    result.returncode == 0
                    and result.stdout
                ):
                    # Validate format-specific output
                    if format_type == "json":
                        try:
                            json.loads(
                                result.stdout
                            )
                            format_valid = True
                            validation_msg = (
                                "Valid JSON"
                            )
                        except (
                            json.JSONDecodeError
                        ) as e:
                            format_valid = False
                            validation_msg = f"Invalid JSON: {e}"
                    elif format_type == "nix":
                        # Basic Nix format validation
                        format_valid = (
                            "pkgs.mkShell"
                            in result.stdout
                            and "{"
                            in result.stdout
                        )
                        validation_msg = (
                            "Valid Nix format"
                            if format_valid
                            else "Invalid Nix format"
                        )
                    else:
                        format_valid = True
                        validation_msg = (
                            "Format check skipped"
                        )

                    self.results[
                        "output_format_validation"
                    ].append(
                        {
                            "format": format_type,
                            "success": True,
                            "format_valid": format_valid,
                            "validation_msg": validation_msg,
                            "output_length": len(
                                result.stdout
                            ),
                        }
                    )
                else:
                    self.results[
                        "output_format_validation"
                    ].append(
                        {
                            "format": format_type,
                            "success": False,
                            "error": (
                                result.stderr[
                                    :200
                                ]
                                if result.stderr
                                else "No output"
                            ),
                        }
                    )

            except Exception as e:
                self.results[
                    "output_format_validation"
                ].append(
                    {
                        "format": format_type,
                        "success": False,
                        "error": str(e),
                    }
                )

        valid_formats = len(
            [
                r
                for r in self.results[
                    "output_format_validation"
                ]
                if r.get("success", False)
                and r.get("format_valid", False)
            ]
        )
        print(
            f"   ✅ {valid_formats}/{len(formats)} output formats validated"
        )

    def test_error_scenario_handling(self):
        """Test error scenarios and graceful failure."""
        print(
            "🔍 Testing error scenario handling..."
        )

        error_scenarios = [
            {
                "args": [],  # Missing required argument
                "description": "Missing flake path",
                "expected_failure": True,
            },
            {
                "args": ["/nonexistent/path"],
                "description": "Non-existent flake path",
                "expected_failure": True,
            },
            {
                "args": [
                    ".",
                    "--format",
                    "invalid",
                ],
                "description": "Invalid format",
                "expected_failure": True,
            },
            {
                "args": [
                    ".",
                    "--shell-name",
                    "nonexistent",
                ],
                "description": "Non-existent shell name",
                "expected_failure": True,
            },
            {
                "args": [
                    ".",
                    "--output",
                    "/root/forbidden.nix",
                ],
                "description": "Permission denied output",
                "expected_failure": True,
            },
        ]

        for scenario in error_scenarios:
            try:
                args = [
                    sys.executable,
                    str(self.script_path),
                ] + scenario["args"]
                result = subprocess.run(
                    args,
                    capture_output=True,
                    text=True,
                    timeout=10,
                )

                # For expected failures, non-zero return code is success
                scenario_handled = (
                    result.returncode != 0
                ) == scenario["expected_failure"]

                self.results[
                    "error_scenario_handling"
                ].append(
                    {
                        "description": scenario[
                            "description"
                        ],
                        "expected_failure": scenario[
                            "expected_failure"
                        ],
                        "actual_returncode": result.returncode,
                        "scenario_handled": scenario_handled,
                        "has_error_message": (
                            len(result.stderr) > 0
                            if result.stderr
                            else False
                        ),
                    }
                )

            except subprocess.TimeoutExpired:
                self.results[
                    "error_scenario_handling"
                ].append(
                    {
                        "description": scenario[
                            "description"
                        ],
                        "scenario_handled": False,
                        "error": "Timeout",
                    }
                )
            except Exception as e:
                self.results[
                    "error_scenario_handling"
                ].append(
                    {
                        "description": scenario[
                            "description"
                        ],
                        "scenario_handled": False,
                        "error": str(e),
                    }
                )

        handled = len(
            [
                r
                for r in self.results[
                    "error_scenario_handling"
                ]
                if r.get(
                    "scenario_handled", False
                )
            ]
        )
        print(
            f"   ✅ {handled}/{len(error_scenarios)} error scenarios handled correctly"
        )

    def test_template_compatibility(self):
        """Test compatibility with available templates."""
        print(
            "🔍 Testing template compatibility..."
        )

        template_dir = Path("./templates")
        if not template_dir.exists():
            print(
                "   ⚠️  Templates directory not found"
            )
            return

        # Find templates with flake.nix files
        templates = []
        for item in template_dir.iterdir():
            if (
                item.is_dir()
                and (item / "flake.nix").exists()
            ):
                templates.append(item)

        for template_path in templates[
            :5
        ]:  # Limit to first 5 templates
            try:
                result = subprocess.run(
                    [
                        sys.executable,
                        str(self.script_path),
                        "--quiet",
                        "--format",
                        "json",
                        str(template_path),
                    ],
                    capture_output=True,
                    text=True,
                    timeout=25,
                )

                if result.returncode == 0:
                    try:
                        data = json.loads(
                            result.stdout
                        )
                        self.results[
                            "template_compatibility"
                        ].append(
                            {
                                "template": template_path.name,
                                "success": True,
                                "packages_found": len(
                                    data.get(
                                        "build_inputs",
                                        [],
                                    )
                                )
                                + len(
                                    data.get(
                                        "native_build_inputs",
                                        [],
                                    )
                                ),
                                "has_shell_hook": bool(
                                    data.get(
                                        "shell_hook",
                                        "",
                                    ).strip()
                                ),
                            }
                        )
                    except json.JSONDecodeError:
                        self.results[
                            "template_compatibility"
                        ].append(
                            {
                                "template": template_path.name,
                                "success": False,
                                "error": "Invalid JSON output",
                            }
                        )
                else:
                    self.results[
                        "template_compatibility"
                    ].append(
                        {
                            "template": template_path.name,
                            "success": False,
                            "error": (
                                result.stderr[
                                    :150
                                ]
                                if result.stderr
                                else "Unknown error"
                            ),
                        }
                    )

            except subprocess.TimeoutExpired:
                self.results[
                    "template_compatibility"
                ].append(
                    {
                        "template": template_path.name,
                        "success": False,
                        "error": "Timeout",
                    }
                )
            except Exception as e:
                self.results[
                    "template_compatibility"
                ].append(
                    {
                        "template": template_path.name,
                        "success": False,
                        "error": str(e),
                    }
                )

        compatible = len(
            [
                r
                for r in self.results[
                    "template_compatibility"
                ]
                if r.get("success", False)
            ]
        )
        total = len(
            self.results["template_compatibility"]
        )
        print(
            f"   ✅ {compatible}/{total} templates compatible"
        )

    def run_all_tests(self):
        """Run all integration tests."""
        print("🚀 FULL INTEGRATION TESTING")
        print("=" * 50)

        if not self.script_path.exists():
            print(
                f"❌ Script not found: {self.script_path}"
            )
            return False

        self.test_real_flake_extraction()
        self.test_command_line_execution()
        self.test_output_format_validation()
        self.test_error_scenario_handling()
        self.test_template_compatibility()

        return self.generate_report()

    def generate_report(self):
        """Generate integration test report."""
        print("\n📊 INTEGRATION TEST RESULTS")
        print("-" * 35)

        total_tests = 0
        total_passed = 0

        for (
            category,
            results,
        ) in self.results.items():
            if not results:
                continue

            if (
                category
                == "error_scenario_handling"
            ):
                # Special handling for error scenarios
                passed = len(
                    [
                        r
                        for r in results
                        if r.get(
                            "scenario_handled",
                            False,
                        )
                    ]
                )
            else:
                passed = len(
                    [
                        r
                        for r in results
                        if r.get("success", False)
                    ]
                )

            total = len(results)
            total_tests += total
            total_passed += passed

            status = (
                "✅"
                if passed == total
                else (
                    "⚠️"
                    if passed > total * 0.7
                    else "❌"
                )
            )
            print(
                f"{status} {category.replace('_', ' ').title()}: {passed}/{total}"
            )

        success_rate = (
            (total_passed / total_tests) * 100
            if total_tests > 0
            else 0
        )
        print(
            f"\n🎯 Integration Success Rate: {success_rate:.1f}% ({total_passed}/{total_tests})"
        )

        if success_rate >= 85:
            print(
                "🏆 EXCELLENT - Production ready integration"
            )
            return True
        elif success_rate >= 70:
            print(
                "⚠️  GOOD - Minor integration issues"
            )
            return True
        else:
            print(
                "❌ POOR - Significant integration problems"
            )
            return False


def main():
    """Run full integration testing."""
    tester = IntegrationTester()
    return tester.run_all_tests()


if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
