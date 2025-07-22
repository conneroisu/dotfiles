# CLAUDE.md - Claude AI Development Assistant Guide

This file provides specific guidance for Claude AI when working with this OCaml template project. It contains project context, coding standards, and development workflows to ensure consistent and high-quality assistance.

## Project Overview

This is a **modern OCaml project template** designed for professional development with:

### Core Technologies
- **OCaml 5.3.0** - Latest compiler with multicore support
- **Dune 3.19** - Modern build system with workspace management
- **Nix Flakes** - Reproducible development environment and packaging
- **Jane Street ecosystem** - Base, Core, Stdio libraries for enhanced standard library

### Key Libraries & Tools
- **Lwt** - Cooperative threading and async programming
- **Yojson** - JSON serialization and parsing
- **Cmdliner** - Command-line argument parsing
- **Logs** - Structured logging with multiple backends
- **Alcotest** - Unit testing framework
- **QCheck** - Property-based testing
- **OCamlformat** - Automatic code formatting
- **Merlin** - IDE integration for completion and navigation
- **ODocs** - Documentation generation

## Project Structure & Architecture

```
ocaml_template/
├── dune-project              # Project metadata and dependencies
├── lib/ocaml_template.ml     # Main library with 4 modules:
│                             #   • Math: fibonacci, prime numbers
│                             #   • Json_utils: JSON handling
│                             #   • Async_utils: Lwt examples
│                             #   • Logger: structured logging
├── bin/main.ml               # CLI application demonstrating features
├── examples/simple_example.ml # Usage examples and demos
├── test/test_ocaml_template.ml # Unit and property-based tests
└── .ocamlformat              # Code formatting configuration
```

## Development Workflow

### Environment Setup
```bash
nix develop                    # Enter development shell
build                         # Build project (alias for dune build)
test                          # Run tests (alias for dune runtest)
fmt                           # Format code (alias for dune build @fmt)
```

### Package Building
```bash
nix build                     # Create installable packages
./result/bin/ocaml_template   # Run main CLI
./result/bin/simple_example   # Run examples
```

## Coding Standards & Best Practices

### OCaml Style Guidelines

#### Code Formatting
- **Indentation**: 2 spaces (configured in .ocamlformat)
- **Line length**: 100 characters maximum
- **Spacing**: Follow .ocamlformat configuration
- **Pattern matching**: Align cases vertically

#### Naming Conventions
- **Modules**: `PascalCase` with underscores for file names (`Json_utils`)
- **Functions**: `snake_case` (`is_prime`, `fetch_data`)
- **Types**: lowercase (`person`, `config_t`)
- **Constants**: `UPPER_CASE` (`DEFAULT_PORT`)
- **Private functions**: prefix with `_` (`_internal_helper`)

#### Library Usage Patterns
```ocaml
(* Always open Base first *)
open Base
open Stdio

(* Use specific opens for other modules *)
open Lwt.Syntax    (* for let* syntax *)
```

### Error Handling Philosophy
1. **Use `Result.t` for operations that can fail**:
   ```ocaml
   let parse_config filename =
     match In_channel.read_all filename with
     | contents -> Ok (parse_contents contents)
     | exception (Sys_error msg) -> Error ("Failed to read: " ^ msg)
   ```

2. **Use `Option.t` for nullable values**:
   ```ocaml
   let find_user_by_id users id =
     List.find users ~f:(fun user -> user.id = id)
   ```

3. **Use `Or_error.t` for detailed error reporting**:
   ```ocaml
   let validate_email email =
     if String.contains email '@'
     then Ok email
     else Or_error.error_string "Invalid email format"
   ```

### Async Programming with Lwt
```ocaml
let async_operation () =
  let open Lwt.Syntax in
  let* data = fetch_remote_data () in
  let* processed = process_data data in
  let* () = save_to_database processed in
  Lwt.return (Ok processed)

(* Always handle timeouts *)
let with_timeout ~seconds operation =
  Lwt.pick [
    operation ();
    (let* () = Lwt_unix.sleep seconds in
     Lwt.fail_with "Operation timed out");
  ]
```

### Testing Patterns
```ocaml
(* Unit tests with Alcotest *)
let test_fibonacci () =
  Alcotest.(check int) "fib(5)" 5 (Math.fibonacci 5);
  Alcotest.(check int) "fib(0)" 0 (Math.fibonacci 0)

(* Property-based tests with QCheck *)
let test_fibonacci_property =
  QCheck.Test.make ~count:100 ~name:"fibonacci monotonic"
    QCheck.Gen.(1 -- 20)
    (fun n -> Math.fibonacci n >= Math.fibonacci (n - 1))
```

## Claude-Specific Instructions

### When Writing Code

1. **Always follow the established patterns** in the existing codebase
2. **Use the same library imports** as existing modules
3. **Maintain consistent error handling** throughout the project
4. **Include appropriate tests** for new functionality
5. **Document public functions** with `(** ... *)` comments

