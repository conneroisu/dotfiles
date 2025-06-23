# Fix Linting Errors from Nix Environment

## Instructions for Claude Code Agent

Systematically identify, categorize, and fix all linting errors reported by running `nix develop -c lint` in the repository. This command uses the project's flake.nix configuration to run project-relevant linting tools.

### Strategic Approach & Insights

**Linting Philosophy:**
- **Consistency Over Perfection**: Focus on consistent code style across the entire codebase
- **Error vs Warning Triage**: Fix errors first (break builds), then warnings (code quality)
- **Tool-Specific Understanding**: Different linters have different priorities and fix strategies
- **Incremental Improvement**: Fix systematically rather than randomly to avoid introducing new issues
- **Context Preservation**: Maintain code functionality while improving style and quality

**Key Insights:**
1. **Batch Similar Fixes**: Group similar errors (like unused imports) for efficient bulk fixing
2. **Dependency Order**: Fix dependency-related issues before style issues
3. **Configuration vs Code**: Sometimes the linting rules need adjustment, not the code
4. **Performance Impact**: Some fixes can impact performance (e.g., object destructuring)
5. **Team Standards**: Linting should reflect team agreements, not arbitrary preferences

### Workflow Steps

1. **Run Initial Linting Analysis**
2. **Parse and Categorize Errors** 
3. **Create Fix Strategy**
4. **Execute Systematic Fixes**
5. **Verify and Test Changes**
6. **Re-run Linting for Validation**

### Implementation

#### Step 1: Initial Linting Analysis

```bash
# Run linting and capture comprehensive output
echo "🔍 Running initial linting analysis..."

# Create linting report directory
mkdir -p lint-reports
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
LINT_REPORT="lint-reports/lint_analysis_$TIMESTAMP.txt"

# Run linting with full output
echo "Running: nix develop -c lint"
if nix develop -c lint > "$LINT_REPORT" 2>&1; then
  echo "✅ No linting errors found!"
  exit 0
else
  echo "📋 Linting errors found. Analysis saved to: $LINT_REPORT"
fi

# Display summary statistics
echo "📊 Linting Error Summary:"
echo "Total lines of output: $(wc -l < "$LINT_REPORT")"
echo "Error patterns found:"
grep -E "(error|Error|ERROR)" "$LINT_REPORT" | wc -l | xargs echo "  Errors:"
grep -E "(warning|Warning|WARN)" "$LINT_REPORT" | wc -l | xargs echo "  Warnings:"
grep -E "(info|Info|INFO)" "$LINT_REPORT" | wc -l | xargs echo "  Info:"

# Show first 20 errors for immediate context
echo -e "\n🔍 First 20 issues:"
head -20 "$LINT_REPORT"
```

#### Step 2: Parse and Categorize Errors

