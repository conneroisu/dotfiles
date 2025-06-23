# Split Commits Workflow

## Instructions for Claude Code Agent

When making changes to a codebase, follow this git workflow to create clean, organized commits by splitting changes into logical, independent commits:

### Workflow Steps

1. **Create a Feature Branch**
   - Create a new branch from the current branch: `git checkout -b feature/descriptive-name`
   - Use a descriptive branch name that reflects the overall changes being made

2. **Analyze Changes for Logical Grouping**
   - Review all pending changes using `git status` and `git diff`
   - Identify logical groups of changes that can be committed independently
   - Group changes by:
     - **Feature additions** - New functionality or capabilities
     - **Bug fixes** - Corrections to existing functionality
     - **Refactoring** - Code restructuring without changing behavior
     - **Documentation updates** - README, comments, API docs
     - **Configuration changes** - Settings, environment files, build configs
     - **Test additions/updates** - Unit tests, integration tests
     - **Dependencies** - Package updates, new libraries
     - **Performance improvements** - Optimizations
     - **Security fixes** - Vulnerability patches
     - **UI/UX changes** - Frontend styling, user experience

3. **Handle Generated Files Before Committing**
   - Check for generated files that shouldn't be committed:
     - Build artifacts (`dist/`, `build/`, `target/`, `bin/`)
     - Dependencies (`node_modules/`, `vendor/`, `.venv/`)
     - Compiled files (`*.pyc`, `__pycache__/`, `*.class`)
     - IDE files (`.vscode/`, `.idea/`, `*.swp`)
     - OS files (`.DS_Store`, `Thumbs.db`)
     - Log files (`*.log`, `logs/`)
   - Update `.gitignore` if needed before staging any files
   - Use selective `git add` for specific files rather than `git add .` if .gitignore is incomplete

4. **Create Split Commits in Logical Order**
   - Stage and commit each logical group separately
   - **Recommended commit order:**
     1. Configuration/setup changes (so other commits can build on them)
     2. Dependencies and package updates
     3. Core functionality/feature additions
     4. Bug fixes
     5. Refactoring
     6. Tests
     7. Documentation
   - Use `git add` to stage specific files for each commit
   - Ensure each commit:
     - Is self-contained and doesn't break functionality
     - Has a clear, descriptive commit message
     - Contains only related changes
     - Can be understood independently

5. **Commit Message Format**
   - Use clear, imperative mood commit messages
   - Format: `type: brief description`
   - **Types:**
     - `feat:` - New feature
     - `fix:` - Bug fix
     - `refactor:` - Code refactoring
     - `docs:` - Documentation
     - `test:` - Tests
     - `config:` - Configuration changes
     - `deps:` - Dependency updates
     - `perf:` - Performance improvements
     - `security:` - Security fixes
     - `style:` - Code style/formatting
   - **Examples:**
     - `feat: add user authentication system`
     - `fix: resolve null pointer exception in payment processing`
     - `refactor: extract common validation logic into utility class`
     - `docs: update API documentation for new endpoints`
     - `test: add unit tests for user service`
     - `config: update database connection settings`
     - `deps: upgrade React to version 18.2`

6. **Merge Back to Original Branch**
   - Switch back to the original branch: `git checkout <original-branch>`
   - Merge the feature branch: `git merge feature/descriptive-name`
   - Delete the feature branch: `git branch -d feature/descriptive-name`

### Commit Independence Guidelines

- **Independent commits**: Each commit should work on its own without requiring other commits in the same branch
- **Avoid dependencies**: Structure commits so they don't depend on each other when possible
- **Logical ordering**: If dependencies exist, ensure commits are ordered logically (dependencies first)
- **Atomic changes**: Each commit should represent one complete, logical change
- **Buildable state**: Each commit should leave the codebase in a buildable/runnable state

### Splitting Strategies

**By File Type:**
- Separate commits for different file types (JS, CSS, HTML, tests)
- Good for changes that touch multiple areas

**By Feature Area:**
- Authentication changes
- Database schema changes  
- API endpoint changes
- Frontend UI changes

**By Change Type:**
- All bug fixes in one commit
- All new features in separate commits
- All refactoring in one commit

### Pre-Commit Checklist for Each Split

1. **Review staged files**: `git diff --cached`
2. **Verify independence**: Ensure commit works on its own
3. **Check for generated files**: Don't commit build artifacts
4. **Test functionality**: Run relevant tests if possible
5. **Review commit message**: Clear and descriptive

### Example Splitting Scenario

**Original changes include:**
- New user registration API endpoint
- Updated database schema
- Frontend registration form
- Input validation utilities
- Unit tests for registration
- Updated API documentation

**Split into commits:**
1. `config: add database migration for user registration`
2. `feat: add input validation utilities`
3. `feat: implement user registration API endpoint`
4. `feat: create user registration frontend form`
5. `test: add unit tests for user registration functionality`
6. `docs: update API documentation for registration endpoints`

### Benefits of Split Commits

- **Easier code review**: Reviewers can understand each change separately
- **Better rollback capability**: Can revert specific features without affecting others
- **Cleaner git history**: Easier to understand project evolution
- **Improved debugging**: `git bisect` works better with atomic commits
- **Enhanced collaboration**: Team members can understand changes more easily

### When Not to Split

- Changes are too tightly coupled to separate
- The overhead of splitting outweighs the benefits
- Working on a personal project where history doesn't matter
- Hotfixes that need to be deployed immediately

### Error Recovery

If commits are in wrong order or need adjustment:
- Use `git rebase -i HEAD~n` to reorder/edit commits
- Use `git reset --soft HEAD~n` to uncommit and re-stage
- Use `git commit --amend` to modify the last commit message

### Notes

- Always test that each individual commit doesn't break the build
- Use `git log --oneline` to verify commit history looks clean
- Consider using conventional commit format for consistency
- Document any complex splitting decisions in commit messages
