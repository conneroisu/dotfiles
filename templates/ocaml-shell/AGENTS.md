# AGENTS.md - AI Agent Integration Guide

This document provides comprehensive guidance for AI agents and coding assistants working with this OCaml project template. It defines workflows, best practices, and standardized approaches for consistent AI-assisted development.

## Table of Contents
- [Quick Reference](#quick-reference)
- [Agent Capabilities & Roles](#agent-capabilities--roles)
- [Workflow Patterns](#workflow-patterns)
- [Code Generation Guidelines](#code-generation-guidelines)
- [Integration Points](#integration-points)
- [Quality Assurance](#quality-assurance)

## Quick Reference

### Essential Commands
```bash
# Environment
nix develop                    # Enter dev shell
build && test                  # Build and test
fmt                           # Format code

# Package Management  
nix build                     # Create packages
./result/bin/ocaml_template   # Test main CLI
```

### Project Structure
```
lib/ocaml_template.ml         # Core library (4 modules)
bin/main.ml                   # CLI application
examples/simple_example.ml    # Usage examples  
test/test_ocaml_template.ml   # Test suite
dune-project                  # Dependencies & metadata
```

### Code Patterns
```ocaml
(* Standard opens *)
open Base
open Stdio

(* Error handling *)
Result.t, Option.t, Or_error.t

(* Async with Lwt *)
let open Lwt.Syntax in
let* data = fetch () in
```

## Agent Capabilities & Roles

### Code Assistant Agent
**Primary Responsibilities:**
- Generate OCaml code following project conventions
- Implement new features in existing modules
- Create comprehensive unit tests
- Maintain code style consistency

**Key Skills Required:**
- OCaml syntax and idioms
- Jane Street Base/Core libraries
- Dune build system
- Functional programming patterns

### Testing Agent  
**Primary Responsibilities:**
- Generate unit tests with Alcotest
- Create property-based tests with QCheck
- Design test scenarios for edge cases
- Maintain test coverage

**Testing Patterns:**
```ocaml
(* Unit test template *)
let test_function_name () =
  let actual = Module.function_name input in
  let expected = expected_output in
  Alcotest.(check test_type) "description" expected actual

(* Property-based test template *)
let property_test =
  QCheck.Test.make ~count:100 ~name:"property description"
    QCheck.Gen.generator
    (fun input -> property_holds input)
```

### Documentation Agent
**Primary Responsibilities:**
- Generate OCaml documentation comments
- Create usage examples
- Update README sections
- Maintain API documentation consistency

**Documentation Standards:**
```ocaml
(** Brief description of the function.

    Longer description with details about behavior,
    parameters, and return values.
    
    @param param_name Description of parameter
    @return Description of return value
    @raises Exception Description of when it's raised
    
    Example:
    {[
      let result = my_function 42 "hello" in
      Printf.printf "Result: %s\n" result
    ]}
*)
```

### Build & Integration Agent
**Primary Responsibilities:**
- Manage Dune configuration
- Update Nix flake dependencies
- Handle cross-platform compatibility
- Optimize build performance

**Build Patterns:**
```lisp
; Library dune file
(library
 (public_name project_name.module_name)
 (name module_name)
 (libraries base stdio dependency_name)
 (preprocess (pps ppx_jane)))

; Executable dune file  
(executable
 (public_name executable_name)
 (name main)
 (libraries project_name base stdio)
 (preprocess (pps ppx_jane)))
```

## Workflow Patterns

### Feature Development Workflow

1. **Analysis Phase**
   - Review existing code structure
   - Identify integration points
   - Plan module dependencies
   - Design error handling strategy

2. **Implementation Phase**
   ```ocaml
   (* Add to existing module or create new section *)
   module New_feature = struct
     type t = { ... }
     
     let create params =
       (* Validate inputs *)
       match validate params with
       | Ok validated -> Ok { ... }
       | Error msg -> Error msg
       
     let process feature_instance =
       (* Implementation with proper error handling *)
   end
   ```

3. **Testing Phase**
   - Add unit tests for all public functions
   - Include property-based tests for mathematical operations
   - Test error conditions and edge cases
   - Verify integration with existing modules

4. **Integration Phase**
   - Update CLI if feature is user-facing
   - Add examples to demonstrate usage
   - Update documentation
   - Verify Nix build still works

### Bug Fix Workflow

1. **Reproduction**
   - Create minimal test case reproducing the issue
   - Identify the root cause in the code
   - Understand impact on dependent modules

2. **Fix Implementation**
   - Implement minimal fix maintaining existing behavior
   - Ensure fix doesn't break existing functionality
   - Add regression tests

3. **Validation**
   - Run full test suite
   - Test edge cases around the fix
   - Verify no performance regressions

### Refactoring Workflow

1. **Safety First**
   - Ensure comprehensive test coverage before refactoring
   - Identify all usage points of code being refactored
   - Plan backward compatibility strategy

2. **Incremental Changes**
   - Make small, focused changes
   - Test after each change
   - Maintain external API stability

3. **Documentation Updates**
   - Update internal documentation
   - Revise examples if necessary
   - Update comments and type annotations

## Code Generation Guidelines

### Module Structure
```ocaml
(* Module header with documentation *)
(** Brief module description.
    
    Detailed description of module purpose and usage patterns.
*)

(* Type definitions *)
type config = {
  field1 : string;
  field2 : int option;
} [@@deriving show, sexp_of]

(* Exception definitions *)
exception Invalid_config of string

(* Private helper functions *)
let _validate_field field =
  (* Implementation *)

(* Public interface functions *)
let create_config ~field1 ?field2 () =
  match _validate_field field1 with
  | true -> Ok { field1; field2 }
  | false -> Error (Invalid_config "field1 validation failed")
```

### Error Handling Patterns
```ocaml
(* Use Result.t for operations that can fail *)
let safe_operation input =
  try
    let result = potentially_failing_operation input in
    Ok result
  with
  | Specific_exception msg -> Error ("Specific error: " ^ msg)
  | exn -> Error ("Unexpected error: " ^ (Exn.to_string exn))

(* Chain operations with Result.bind or let* *)
let complex_operation input =
  let open Result.Let_syntax in
  let%bind validated = validate_input input in
  let%bind processed = process_data validated in
  let%bind saved = save_result processed in
  return saved
```

### Async Programming Patterns
```ocaml
(* Standard Lwt pattern *)
let async_fetch_and_process url =
  let open Lwt.Syntax in
  Lwt.catch
    (fun () ->
      let* response = Http.get url in
      let* data = Http.body response in
      let* result = process_async data in
      Lwt.return (Ok result))
    (fun exn ->
      let error_msg = Exn.to_string exn in
      Logs.err (fun m -> m "Async operation failed: %s" error_msg);
      Lwt.return (Error error_msg))
```

## Integration Points

### CLI Integration
When adding features that should be exposed via CLI:

```ocaml
(* Add to bin/main.ml *)
let new_command_handler arg1 arg2 =
  (* Setup logging *)
  Logger.setup_logging (Some Logs.Info);
  
  (* Call library functions *)
  match Library.new_feature arg1 arg2 with
  | Ok result -> 
    Printf.printf "Success: %s\n" (Library.result_to_string result)
  | Error msg ->
    Printf.eprintf "Error: %s\n" msg;
    exit 1

(* If using Cmdliner, add command definition *)
let new_command =
  let open Cmdliner in
  let arg1 = Arg.(required & pos 0 (some string) None & info []) in
  let arg2 = Arg.(value & opt string "default" & info ["arg2"]) in
  Term.(const new_command_handler $ arg1 $ arg2),
  Term.info "new-command" ~doc:"Description of new command"
```

### Library API Design
```ocaml
(* Design composable APIs *)
module My_feature = struct
  type t
  type config = { ... }
  type error = 
    | Invalid_input of string
    | Processing_failed of string
    | Network_error of string
  
  val create : config -> (t, error) result
  val process : t -> input -> (output, error) result  
  val to_json : t -> Yojson.Basic.t
  val from_json : Yojson.Basic.t -> (t, error) result
end
```

### Testing Integration
```ocaml
(* Add to test/test_ocaml_template.ml *)
module My_feature_tests = struct
  let test_create_valid () =
    let config = My_feature.{ ... } in
    match My_feature.create config with
    | Ok instance -> Alcotest.pass
    | Error _ -> Alcotest.fail "Expected successful creation"
  
  let test_create_invalid () =
    let invalid_config = My_feature.{ ... } in
    match My_feature.create invalid_config with
    | Ok _ -> Alcotest.fail "Expected creation to fail"
    | Error (Invalid_input _) -> Alcotest.pass
    | Error _ -> Alcotest.fail "Expected Invalid_input error"
    
  let property_test_commutative =
    QCheck.Test.make ~count:100 ~name:"operation is commutative"
      QCheck.(pair int int)
      (fun (a, b) -> My_feature.combine a b = My_feature.combine b a)
end

(* Add to main test suite *)
let my_feature_tests = [
  "create_valid", `Quick My_feature_tests.test_create_valid;
  "create_invalid", `Quick My_feature_tests.test_create_invalid;
]
```

## Quality Assurance

### Code Review Checklist
Before submitting generated code, verify:

- [ ] **Compilation**: Code compiles without warnings
- [ ] **Tests**: All tests pass, new functionality has tests
- [ ] **Formatting**: Code follows .ocamlformat standards
- [ ] **Documentation**: Public functions are documented
- [ ] **Error Handling**: Errors are handled appropriately
- [ ] **Performance**: No obvious performance regressions
- [ ] **Compatibility**: Works with existing module interfaces
- [ ] **Examples**: Usage examples are updated if relevant

### Common Anti-Patterns to Avoid

1. **Overuse of Exceptions**
   ```ocaml
   (* BAD *)
   let parse_int str =
     int_of_string str  (* Can raise exception *)
   
   (* GOOD *)
   let parse_int str =
     try Ok (int_of_string str)
     with Failure _ -> Error "Invalid integer"
   ```

2. **Ignoring Error Cases**
   ```ocaml
   (* BAD *)
   let process_file filename =
     let content = In_channel.read_all filename in
     parse_content content
   
   (* GOOD *)  
   let process_file filename =
     try
       let content = In_channel.read_all filename in
       Ok (parse_content content)
     with
     | Sys_error msg -> Error ("File error: " ^ msg)
   ```

3. **Inefficient List Operations**
   ```ocaml
   (* BAD - O(n²) complexity *)
   let reverse_append lst1 lst2 =
     (List.rev lst1) @ lst2
   
   (* GOOD - O(n) complexity *)
   let reverse_append lst1 lst2 =
     List.fold_left lst1 ~init:lst2 ~f:(fun acc x -> x :: acc)
   ```

### Performance Considerations

1. **Tail Recursion**
   ```ocaml
   (* Use tail recursion for large datasets *)
   let rec factorial_tail n acc =
     if n <= 1 then acc
     else factorial_tail (n - 1) (n * acc)
   
   let factorial n = factorial_tail n 1
   ```

2. **Appropriate Data Structures**
   ```ocaml
   (* Use Array for random access *)
   let lookup_table = Array.create ~len:1000 default_value
   
   (* Use List for sequential access *)
   let sequential_data = [item1; item2; item3]
   
   (* Use Map for key-value lookups *)
   let user_database = Map.create (module String)
   ```

3. **Lazy Evaluation**
   ```ocaml
   (* Use Sequence for large datasets *)
   let large_computation input =
     input
     |> Sequence.of_list
     |> Sequence.map ~f:expensive_operation
     |> Sequence.filter ~f:predicate
     |> Sequence.take 10
     |> Sequence.to_list
   ```

### Security Guidelines

1. **Input Validation**
   ```ocaml
   let sanitize_filename filename =
     let forbidden_chars = ['/', '\\', ':', '*', '?', '"', '<', '>', '|'] in
     if List.exists forbidden_chars ~f:(String.contains filename)
     then Error "Filename contains forbidden characters"
     else Ok filename
   ```

2. **Safe String Operations**
   ```ocaml
   let safe_substring str ~pos ~len =
     if pos >= 0 && len >= 0 && pos + len <= String.length str
     then Ok (String.sub str ~pos ~len)
     else Error "Invalid substring parameters"
   ```

---

This guide should be consulted by AI agents before making significant changes to the codebase. When patterns evolve, update this document to maintain consistency across all AI-assisted development.