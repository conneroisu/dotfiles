# C++ Development Shell Template

A comprehensive C++ development environment with modern tooling for building high-performance C++ applications.

## Features

### Multiple Compilers
- **GCC** - GNU Compiler Collection with C++23 support
- **Clang** - LLVM-based compiler with advanced diagnostics
- **Cross-compiler Testing** - Build with both compilers for compatibility

### Modern Build Systems
- **CMake** - Cross-platform build system generator
- **Meson** - Fast, user-friendly build system
- **Ninja** - Small build system focused on speed
- **GNU Make** - Traditional make tool

### Advanced Static Analysis
- **clang-tidy** - Clang-based C++ linter with extensive checks
- **cppcheck** - Static analysis tool for C/C++
- **include-what-you-use** - Include optimization tool
- **cpplint** - Google's C++ style checker

### Debugging and Profiling
- **GDB** - GNU Debugger with pretty printers
- **LLDB** - LLVM Debugger with advanced features
- **Valgrind** - Memory error detection and profiling
- **rr** - Record and replay debugger
- **heaptrack** - Heap memory profiler
- **perf** - Linux performance analysis tools

### Testing Frameworks
- **Google Test** - Google's C++ testing framework
- **Catch2** - Modern C++ test framework
- **Doctest** - Lightweight testing framework

### Package Management
- **Conan** - Modern C++ package manager
- **vcpkg** - Microsoft's C++ package manager

### Documentation
- **Doxygen** - API documentation generator
- **Graphviz** - Diagram generation for Doxygen

## Quick Start

```bash
# Create new project from template
nix flake init -t github:conneroisu/dotfiles#cpp-shell

# Enter development shell
nix develop

# Initialize CMake project
init-cmake

# Build with GCC
build-gcc

# Build with Clang
build-clang

# Run tests
test-project
```

## Available Commands

### Project Initialization
- `init-cmake` - Initialize modern CMake project with C++20
- `init-meson` - Initialize Meson project with C++20
- `cx` - Edit CMakeLists.txt
- `mx` - Edit meson.build

### Building
- `build-gcc` - Build project with GCC compiler
- `build-clang` - Build project with Clang compiler
- `build-meson` - Build project with Meson build system

### Testing
- `test-project` - Run all project tests

### Static Analysis
- `analyze-clang-tidy` - Run clang-tidy analysis
- `analyze-cppcheck` - Run cppcheck analysis
- `analyze-iwyu` - Run include-what-you-use analysis

### Debugging
- `debug-gdb` - Debug executable with GDB
- `debug-lldb` - Debug executable with LLDB
- `profile-valgrind` - Memory profiling with Valgrind

### Documentation and Utilities
- `docs` - Generate API documentation with Doxygen
- `format` - Format code with clang-format
- `clean` - Clean build artifacts
- `dx` - Edit flake.nix

## Project Structure

The template creates a modern C++ project structure:

```
my-cpp-project/
├── src/
│   └── main.cpp          # Main application source
├── include/              # Header files
├── tests/
│   ├── CMakeLists.txt    # Test configuration
│   └── test_main.cpp     # Test files
├── CMakeLists.txt        # CMake configuration
├── meson.build           # Meson configuration (alternative)
├── build-gcc/            # GCC build directory
├── build-clang/          # Clang build directory
├── builddir/             # Meson build directory
└── flake.nix             # Nix development environment
```

## CMake Configuration

The template generates a modern CMake configuration:

```cmake
cmake_minimum_required(VERSION 3.20)
project(MyProject VERSION 1.0.0 LANGUAGES CXX)

# Modern C++ standards
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Compiler-specific optimizations
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    set(CMAKE_CXX_FLAGS_DEBUG "-g -O0 -fsanitize=address,undefined")
    set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG")
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    set(CMAKE_CXX_FLAGS_DEBUG "-g -O0 -fsanitize=address,undefined")
    set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG")
endif()
```

## Compiler Switching

Build with different compilers for testing:

```bash
# Build with GCC
build-gcc

# Build with Clang  
build-clang

# Compare outputs and performance
```

## Static Analysis Workflow

Comprehensive code analysis:

```bash
# Generate compile commands for analysis tools
cmake -B build -S . -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

# Run different analyzers
analyze-clang-tidy    # Clang-based linting
analyze-cppcheck      # Static analysis
analyze-iwyu          # Include optimization
```

