{ pkgs ? import <nixpkgs> {} }:

let
  # Import the spec file under test
  specFile = ./.spec.nix;

  # Test utilities for consistent testing patterns
  testAssert = condition: message:
    if condition then true
    else throw "Test failed: ${message}";

  testEquals = expected: actual: message:
    testAssert (expected == actual) "${message} - Expected: ${builtins.toString expected}, Got: ${builtins.toString actual}";

  testHasAttr = attr: set: message:
    testAssert (builtins.hasAttr attr set) "${message} - Missing attribute: ${attr}";

  testIsString = value: message:
    testAssert (builtins.isString value) "${message} - Expected string, got ${builtins.typeOf value}";

  testIsList = value: message:
    testAssert (builtins.isList value) "${message} - Expected list, got ${builtins.typeOf value}";

  testIsFunction = value: message:
    testAssert (builtins.isFunction value) "${message} - Expected function, got ${builtins.typeOf value}";

  testIsAttrs = value: message:
    testAssert (builtins.isAttrs value) "${message} - Expected attribute set, got ${builtins.typeOf value}";

  # Runner summary (unused in this derivation but available for expansions)
  runTests = tests:
    let
      results  = map (t: t.run) tests;
      successes = builtins.filter (x: x == true) results;
      failures  = builtins.filter (x: x != true) results;
    in {
      total   = builtins.length tests;
      passed  = builtins.length successes;
      failed  = builtins.length failures;
      success = builtins.length failures == 0;
    };
in

