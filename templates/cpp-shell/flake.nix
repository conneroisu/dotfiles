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
        init-cmake = {
          exec = rooted ''
                        cd "$REPO_ROOT"
                        if [ ! -f CMakeLists.txt ]; then
                          cat > CMakeLists.txt << 'EOF'
            cmake_minimum_required(VERSION 3.20)
            project(MyProject VERSION 1.0.0 LANGUAGES CXX)

            # Set C++ standard
            set(CMAKE_CXX_STANDARD 20)
            set(CMAKE_CXX_STANDARD_REQUIRED ON)
            set(CMAKE_CXX_EXTENSIONS OFF)

            # Compiler-specific options
            if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
                set(CMAKE_CXX_FLAGS "-Wall -Wextra -Wpedantic")
                set(CMAKE_CXX_FLAGS_DEBUG "-g -O0 -fsanitize=address,undefined")
                set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG")
            elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
                set(CMAKE_CXX_FLAGS "-Wall -Wextra -Wpedantic")
                set(CMAKE_CXX_FLAGS_DEBUG "-g -O0 -fsanitize=address,undefined")
                set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG")
            endif()

            # Create directories
            file(MAKE_DIRECTORY src include tests)

            # Main executable
            add_executable(main src/main.cpp)
            target_include_directories(main PRIVATE include)

            # Enable testing
            enable_testing()
            add_subdirectory(tests)
            EOF

                          mkdir -p src include tests

                          cat > src/main.cpp << 'EOF'
            #include <iostream>
            #include <vector>
            #include <string>

            int main() {
                std::cout << "Hello, Modern C++!" << std::endl;

                // C++20 features example
                std::vector<std::string> items = {"C++", "is", "awesome"};

                for (const auto& item : items) {
                    std::cout << item << " ";
                }
                std::cout << std::endl;

                return 0;
            }
            EOF

                          cat > tests/CMakeLists.txt << 'EOF'
            # Find required packages for testing
            find_package(GTest QUIET)

            if(GTest_FOUND)
                add_executable(tests test_main.cpp)
                target_link_libraries(tests GTest::gtest_main)
                target_include_directories(tests PRIVATE ../include)

                include(GoogleTest)
                gtest_discover_tests(tests)
            else()
                message(WARNING "Google Test not found. Skipping tests.")
            endif()
            EOF

                          cat > tests/test_main.cpp << 'EOF'
            #include <gtest/gtest.h>

            TEST(BasicTest, TruthTest) {
                EXPECT_TRUE(true);
            }

            TEST(BasicTest, ArithmeticTest) {
                EXPECT_EQ(2 + 2, 4);
                EXPECT_NE(2 + 2, 5);
            }

            int main(int argc, char **argv) {
                ::testing::InitGoogleTest(&argc, argv);
                return RUN_ALL_TESTS();
            }
            EOF

                          echo "CMake project initialized with C++20 support!"
                          echo "Files created:"
                          echo "  - CMakeLists.txt (main build file)"
                          echo "  - src/main.cpp (example main file)"
                          echo "  - tests/ (test directory with Google Test setup)"
                        else
                          echo "CMakeLists.txt already exists"
                        fi
          '';
          deps = with pkgs; [cmake];
          description = "Initialize CMake project with modern C++";
        };
        init-meson = {
          exec = rooted ''
                        cd "$REPO_ROOT"
                        if [ ! -f meson.build ]; then
                          cat > meson.build << 'EOF'
            project('myproject', 'cpp',
              version : '0.1.0',
              default_options : [
                'warning_level=3',
                'cpp_std=c++20',
                'buildtype=debugoptimized'
              ])

            # Compiler setup
            cpp = meson.get_compiler('cpp')

            # Add compiler flags
            add_project_arguments(['-Wall', '-Wextra', '-Wpedantic'], language : 'cpp')

            if get_option('buildtype') == 'debug'
              add_project_arguments(['-fsanitize=address,undefined'], language : 'cpp')
              add_project_link_arguments(['-fsanitize=address,undefined'], language : 'cpp')
            endif

            # Create directories
            run_command('mkdir', '-p', 'src', 'include', 'tests', check: false)

            # Include directories
            inc = include_directories('include')

            # Main executable
            sources = files('src/main.cpp')
            executable('main', sources, include_directories : inc, install : true)

            # Testing
            if get_option('tests')
              gtest_dep = dependency('gtest', main : true, required : false)
              if gtest_dep.found()
                test_sources = files('tests/test_main.cpp')
                test_exe = executable('tests', test_sources,
                                     dependencies : gtest_dep,
                                     include_directories : inc)
                test('basic_test', test_exe)
              endif
            endif
            EOF

                          mkdir -p src include tests

                          cat > src/main.cpp << 'EOF'
            #include <iostream>
            #include <vector>
            #include <string>

            int main() {
                std::cout << "Hello, Modern C++ with Meson!" << std::endl;

                // C++20 features example
                std::vector<std::string> items = {"Meson", "build", "system"};

                for (const auto& item : items) {
                    std::cout << item << " ";
                }
                std::cout << std::endl;

                return 0;
            }
            EOF

                          cat > meson_options.txt << 'EOF'
            option('tests', type : 'boolean', value : true, description : 'Build tests')
            EOF

                          echo "Meson project initialized with C++20 support!"
                        else
                          echo "meson.build already exists"
                        fi
          '';
          deps = with pkgs; [meson];
          description = "Initialize Meson project with modern C++";
        };
        build-gcc = {
          exec = rooted ''
            cd "$REPO_ROOT"
            if [ -f CMakeLists.txt ]; then
              mkdir -p build-gcc
              cd build-gcc
              CC=gcc CXX=g++ cmake .. -DCMAKE_BUILD_TYPE=Debug
              make -j$(nproc)
              echo "Built with GCC successfully!"
            else
              echo "No CMakeLists.txt found. Run 'init-cmake' first."
            fi
          '';
          deps = with pkgs; [gcc cmake gnumake];
          description = "Build project with GCC";
        };
        build-clang = {
          exec = rooted ''
            cd "$REPO_ROOT"
            if [ -f CMakeLists.txt ]; then
              mkdir -p build-clang
              cd build-clang
              CC=clang CXX=clang++ cmake .. -DCMAKE_BUILD_TYPE=Debug
              make -j$(nproc)
              echo "Built with Clang successfully!"
            else
              echo "No CMakeLists.txt found. Run 'init-cmake' first."
            fi
          '';
          deps = with pkgs; [clang cmake gnumake];
          description = "Build project with Clang";
        };
        build-meson = {
          exec = rooted ''
            cd "$REPO_ROOT"
            if [ -f meson.build ]; then
              meson setup builddir --buildtype=debugoptimized
              meson compile -C builddir
              echo "Built with Meson successfully!"
            else
              echo "No meson.build found. Run 'init-meson' first."
            fi
          '';
          deps = with pkgs; [meson ninja];
          description = "Build project with Meson";
        };
        test-project = {
          exec = rooted ''
            cd "$REPO_ROOT"
            if [ -d build-gcc ]; then
              cd build-gcc
              ctest --verbose
            elif [ -d builddir ]; then
              cd builddir
              meson test
            else
              echo "No build directory found. Build the project first."
            fi
          '';
          deps = with pkgs; [cmake gtest];
          description = "Run project tests";
        };
        analyze-clang-tidy = {
          exec = rooted ''
            cd "$REPO_ROOT"
            if [ -f compile_commands.json ]; then
              clang-tidy src/*.cpp include/*.hpp -- -std=c++20
            else
              echo "No compile_commands.json found. Build with CMAKE_EXPORT_COMPILE_COMMANDS=ON"
            fi
          '';
          deps = with pkgs; [clang-tools];
          description = "Run clang-tidy static analysis";
        };
        analyze-cppcheck = {
          exec = rooted ''
            cd "$REPO_ROOT"
            cppcheck --enable=all --std=c++20 --suppress=missingIncludeSystem src/ include/
          '';
          deps = with pkgs; [cppcheck];
          description = "Run cppcheck static analysis";
        };
        analyze-iwyu = {
          exec = rooted ''
            cd "$REPO_ROOT"
            if [ -f compile_commands.json ]; then
              include-what-you-use -p . src/*.cpp
            else
              echo "No compile_commands.json found. Build with CMAKE_EXPORT_COMPILE_COMMANDS=ON"
            fi
          '';
          deps = with pkgs; [include-what-you-use];
          description = "Run include-what-you-use analysis";
        };
        debug-gdb = {
          exec = rooted ''
            cd "$REPO_ROOT"
            if [ -f build-gcc/main ]; then
              gdb build-gcc/main
            elif [ -f build-clang/main ]; then
              gdb build-clang/main
            elif [ -f builddir/main ]; then
              gdb builddir/main
            else
              echo "No executable found. Build the project first."
            fi
          '';
          deps = with pkgs; [gdb];
          description = "Debug with GDB";
        };
        debug-lldb = {
          exec = rooted ''
            cd "$REPO_ROOT"
            if [ -f build-clang/main ]; then
              lldb build-clang/main
            elif [ -f build-gcc/main ]; then
              lldb build-gcc/main
            elif [ -f builddir/main ]; then
              lldb builddir/main
            else
              echo "No executable found. Build the project first."
            fi
          '';
          deps = with pkgs; [lldb];
          description = "Debug with LLDB";
        };
        profile-valgrind = {
          exec = rooted ''
            cd "$REPO_ROOT"
            if [ -f build-gcc/main ]; then
              valgrind --tool=memcheck --leak-check=full --show-leak-kinds=all build-gcc/main
            elif [ -f builddir/main ]; then
              valgrind --tool=memcheck --leak-check=full --show-leak-kinds=all builddir/main
            else
              echo "No executable found. Build the project first."
            fi
          '';
          deps = with pkgs; [valgrind];
          description = "Profile with Valgrind";
        };
        docs = {
          exec = rooted ''
            cd "$REPO_ROOT"
            if [ ! -f Doxyfile ]; then
              doxygen -g
              sed -i 's/PROJECT_NAME           = "My Project"/PROJECT_NAME           = "'"$(basename "$REPO_ROOT")"'"/g' Doxyfile
              sed -i 's/INPUT                  =/INPUT                  = src include/g' Doxyfile
              sed -i 's/RECURSIVE              = NO/RECURSIVE              = YES/g' Doxyfile
              sed -i 's/EXTRACT_ALL            = NO/EXTRACT_ALL            = YES/g' Doxyfile
            fi
            doxygen Doxyfile
            echo "Documentation generated in html/ directory"
          '';
          deps = with pkgs; [doxygen];
          description = "Generate documentation with Doxygen";
        };
        clean = {
          exec = rooted ''
            cd "$REPO_ROOT"
            rm -rf build-gcc build-clang builddir html/ latex/
            echo "Build artifacts cleaned!"
          '';
          description = "Clean build artifacts";
        };
        format = {
          exec = rooted ''
            cd "$REPO_ROOT"
            find src include tests -name "*.cpp" -o -name "*.hpp" -o -name "*.h" | xargs clang-format -i
            echo "Code formatted with clang-format!"
          '';
          deps = with pkgs; [clang-tools];
          description = "Format code with clang-format";
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
            clangd
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
            linuxPackages.perf-tools
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