```bash
# Create error categorization script
cat > categorize_lint_errors.sh << 'EOF'
#!/bin/bash

LINT_REPORT="$1"
if [[ ! -f "$LINT_REPORT" ]]; then
  echo "Usage: $0 <lint-report-file>"
  exit 1
fi

echo "🏷️  CATEGORIZING LINTING ERRORS"
echo "================================"

# Common linting error patterns across different tools
declare -A ERROR_CATEGORIES

# JavaScript/TypeScript (ESLint) errors
ERROR_CATEGORIES["js_unused_vars"]="no-unused-vars|@typescript-eslint/no-unused-vars"
ERROR_CATEGORIES["js_missing_semicolon"]="semi|missing-semicolon"
ERROR_CATEGORIES["js_quotes"]="quotes|@typescript-eslint/quotes"
ERROR_CATEGORIES["js_indent"]="indent|@typescript-eslint/indent"
ERROR_CATEGORIES["js_no_console"]="no-console"
ERROR_CATEGORIES["js_prefer_const"]="prefer-const"
ERROR_CATEGORIES["js_eqeqeq"]="eqeqeq"
ERROR_CATEGORIES["js_import_order"]="import/order|simple-import-sort"

# Python (flake8, pylint, black) errors
ERROR_CATEGORIES["py_import_unused"]="F401|imported but unused"
ERROR_CATEGORIES["py_line_length"]="E501|line too long"
ERROR_CATEGORIES["py_whitespace"]="E20[0-9]|W29[0-9]"
ERROR_CATEGORIES["py_indentation"]="E1[0-9][0-9]|indentation"
ERROR_CATEGORIES["py_blank_lines"]="E30[0-9]"
ERROR_CATEGORIES["py_undefined_name"]="F821|undefined name"
ERROR_CATEGORIES["py_syntax"]="E999|SyntaxError"

# Go (golint, go vet) errors
ERROR_CATEGORIES["go_fmt"]="gofmt|not formatted"
ERROR_CATEGORIES["go_vet"]="go vet|suspicious"
ERROR_CATEGORIES["go_lint"]="golint|should"
ERROR_CATEGORIES["go_ineffassign"]="ineffectual assignment"
ERROR_CATEGORIES["go_unused"]="declared but not used"

# Rust (clippy) errors
ERROR_CATEGORIES["rust_warnings"]="warning:|clippy::"
ERROR_CATEGORIES["rust_unused"]="unused|never read"
ERROR_CATEGORIES["rust_style"]="clippy::style"
ERROR_CATEGORIES["rust_complexity"]="clippy::complexity"

# Create categorized output
for category in "${!ERROR_CATEGORIES[@]}"; do
  pattern="${ERROR_CATEGORIES[$category]}"
  count=$(grep -cE "$pattern" "$LINT_REPORT" 2>/dev/null || echo "0")
  
  if [[ $count -gt 0 ]]; then
    echo "📂 $category: $count issues"
    
    # Create category-specific file
    grep -E "$pattern" "$LINT_REPORT" > "lint-reports/category_$category.txt" 2>/dev/null
    
    # Show first few examples
    echo "   Examples:"
    head -3 "lint-reports/category_$category.txt" | sed 's/^/     /'
    echo ""
  fi
done

# Find uncategorized errors
grep -vE "$(IFS='|'; echo "${ERROR_CATEGORIES[*]}")" "$LINT_REPORT" > "lint-reports/category_uncategorized.txt" 2>/dev/null
uncategorized_count=$(wc -l < "lint-reports/category_uncategorized.txt")
if [[ $uncategorized_count -gt 0 ]]; then
  echo "📂 uncategorized: $uncategorized_count issues"
  echo "   Examples:"
  head -3 "lint-reports/category_uncategorized.txt" | sed 's/^/     /'
fi

echo "📁 Category files created in lint-reports/"
EOF

chmod +x categorize_lint_errors.sh
./categorize_lint_errors.sh "$LINT_REPORT"
```

#### Step 3: Create Fix Strategy