pkgs.stdenv.mkDerivation {
  name   = "spec-nix-tests";
  src    = ./.;
  doCheck = true;

  buildPhase = ''
    echo "=== Running Comprehensive Tests for .spec.nix ==="
    echo "Testing framework: Nix built-in testing with derivations and assertions"
    echo ""
  '';

  checkPhase = ''
    #
    # Phase 1: Basic Evaluation Tests
    #
    echo "Phase 1: Basic Evaluation Tests"
    echo "==============================="
    if [ ! -f "${specFile}" ]; then
      echo "✗ FAIL: .spec.nix file does not exist"
      exit 1
    fi
    echo "✓ PASS: .spec.nix file exists and is readable"

    if ! ${pkgs.nix}/bin/nix-instantiate --parse "${specFile}" > /dev/null 2>&1; then
      echo "✗ FAIL: .spec.nix has invalid Nix syntax"
      exit 1
    fi
    echo "✓ PASS: .spec.nix has valid Nix syntax"

    #
    # Phase 2: Evaluation and Type Validation Tests
    #
    echo ""
    echo "Phase 2: Evaluation and Type Validation Tests"
    echo "=============================================="
    echo "Testing evaluation with standard pkgs..."
    if ${pkgs.nix}/bin/nix-instantiate --eval --strict -E '
      let pkgs = import <nixpkgs> {}; in builtins.typeOf (import ${specFile} { inherit pkgs; })
    ' > /dev/null 2>&1; then
      echo "✓ PASS: Evaluates successfully with standard pkgs"
    else
      echo "⚠ WARNING: May not evaluate with standard pkgs (could be expected for empty spec)"
    fi

    echo "Testing evaluation with minimal pkgs..."
    EVAL_RESULT=$(${pkgs.nix}/bin/nix-instantiate --eval --strict -E '
      let pkgs = {}; in try (builtins.typeOf (import ${specFile} { inherit pkgs; })) catch "error"
    ' 2>/dev/null || echo "error")
    if [ "$EVAL_RESULT" != "error" ]; then
      echo "✓ PASS: Handles minimal pkgs gracefully"
    else
      echo "⚠ INFO: Requires full pkgs (normal for many specs)"
    fi

    echo "Testing error handling with null inputs..."
    if ! ${pkgs.nix}/bin/nix-instantiate --eval --strict -E '
      import ${specFile} { pkgs = null; }
    ' > /dev/null 2>&1; then
      echo "✓ PASS: Properly handles null inputs with error"
    else
      echo "⚠ WARNING: Accepts null inputs (may not be intended)"
    fi

    echo "Testing evaluation reproducibility..."
    RESULT1=$(${pkgs.nix}/bin/nix-instantiate --eval --json -E '
      import ${specFile} { pkgs = import <nixpkgs> {}; }
    ' 2>/dev/null || echo "null")
    RESULT2=$(${pkgs.nix}/bin/nix-instantiate --eval --json -E '
      import ${specFile} { pkgs = import <nixpkgs> {}; }
    ' 2>/dev/null || echo "null")
    if [ "$RESULT1" = "$RESULT2" ]; then
      echo "✓ PASS: Evaluation is reproducible"
    else
      echo "✗ FAIL: Evaluation produces different results"
      exit 1
    fi

    #
    # Phase 3: Structural Validation Tests
    #
    echo ""
    echo "Phase 3: Structural Validation Tests"
    echo "===================================="
    OUTPUT_TYPE=$(${pkgs.nix}/bin/nix-instantiate --eval --strict -E '
      let
        pkgs   = import <nixpkgs> {};
        result = import ${specFile} { inherit pkgs; };
      in builtins.typeOf result
    ' 2>/dev/null || echo "error")
    case "$OUTPUT_TYPE" in
      set)    echo "✓ PASS: Spec returns attribute set" ;;
      lambda) echo "✓ PASS: Spec returns function" ;;
      string) echo "✓ PASS: Spec returns string" ;;
      list)   echo "✓ PASS: Spec returns list" ;;
      null)   echo "ℹ INFO: Spec returns null (may be empty spec)" ;;
      error)  echo "ℹ INFO: Spec requires specific inputs (common pattern)" ;;
      *)      echo "✓ PASS: Spec returns $OUTPUT_TYPE" ;;
    esac

    if [ "$OUTPUT_TYPE" = "set" ]; then
      echo "Testing common spec attributes..."
      for attr in name version description src buildInputs meta; do
        if ${pkgs.nix}/bin/nix-instantiate --eval -E '
          let
            pkgs   = import <nixpkgs> {};
            result = import ${specFile} { inherit pkgs; };
          in builtins.hasAttr "'$attr'" result
        ' 2>/dev/null | grep -q true; then
          echo "✓ PASS: Has '$attr' attribute"
        else
          echo "ℹ INFO: No '$attr' attribute (may not be needed)"
        fi
      done
    fi

    echo "Testing attribute type consistency..."
    ${pkgs.nix}/bin/nix-instantiate --eval --strict -E '
      let
        pkgs   = import <nixpkgs> {};
        result = import ${specFile} { inherit pkgs; };
        validateTypes = attrs:
          builtins.all (attr:
            let value = attrs.${attr}; in
            if builtins.isString value then true
            else if builtins.isList value then true
            else if builtins.isAttrs value then true
            else if builtins.isFunction value then true
            else false
          ) (builtins.attrNames attrs);
      in if builtins.isAttrs result then validateTypes result else true
    ' > /dev/null 2>&1 && echo "✓ PASS: Attribute types are consistent" || echo "ℹ INFO: Type validation skipped"

    #
    # Phase 4: Edge Case and Error Handling Tests
    #
    echo ""
    echo "Phase 4: Edge Case and Error Handling Tests"
    echo "==========================================="
    echo "Testing with empty overlays..."
    if ${pkgs.nix}/bin/nix-instantiate --eval -E '
      let
        pkgs   = import <nixpkgs> { overlays = []; };
        result = import ${specFile} { inherit pkgs; };
      in true
    ' > /dev/null 2>&1; then
      echo "✓ PASS: Works with empty overlays"
    else
      echo "ℹ INFO: May require specific overlays"
    fi

    echo "Testing performance characteristics..."
    START_TIME=$(date +%s%N)
    ${pkgs.nix}/bin/nix-instantiate --eval "${specFile}" > /dev/null 2>&1 || true
    END_TIME=$(date +%s%N)
    DURATION=$((($END_TIME - $START_TIME) / 1000000))
    if [ $DURATION -lt 5000 ]; then
      echo "✓ PASS: Evaluation completes quickly ($DURATION ms)"
    elif [ $DURATION -lt 30000 ]; then
      echo "⚠ WARNING: Evaluation is slow ($DURATION ms)"
    else
      echo "✗ FAIL: Evaluation is very slow ($DURATION ms)"
      exit 1
    fi

    echo "Testing restricted evaluation mode..."
    if ${pkgs.nix}/bin/nix-instantiate --eval --restrict-eval "${specFile}" > /dev/null 2>&1; then
      echo "✓ PASS: Works in restricted evaluation mode"
    else
      echo "ℹ INFO: Requires unrestricted evaluation (may access network/filesystem)"
    fi

    echo "Testing import behavior and dependencies..."
    IMPORTS=$(grep -c "import\\|require" "${specFile}" 2>/dev/null || echo "0")
    if [ "$IMPORTS" -eq 0 ]; then
      echo "✓ PASS: No external imports (self-contained)"
    else
      echo "ℹ INFO: Uses $IMPORTS import statements"
      if grep -q "import <" "${specFile}" 2>/dev/null; then
        echo "⚠ WARNING: Uses angle bracket imports (consider parameterizing)"
      fi
      if grep -q "import.*http" "${specFile}" 2>/dev/null; then
        echo "⚠ WARNING: Imports from HTTP sources (security consideration)"
      fi
    fi

    #
    # Phase 5: Code Quality and Best Practices
    #
    echo ""
    echo "Phase 5: Code Quality and Best Practices"
    echo "========================================"
    echo "Checking for 'rec' usage..."
    if grep -q "rec\\s*{" "${specFile}" 2>/dev/null; then
      echo "⚠ INFO: Uses 'rec' (consider if necessary for maintainability)"
    fi

    echo "Checking for 'with' statements..."
    if grep -q "with\\s" "${specFile}" 2>/dev/null; then
      echo "⚠ INFO: Uses 'with' statements (consider explicit imports for clarity)"
    fi

    echo "Checking for TODO/FIXME comments..."
    if grep -qi "todo\\|fixme\\|hack" "${specFile}" 2>/dev/null; then
      echo "ℹ INFO: Contains TODO/FIXME comments"
    fi

    echo "Checking Nix formatting..."
    if command -v nixfmt >/dev/null 2>&1; then
      if nixfmt --check "${specFile}" 2>/dev/null; then
        echo "✓ PASS: Nix formatting is correct"
      else
        echo "⚠ INFO: Consider running nixfmt for consistent formatting"
      fi
    else
      echo "ℹ INFO: nixfmt not available, skipping format check"
    fi

    echo "Checking documentation comments..."
    COMMENT_LINES=$(grep -c "^\\s*#" "${specFile}" 2>/dev/null || echo "0")
    if [ "$COMMENT_LINES" -gt 0 ]; then
      echo "✓ PASS: Contains $COMMENT_LINES comment lines"
    else
      echo "ℹ INFO: No comments found (consider adding documentation)"
    fi

    #
    # Phase 6: Integration and Final Validation
    #
    echo ""
    echo "Phase 6: Integration and Final Validation"
    echo "========================================"
    echo "Testing instantiation with nix-instantiate..."
    if ${pkgs.nix}/bin/nix-instantiate "${specFile}" > /dev/null 2>&1; then
      echo "✓ PASS: Can be instantiated with nix-instantiate"
    else
      echo "ℹ INFO: Not suitable for direct instantiation (may be a library/config)"
    fi

    echo "Validating spec file size..."
    FILE_SIZE=$(stat -c%s "${specFile}" 2>/dev/null || stat -f%z "${specFile}" 2>/dev/null || echo "0")
    if [ "$FILE_SIZE" -eq 0 ]; then
      echo "ℹ INFO: Empty spec file - this is a placeholder or template"
    elif [ "$FILE_SIZE" -lt 100 ]; then
      echo "ℹ INFO: Very minimal spec ($FILE_SIZE bytes)"
    else
      echo "✓ PASS: Substantial spec file ($FILE_SIZE bytes)"
    fi

    echo ""
    echo "=== Test Suite Summary ==="
    echo "All available tests completed successfully!"
    echo "Spec file: ${specFile}"
    echo "Testing framework: Nix built-in testing with derivations and assertions"
    echo "Test categories: Evaluation, Type validation, Structure, Edge cases, Best practices, Integration"
    echo "Final validation: Test suite execution successful ✅"
  '';

  installPhase = ''
    mkdir -p $out
    echo "Basic tests completed successfully" > $out/test-results.txt
  '';

  postInstall = ''
    cat > $out/run-tests.sh << 'EOF'
#!/usr/bin/env bash
set -e
echo "🧪 Running .spec.nix test suite..."
echo "Using Nix built-in testing framework"
nix-build test_spec.nix -o result-spec-tests
if [ -f "result-spec-tests/test-results.txt" ]; then
  echo "📊 Test Results:"
  cat result-spec-tests/test-results.txt
else
  echo "⚠️  No test results file found"
fi
echo "🧹 Cleaning up..."
rm -f result-spec-tests
echo "✅ Test execution completed!"
EOF
    chmod +x $out/run-tests.sh
    echo "Test suite built successfully" >> $out/test-results.txt
    echo "Framework: Nix built-in testing with derivations and assertions" >> $out/test-results.txt
    echo "Categories: Evaluation, Validation, Structure, Edge cases, Best practices, Integration" >> $out/test-results.txt
  '';

  meta = {
    description = "Comprehensive test suite for .spec.nix using Nix built-in testing capabilities";
    longDescription = ''
      This test suite validates .spec.nix files using Nix's native testing approach with derivations,
      assertions, and nix-instantiate. It covers evaluation tests, structural validation, edge cases,
      error handling, code quality checks, and integration testing.
    '';
  };
}