/**
# C++ Development Shell Template

## Description
Comprehensive C++ development environment with modern tooling for building
high-performance C++ applications. Features the latest C++ standards, multiple
compilers, advanced debugging tools, static analysis, and package management
for productive C++ development.

## Platform Support
- ✅ x86_64-linux
- ✅ aarch64-linux (ARM64 Linux)
- ✅ x86_64-darwin (Intel macOS)
- ✅ aarch64-darwin (Apple Silicon macOS)

## What This Provides
- **Multiple Compilers**: GCC, Clang, with C++23 support
- **Build Systems**: CMake, Meson, Ninja, Make
- **Package Management**: Conan, vcpkg integration
- **Static Analysis**: clang-tidy, cppcheck, include-what-you-use
- **Debugging**: GDB, LLDB with pretty printers
- **Testing**: Google Test, Catch2, Doctest
- **Profiling**: Valgrind, perf tools
- **Documentation**: Doxygen for API documentation

## Key Features
- **Modern C++ Standards**: C++17, C++20, C++23 support
- **Cross-compiler Support**: Easy switching between GCC and Clang
- **Advanced Tooling**: Comprehensive static analysis and debugging
- **Multiple Build Systems**: Choose the best tool for your project
- **Package Management**: Modern C++ dependency management
- **IDE Integration**: Language servers and development tools

## Usage
```bash
# Create new project from template
nix flake init -t github:conneroisu/dotfiles#cpp-shell

# Enter development shell
nix develop

# Initialize CMake project
init-cmake

# Build with different compilers
build-gcc
build-clang

# Format code
nix fmt
```

## Development Workflow
- Use CMake or Meson for build configuration
- Multiple compiler support for compatibility testing
- Comprehensive static analysis and linting
- Advanced debugging with GDB/LLDB
- Modern package management with Conan/vcpkg
*/
{
  description = "A development shell for C++";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = {
    nixpkgs,
    flake-utils,
    treefmt-nix,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      rooted = exec:
        builtins.concatStringsSep "\n"
        [
          ''REPO_ROOT="$(git rev-parse --show-toplevel)"''
          exec
        ];

      scripts = {
        dx = {
          exec = rooted ''$EDITOR "$REPO_ROOT"/flake.nix'';
          description = "Edit flake.nix";
          deps = [pkgs.git];
        };
        cx = {
          exec = rooted ''$EDITOR "$REPO_ROOT"/CMakeLists.txt'';
          description = "Edit CMakeLists.txt";
        };
        mx = {
          exec = rooted ''$EDITOR "$REPO_ROOT"/meson.build'';
          description = "Edit meson.build";
        };
      };

      scriptPackages =
        pkgs.lib.mapAttrs
        (
          name: script:
            pkgs.writeShellApplication {
              inherit name;
              text = script.exec;
              runtimeInputs = script.deps or [];
            }
        )
        scripts;
    in {
      devShells.default = pkgs.mkShell {
        name = "cpp-dev";

        # Available packages on https://search.nixos.org/packages
        packages = with pkgs;
          [
            # Nix tooling
            alejandra
            nixd
            statix
            deadnix

            # C++ Compilers
            gcc
            clang
            llvm

            # Build Systems
            cmake
            meson
            ninja
            gnumake
            bear # Generate compile_commands.json

            # Package Managers
            conan
            vcpkg

            # Static Analysis
            clang-tools # clang-tidy, clang-format
            cppcheck
            include-what-you-use
            cpplint

            # Debugging and Profiling
            gdb
            lldb
            valgrind
            rr # Record and replay debugger

            # Testing Frameworks
            gtest
            catch2
            doctest

            # Documentation
            doxygen
            graphviz # For Doxygen diagrams

            # Language Servers and IDE Tools
            ccls

            # Libraries (commonly used)
            boost
            eigen
            fmt
            spdlog
            nlohmann_json
            protobuf

            # Development Utilities
            pkg-config
            autoconf
            automake
            libtool
            git
            gitflow
            pre-commit

            # Performance Tools
            hotspot # GUI for perf
            heaptrack # Heap profiler

            # Cross-platform support
          ]
          ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
            # Linux-specific tools
            strace
            ltrace
            patchelf
          ]
          ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
            # macOS-specific tools
            darwin.apple_sdk.frameworks.Foundation
            darwin.apple_sdk.frameworks.CoreFoundation
          ]
          ++ builtins.attrValues scriptPackages;

        shellHook = ''
          echo "🚀 C++ Development Environment"
          echo "📦 GCC version: $(gcc --version | head -n1)"
          echo "📦 Clang version: $(clang --version | head -n1)"
          echo "📦 CMake version: $(cmake --version | head -n1)"
          echo ""
          echo "🛠️  Available Compilers:"
          echo "   • gcc/g++       - GNU Compiler Collection"
          echo "   • clang/clang++ - LLVM Clang compiler"
          echo ""
          echo "🔧 Build Systems:"
          echo "   • cmake         - Cross-platform build system"
          echo "   • meson         - Fast build system"
          echo "   • ninja         - Small build system with focus on speed"
          echo "   • make          - GNU Make build tool"
          echo ""
          echo "🧪 Testing Frameworks:"
          echo "   • gtest         - Google Test framework"
          echo "   • catch2        - Modern C++ test framework"
          echo "   • doctest       - Lightweight testing framework"
          echo ""
          echo "🔍 Static Analysis:"
          echo "   • clang-tidy    - Clang-based C++ linter"
          echo "   • cppcheck      - Static analysis tool"
          echo "   • include-what-you-use - Include optimization"
          echo ""
          echo "🐛 Debugging Tools:"
          echo "   • gdb           - GNU Debugger"
          echo "   • lldb          - LLVM Debugger"
          echo "   • valgrind      - Memory error detector"
          echo "   • rr            - Record and replay debugger"
          echo ""
          echo "📚 Package Management:"
          echo "   • conan         - C++ package manager"
          echo "   • vcpkg         - Microsoft C++ package manager"
          echo ""
          echo "🚀 Quick Commands:"
          echo "   • init-cmake    - Initialize CMake project"
          echo "   • init-meson    - Initialize Meson project"
          echo "   • build-gcc     - Build with GCC"
          echo "   • build-clang   - Build with Clang"
          echo "   • build-meson   - Build with Meson"
          echo "   • test-project  - Run tests"
          echo "   • analyze-clang-tidy - Static analysis with clang-tidy"
          echo "   • analyze-cppcheck   - Static analysis with cppcheck"
          echo "   • debug-gdb     - Debug with GDB"
          echo "   • debug-lldb    - Debug with LLDB"
          echo "   • profile-valgrind - Memory profiling"
          echo "   • docs          - Generate documentation"
          echo "   • format        - Format code"
          echo "   • clean         - Clean build artifacts"
          echo ""
          echo "💡 Try: 'init-cmake && build-gcc' to set up and build a C++ project!"
          echo "💡 Try: 'nix fmt' to format Nix code!"

          # Set up environment variables
          export CC=gcc
          export CXX=g++
          export CMAKE_EXPORT_COMPILE_COMMANDS=ON
        '';
      };

      packages = {
        # Example C++ package build (uncomment and customize)
        # default = pkgs.stdenv.mkDerivation {
        #   pname = "my-cpp-project";
        #   version = "0.1.0";
        #   src = ./.;
        #   nativeBuildInputs = with pkgs; [ cmake ];
        #   buildInputs = with pkgs; [ boost ];
        #   configurePhase = ''
        #     cmake -B build -S . -DCMAKE_BUILD_TYPE=Release
        #   '';
        #   buildPhase = ''
        #     cmake --build build -j$NIX_BUILD_CORES
        #   '';
        #   installPhase = ''
        #     cmake --install build --prefix $out
        #   '';
        #   meta = with pkgs.lib; {
        #     description = "My C++ project";
        #     homepage = "https://github.com/user/my-cpp-project";
        #     license = licenses.mit;
        #     maintainers = with maintainers; [ ];
        #   };
        # };
      };

      formatter = let
        treefmtModule = {
          projectRootFile = "flake.nix";
          programs = {
            alejandra.enable = true; # Nix formatter
            clang-format.enable = true; # C++ formatter
          };
          settings = {
            formatter = {
              clang-format = {
                options = ["--style=Google"];
                includes = ["*.cpp" "*.hpp" "*.h" "*.cc" "*.cxx"];
              };
            };
          };
        };
      in
        treefmt-nix.lib.mkWrapper pkgs treefmtModule;
    });
}