## Testing Strategy

Multiple testing frameworks available:

### Google Test
```cpp
#include <gtest/gtest.h>

TEST(BasicTest, TruthTest) {
    EXPECT_TRUE(true);
}

TEST(MathTest, Addition) {
    EXPECT_EQ(2 + 2, 4);
}
```

### Catch2
```cpp
#include <catch2/catch.hpp>

TEST_CASE("Basic test", "[basic]") {
    REQUIRE(2 + 2 == 4);
}
```

## Debugging Features

### GDB with Pretty Printers
```bash
debug-gdb
# Enhanced STL container display
# Smart pointer visualization
# Custom type formatting
```

### LLDB Advanced Features
```bash
debug-lldb
# LLVM-based debugging
# Advanced expression evaluation
# Cross-platform compatibility
```

## Memory Analysis

### Valgrind Integration
```bash
profile-valgrind
# Memory leak detection
# Use-after-free detection
# Double-free detection
# Memory access violations
```

### AddressSanitizer
Built into debug builds automatically:
- Fast memory error detection
- Use-after-free detection
- Buffer overflow detection

## Package Management

### Conan Integration
```bash
# Install Conan packages
conan install boost/1.82.0@

# Use in CMake
find_package(Boost REQUIRED)
target_link_libraries(main Boost::boost)
```

### vcpkg Integration
```bash
# Install vcpkg packages
vcpkg install fmt spdlog nlohmann-json

# Use with CMake toolchain
cmake -B build -S . -DCMAKE_TOOLCHAIN_FILE=/path/to/vcpkg.cmake
```

## Performance Optimization

### Compiler Optimizations
- **Debug**: `-g -O0 -fsanitize=address,undefined`
- **Release**: `-O3 -DNDEBUG -march=native`
- **Profile-guided optimization** support

### Profiling Tools
- **perf** - CPU profiling and analysis
- **heaptrack** - Memory allocation profiling
- **Valgrind Callgrind** - Call graph profiling

## IDE Integration

### Language Servers
- **clangd** - Clang-based language server
- **ccls** - Alternative C++ language server

### Features
- Real-time error checking
- Code completion
- Refactoring support
- Symbol navigation

## Modern C++ Features

The environment supports cutting-edge C++ standards:

### C++20 Features
- Concepts
- Modules (experimental)
- Coroutines
- Ranges library
- std::format

### C++23 Features (where available)
- std::print
- Multidimensional subscript operator
- Static operator()
- Deducing this

## Cross-Platform Support

- ✅ **Linux** (x86_64, ARM64)
- ✅ **macOS** (Intel, Apple Silicon)
- 🔧 **Windows** (via WSL)

### Platform-Specific Tools
- **Linux**: strace, ltrace, perf
- **macOS**: Xcode tools, system frameworks
- **Cross-platform**: Most tools work everywhere

## Best Practices

### Code Organization
```cpp
// Modern header organization
#include <algorithm>  // Standard library first
#include <vector>

#include <boost/algorithm/string.hpp>  // Third-party

#include "my_project/my_header.hpp"    // Project headers
```

### CMake Best Practices
- Use `target_*` commands instead of global variables
- Prefer `find_package()` over manual library handling
- Enable `CMAKE_EXPORT_COMPILE_COMMANDS` for tooling

### Static Analysis Integration
- Run clang-tidy in CI/CD
- Use `.clang-tidy` configuration files
- Integrate with pre-commit hooks

## Troubleshooting

### Common Issues

**Compiler not found**: Check that GCC/Clang are in PATH
**CMake errors**: Ensure CMake 3.20+ is available
**Test failures**: Verify Google Test is properly linked
**Static analysis**: Generate compile_commands.json first

### Performance Tips
- Use Ninja for faster builds
- Enable ccache for compilation caching
- Use multiple build directories for different configurations
- Leverage parallel builds with `-j$(nproc)`

## Advanced Features

### Sanitizers
- AddressSanitizer (ASan)
- UndefinedBehaviorSanitizer (UBSan)
- ThreadSanitizer (TSan)
- MemorySanitizer (MSan)

### Link-Time Optimization
```cmake
set_property(TARGET main PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
```

### Custom Toolchains
Easy switching between different compiler versions and cross-compilation targets.

This template provides everything needed for professional C++ development, from simple programs to complex applications with modern tooling and best practices.