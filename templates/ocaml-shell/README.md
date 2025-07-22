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

# Initialize a new project
init-project

# Build and run
build
dune exec my_project
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
| `init-project` | Create a new OCaml project structure |
| `build` | Build your project (`dune build`) |
| `test` | Run tests (`dune runtest`) |
| `repl` | Start REPL with project loaded (`dune utop`) |
| `fmt` | Format code with ocamlformat |
| `docs` | Generate documentation with odoc |
| `clean` | Clean build artifacts |
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

When you run `init-project`, it creates:

```
my_project/
├── dune-project          # Project configuration
├── lib/                  # Library code
│   ├── dune             # Library build config
│   └── my_project.ml    # Main library module
├── bin/                 # Executable code
│   ├── dune            # Binary build config
│   └── main.ml         # Main executable
└── test/               # Test code
    ├── dune           # Test build config
    └── test_my_project.ml
```

## Configuration Files

The shell automatically creates:

### `.ocamlformat`
```
version = 0.27.0
profile = default
margin = 100
indent = 2
break-cases = fit-or-vertical
```

This provides consistent formatting across your project.

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

Uncomment and customize the package definition in `flake.nix` to build installable packages:

```nix
packages.default = pkgs.ocamlPackages.buildDunePackage {
  pname = "my-project";
  version = "0.1.0";
  src = ./.;
  # ... customize as needed
};
```

Then build with:
```bash
nix build
```

## Examples

### Simple Hello World
```ocaml
(* lib/my_project.ml *)
let greet name = Printf.sprintf "Hello, %s!" name

(* bin/main.ml *)
let () = print_endline (My_project.greet "OCaml")
```

### Using Lwt for Async
```ocaml
open Lwt.Syntax

let fetch_data () =
  let* () = Lwt_unix.sleep 1.0 in
  Lwt.return "Data fetched!"

let () = 
  Lwt_main.run (fetch_data ()) |> print_endline
```

### Property-based Testing
```ocaml
open QCheck

let test_reverse_involution =
  Test.make ~count:1000 ~name:"reverse is involution"
    (list int) (fun l -> List.rev (List.rev l) = l)

let () = QCheck_runner.run_tests [test_reverse_involution]
```

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