```bash
# Generate fix strategy based on error analysis
cat > create_fix_strategy.sh << 'EOF'
#!/bin/bash

echo "🎯 CREATING LINT FIX STRATEGY"
echo "============================="

# Priority order for fixing (high to low impact)
declare -a FIX_PRIORITY=(
  "py_syntax"           # Syntax errors break builds
  "rust_warnings"       # Rust warnings often indicate real issues  
  "go_vet"             # Go vet finds potential bugs
  "js_eqeqeq"          # Equality issues can cause bugs
  "py_undefined_name"   # Undefined variables cause runtime errors
  "go_unused"          # Unused code cleanup
  "js_unused_vars"     # Unused variables cleanup
  "py_import_unused"   # Unused imports cleanup
  "js_prefer_const"    # const vs let preference
  "js_no_console"      # Remove console.log statements
  "py_line_length"     # Line length formatting
  "js_quotes"          # Quote consistency
  "js_missing_semicolon" # Semicolon consistency
  "py_whitespace"      # Whitespace cleanup
  "py_indentation"     # Indentation fixes
  "py_blank_lines"     # Blank line formatting
  "js_indent"          # JavaScript indentation
  "go_fmt"             # Go formatting
  "rust_style"         # Rust style improvements
  "js_import_order"    # Import organization
)

echo "📋 Fix Strategy (in priority order):"
echo ""

for category in "${FIX_PRIORITY[@]}"; do
  if [[ -f "lint-reports/category_$category.txt" ]] && [[ -s "lint-reports/category_$category.txt" ]]; then
    count=$(wc -l < "lint-reports/category_$category.txt")
    echo "🔧 Priority: $category ($count issues)"
    
    # Generate specific fix commands for each category
    case $category in
      "py_syntax")
        echo "   Strategy: Manual review required - syntax errors need careful analysis"
        ;;
      "js_unused_vars"|"py_import_unused")
        echo "   Strategy: Auto-remove unused imports/variables (verify no side effects)"
        ;;
      "js_prefer_const")
        echo "   Strategy: Auto-fix let→const where variable isn't reassigned"
        ;;
      "js_no_console")
        echo "   Strategy: Remove console.log/warn/error (keep console.info for production)"
        ;;
      "py_line_length")
        echo "   Strategy: Auto-format with black/prettier, manual split for complex lines"
        ;;
      "js_quotes"|"js_missing_semicolon")
        echo "   Strategy: Auto-fix with eslint --fix"
        ;;
      "go_fmt")
        echo "   Strategy: Auto-fix with gofmt"
        ;;
      "py_whitespace"|"py_indentation"|"py_blank_lines")
        echo "   Strategy: Auto-fix with black or autopep8"
        ;;
      *)
        echo "   Strategy: Review and fix manually"
        ;;
    esac
    echo ""
  fi
done

# Create fix execution plan
cat > fix_execution_plan.md << 'PLAN'
# Lint Fix Execution Plan

## Phase 1: Critical Fixes (Build-Breaking)
- [ ] Syntax errors
- [ ] Undefined variables/names
- [ ] Import/compilation errors

## Phase 2: Logic & Bug Prevention
- [ ] Equality operator issues (== vs ===)
- [ ] Go vet warnings
- [ ] Rust clippy warnings

## Phase 3: Code Cleanup
- [ ] Unused variables/imports
- [ ] Console.log removal
- [ ] Dead code removal

## Phase 4: Formatting & Style
- [ ] Auto-format with language tools
- [ ] Indentation consistency
- [ ] Quote style consistency
- [ ] Import organization

## Verification Strategy
1. Run tests after each phase
2. Verify no functional changes
3. Re-run linting to confirm fixes
4. Manual code review for complex changes

PLAN

echo "📄 Execution plan created: fix_execution_plan.md"
EOF

chmod +x create_fix_strategy.sh
./create_fix_strategy.sh
```

#### Step 4: Execute Systematic Fixes

