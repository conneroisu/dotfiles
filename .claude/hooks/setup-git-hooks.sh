#!/usr/bin/env bash
#
# Setup Git Hooks for Claude Code Hook System
# Installs pre-commit hooks to ensure code quality
#

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly GIT_HOOKS_DIR="$SCRIPT_DIR/.git/hooks"

# Colors
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✅${NC} $1"
}

main() {
    log_info "Setting up Git hooks for Claude Code Hook System..."
    
    # Check if we're in a git repository
    if [ ! -d "$SCRIPT_DIR/.git" ]; then
        log_info "Not in a git repository - hooks will be available for manual use"
        log_success "Pre-commit script is available at: ./pre-commit.sh"
        return 0
    fi
    
    # Create hooks directory if it doesn't exist
    mkdir -p "$GIT_HOOKS_DIR"
    
    # Install pre-commit hook
    cat > "$GIT_HOOKS_DIR/pre-commit" << 'EOF'
#!/usr/bin/env bash
# Git pre-commit hook for Claude Code Hook System
# Automatically runs code quality checks

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
exec "$HOOK_DIR/pre-commit.sh"
EOF
    
    chmod +x "$GIT_HOOKS_DIR/pre-commit"
    
    log_success "Git pre-commit hook installed successfully!"
    log_info "The hook will run automatically before each commit"
    log_info "To bypass the hook temporarily, use: git commit --no-verify"
    
    # Test the hook
    log_info "Testing the pre-commit hook..."
    if "$SCRIPT_DIR/pre-commit.sh"; then
        log_success "Pre-commit hook test passed!"
    else
        log_info "Pre-commit hook test failed - but installation completed"
        log_info "Run 'bun install' and fix any issues before committing"
    fi
}

main "$@"