### Code Generation Guidelines

1. **Type Safety First**:
   - Define custom types for domain concepts
   - Use pattern matching exhaustively
   - Avoid `Obj.magic` or unsafe operations
   - Prefer explicit type annotations for clarity

2. **Performance Awareness**:
   - Use tail recursion for list processing
   - Choose appropriate data structures (Array vs List vs Sequence)
   - Be mindful of allocation patterns
   - Consider lazy evaluation with `Core.Sequence` when appropriate

3. **Module Organization**:
   - Group related functions into modules
   - Use module signatures (`.mli` files) for public interfaces
   - Follow the project's module hierarchy
   - Keep modules focused and cohesive

### Common Tasks & Solutions

#### Adding New Functionality
1. **Extend existing modules** rather than creating new ones when logical
2. **Add tests** in `test/test_ocaml_template.ml`
3. **Update examples** in `examples/simple_example.ml` if relevant
4. **Consider CLI integration** in `bin/main.ml` if user-facing

#### Working with JSON
```ocaml
(* Define types first *)
type config = {
  host : string;
  port : int;
  debug : bool;
} [@@deriving show]

(* Create conversion functions *)
let config_to_json { host; port; debug } =
  `Assoc [
    ("host", `String host);
    ("port", `Int port);
    ("debug", `Bool debug);
  ]

let config_from_json = function
  | `Assoc assoc ->
    let open Result.Let_syntax in
    let%bind host = extract_string assoc "host" in
    let%bind port = extract_int assoc "port" in 
    let%bind debug = extract_bool assoc "debug" in
    Ok { host; port; debug }
  | _ -> Error "Expected JSON object"
```

#### Async Operations
```ocaml
let fetch_and_process url =
  let open Lwt.Syntax in
  (* Use proper error handling *)
  Lwt.catch
    (fun () ->
      let* response = Http_client.get url in
      let* data = Http_client.read_body response in
      let processed = process_data data in
      Lwt.return (Ok processed))
    (function
      | Http_client.Connection_failed -> 
        Lwt.return (Error "Connection failed")
      | exn -> 
        Lwt.return (Error (Exn.to_string exn)))
```

### Build System Integration

#### Adding Dependencies
1. **Update `dune-project`** with new dependencies:
   ```lisp
   (depends 
     ocaml dune base stdio
     new-package-name)
   ```

2. **Update Nix flake** if the dependency isn't in nixpkgs:
   ```nix
   propagatedBuildInputs = with pkgs.ocamlPackages; [
     # existing dependencies
     new-package-name
   ];
   ```

3. **Update module `dune` files**:
   ```lisp
   (libraries base stdio new-package-name)
   ```

#### Creating New Executables
```lisp
(executable
 (public_name my-new-tool)
 (name my_new_tool)
 (libraries ocaml_template base stdio)
 (preprocess (pps ppx_jane)))
```

## Debugging & Troubleshooting

### Common Issues
1. **Missing dependencies**: Check `dune-project` and module `dune` files
2. **Build failures**: Run `dune clean` then `dune build`
3. **Test failures**: Run individual tests with `dune exec test/test_ocaml_template.exe`
4. **Formatting issues**: Run `fmt` command or `dune build @fmt --auto-promote`

### Development Tips
1. **Use `dune utop`** for REPL with project loaded
2. **Use `dune exec`** to run executables during development
3. **Use `dune build @doc`** to generate and check documentation
4. **Use `merlin`** for IDE integration (auto-configured)

## Project Goals & Philosophy

This template demonstrates:
- **Modern OCaml practices** suitable for production use
- **Comprehensive tooling integration** for professional development
- **Cross-platform packaging** with Nix
- **Testing best practices** with multiple frameworks
- **Documentation-driven development** with examples and guides

### Quality Standards
- **Code coverage**: Aim for >80% test coverage
- **Documentation**: All public functions documented
- **Performance**: No obvious performance regressions
- **Compatibility**: Support current stable OCaml (5.3.0+)
- **Dependencies**: Minimize external dependencies, prefer well-maintained libraries

### Maintenance Guidelines
- **Keep dependencies updated** but test thoroughly
- **Follow semantic versioning** for releases
- **Maintain backward compatibility** when possible
- **Document breaking changes** clearly
- **Regular security audits** of dependencies

## Reference Resources

- [OCaml Manual](https://ocaml.org/manual/)
- [Dune Documentation](https://dune.readthedocs.io/)
- [Base Library Documentation](https://github.com/janestreet/base)
- [Lwt Manual](https://ocsigen.org/lwt/latest/manual/)
- [Real World OCaml](https://dev.realworldocaml.org/)

---

This guide should be updated as the project evolves. When adding new patterns or practices, document them here for consistency.