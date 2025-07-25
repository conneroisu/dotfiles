#!/usr/bin/env bash
#
# Pre-commit Hook for Claude Code Hook System
# Ensures code quality and security before commits
#
# Tiger Style principles:
# - Safety: Multiple validation layers prevent bad code from entering the repo
# - Performance: Fast checks that provide immediate feedback  
# - Developer Experience: Clear error messages and automatic fixes where possible

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Configuration
readonly HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly MAX_WARNINGS=0
readonly TIMEOUT=120 # 2 minutes timeout for all checks

log_info() {
    echo -e "${BLUE}ℹ${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}✅${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1" >&2
}

log_error() {
    echo -e "${RED}❌${NC} $1" >&2
}

# Check if we're in the correct directory
cd "$HOOK_DIR" || {
    log_error "Failed to change to hook directory: $HOOK_DIR"
    exit 1
}

# Verify required tools are available
check_dependencies() {
    local missing_deps=()
    
    if ! command -v bun >/dev/null 2>&1; then
        missing_deps+=("bun")
    fi
    
    if [ ! -f "./node_modules/.bin/eslint" ]; then
        missing_deps+=("eslint (run: bun install)")
    fi
    
    if [ ! -f "./node_modules/.bin/prettier" ]; then
        missing_deps+=("prettier (run: bun install)")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log_info "Run 'bun install' to install missing dependencies"
        exit 1
    fi
}

# Run TypeScript type checking
run_typescript_check() {
    log_info "Running TypeScript type check..."
    
    if timeout "$TIMEOUT" bun x tsc --noEmit --project ./tsconfig.json; then
        log_success "TypeScript type check passed"
        return 0
    else
        log_error "TypeScript type check failed"
        log_info "Fix type errors before committing"
        return 1
    fi
}

# Run ESLint with strict rules
run_eslint_check() {
    log_info "Running ESLint with strict rules (max warnings: $MAX_WARNINGS)..."
    
    # Get list of TypeScript files to check
    local ts_files
    if ! ts_files=$(git diff --cached --name-only --diff-filter=ACM | grep '\.ts$' || true); then
        log_warning "No TypeScript files to lint"
        return 0
    fi
    
    if [ -z "$ts_files" ]; then
        log_warning "No TypeScript files to lint"
        return 0
    fi
    
    log_info "Checking files: $(echo "$ts_files" | tr '\n' ' ')"
    
    if timeout "$TIMEOUT" ./node_modules/.bin/eslint $ts_files --max-warnings "$MAX_WARNINGS" --format=compact; then
        log_success "ESLint check passed"
        return 0
    else
        log_error "ESLint check failed"
        log_info "Run 'bun run lint:fix' to automatically fix issues"
        return 1
    fi
}

# Run Prettier format check
run_prettier_check() {
    log_info "Running Prettier format check..."
    
    # Get list of TypeScript files to check
    local ts_files
    if ! ts_files=$(git diff --cached --name-only --diff-filter=ACM | grep '\.ts$' || true); then
        log_warning "No TypeScript files to format check"
        return 0
    fi
    
    if [ -z "$ts_files" ]; then
        log_warning "No TypeScript files to format check"
        return 0
    fi
    
    if timeout "$TIMEOUT" ./node_modules/.bin/prettier --check $ts_files; then
        log_success "Prettier format check passed"
        return 0
    else
        log_error "Prettier format check failed"
        log_info "Run 'bun run format' to fix formatting issues"
        return 1
    fi
}

# Run security audit
run_security_audit() {
    log_info "Running security audit..."
    
    # Run bun audit but don't fail on moderate/low severity issues
    if timeout "$TIMEOUT" bun audit --audit-level high; then
        log_success "Security audit passed"
        return 0
    else
        log_warning "Security audit found issues"
        log_info "Review security vulnerabilities before committing"
        # Don't fail the commit for security issues, just warn
        return 0
    fi
}

# Validate hook configuration files
validate_hook_config() {
    log_info "Validating hook configuration..."
    
    local config_errors=0
    
    # Check tsconfig.json
    if [ ! -f "./tsconfig.json" ]; then
        log_error "Missing tsconfig.json"
        ((config_errors++))
    elif ! bun x tsc --noEmit --project ./tsconfig.json --dry 2>/dev/null; then
        log_error "Invalid tsconfig.json"
        ((config_errors++))
    fi
    
    # Check ESLint config
    if [ ! -f "./.eslintrc.cjs" ]; then
        log_error "Missing .eslintrc.cjs"
        ((config_errors++))
    fi
    
    # Check Prettier config  
    if [ ! -f "./.prettierrc.json" ]; then
        log_error "Missing .prettierrc.json"
        ((config_errors++))
    fi
    
    if [ $config_errors -eq 0 ]; then
        log_success "Hook configuration validation passed"
        return 0
    else
        log_error "Hook configuration validation failed ($config_errors errors)"
        return 1
    fi
}

# Main execution
main() {
    log_info "🔍 Running pre-commit checks for Claude Code Hook System"
    log_info "Following Tiger Style principles: Safety, Performance, Developer Experience"
    echo
    
    local exit_code=0
    local checks_passed=0
    local total_checks=5
    
    # Run all checks
    if check_dependencies; then
        ((checks_passed++))
        log_success "Dependencies check passed"
    else
        exit_code=1
        log_error "Dependencies check failed"
    fi
    
    echo
    
    if validate_hook_config; then
        ((checks_passed++))
    else
        exit_code=1
    fi
    
    echo
    
    if run_typescript_check; then
        ((checks_passed++))
    else
        exit_code=1
    fi
    
    echo
    
    if run_eslint_check; then
        ((checks_passed++))
    else
        exit_code=1
    fi
    
    echo
    
    if run_prettier_check; then
        ((checks_passed++))
    else
        exit_code=1
    fi
    
    echo
    
    # Security audit (non-blocking)
    run_security_audit
    
    echo
    
    # Summary
    if [ $exit_code -eq 0 ]; then
        log_success "🎉 All pre-commit checks passed! ($checks_passed/$total_checks)"
        log_info "Code meets Tiger Style quality standards"
    else
        log_error "💥 Pre-commit checks failed! ($checks_passed/$total_checks passed)"
        log_info "Fix the issues above before committing"
        echo
        log_info "Quick fixes:"
        log_info "  • Format code: bun run format"
        log_info "  • Fix linting: bun run lint:fix" 
        log_info "  • Type check: bun run typecheck"
    fi
    
    exit $exit_code
}

# Run main function
main "$@"