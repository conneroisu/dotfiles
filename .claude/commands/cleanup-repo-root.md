# Clean Up Repository Root

## Overview
Intelligently clean up the root directory of a repository by removing unnecessary files while preserving essential project files and anything with git history.

## Instructions

You are tasked with cleaning up the root directory of a repository. Follow these steps carefully to ensure you don't accidentally remove important files:

### Step 1: Analyze Current State
1. **Run `git status`** to see current tracked/untracked files
2. **Run `git ls-files`** to see all files currently tracked by git
3. **Run `ls -la`** to see all files in the root directory, including hidden files
4. **Check for `.gitignore`** patterns that might indicate what should be ignored

### Step 2: Analyze File Modification Dates
Understanding when files were last modified is crucial for safe cleanup:

**Commands to analyze timestamps:**
```bash
# Show files sorted by modification time (newest first)
ls -lt

# Show files sorted by modification time (oldest first)  
ls -ltr

# Show detailed timestamps with find (files modified in last 7 days)
find . -maxdepth 1 -type f -mtime -7 -ls

# Show files older than 30 days
find . -maxdepth 1 -type f -mtime +30 -ls

# Show files modified today
find . -maxdepth 1 -type f -mtime 0 -ls
```

**Modification date safety rules:**
- **Recently modified (< 7 days)**: High risk - likely active work, be very careful
- **Modified 1-4 weeks ago**: Medium risk - could be recent work or experiments  
- **Modified 1-6 months ago**: Lower risk - but check if it's project-related
- **Very old (> 1 year)**: Could be safe to remove if it's clearly temp/build artifacts
- **Very recent (today/yesterday)**: Almost never remove unless obviously temp files

**Special considerations:**
- **Files modified very recently during active development**: NEVER remove
- **Old build artifacts**: Usually safe to remove regardless of age
- **Old configuration files**: Keep even if old - they might be important defaults
- **Old logs**: Usually safe to remove if over a few weeks old
- **Recently touched OS files (`.DS_Store`)**: Safe to remove regardless of date

### Step 3: Identify Essential Files (NEVER DELETE)
Always preserve these types of files:
- **Git files**: `.git/`, `.gitignore`, `.gitattributes`, `.gitmodules`
- **Project config**: `package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`, `composer.json`, etc.
- **Documentation**: `README*`, `LICENSE*`, `CHANGELOG*`, `CONTRIBUTING*`
- **CI/CD**: `.github/`, `.gitlab-ci.yml`, `Jenkinsfile`, etc.
- **Environment**: `.env.example`, `docker-compose.yml`, `Dockerfile`, `flake.nix`, `shell.nix`
- **IDE config**: `.vscode/`, `.idea/` (check if tracked in git first)
- **Any file tracked by git** (from `git ls-files` output)

### Step 4: Identify Candidates for Removal
Look for these types of files that are typically safe to remove:
- **Build artifacts**: `dist/`, `build/`, `target/`, `out/`, `*.o`, `*.exe`
- **Dependencies**: `node_modules/`, `vendor/`, `__pycache__/`, `.pytest_cache/`
- **Temporary files**: `*.tmp`, `*.temp`, `*.log`, `*.swp`, `*~`
- **OS files**: `.DS_Store`, `Thumbs.db`, `desktop.ini`
- **Editor files**: `*.bak`, `*.orig`, `*.rej`
- **Test artifacts**: `coverage/`, `.nyc_output/`, `.coverage`

### Step 5: Safety Checks
Before removing any file:
1. **Check if it's tracked by git**: `git ls-files | grep filename`
2. **Check git history**: `git log --follow -- filename` (if it has history, be very careful)
3. **Analyze modification date**: Use the timestamp analysis from Step 2 - recently modified files are high risk
4. **Check file size**: Large files (>50MB) might be important binaries
5. **Cross-reference with .gitignore**: If it's ignored, it might be safe to remove
6. **Look for patterns**: If removing a directory, ensure it matches common build/temp patterns

**Modification date decision matrix:**
- Recent file + Unknown purpose = ASK USER
- Recent file + Build artifact = Usually safe but confirm
- Old file + Configuration-like = KEEP
- Old file + Log/temp pattern = Usually safe to remove

### Step 6: Safe Removal Process
1. **Start with obviously safe files** (like `.DS_Store`, `node_modules/`)
2. **Move questionable files to a temporary backup location** before deletion
3. **Use `git clean -n`** to see what git considers safe to remove (dry run)
4. **Ask for confirmation** before removing anything that might be important
5. **Document what you're removing** and why

### Step 7: Clean Up Commands
Use these git commands to help with cleanup:
```bash
# See what git would clean (dry run)
git clean -n -d

# Remove untracked files and directories (be careful!)
git clean -f -d

# Remove ignored files too (very careful!)
git clean -f -d -x
```

### Step 8: Final Verification
After cleanup:
1. **Run `git status`** to ensure no tracked files were accidentally removed
2. **Test that the project still builds/runs** if applicable
3. **Check if any essential files are missing**

## Safety Guidelines
- **NEVER remove anything tracked by git without explicit confirmation**
- **When in doubt, ASK** before removing files
- **Create backups** of questionable files before removal
- **Focus on obvious temporary/build files first**
- **Preserve anything that looks like configuration or documentation**

## Example Safe Cleanup Commands
```bash
# Remove common safe targets
rm -rf node_modules/
rm -rf .DS_Store
rm -rf *.log
rm -rf dist/ build/ out/
rm -rf __pycache__/ .pytest_cache/
rm -rf .nyc_output/ coverage/

# Use git clean for untracked files (after careful review)
git clean -f -d
```

Remember: It's better to leave a questionable file than to accidentally remove something important. When in doubt, ask the user for guidance.
