# OCaml Development Shell

A comprehensive Nix flake for OCaml development with modern tooling and best practices.

## Features

🐪 **OCaml 5.3.0** - Latest OCaml compiler with multicore support
🔨 **Dune 3.19** - Modern build system for OCaml
🎨 **OCamlformat** - Consistent code formatting
🧠 **Language Server** - OCaml LSP for IDE integration
📚 **Rich Library Ecosystem** - Pre-configured with popular libraries
🧪 **Testing Frameworks** - Alcotest and QCheck included
📖 **Documentation** - ODocs for generating documentation

## Quick Start

### Using Nix Flakes

```bash
# Enter the development shell
nix develop

# Build the project  
build

# Run the main CLI application
dune exec ocaml_template

# Run the examples
run-example

# Build installable packages
nix build

# Run the built binary
./result/bin/ocaml_template
```

### Using Traditional Nix

```bash
# Enter the development shell
nix-shell

# Or use direnv for automatic shell activation
echo "use flake" > .envrc
direnv allow
```

## Available Commands

Once in the development shell, you have access to these convenient commands:

| Command | Description |
|---------|-------------|
| `build` | Build your project (`dune build`) |
| `test` | Run tests (`dune runtest`) |
| `repl` | Start REPL with project loaded (`dune utop`) |
| `fmt` | Format code with ocamlformat |
| `docs` | Generate documentation with odoc |
| `clean` | Clean build artifacts |
| `run-example` | Run the simple example program |
| `dx` | Edit flake.nix |
| `ox` | Edit dune-project |

## Included Tools

### Core Development
- **OCaml 5.3.0** - The OCaml compiler and runtime
- **Dune** - Build system and project manager
- **opam** - Package manager (for external dependencies)
- **findlib** - Library manager

### Editor Integration
- **OCaml LSP Server** - Language server protocol support
- **Merlin** - Context-sensitive completion and navigation
- **OCamlformat** - Code formatter with consistent style
- **OCP Indent** - Intelligent indentation

### Libraries Included
- **Base & Stdio** - Jane Street's enhanced standard library
- **Core** - Industrial-strength alternative standard library
- **Lwt** - Cooperative threading library
- **Cmdliner** - Command-line argument parsing
- **Yojson** - JSON processing library
- **Logs** - Logging framework

### Testing & Documentation
- **Alcotest** - Lightweight testing framework
- **QCheck** - Property-based testing
- **OUnit2** - Unit testing framework
- **ODocs** - Documentation generation

### PPX Extensions
- **ppx_deriving** - Code generation from type definitions
- **ppx_jane** - Jane Street's PPX collection
- **ppx_inline_test** - Inline test definitions
- **ppx_expect** - Expectation-based testing

## Project Structure

The template includes a complete project structure:

```
ocaml_template/
├── dune-project              # Project configuration & dependencies
├── .ocamlformat             # Code formatting configuration
├── lib/                     # Library code
│   ├── dune                # Library build configuration
│   └── ocaml_template.ml   # Main library with modules:
│                           #   - Math (fibonacci, primes)
│                           #   - Json_utils (JSON handling)
│                           #   - Async_utils (Lwt examples)
│                           #   - Logger (structured logging)
├── bin/                    # Executable applications
│   ├── dune               # Binary build configuration
│   └── main.ml           # Main CLI application
├── examples/              # Usage examples
│   ├── dune              # Example build configuration
│   └── simple_example.ml # Demonstrates library features
└── test/                 # Test suite (temporarily simplified)
    ├── dune             # Test build configuration
    └── test_ocaml_template.ml # Unit & property-based tests
```

## Configuration Files

### Development Configuration
- **`.ocamlformat`** - Automatic code formatting configuration
- **`.envrc`** - Direnv integration for automatic shell activation  
- **`.gitignore`** - Comprehensive ignore patterns for OCaml development

### AI Development Assistant Integration
- **`.cursorrules`** - Cursor IDE rules for OCaml development
- **`CLAUDE.md`** - Claude AI development assistance guide
- **`AGENTS.md`** - Multi-agent AI workflow patterns  
- **`GEMINI.md`** - Google Gemini AI integration guide

