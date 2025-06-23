# Validate All Repository Examples

## Instructions for Claude Code Agent

Systematically test and validate every example in the `./examples` directory to ensure they all run correctly, are properly documented, and provide a good user experience.

### Testing Philosophy & Strategy

**Core Testing Principles:**
- **Zero Assumptions**: Test as if you've never seen the codebase before
- **Fresh Environment**: Simulate new user experience with clean setup
- **Comprehensive Coverage**: Test functionality, documentation, and edge cases
- **Automation-First**: Create repeatable, automated validation processes
- **User-Centric**: Focus on the end-user experience, not just code execution
- **Fail-Fast**: Identify issues quickly with clear error reporting

### Multi-Layer Testing Strategy

#### Layer 1: Static Analysis & Pre-Flight Checks
#### Layer 2: Dependency & Environment Validation  
#### Layer 3: Functional Execution Testing
#### Layer 4: Documentation & User Experience Testing
#### Layer 5: Integration & Performance Testing

### Workflow Steps

1. **Discovery & Inventory**
   - Scan all examples in `./examples` directory
   - Catalog example types, technologies, and complexity levels
   - Identify dependencies and requirements for each example
   - Create testing matrix based on example characteristics

2. **Create Testing Infrastructure**
   - Set up isolated testing environments
   - Create automated testing scripts
   - Implement result reporting and logging
   - Design test data and mock services if needed

3. **Execute Comprehensive Testing**
   - Run all testing layers systematically
   - Document results and failures
   - Create remediation plans for failed examples
   - Validate fixes and re-test

4. **Generate Testing Report**
   - Summarize testing results
   - Provide actionable recommendations
   - Update example documentation as needed
   - Create ongoing validation processes

### Testing Implementation

#### Discovery Commands

```bash
# Create comprehensive example inventory
find ./examples -mindepth 1 -maxdepth 1 -type d | sort > examples_list.txt

# Analyze example structure and complexity
for example in $(cat examples_list.txt); do
  echo "=== Analysis: $example ==="
  echo "Files: $(find $example -type f | wc -l)"
  echo "Languages: $(find $example -name "*.js" -o -name "*.py" -o -name "*.go" -o -name "*.rs" -o -name "*.java" | sed 's/.*\.//' | sort -u | tr '\n' ' ')"
  echo "Dependencies: $(find $example -name "package.json" -o -name "requirements.txt" -o -name "Cargo.toml" -o -name "go.mod" -o -name "pom.xml")"
  echo "Config files: $(find $example -name "*.json" -o -name "*.yaml" -o -name "*.yml" -o -name "*.env*" -o -name "*.conf*")"
  echo "Documentation: $(find $example -name "*.md" -o -name "*.txt")"
  echo "---"
done

# Check for external service dependencies
grep -r "http://" ./examples/ | grep -v ".git" | head -10
grep -r "https://" ./examples/ | grep -v ".git" | head -10
grep -r "localhost" ./examples/ | head -10
grep -r "127.0.0.1" ./examples/ | head -10
```

#### Layer 1: Static Analysis & Pre-Flight Checks

