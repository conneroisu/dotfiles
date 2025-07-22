# GEMINI.md - Google Gemini AI Integration Guide

This document provides specific guidance for Google Gemini AI when working with this OCaml project template. It includes project context, development patterns, and Gemini-specific optimization strategies for effective AI-assisted OCaml development.

## Project Context for Gemini

### System Overview
This is a **production-ready OCaml project template** featuring:
- **Modern OCaml 5.3.0** with multicore capabilities
- **Jane Street ecosystem** (Base, Core, Stdio) for enhanced functionality
- **Comprehensive tooling** including Dune, Nix, testing frameworks
- **Cross-platform support** via Nix flakes for reproducible environments

### Architecture Summary
```
Core Library (lib/ocaml_template.ml):
├── Math module      → Fibonacci, prime numbers, mathematical utilities
├── Json_utils       → Yojson serialization with type safety
├── Async_utils      → Lwt cooperative threading patterns  
└── Logger           → Structured logging with configurable levels

Applications:
├── CLI (bin/main.ml)           → Command-line interface demo
└── Examples (examples/)        → Usage demonstration and tutorials

Quality Assurance:
├── Tests (test/)               → Alcotest unit + QCheck property tests
├── Documentation (ODocs)       → Auto-generated API documentation
└── Formatting (.ocamlformat)   → Consistent code style
```

## Gemini-Specific Development Guidelines

### Prompt Engineering for OCaml
When interacting with Gemini for OCaml development, structure requests as:

1. **Context Setting**:
   ```
   "Working with OCaml 5.3.0 project using Jane Street Base/Core libraries.
   Current focus: [specific module/feature]
   Requirements: [specific needs]"
   ```

2. **Code Generation Pattern**:
   ```
   "Generate OCaml code that:
   - Uses Base standard library
   - Follows functional programming principles
   - Includes comprehensive error handling with Result.t
   - Has appropriate type annotations
   - Includes unit tests with Alcotest"
   ```

3. **Review and Analysis Pattern**:
   ```
   "Review this OCaml code for:
   - Functional programming best practices
   - Performance implications
   - Error handling completeness
   - Type safety
   - OCaml idioms and conventions"
   ```

### Gemini Optimization Strategies

#### Multimodal Code Understanding
Gemini's multimodal capabilities can be leveraged for:

1. **Visual Code Analysis**:
   - Analyze code structure diagrams
   - Review architectural flowcharts
   - Process error message screenshots
   - Understand build output visualizations

2. **Documentation Integration**:
   - Parse complex API documentation
   - Analyze library usage examples
   - Review coding standard documents
   - Process OCaml language specification excerpts

#### Large Context Utilization
With Gemini's large context window:

1. **Whole-Project Analysis**:
   ```
   Include entire project structure when asking:
   "Analyze the complete codebase for [specific concern]
   considering all modules and their interactions"
   ```

2. **Multi-File Refactoring**:
   ```
   "Refactor the following files simultaneously to maintain
   consistency across the entire module system"
   ```

3. **Comprehensive Testing**:
   ```
   "Generate complete test suite covering all modules
   with both unit tests and integration scenarios"
   ```

## Language Model Specific Patterns

### OCaml Code Generation Templates for Gemini

#### Module Creation Template
```ocaml
(* Request template for new modules *)
"Create a new OCaml module for [functionality] that:

Module Structure:
- Uses Jane Street Base library
- Defines appropriate types with [@@deriving show, sexp]
- Implements error handling with Result.t
- Includes comprehensive documentation
- Follows project naming conventions

Example integration with existing codebase:
[provide relevant code context]

Required functions:
- create : config -> (t, error) result
- process : t -> input -> (output, error) result  
- to_string : t -> string

Include both .ml implementation and .mli interface."
```