```bash
# Create comprehensive fix execution script
cat > execute_lint_fixes.sh << 'EOF'
#!/bin/bash

echo "🔧 EXECUTING LINT FIXES"
echo "======================="

# Safety checks
if [[ ! -d ".git" ]]; then
  echo "❌ Not in a git repository. Fixes require version control."
  exit 1
fi

# Create backup branch
echo "💾 Creating backup branch..."
BACKUP_BRANCH="lint-fixes-backup-$(date +%Y%m%d_%H%M%S)"
git checkout -b "$BACKUP_BRANCH"
git checkout -

echo "✅ Backup created: $BACKUP_BRANCH"

# Auto-fix functions for different categories
auto_fix_eslint() {
  echo "🔧 Auto-fixing ESLint issues..."
  if command -v npx >/dev/null && [[ -f "package.json" ]]; then
    npx eslint . --fix --ext .js,.ts,.jsx,.tsx 2>/dev/null || true
  fi
}

auto_fix_python() {
  echo "🔧 Auto-fixing Python formatting..."
  if command -v black >/dev/null; then
    black . 2>/dev/null || true
  elif command -v autopep8 >/dev/null; then
    find . -name "*.py" -exec autopep8 --in-place --aggressive --aggressive {} \; 2>/dev/null || true
  fi
  
  # Fix import order
  if command -v isort >/dev/null; then
    isort . 2>/dev/null || true
  fi
}

auto_fix_go() {
  echo "🔧 Auto-fixing Go formatting..."
  if command -v gofmt >/dev/null; then
    find . -name "*.go" -exec gofmt -w {} \; 2>/dev/null || true
  fi
  
  if command -v goimports >/dev/null; then
    find . -name "*.go" -exec goimports -w {} \; 2>/dev/null || true
  fi
}

auto_fix_rust() {
  echo "🔧 Auto-fixing Rust formatting..."
  if command -v rustfmt >/dev/null; then
    cargo fmt 2>/dev/null || true
  fi
}

manual_fix_unused_imports() {
  echo "🔧 Fixing unused imports..."
  
  # JavaScript/TypeScript unused imports
  if [[ -f "lint-reports/category_js_unused_vars.txt" ]]; then
    while IFS= read -r line; do
      if [[ $line =~ ([^:]+):([0-9]+).*'([^']+)'.*is defined but never used ]]; then
        file="${BASH_REMATCH[1]}"
        line_num="${BASH_REMATCH[2]}"
        var_name="${BASH_REMATCH[3]}"
        
        # Remove unused import (simple cases)
        if grep -q "import.*$var_name" "$file"; then
          sed -i "/import.*$var_name.*from/d" "$file" 2>/dev/null || true
        fi
      fi
    done < "lint-reports/category_js_unused_vars.txt"
  fi
  
  # Python unused imports
  if [[ -f "lint-reports/category_py_import_unused.txt" ]]; then
    while IFS= read -r line; do
      if [[ $line =~ ([^:]+):([0-9]+).*'([^']+)'.*imported.but.unused ]]; then
        file="${BASH_REMATCH[1]}"
        line_num="${BASH_REMATCH[2]}"
        import_name="${BASH_REMATCH[3]}"
        
        # Remove unused import line
        sed -i "${line_num}d" "$file" 2>/dev/null || true
      fi
    done < "lint-reports/category_py_import_unused.txt"
  fi
}

fix_console_statements() {
  echo "🔧 Removing console statements..."
  
  # Remove console.log, console.warn, console.error (keep console.info)
  find . -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" | \
    xargs sed -i '/console\.\(log\|warn\|error\)/d' 2>/dev/null || true
}

fix_const_preferences() {
  echo "🔧 Converting let to const where appropriate..."
  
  # This is complex - use ESLint auto-fix for this
  if command -v npx >/dev/null && [[ -f "package.json" ]]; then
    npx eslint . --fix --rule 'prefer-const: error' 2>/dev/null || true
  fi
}

test_after_fixes() {
  echo "🧪 Running tests to verify fixes..."
  
  # Try to run tests in different ways
  if [[ -f "package.json" ]] && grep -q '"test"' package.json; then
    npm test 2>/dev/null || echo "⚠️  npm test failed or no tests"
  elif command -v pytest >/dev/null; then
    pytest --tb=short 2>/dev/null || echo "⚠️  pytest failed or no tests"
  elif [[ -f "go.mod" ]]; then
    go test ./... 2>/dev/null || echo "⚠️  go test failed or no tests"
  elif [[ -f "Cargo.toml" ]]; then
    cargo test 2>/dev/null || echo "⚠️  cargo test failed or no tests"
  else
    echo "ℹ️  No test runner detected, skipping test verification"
  fi
}

# Execute fixes in priority order
echo "📍 Phase 1: Auto-formatting fixes"
auto_fix_eslint
auto_fix_python  
auto_fix_go
auto_fix_rust

echo "📍 Phase 2: Manual cleanup fixes"
manual_fix_unused_imports
fix_console_statements
fix_const_preferences

echo "📍 Phase 3: Test verification"
test_after_fixes

# Check if fixes worked
echo "📍 Phase 4: Verification"
echo "🔍 Re-running linting to check improvements..."

VERIFICATION_REPORT="lint-reports/post_fix_verification_$(date +%Y%m%d_%H%M%S).txt"
if nix develop -c lint > "$VERIFICATION_REPORT" 2>&1; then
  echo "🎉 SUCCESS: All linting errors fixed!"
  rm -f "$VERIFICATION_REPORT"
else
  original_errors=$(wc -l < "$LINT_REPORT")
  remaining_errors=$(wc -l < "$VERIFICATION_REPORT")
  fixed_errors=$((original_errors - remaining_errors))
  
  echo "📊 Fix Results:"
  echo "   Original errors: $original_errors"
  echo "   Remaining errors: $remaining_errors" 
  echo "   Fixed errors: $fixed_errors"
  echo "   Success rate: $(( fixed_errors * 100 / original_errors ))%"
  
  if [[ $remaining_errors -lt $((original_errors / 2)) ]]; then
    echo "✅ Significant improvement achieved!"
  else
    echo "⚠️  Manual intervention needed for remaining errors"
    echo "📄 Remaining issues saved to: $VERIFICATION_REPORT"
  fi
fi

# Show git diff summary
echo ""
echo "📝 Changes made:"
git diff --stat
echo ""
echo "🔄 To review changes: git diff"
echo "💾 To commit changes: git add . && git commit -m 'fix: resolve linting errors'"
echo "🔙 To revert changes: git checkout $BACKUP_BRANCH"
EOF

chmod +x execute_lint_fixes.sh
./execute_lint_fixes.sh
```