```bash
# Create validation script: validate_examples_static.sh
cat > validate_examples_static.sh << 'EOF'
#!/bin/bash

echo "=== STATIC ANALYSIS & PRE-FLIGHT CHECKS ==="
FAILED_EXAMPLES=()

for example_dir in ./examples/*/; do
  example_name=$(basename "$example_dir")
  echo "Testing: $example_name"
  
  # Check README exists and is non-empty
  if [[ ! -f "$example_dir/README.md" ]]; then
    echo "❌ Missing README.md in $example_name"
    FAILED_EXAMPLES+=("$example_name:missing-readme")
  elif [[ ! -s "$example_dir/README.md" ]]; then
    echo "❌ Empty README.md in $example_name"
    FAILED_EXAMPLES+=("$example_name:empty-readme")
  fi
  
  # Syntax checking for different languages
  # JavaScript/TypeScript
  if find "$example_dir" -name "*.js" -o -name "*.ts" | grep -q .; then
    if command -v node >/dev/null; then
      for jsfile in $(find "$example_dir" -name "*.js" -o -name "*.ts"); do
        if ! node -c "$jsfile" 2>/dev/null; then
          echo "❌ Syntax error in $jsfile"
          FAILED_EXAMPLES+=("$example_name:js-syntax")
        fi
      done
    fi
  fi
  
  # Python
  if find "$example_dir" -name "*.py" | grep -q .; then
    if command -v python3 >/dev/null; then
      for pyfile in $(find "$example_dir" -name "*.py"); do
        if ! python3 -m py_compile "$pyfile" 2>/dev/null; then
          echo "❌ Syntax error in $pyfile"
          FAILED_EXAMPLES+=("$example_name:py-syntax")
        fi
      done
    fi
  fi
  
  # Check for hardcoded credentials or sensitive data
  if grep -r -i "password\|secret\|key\|token" "$example_dir" --include="*.js" --include="*.py" --include="*.go" --include="*.rs" | grep -v "example\|placeholder\|your_\|<.*>\|\[.*\]"; then
    echo "⚠️  Potential hardcoded credentials in $example_name"
    FAILED_EXAMPLES+=("$example_name:potential-credentials")
  fi
  
  # Check for broken relative imports/requires
  if grep -r "\.\./\.\." "$example_dir" --include="*.js" --include="*.py" --include="*.go"; then
    echo "⚠️  Deep relative imports found in $example_name (may break in isolation)"
    FAILED_EXAMPLES+=("$example_name:deep-imports")
  fi
  
  echo "✅ Static analysis complete for $example_name"
done

if [[ ${#FAILED_EXAMPLES[@]} -gt 0 ]]; then
  echo "❌ Static analysis found issues:"
  printf '%s\n' "${FAILED_EXAMPLES[@]}"
  exit 1
else
  echo "✅ All examples passed static analysis"
fi
EOF

chmod +x validate_examples_static.sh
./validate_examples_static.sh
```

#### Layer 2: Dependency & Environment Validation

```bash
# Create dependency validation script: validate_dependencies.sh
cat > validate_dependencies.sh << 'EOF'
#!/bin/bash

echo "=== DEPENDENCY & ENVIRONMENT VALIDATION ==="
FAILED_EXAMPLES=()

for example_dir in ./examples/*/; do
  example_name=$(basename "$example_dir")
  echo "Validating dependencies for: $example_name"
  
  cd "$example_dir" || continue
  
  # Node.js dependencies
  if [[ -f "package.json" ]]; then
    echo "  Checking Node.js dependencies..."
    if command -v npm >/dev/null; then
      if ! npm install --dry-run 2>/dev/null; then
        echo "❌ npm install failed for $example_name"
        FAILED_EXAMPLES+=("$example_name:npm-install")
      else
        # Actually install for testing
        if ! npm install --silent 2>/dev/null; then
          echo "❌ npm install failed for $example_name"
          FAILED_EXAMPLES+=("$example_name:npm-install")
        fi
      fi
    else
      echo "⚠️  npm not available, skipping Node.js dependency check"
    fi
  fi
  
  # Python dependencies
  if [[ -f "requirements.txt" ]]; then
    echo "  Checking Python dependencies..."
    if command -v pip3 >/dev/null; then
      if ! pip3 install -r requirements.txt --dry-run 2>/dev/null; then
        echo "❌ pip install failed for $example_name"
        FAILED_EXAMPLES+=("$example_name:pip-install")
      fi
    else
      echo "⚠️  pip3 not available, skipping Python dependency check"
    fi
  fi
  
  # Go dependencies
  if [[ -f "go.mod" ]]; then
    echo "  Checking Go dependencies..."
    if command -v go >/dev/null; then
      if ! go mod download 2>/dev/null; then
        echo "❌ go mod download failed for $example_name"
        FAILED_EXAMPLES+=("$example_name:go-deps")
      fi
    else
      echo "⚠️  go not available, skipping Go dependency check"
    fi
  fi
  
  # Rust dependencies
  if [[ -f "Cargo.toml" ]]; then
    echo "  Checking Rust dependencies..."
    if command -v cargo >/dev/null; then
      if ! cargo check 2>/dev/null; then
        echo "❌ cargo check failed for $example_name"
        FAILED_EXAMPLES+=("$example_name:cargo-check")
      fi
    else
      echo "⚠️  cargo not available, skipping Rust dependency check"
    fi
  fi
  
  # Check for missing environment files
  if grep -r "\.env" . --include="*.md" --include="*.js" --include="*.py" | grep -q .; then
    if [[ ! -f ".env" && ! -f ".env.example" && ! -f "config/.env.example" ]]; then
      echo "❌ Example references .env but no .env.example provided for $example_name"
      FAILED_EXAMPLES+=("$example_name:missing-env-example")
    fi
  fi
  
  cd - >/dev/null
  echo "✅ Dependency validation complete for $example_name"
done

if [[ ${#FAILED_EXAMPLES[@]} -gt 0 ]]; then
  echo "❌ Dependency validation found issues:"
  printf '%s\n' "${FAILED_EXAMPLES[@]}"
  exit 1
else
  echo "✅ All examples passed dependency validation"
fi
EOF

chmod +x validate_dependencies.sh
./validate_dependencies.sh
```

