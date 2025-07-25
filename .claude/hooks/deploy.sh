#!/usr/bin/env bash
# Claude Code Hook System Deployment Script
# 
# Automates the installation and configuration of the hook system
# with comprehensive validation and error handling.

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly BOLD='\033[1m'
readonly NC='\033[0m' # No Color

# Configuration
readonly HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CLAUDE_CONFIG_DIR="$HOME/.config/claude"
readonly SETTINGS_FILE="$CLAUDE_CONFIG_DIR/settings.json"
readonly BACKUP_SUFFIX=".backup.$(date +%s)"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_header() {
    echo -e "\n${BOLD}${BLUE}$1${NC}"
    echo -e "${BLUE}$(printf '=%.0s' $(seq 1 ${#1}))${NC}"
}

# Validation functions
check_prerequisites() {
    log_header "Checking Prerequisites"
    
    local missing_deps=()
    
    # Check for required commands
    for cmd in bun node npm; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        else
            log_info "$cmd: $(command -v "$cmd")"
        fi
    done
    
    # Check for optional commands with warnings
    for cmd in nix llm tts_elevenlabs tts_openai tts_pyttsx3; do
        if ! command -v "$cmd" &> /dev/null; then
            log_warning "$cmd not found - related features may not work"
        else
            log_info "$cmd: $(command -v "$cmd")"
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_error "Please install the missing dependencies and try again"
        exit 1
    fi
    
    log_success "All required dependencies found"
}

install_dependencies() {
    log_header "Installing Dependencies"
    
    if [ ! -f "$HOOK_DIR/package.json" ]; then
        log_error "package.json not found in $HOOK_DIR"
        exit 1
    fi
    
    cd "$HOOK_DIR"
    
    log_info "Installing Bun dependencies..."
    if bun install; then
        log_success "Dependencies installed successfully"
    else
        log_error "Failed to install dependencies"
        exit 1
    fi
}

run_tests() {
    log_header "Running Tests"
    
    cd "$HOOK_DIR"
    
    if [ -d "tests" ]; then
        log_info "Running test suite..."
        if bun test --silent; then
            log_success "All tests passed"
        else
            log_warning "Some tests failed - deployment continuing"
            log_warning "Review test output and fix issues if needed"
        fi
    else
        log_warning "No test directory found - skipping tests"
    fi
}

setup_configuration() {
    log_header "Setting Up Configuration"
    
    # Create Claude config directory if it doesn't exist
    if [ ! -d "$CLAUDE_CONFIG_DIR" ]; then
        log_info "Creating Claude config directory: $CLAUDE_CONFIG_DIR"
        mkdir -p "$CLAUDE_CONFIG_DIR"
    fi
    
    # Create settings.json if it doesn't exist
    if [ ! -f "$SETTINGS_FILE" ]; then
        log_info "Creating new settings.json"
        echo '{}' > "$SETTINGS_FILE"
    else
        log_info "Backing up existing settings.json"
        cp "$SETTINGS_FILE" "${SETTINGS_FILE}${BACKUP_SUFFIX}"
    fi
    
    # Generate hook configuration
    local hook_config
    hook_config=$(cat << EOF
{
  "hooks": {
    "notification": {
      "command": "cd $HOOK_DIR && bun index.ts notification"
    },
    "pre_tool_use": {
      "command": "cd $HOOK_DIR && bun index.ts pre_tool_use"
    },
    "post_tool_use": {
      "command": "cd $HOOK_DIR && bun index.ts post_tool_use"
    },
    "user_prompt_submit": {
      "command": "cd $HOOK_DIR && bun index.ts user_prompt_submit"
    },
    "stop": {
      "command": "cd $HOOK_DIR && bun index.ts stop --chat"
    },
    "subagent_stop": {
      "command": "cd $HOOK_DIR && bun index.ts subagent_stop --chat"
    }
  }
}
EOF
)
    
    # Merge with existing settings if they exist
    if command -v jq &> /dev/null; then
        log_info "Merging hook configuration with existing settings"
        local temp_file
        temp_file=$(mktemp)
        jq -s '.[0] * .[1]' "$SETTINGS_FILE" <(echo "$hook_config") > "$temp_file"
        mv "$temp_file" "$SETTINGS_FILE"
    else
        log_warning "jq not found - overwriting settings.json"
        echo "$hook_config" > "$SETTINGS_FILE"
    fi
    
    log_success "Configuration updated: $SETTINGS_FILE"
}