#### Step 5: Advanced Fix Strategies

```bash
# Create advanced fixing strategies for complex scenarios
cat > advanced_lint_strategies.sh << 'EOF'
#!/bin/bash

echo "🚀 ADVANCED LINT FIXING STRATEGIES"
echo "=================================="

# Handle complex linting scenarios that require manual intervention
handle_complex_line_length() {
  echo "🔧 Handling complex line length issues..."
  
  # Find long lines that can't be auto-fixed
  if [[ -f "lint-reports/category_py_line_length.txt" ]]; then
    while IFS= read -r line; do
      if [[ $line =~ ([^:]+):([0-9]+):.*line.too.long ]]; then
        file="${BASH_REMATCH[1]}"
        line_num="${BASH_REMATCH[2]}"
        
        # Get the actual long line
        long_line=$(sed -n "${line_num}p" "$file")
        
        # Smart line breaking strategies
        if [[ $long_line =~ .*\.format\(.*\).* ]]; then
          echo "   📝 Format string in $file:$line_num - consider multi-line format"
        elif [[ $long_line =~ .*if.*and.*and.* ]]; then
          echo "   📝 Complex condition in $file:$line_num - consider extracting to variable"
        elif [[ $long_line =~ .*import.* ]]; then
          echo "   📝 Long import in $file:$line_num - consider parentheses grouping"
        fi
      fi
    done < "lint-reports/category_py_line_length.txt"
  fi
}

fix_naming_conventions() {
  echo "🔧 Fixing naming convention issues..."
  
  # Python snake_case fixes
  if grep -r "camelCase" --include="*.py" . >/dev/null 2>&1; then
    echo "   ⚠️  Found camelCase in Python files - consider snake_case conversion"
    
    # Show examples for manual review
    grep -rn "def [a-z][a-zA-Z]*[A-Z]" --include="*.py" . | head -5 | while read -r match; do
      echo "     Example: $match"
    done
  fi
  
  # JavaScript camelCase consistency
  if grep -r "snake_case" --include="*.js" --include="*.ts" . >/dev/null 2>&1; then
    echo "   ⚠️  Found snake_case in JavaScript files - consider camelCase conversion"
  fi
}

optimize_imports() {
  echo "🔧 Optimizing import statements..."
  
  # Group imports by type (standard library, third-party, local)
  if command -v isort >/dev/null; then
    echo "   Running isort with profile configuration..."
    isort . --profile black --force-sort-within-sections 2>/dev/null || true
  fi
  
  # JavaScript import optimization
  if command -v npx >/dev/null && [[ -f "package.json" ]]; then
    if npm list eslint-plugin-simple-import-sort >/dev/null 2>&1; then
      echo "   Running JavaScript import sorting..."
      npx eslint . --fix --rule 'simple-import-sort/imports: error' 2>/dev/null || true
    fi
  fi
}

handle_security_linting() {
  echo "🔐 Addressing security-related linting issues..."
  
  # Check for potential security issues
  security_patterns=(
    "eval\("
    "dangerouslySetInnerHTML"
    "innerHTML.*=.*"
    "document\.write"
    "setTimeout.*string"
    "setInterval.*string"
  )
  
  for pattern in "${security_patterns[@]}"; do
    if grep -r "$pattern" --include="*.js" --include="*.ts" . >/dev/null 2>&1; then
      echo "   ⚠️  Found potentially unsafe pattern: $pattern"
      grep -rn "$pattern" --include="*.js" --include="*.ts" . | head -3 | while read -r match; do
        echo "     Location: $match"
      done
    fi
  done
}

performance_lint_fixes() {
  echo "⚡ Addressing performance-related linting issues..."
  
  # Check for performance anti-patterns
  if grep -r ".*\.map(.*return.*" --include="*.js" --include="*.ts" . | grep -v "=>" >/dev/null 2>&1; then
    echo "   💡 Found map() with return statements - consider arrow functions"
  fi
  
  if grep -r "for.*in.*Object\.keys" --include="*.js" --include="*.ts" . >/dev/null 2>&1; then
    echo "   💡 Found for...in with Object.keys() - consider for...of or Object.entries()"
  fi
}

create_lint_prevention_config() {
  echo "⚙️  Creating lint prevention configuration..."
  
  # Pre-commit hook to prevent future linting issues
  if [[ -d ".git" ]] && ! [[ -f ".git/hooks/pre-commit" ]]; then
    cat > .git/hooks/pre-commit << 'HOOK'
#!/bin/bash
echo "Running pre-commit linting check..."
if ! nix develop -c lint >/dev/null 2>&1; then
  echo "❌ Linting errors detected. Please fix before committing."
  echo "Run: nix develop -c lint"
  exit 1
fi
echo "✅ Linting passed"
HOOK
    
    chmod +x .git/hooks/pre-commit
    echo "   ✅ Pre-commit hook installed"
  fi
  
  # VS Code settings for consistent linting
  if [[ ! -d ".vscode" ]]; then
    mkdir -p .vscode
    
    cat > .vscode/settings.json << 'VSCODE'
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": true,
    "source.organizeImports": true
  },
  "python.formatting.provider": "black",
  "python.linting.enabled": true,
  "python.linting.flake8Enabled": true,
  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[python]": {
    "editor.defaultFormatter": "ms-python.black-formatter"
  }
}
VSCODE
    
    echo "   ✅ VS Code settings configured for consistent linting"
  fi
}

# Execute advanced strategies
handle_complex_line_length
fix_naming_conventions
optimize_imports
handle_security_linting
performance_lint_fixes
create_lint_prevention_config

echo "🎯 Advanced fixing complete!"
EOF

chmod +x advanced_lint_strategies.sh
./advanced_lint_strategies.sh
```