#### Error Handling Template
```ocaml
(* Request template for robust error handling *)
"Implement error handling for [specific operation] using:

Error Strategy:
- Custom error types with meaningful variants
- Result.t for operations that can fail
- Or_error.t for detailed error reporting
- Proper error propagation through call chain

Error Types:
type error = 
  | Invalid_input of string
  | Processing_failed of string
  | External_service_error of string

Integration with existing error handling patterns in the codebase."
```

#### Async Programming Template
```ocaml
(* Request template for Lwt async code *)
"Create async OCaml code using Lwt for [operation] that:

Async Requirements:
- Uses Lwt.Syntax for let* binding
- Implements proper timeout handling
- Includes error recovery mechanisms
- Follows cooperative threading best practices

Pattern:
let async_operation params =
  let open Lwt.Syntax in
  Lwt.catch
    (fun () -> 
      let* step1 = async_step1 params in
      let* step2 = async_step2 step1 in
      Lwt.return (Ok step2))
    (fun exn -> 
      Lwt.return (Error (error_from_exception exn)))

Include timeout wrapper and proper resource cleanup."
```

### Testing Strategy with Gemini

#### Comprehensive Test Generation
```
"Generate comprehensive test suite for [module] including:

Unit Tests (Alcotest):
- Happy path scenarios
- Edge cases and boundary conditions  
- Error conditions and failure modes
- Input validation testing

Property-Based Tests (QCheck):
- Mathematical properties (if applicable)
- Invariant checking
- Roundtrip properties (serialization/deserialization)
- Compositional properties

Integration Tests:
- Module interaction testing
- CLI integration (if applicable)
- End-to-end workflow testing

Test Structure:
- Descriptive test names
- Clear assertions with meaningful failure messages
- Proper setup/teardown if needed
- Performance regression tests where relevant"
```

#### Test Data Generation
```
"Generate realistic test data for [domain] that covers:
- Normal use cases
- Edge cases (empty, maximum, minimum values)
- Invalid inputs for negative testing
- Unicode/internationalization concerns
- Performance stress scenarios

Format as OCaml let bindings with appropriate types."
```

## Advanced Gemini Techniques

### Code Review and Analysis

#### Architectural Review
```
"Perform architectural analysis of the OCaml codebase focusing on:

Design Patterns:
- Module organization and dependencies
- Abstraction levels and interfaces
- Data flow and transformation patterns
- Error propagation strategies

Code Quality:
- Functional programming principles adherence
- Performance implications of data structures
- Memory usage patterns
- Concurrent programming safety

Maintainability:
- Code duplication identification
- Refactoring opportunities
- Documentation completeness
- Testing coverage gaps

Provide specific recommendations with code examples."
```

#### Performance Analysis
```
"Analyze OCaml code for performance optimization:

Algorithmic Complexity:
- Time complexity analysis
- Space complexity evaluation
- Tail recursion optimization opportunities
- Data structure choice evaluation

OCaml-Specific Optimizations:
- Allocation pattern analysis
- Boxing/unboxing considerations
- Compilation optimization opportunities
- Memory layout improvements

Benchmarking Strategy:
- Critical path identification
- Measurement methodology
- Performance regression prevention
- Optimization validation approach"
```

### Advanced Code Generation

#### DSL Integration
```
"Create OCaml code that integrates with [external system/API] using:

Integration Requirements:
- Type-safe API binding generation
- Comprehensive error handling for external failures
- Async operation support with proper timeout
- Configuration management
- Logging integration

Generated Code Should Include:
- Client module with connection management
- Request/response type definitions
- Error handling with meaningful error messages
- Usage examples and documentation
- Unit tests with mocking for external dependencies"
```

#### Metaprogramming with PPX
```
"Generate OCaml code using PPX extensions for [specific need]:

PPX Usage:
- [@@deriving show, sexp] for type serialization
- ppx_jane extensions for additional functionality  
- Custom PPX integration if needed

Code Generation:
- Compile-time validation
- Automatic instance generation
- Code transformation patterns
- Integration with existing PPX usage in project"
```

## Quality Assurance for Gemini

### Code Validation Checklist