setup_environment() {
    log_header "Setting Up Environment"
    
    # Create .env.example if it doesn't exist
    local env_example="$HOOK_DIR/.env.example"
    if [ ! -f "$env_example" ]; then
        log_info "Creating .env.example"
        cat > "$env_example" << 'EOF'
# Claude Code Hook System Environment Configuration
# Copy this file to .env and configure as needed

# TTS Configuration (optional)
# ELEVENLABS_API_KEY=your_elevenlabs_key_here
# OPENAI_API_KEY=your_openai_key_here

# LLM Configuration (optional)
# ANTHROPIC_API_KEY=your_anthropic_key_here
# CLAUDE_HOOKS_OPENAI_MODEL=gpt-4o-mini
# CLAUDE_HOOKS_ANTHROPIC_MODEL=claude-3-haiku-20240307

# Timeout Configuration (milliseconds)
# CLAUDE_HOOKS_TIMEOUT_GENERAL=60000
# CLAUDE_HOOKS_TIMEOUT_LINTING=120000
# CLAUDE_HOOKS_TIMEOUT_AI=15000
# CLAUDE_HOOKS_TIMEOUT_TTS=10000

# Logging Configuration
# CLAUDE_HOOKS_LOG_LEVEL=info
# CLAUDE_HOOKS_LOGS_DIR=logs
# CLAUDE_HOOKS_MAX_LOG_SIZE=1048576

# Feature Toggles
# CLAUDE_HOOKS_AI_COMPLETION=true
# CLAUDE_HOOKS_TTS_ANNOUNCEMENTS=true
# CLAUDE_HOOKS_TRANSCRIPT_COPY=true
# CLAUDE_HOOKS_LINTING=true

# Security Configuration
# CLAUDE_HOOKS_BLOCK_DANGEROUS=true
# CLAUDE_HOOKS_PROTECT_ENV=true
# CLAUDE_HOOKS_MAX_INPUT_SIZE=1048576
EOF
        log_success "Created .env.example"
    fi
    
    # Create logs directory
    local log_dir="$HOOK_DIR/logs"
    if [ ! -d "$log_dir" ]; then
        log_info "Creating logs directory: $log_dir"
        mkdir -p "$log_dir"
        log_success "Logs directory created"
    fi
    
    # Set appropriate permissions
    log_info "Setting file permissions"
    chmod +x "$HOOK_DIR/index.ts" 2>/dev/null || true
    chmod 755 "$log_dir"
    
    log_success "Environment setup complete"
}

validate_installation() {
    log_header "Validating Installation"
    
    cd "$HOOK_DIR"
    
    # Test help command
    log_info "Testing help command..."
    if bun index.ts --help &> /dev/null; then
        log_success "Help command works"
    else
        log_error "Help command failed"
        return 1
    fi
    
    # Test configuration loading
    log_info "Testing configuration..."
    if bun index.ts --config &> /dev/null; then
        log_success "Configuration loads successfully"
    else
        log_error "Configuration loading failed"
        return 1
    fi
    
    # Test each hook type
    for hook_type in notification pre_tool_use post_tool_use user_prompt_submit; do
        log_info "Testing $hook_type hook..."
        if echo '{"test": "data"}' | timeout 10s bun index.ts "$hook_type" &> /dev/null; then
            log_success "$hook_type hook works"
        else
            log_warning "$hook_type hook test failed - may need configuration"
        fi
    done
    
    log_success "Installation validation complete"
}

show_next_steps() {
    log_header "Next Steps"
    
    echo "🎉 Claude Code Hook System deployed successfully!"
    echo
    echo "📁 Installation Directory: $HOOK_DIR"
    echo "⚙️  Configuration File: $SETTINGS_FILE" 
    echo "📝 Environment Template: $HOOK_DIR/.env.example"
    echo "📊 Logs Directory: $HOOK_DIR/logs"
    echo
    echo "🔧 Optional Configuration:"
    echo "  1. Copy .env.example to .env and configure API keys"
    echo "  2. Customize timeouts and features in environment variables"
    echo "  3. Install optional TTS tools (tts_elevenlabs, tts_openai, tts_pyttsx3)"
    echo "  4. Install llm CLI tool for AI completion messages"
    echo
    echo "🧪 Testing Commands:"
    echo "  bun index.ts --help        # Show help"
    echo "  bun index.ts --config      # Show configuration" 
    echo "  bun index.ts --stats       # Show performance stats"
    echo "  bun test                   # Run test suite"
    echo
    echo "🚀 The hooks are now active in Claude Code!"
    echo "   Start a new Claude Code session to see them in action."
}

cleanup_on_error() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_error "Deployment failed with exit code $exit_code"
        
        # Restore settings backup if it exists
        if [ -f "${SETTINGS_FILE}${BACKUP_SUFFIX}" ]; then
            log_info "Restoring settings backup"
            mv "${SETTINGS_FILE}${BACKUP_SUFFIX}" "$SETTINGS_FILE"
        fi
        
        log_error "Deployment aborted - system restored to previous state"
    fi
    exit $exit_code
}

main() {
    # Set up error handling
    trap cleanup_on_error ERR
    
    log_header "Claude Code Hook System Deployment"
    log_info "Starting deployment process..."
    log_info "Hook directory: $HOOK_DIR"
    
    check_prerequisites
    install_dependencies
    run_tests
    setup_configuration
    setup_environment
    validate_installation
    show_next_steps
    
    log_success "Deployment completed successfully! 🎉"
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Claude Code Hook System Deployment Script"
        echo
        echo "Usage: $0 [options]"
        echo
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --check        Only check prerequisites"
        echo "  --validate     Only validate existing installation"
        echo
        echo "This script will:"
        echo "  1. Check for required dependencies"
        echo "  2. Install Bun dependencies"  
        echo "  3. Run tests"
        echo "  4. Set up Claude Code configuration"
        echo "  5. Create environment files"
        echo "  6. Validate the installation"
        exit 0
        ;;
    --check)
        check_prerequisites
        exit 0
        ;;
    --validate)
        validate_installation
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac