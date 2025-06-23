# Single Commit with Generated Files Handling

## Instructions for Claude Code Agent

When making changes to a codebase, follow this git workflow to create a clean commit while properly handling generated files and builds:

### Workflow Steps

1. **Create a Feature Branch**
   - Create a new branch from the current branch: `git checkout -b feature/descriptive-name`
   - Use a descriptive branch name that reflects the changes being made

2. **Analyze Files for Generated Content**
   - Review all pending changes using `git status`
   - Identify files that are generated or built automatically:
     - Build artifacts (`dist/`, `build/`, `target/`, `bin/`)
     - Compiled files (`.class`, `.o`, `.pyc`, `__pycache__/`)
     - Package files (`node_modules/`, `vendor/`, `.venv/`)
     - IDE files (`.vscode/`, `.idea/`, `*.swp`)
     - OS files (`.DS_Store`, `Thumbs.db`)
     - Log files (`*.log`, `logs/`)
     - Temporary files (`tmp/`, `temp/`, `*.tmp`)
     - Generated documentation (`docs/_build/`, `site/`)
     - Lock files that shouldn't be committed (`package-lock.json` in some cases)

3. **Handle Generated Files - Choose One Approach:**

   **Option A: Update .gitignore (Preferred)**
   - Check if `.gitignore` exists and is comprehensive
   - Add any missing patterns for generated files to `.gitignore`
   - Common patterns to add:
     ```
     # Build artifacts
     dist/
     build/
     target/
     bin/
     
     # Dependencies
     node_modules/
     vendor/
     .venv/
     
     # IDE files
     .vscode/
     .idea/
     *.swp
     *.swo
     
     # OS files
     .DS_Store
     Thumbs.db
     
     # Logs
     *.log
     logs/
     
     # Temporary files
     tmp/
     temp/
     *.tmp
     
     # Compiled files
     *.class
     *.o
     *.pyc
     __pycache__/
     ```
   - Then use `git add .` to add all non-ignored files

   **Option B: Selective File Addition**
   - Use `git add` with specific file patterns or individual files
   - Add only source files, configuration files, and documentation
   - Examples:
     - `git add src/` (add source directory)
     - `git add *.py *.js *.html *.css` (add specific file types)
     - `git add README.md package.json requirements.txt` (add specific files)
   - Avoid using `git add .` if .gitignore is incomplete

4. **Create Single Commit**
   - Stage the appropriate files using chosen method above
   - Create one comprehensive commit with all changes
   - Use a clear, descriptive commit message that summarizes all changes
   - Format: `feat: description of all changes made`
   - Example: `feat: implement user authentication with JWT tokens and password hashing`

5. **Merge Back to Original Branch**
   - Switch back to the original branch: `git checkout <original-branch>`
   - Merge the feature branch: `git merge feature/descriptive-name`
   - Delete the feature branch: `git branch -d feature/descriptive-name`

### File Detection Guidelines

**Always Check These Common Generated Patterns:**
- Any directory named: `dist`, `build`, `target`, `bin`, `out`, `output`
- Node.js: `node_modules/`, `package-lock.json` (sometimes)
- Python: `__pycache__/`, `*.pyc`, `.venv/`, `venv/`, `.pytest_cache/`
- Java: `target/`, `*.class`, `.gradle/`
- .NET: `bin/`, `obj/`, `packages/`
- Go: `vendor/` (if using dep)
- Rust: `target/`
- IDE files: `.vscode/`, `.idea/`, `*.sublime-*`
- OS files: `.DS_Store`, `Thumbs.db`, `desktop.ini`

### Pre-Commit Checklist

1. **Review git status**: `git status` to see all changes
2. **Check for generated files**: Look for patterns above
3. **Update .gitignore**: Add missing patterns if needed
4. **Verify staging**: Use `git diff --cached` to review staged changes
5. **Ensure no sensitive data**: Check for API keys, passwords, tokens
6. **Test build**: Ensure the commit doesn't break functionality

### Commit Message Guidelines

- Use imperative mood: "Add feature" not "Added feature"
- Be descriptive but concise
- Include context about what was accomplished
- Examples:
  - `feat: add user registration and login functionality`
  - `fix: resolve database connection timeout issues`
  - `refactor: restructure authentication module for better maintainability`
  - `docs: update API documentation with new endpoints`

### Error Recovery

If you accidentally commit generated files:
1. `git reset --soft HEAD~1` (undo commit, keep changes staged)
2. Update `.gitignore` with missing patterns
3. `git reset` (unstage all files)
4. `git add .` (re-stage only non-ignored files)
5. `git commit -m "your message"` (create new commit)

### Notes

- Always prioritize updating `.gitignore` over selective adding
- When in doubt, err on the side of caution and don't commit questionable files
- Use `git diff --name-only` to list changed files for review
- Consider using `git add -p` for interactive staging if unsure about specific changes