### Key Insights & Best Practices

#### Strategic Insights

1. **Error Hierarchy Understanding**
   - **Syntax errors** block builds → Fix first
   - **Logic errors** (undefined vars, wrong equality) → Fix second  
   - **Style errors** (formatting, quotes) → Fix last
   - **Performance hints** → Consider context before changing

2. **Tool-Specific Behaviors**
   - **ESLint**: Great auto-fix capabilities, but review complex changes
   - **Black/Prettier**: Aggressive formatters that may change semantics
   - **Go fmt**: Very reliable, almost always safe to auto-apply
   - **Clippy**: Often suggests performance improvements worth manual review

3. **Batch Fix Strategies**
   - **Group similar errors**: Fix all "unused imports" together
   - **Language separation**: Handle each language's tools separately
   - **Test frequently**: Run tests after each major batch of fixes

4. **Configuration vs Code Dilemma**
   - Sometimes linting rules are too strict for the project context
   - Consider updating `.eslintrc`, `pyproject.toml`, or similar configs
   - Team agreement on style is more important than arbitrary rules

#### Performance Considerations

- **Large codebases**: Process files in chunks to avoid memory issues
- **Auto-formatters**: Can be slow on large files, consider parallel processing
- **Test runs**: Only run relevant tests after changes, not full suite each time

#### Team Workflow Integration

- **Pre-commit hooks**: Prevent future linting debt
- **CI/CD integration**: Fail builds on linting errors
- **Editor configuration**: Consistent settings across team members
- **Gradual adoption**: Fix incrementally rather than all at once

### Execution Summary

Run the complete linting fix process:

```bash
# Full automated process
nix develop -c lint > initial_report.txt 2>&1
./categorize_lint_errors.sh initial_report.txt
./create_fix_strategy.sh
./execute_lint_fixes.sh
./advanced_lint_strategies.sh

# Final verification
nix develop -c lint
```

### Expected Outcomes

After completion:
- ✅ All or most linting errors resolved
- ✅ Code maintains functionality (verified by tests)
- ✅ Consistent code style across the project
- ✅ Prevention measures in place (pre-commit hooks, editor settings)
- ✅ Clear documentation of remaining manual fixes needed
- ✅ Performance and security improvements where applicable

### Emergency Recovery

If fixes break something:
```bash
# Restore from backup branch
git checkout lint-fixes-backup-[timestamp]
git branch -D [current-branch]
git checkout -b [current-branch]
```

This systematic approach ensures thorough, safe, and effective resolution of all linting issues while maintaining code quality and functionality.