### Code Formatting (`.ocamlformat`)
```
version = 0.27.0
profile = default
margin = 100
indent = 2
break-cases = fit-or-vertical
```

### AI Assistant Configuration
The project includes comprehensive AI assistant integration:
- **Cursor IDE**: Optimized rules for OCaml development with modern tooling
- **Claude AI**: Detailed project context and coding standards
- **Multi-Agent**: Workflows for coordinated AI assistance
- **Google Gemini**: Large context utilization strategies

These configurations ensure consistent, high-quality AI-assisted development.

## Development Workflow

1. **Start Development**:
   ```bash
   nix develop
   init-project  # if starting from scratch
   ```

2. **Write Code**:
   - Edit files in `lib/`, `bin/`, `test/`
   - Use your favorite editor with OCaml LSP support

3. **Build and Test**:
   ```bash
   build        # Compile your project
   test         # Run tests
   fmt          # Format code
   ```

4. **Interactive Development**:
   ```bash
   repl         # Start utop with your project loaded
   ```

5. **Documentation**:
   ```bash
   docs         # Generate HTML documentation
   ```

## IDE Integration

### VS Code
Install the "OCaml Platform" extension for:
- Syntax highlighting
- IntelliSense completion
- Error diagnostics
- Formatting on save

### Vim/Neovim
Configure your LSP client to use `ocamllsp`.

### Emacs
Use `tuareg-mode` with `merlin` for OCaml development.

## Adding Dependencies

### Using Dune
Add dependencies to your `dune-project`:

```lisp
(package
 (name my_project)
 (depends 
   ocaml 
   dune 
   base 
   stdio
   lwt          ; Add new dependencies here
   cohttp-lwt-unix))
```

### Using opam (for external packages)
```bash
opam install lwt cohttp-lwt-unix
```

## Building Packages

The template includes ready-to-use Nix package definitions:

### Main Package (default)
```bash
nix build                    # Builds complete project with CLI and examples
./result/bin/ocaml_template  # Run the main CLI
./result/bin/simple_example  # Run the examples
```

### Library Only  
```bash
nix build .#lib             # Builds only the library component
```

### Examples Package
```bash  
nix build .#examples        # Builds library + examples
```

The packages are defined in `flake.nix` with:
- Full dependency management
- Proper OCaml ecosystem integration
- Cross-platform support (Linux, macOS)
- Metadata and documentation

## Examples

### Running the Examples

```bash
# In development shell
run-example

# Or with nix build
nix build && ./result/bin/simple_example
```

Output:
```
=== OCaml Template Examples ===

1. Basic Greetings:
   Hello, Alice!
   Bonjour, Bob!

2. Math Functions:
   Fibonacci sequence (first 10): 0, 1, 1, 2, 3, 5, 8, 13, 21, 34
   Prime numbers up to 50: 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47

3. JSON Handling:
   { "name": "Alice", "age": 25, "email": "alice@example.com" }
   { "name": "Bob", "age": 30, "email": null }

4. Logging Example:
   [INFO] This is an info message
   [WARNING] This is a warning
```

### Main CLI Application

```bash
# Build and run
build && dune exec ocaml_template

# Or use nix build
nix build && ./result/bin/ocaml_template
```

The CLI demonstrates:
- Mathematical computations (Fibonacci, prime numbers)
- JSON serialization/deserialization
- Structured logging
- Modern OCaml patterns

## Troubleshooting

### Common Issues

1. **Opam not initialized**: The shell will attempt to initialize opam automatically
2. **Missing dependencies**: Add them to your `dune-project` file
3. **Format conflicts**: Run `fmt` to apply consistent formatting

### Getting Help

- OCaml Manual: https://ocaml.org/manual/
- Dune Documentation: https://dune.readthedocs.io/
- Jane Street Libraries: https://github.com/janestreet
- OCaml Discourse: https://discuss.ocaml.org/

Happy OCaml coding! 🐪