#### Layer 3: Functional Execution Testing

```bash
# Create execution testing script: validate_execution.sh
cat > validate_execution.sh << 'EOF'
#!/bin/bash

echo "=== FUNCTIONAL EXECUTION TESTING ==="
FAILED_EXAMPLES=()
TIMEOUT_DURATION=30

run_with_timeout() {
  local timeout_duration=$1
  local command=$2
  local example_name=$3
  
  echo "Running: $command (timeout: ${timeout_duration}s)"
  
  if timeout "$timeout_duration" bash -c "$command" 2>&1; then
    echo "✅ Command completed successfully"
    return 0
  else
    local exit_code=$?
    if [[ $exit_code -eq 124 ]]; then
      echo "❌ Command timed out after ${timeout_duration}s"
      FAILED_EXAMPLES+=("$example_name:timeout")
    else
      echo "❌ Command failed with exit code $exit_code"
      FAILED_EXAMPLES+=("$example_name:execution-failure")
    fi
    return $exit_code
  fi
}

for example_dir in ./examples/*/; do
  example_name=$(basename "$example_dir")
  echo "Testing execution for: $example_name"
  
  cd "$example_dir" || continue
  
  # Copy .env.example to .env if it exists
  if [[ -f ".env.example" ]]; then
    cp .env.example .env
  elif [[ -f "config/.env.example" ]]; then
    cp config/.env.example .env
  fi
  
  # Determine how to run the example
  executed=false
  
  # Node.js projects
  if [[ -f "package.json" ]]; then
    if [[ -f "package.json" ]] && grep -q '"start"' package.json; then
      run_with_timeout $TIMEOUT_DURATION "npm start" "$example_name"
      executed=true
    elif [[ -f "index.js" ]]; then
      run_with_timeout $TIMEOUT_DURATION "node index.js" "$example_name"
      executed=true
    elif [[ -f "app.js" ]]; then
      run_with_timeout $TIMEOUT_DURATION "node app.js" "$example_name"
      executed=true
    elif [[ -f "main.js" ]]; then
      run_with_timeout $TIMEOUT_DURATION "node main.js" "$example_name"
      executed=true
    fi
  fi
  
  # Python projects
  if [[ ! $executed == true ]] && find . -name "*.py" | grep -q .; then
    if [[ -f "main.py" ]]; then
      run_with_timeout $TIMEOUT_DURATION "python3 main.py" "$example_name"
      executed=true
    elif [[ -f "app.py" ]]; then
      run_with_timeout $TIMEOUT_DURATION "python3 app.py" "$example_name"
      executed=true
    elif [[ -f "run.py" ]]; then
      run_with_timeout $TIMEOUT_DURATION "python3 run.py" "$example_name"
      executed=true
    else
      # Find any Python file and try to run it
      py_file=$(find . -name "*.py" -not -path "./tests/*" | head -1)
      if [[ -n "$py_file" ]]; then
        run_with_timeout $TIMEOUT_DURATION "python3 $py_file" "$example_name"
        executed=true
      fi
    fi
  fi
  
  # Go projects
  if [[ ! $executed == true ]] && [[ -f "main.go" || -f "go.mod" ]]; then
    run_with_timeout $TIMEOUT_DURATION "go run ." "$example_name"
    executed=true
  fi
  
  # Rust projects
  if [[ ! $executed == true ]] && [[ -f "Cargo.toml" ]]; then
    run_with_timeout $TIMEOUT_DURATION "cargo run" "$example_name"
    executed=true
  fi
  
  # Shell scripts
  if [[ ! $executed == true ]] && find . -name "*.sh" | grep -q .; then
    script_file=$(find . -name "*.sh" | head -1)
    if [[ -n "$script_file" ]]; then
      chmod +x "$script_file"
      run_with_timeout $TIMEOUT_DURATION "./$script_file" "$example_name"
      executed=true
    fi
  fi
  
  # Docker projects
  if [[ ! $executed == true ]] && [[ -f "Dockerfile" ]]; then
    echo "Found Dockerfile, attempting to build and run..."
    if docker build -t "example-$example_name" . 2>/dev/null; then
      run_with_timeout $TIMEOUT_DURATION "docker run --rm example-$example_name" "$example_name"
      executed=true
    else
      echo "❌ Docker build failed for $example_name"
      FAILED_EXAMPLES+=("$example_name:docker-build")
    fi
  fi
  
  if [[ ! $executed == true ]]; then
    echo "⚠️  Could not determine how to run $example_name"
    FAILED_EXAMPLES+=("$example_name:unknown-execution")
  fi
  
  cd - >/dev/null
  echo "---"
done

if [[ ${#FAILED_EXAMPLES[@]} -gt 0 ]]; then
  echo "❌ Execution testing found issues:"
  printf '%s\n' "${FAILED_EXAMPLES[@]}"
  exit 1
else
  echo "✅ All examples executed successfully"
fi
EOF

chmod +x validate_execution.sh
./validate_execution.sh
```