Before accepting Gemini-generated code, verify:

#### Functional Requirements
- [ ] **Correctness**: Logic implements specified behavior
- [ ] **Completeness**: All edge cases are handled
- [ ] **Integration**: Properly integrates with existing modules
- [ ] **API Consistency**: Follows established patterns

#### OCaml Best Practices
- [ ] **Type Safety**: Leverages OCaml's type system effectively
- [ ] **Error Handling**: Uses Result.t/Option.t appropriately
- [ ] **Performance**: Uses efficient algorithms and data structures
- [ ] **Memory Safety**: Avoids common pitfalls

#### Project Standards
- [ ] **Style Compliance**: Follows .ocamlformat configuration
- [ ] **Documentation**: Public functions have appropriate comments
- [ ] **Testing**: Includes comprehensive tests
- [ ] **Dependencies**: Uses only approved project dependencies

### Common Gemini Pitfalls in OCaml

#### Pattern Matching
```ocaml
(* Gemini might generate non-exhaustive patterns *)
(* PROBLEMATIC *)
let process_option = function
  | Some x -> handle_value x
  (* Missing None case *)

(* CORRECTED *)
let process_option = function
  | Some x -> handle_value x
  | None -> handle_none ()
```

#### Error Propagation
```ocaml
(* Gemini might not properly chain errors *)
(* PROBLEMATIC *)
let complex_operation input =
  let result1 = step1 input in
  let result2 = step2 result1 in
  step3 result2

(* CORRECTED *)
let complex_operation input =
  let open Result.Let_syntax in
  let%bind result1 = step1 input in
  let%bind result2 = step2 result1 in
  step3 result2
```

#### Resource Management
```ocaml
(* Gemini might not handle resource cleanup *)
(* PROBLEMATIC *)
let process_file filename =
  let ic = In_channel.open_text filename in
  let content = In_channel.input_all ic in
  parse_content content

(* CORRECTED *)
let process_file filename =
  In_channel.with_file filename ~f:(fun ic ->
    let content = In_channel.input_all ic in
    parse_content content)
```

## Integration with Other AI Tools

### Multi-Agent Workflows

When using Gemini alongside other AI tools:

1. **Gemini for Architecture**: Use Gemini's large context for high-level design
2. **Claude for Implementation**: Leverage Claude's coding precision for detailed implementation
3. **Cursor for IDE Integration**: Use Cursor for real-time coding assistance
4. **Specialized Tools**: Use domain-specific AI tools for specialized tasks

### Handoff Patterns

#### Gemini → Claude Handoff
```
"Gemini Analysis Complete:

Architecture decisions:
[Gemini's architectural recommendations]

Module interfaces:
[Detailed interface specifications]

Claude Implementation Request:
Please implement the following modules according to the specifications,
ensuring adherence to the project's OCaml conventions and error handling patterns."
```

#### Claude → Gemini Handoff  
```
"Claude Implementation Complete:

Implemented modules:
[List of completed modules with functionality]

Gemini Review Request:
Please review the implementation for:
- Architectural consistency with original design
- Performance implications at scale
- Integration opportunities with other systems
- Documentation and testing completeness"
```

## Continuous Learning and Adaptation

### Feedback Integration

1. **Code Review Feedback**: Incorporate human review feedback into future requests
2. **Performance Metrics**: Use actual performance data to improve optimization suggestions
3. **Bug Reports**: Learn from production issues to improve error handling suggestions
4. **User Patterns**: Adapt to team-specific coding patterns and preferences

### Model Improvement Strategies

1. **Context Refinement**: Continuously improve context provided to Gemini
2. **Template Evolution**: Update templates based on successful patterns
3. **Error Analysis**: Analyze common mistakes and prevent them proactively
4. **Best Practice Updates**: Keep guidance current with OCaml ecosystem evolution

---

This guide should be referenced when using Google Gemini for OCaml development tasks. Update this document as new capabilities and patterns emerge.