#### Layer 4: Documentation & User Experience Testing

```bash
# Create documentation validation script: validate_documentation.sh
cat > validate_documentation.sh << 'EOF'
#!/bin/bash

echo "=== DOCUMENTATION & USER EXPERIENCE TESTING ==="
FAILED_EXAMPLES=()

validate_readme() {
  local example_dir=$1
  local example_name=$2
  local readme_file="$example_dir/README.md"
  
  if [[ ! -f "$readme_file" ]]; then
    echo "❌ Missing README.md"
    FAILED_EXAMPLES+=("$example_name:missing-readme")
    return 1
  fi
  
  # Check for essential sections
  local content=$(cat "$readme_file")
  
  # Check for description
  if ! echo "$content" | grep -qi "description\|what.*does\|overview"; then
    echo "⚠️  README missing clear description"
    FAILED_EXAMPLES+=("$example_name:missing-description")
  fi
  
  # Check for setup/installation instructions
  if ! echo "$content" | grep -qi "install\|setup\|getting started\|quick start"; then
    echo "⚠️  README missing setup instructions"
    FAILED_EXAMPLES+=("$example_name:missing-setup")
  fi
  
  # Check for usage instructions
  if ! echo "$content" | grep -qi "usage\|how to run\|running\|execute"; then
    echo "⚠️  README missing usage instructions"
    FAILED_EXAMPLES+=("$example_name:missing-usage")
  fi
  
  # Check for code blocks with runnable commands
  if ! echo "$content" | grep -A5 -B5 '```' | grep -qi "npm\|python\|go run\|cargo\|node\|./"; then
    echo "⚠️  README missing executable code examples"
    FAILED_EXAMPLES+=("$example_name:missing-code-examples")
  fi
  
  # Check for broken internal links
  while IFS= read -r line; do
    if [[ $line =~ \[.*\]\(([^)]+)\) ]]; then
      link="${BASH_REMATCH[1]}"
      if [[ ! $link =~ ^https?:// ]] && [[ ! -f "$example_dir/$link" ]]; then
        echo "❌ Broken internal link: $link"
        FAILED_EXAMPLES+=("$example_name:broken-link")
      fi
    fi
  done < "$readme_file"
  
  echo "✅ README validation complete"
}

for example_dir in ./examples/*/; do
  example_name=$(basename "$example_dir")
  echo "Validating documentation for: $example_name"
  
  validate_readme "$example_dir" "$example_name"
  
  # Check for configuration documentation
  if find "$example_dir" -name "*.env*" -o -name "config.*" | grep -q .; then
    if ! grep -qi "config\|environment\|settings" "$example_dir/README.md" 2>/dev/null; then
      echo "⚠️  Configuration files present but not documented"
      FAILED_EXAMPLES+=("$example_name:undocumented-config")
    fi
  fi
  
  # Check for dependency documentation
  if find "$example_dir" -name "package.json" -o -name "requirements.txt" -o -name "Cargo.toml" -o -name "go.mod" | grep -q .; then
    if ! grep -qi "install\|dependencies\|requirements" "$example_dir/README.md" 2>/dev/null; then
      echo "⚠️  Dependencies present but installation not documented"
      FAILED_EXAMPLES+=("$example_name:undocumented-deps")
    fi
  fi
  
  echo "---"
done

if [[ ${#FAILED_EXAMPLES[@]} -gt 0 ]]; then
  echo "❌ Documentation validation found issues:"
  printf '%s\n' "${FAILED_EXAMPLES[@]}"
  exit 1
else
  echo "✅ All examples passed documentation validation"
fi
EOF

chmod +x validate_documentation.sh
./validate_documentation.sh
```

#### Layer 5: Integration & Performance Testing

```bash
# Create integration testing script: validate_integration.sh
cat > validate_integration.sh << 'EOF'
#!/bin/bash

echo "=== INTEGRATION & PERFORMANCE TESTING ==="
FAILED_EXAMPLES=()

for example_dir in ./examples/*/; do
  example_name=$(basename "$example_dir")
  echo "Integration testing for: $example_name"
  
  cd "$example_dir" || continue
  
  # Test with different Node.js versions (if applicable)
  if [[ -f "package.json" ]] && command -v nvm >/dev/null; then
    echo "Testing with different Node.js versions..."
    for version in 16 18 20; do
      if nvm use $version 2>/dev/null; then
        if ! npm install --silent 2>/dev/null; then
          echo "❌ Failed with Node.js $version"
          FAILED_EXAMPLES+=("$example_name:node$version-compat")
        fi
      fi
    done
  fi
  
  # Performance testing for resource-intensive examples
  if grep -qi "performance\|benchmark\|load\|stress" README.md 2>/dev/null; then
    echo "Running performance validation..."
    
    # Memory usage check
    memory_before=$(free -m | awk 'NR==2{print $3}')
    
    # Run example and measure resource usage
    if [[ -f "package.json" ]] && grep -q '"start"' package.json; then
      timeout 10s npm start &
      pid=$!
      sleep 5
      
      # Check if process is still running (not crashed)
      if ! kill -0 $pid 2>/dev/null; then
        echo "❌ Example crashed during performance test"
        FAILED_EXAMPLES+=("$example_name:performance-crash")
      fi
      
      kill $pid 2>/dev/null
    fi
    
    memory_after=$(free -m | awk 'NR==2{print $3}')
    memory_diff=$((memory_after - memory_before))
    
    if [[ $memory_diff -gt 1000 ]]; then  # More than 1GB
      echo "⚠️  High memory usage detected: ${memory_diff}MB"
      FAILED_EXAMPLES+=("$example_name:high-memory")
    fi
  fi
  
  # Network connectivity testing
  if grep -r "http\|api\|fetch\|request" . --include="*.js" --include="*.py" --include="*.go" | grep -v test | head -1 | grep -q .; then
    echo "Testing network connectivity requirements..."
    
    # Check if example gracefully handles network failures
    # This is a simplified test - in practice, you'd mock network calls
    if ! ping -c 1 google.com >/dev/null 2>&1; then
      echo "⚠️  Example may fail without internet connectivity"
      FAILED_EXAMPLES+=("$example_name:network-dependency")
    fi
  fi
  
  # Security testing
  echo "Running basic security checks..."
  
  # Check for vulnerable dependencies (Node.js)
  if [[ -f "package.json" ]] && command -v npm >/dev/null; then
    if npm audit --audit-level high 2>/dev/null | grep -q "found.*vulnerabilities"; then
      echo "⚠️  High-severity vulnerabilities found in dependencies"
      FAILED_EXAMPLES+=("$example_name:security-vulnerabilities")
    fi
  fi
  
  # Check for insecure configurations
  if grep -r "http://" . --include="*.js" --include="*.py" --include="*.go" | grep -v localhost | grep -v 127.0.0.1 | grep -q .; then
    echo "⚠️  Insecure HTTP URLs found (should use HTTPS)"
    FAILED_EXAMPLES+=("$example_name:insecure-http")
  fi
  
  cd - >/dev/null
  echo "---"
done

if [[ ${#FAILED_EXAMPLES[@]} -gt 0 ]]; then
  echo "❌ Integration testing found issues:"
  printf '%s\n' "${FAILED_EXAMPLES[@]}"
  exit 1
else
  echo "✅ All examples passed integration testing"
fi
EOF

chmod +x validate_integration.sh
./validate_integration.sh
```

### Comprehensive Testing Report Generation

```bash
# Create comprehensive test runner: run_all_tests.sh
cat > run_all_tests.sh << 'EOF'
#!/bin/bash

echo "🚀 COMPREHENSIVE EXAMPLE VALIDATION SUITE"
echo "========================================"

TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
REPORT_FILE="example_validation_report_$TIMESTAMP.md"

# Initialize report
cat > "$REPORT_FILE" << 'REPORT_HEADER'
# Example Validation Report

**Generated:** $(date)
**Total Examples:** $(find ./examples -mindepth 1 -maxdepth 1 -type d | wc -l)

## Executive Summary

| Test Layer | Status | Issues Found |
|------------|--------|--------------|
REPORT_HEADER

# Function to run test and capture results
run_test_layer() {
  local test_name=$1
  local script_name=$2
  
  echo "Running $test_name..."
  if ./"$script_name" > "${test_name// /_}.log" 2>&1; then
    echo "✅ $test_name: PASSED"
    echo "| $test_name | ✅ PASSED | 0 |" >> "$REPORT_FILE"
  else
    echo "❌ $test_name: FAILED"
    issues=$(grep "❌\|⚠️" "${test_name// /_}.log" | wc -l)
    echo "| $test_name | ❌ FAILED | $issues |" >> "$REPORT_FILE"
    
    # Append detailed failures to report
    echo -e "\n### $test_name Failures\n" >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"
    grep "❌\|⚠️" "${test_name// /_}.log" >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"
  fi
}

# Run all test layers
run_test_layer "Static Analysis" "validate_examples_static.sh"
run_test_layer "Dependency Validation" "validate_dependencies.sh"
run_test_layer "Execution Testing" "validate_execution.sh"
run_test_layer "Documentation Testing" "validate_documentation.sh"
run_test_layer "Integration Testing" "validate_integration.sh"

# Generate detailed example status
echo -e "\n## Detailed Example Status\n" >> "$REPORT_FILE"

for example_dir in ./examples/*/; do
  example_name=$(basename "$example_dir")
  
  echo "### $example_name" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
  
  # Gather example metadata
  echo "**Location:** \`$example_dir\`" >> "$REPORT_FILE"
  
  if [[ -f "$example_dir/README.md" ]]; then
    description=$(head -5 "$example_dir/README.md" | grep -v "^#" | head -1)
    echo "**Description:** $description" >> "$REPORT_FILE"
  fi
  
  # Count files and languages
  file_count=$(find "$example_dir" -type f | wc -l)
  languages=$(find "$example_dir" -name "*.js" -o -name "*.py" -o -name "*.go" -o -name "*.rs" -o -name "*.java" | sed 's/.*\.//' | sort -u | tr '\n' ' ')
  
  echo "**Files:** $file_count" >> "$REPORT_FILE"
  echo "**Languages:** $languages" >> "$REPORT_FILE"
  
  # Check status across all test logs
  overall_status="✅ PASSED"
  for log_file in *.log; do
    if grep -q "$example_name.*❌" "$log_file" 2>/dev/null; then
      overall_status="❌ FAILED"
      break
    elif grep -q "$example_name.*⚠️" "$log_file" 2>/dev/null; then
      overall_status="⚠️ WARNING"
    fi
  done
  
  echo "**Status:** $overall_status" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"
done

# Add recommendations
echo -e "\n## Recommendations\n" >> "$REPORT_FILE"

failed_count=$(grep "❌ FAILED" "$REPORT_FILE" | wc -l)
warning_count=$(grep "⚠️" *.log 2>/dev/null | wc -l)

if [[ $failed_count -gt 0 ]]; then
  echo "### Critical Issues ($failed_count)" >> "$REPORT_FILE"
  echo "- Review and fix all failed examples before release" >> "$REPORT_FILE"
  echo "- Consider removing or archiving severely broken examples" >> "$REPORT_FILE"
  echo "- Update documentation for failed examples" >> "$REPORT_FILE"
fi

if [[ $warning_count -gt 0 ]]; then
  echo "### Improvements Needed ($warning_count warnings)" >> "$REPORT_FILE"
  echo "- Address documentation gaps" >> "$REPORT_FILE"
  echo "- Fix security vulnerabilities in dependencies" >> "$REPORT_FILE"
  echo "- Improve error handling and edge cases" >> "$REPORT_FILE"
fi

echo "### General Recommendations" >> "$REPORT_FILE"
echo "- Implement automated testing in CI/CD pipeline" >> "$REPORT_FILE"
echo "- Create example testing templates for new examples" >> "$REPORT_FILE"
echo "- Regular dependency updates and security scanning" >> "$REPORT_FILE"
echo "- Consider containerizing complex examples for consistency" >> "$REPORT_FILE"

echo ""
echo "📊 Testing complete! Report generated: $REPORT_FILE"
echo "📈 Summary:"
echo "   Total Examples: $(find ./examples -mindepth 1 -maxdepth 1 -type d | wc -l)"
echo "   Failed Tests: $failed_count"
echo "   Warnings: $warning_count"

# Clean up log files
rm -f *.log

if [[ $failed_count -gt 0 ]]; then
  exit 1
else
  echo "🎉 All examples are working correctly!"
  exit 0
fi
EOF

chmod +x run_all_tests.sh
```

### Advanced Testing Strategies

#### Container-Based Testing
```bash
# Create Docker-based isolated testing
cat > Dockerfile.example-testing << 'EOF'
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    curl \
    git \
    python3 \
    python3-pip \
    nodejs \
    npm \
    golang-go \
    build-essential

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /workspace
COPY . .

CMD ["./run_all_tests.sh"]
EOF

# Run tests in isolated container
docker build -f Dockerfile.example-testing -t example-tester .
docker run --rm example-tester
```

#### Continuous Integration Integration
```yaml
# .github/workflows/example-validation.yml
name: Validate Examples

on:
  push:
    paths:
      - 'examples/**'
  pull_request:
    paths:
      - 'examples/**'

jobs:
  validate-examples:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [16, 18, 20]
        python-version: [3.8, 3.9, 3.10]
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: ${{ matrix.node-version }}
    
    - name: Setup Python
      uses: actions/setup-python@v4
      with:
        python-version: ${{ matrix.python-version }}
    
    - name: Setup Go
      uses: actions/setup-go@v4
      with:
        go-version: '1.19'
    
    - name: Setup Rust
      uses: actions-rs/toolchain@v1
      with:
        toolchain: stable
    
    - name: Run Example Validation
      run: ./run_all_tests.sh
    
    - name: Upload Test Report
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: example-validation-report
        path: example_validation_report_*.md
```

### Implementation Notes

1. **Test Isolation**: Each test layer is independent and can be run separately
2. **Comprehensive Coverage**: Tests functionality, documentation, security, and performance
3. **Automation Ready**: Scripts are designed for CI/CD integration
4. **Clear Reporting**: Detailed reports with actionable recommendations
5. **Multiple Languages**: Supports Node.js, Python, Go, Rust, and shell scripts
6. **Security Focused**: Includes dependency vulnerability scanning and credential checks
7. **Performance Aware**: Basic performance and resource usage validation
8. **Documentation Driven**: Emphasizes user experience and documentation quality

### Expected Outcomes

After running this validation suite:
- ✅ All examples execute without errors
- ✅ Dependencies are properly documented and installable
- ✅ Documentation is complete and accurate
- ✅ No security vulnerabilities in examples
- ✅ Examples work across different environment versions
- ✅ Performance is acceptable for resource-intensive examples
- ✅ User experience is smooth for new developers

Run the comprehensive test with:
```bash
./run_all_tests.sh
```

This will generate a detailed report showing the status of all examples and provide actionable recommendations for improvements.
