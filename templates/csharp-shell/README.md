# C# Development Shell Template

A Nix flake template for C# development with .NET 8 SDK and `buildDotnetModule`.

## Features

- .NET 8 SDK development environment
- NuGet package management with Nix
- OmniSharp language server support
- NetCoreDbg debugger
- Example console application with Newtonsoft.Json

## Quick Start

```bash
# Initialize in current directory
nix flake init -t github:conneroisu/dotfiles#csharp-shell

# Enter development shell
nix develop

# Build and run with dotnet
dotnet build src/MyApp.csproj
dotnet run --project src/MyApp.csproj -- arg1 arg2

# Build with Nix
nix build

# Run Nix-built binary
./result/bin/MyApp arg1 arg2
```

## Project Structure

```
.
├── flake.nix           # Nix flake configuration
├── deps.json           # NuGet dependencies for Nix
├── src/
│   ├── MyApp.csproj    # C# project file
│   └── Program.cs      # Main application code
└── .gitignore          # Git ignore rules
```

## Managing Dependencies

### Adding NuGet Packages

1. Edit `src/MyApp.csproj` to add PackageReference
2. Restore packages and regenerate deps.json:
   ```bash
   nix develop -c bash -c "dotnet restore src/MyApp.csproj --packages=packageDir && nuget-to-json packageDir > deps.json && rm -r packageDir"
   ```
3. Rebuild with Nix:
   ```bash
   nix build
   ```

## Development Tools

The development shell includes:

- **dotnet**: .NET 8 SDK for building and running C# applications
- **omnisharp-roslyn**: Language server for IDE support
- **netcoredbg**: Debugger for .NET Core
- **nuget-to-json**: Tool for generating Nix-compatible dependency files

## Customization

### Change .NET Version

Edit `flake.nix` to use a different SDK version:
```nix
dotnet = pkgs.dotnet-sdk_9;  # For .NET 9
dotnet-runtime = pkgs.dotnet-runtime_9;
```

### Multiple Projects

Add additional project files to the `projectFile` attribute or use a solution file:
```nix
projectFile = "src/MySolution.sln";
```

### Publishing

To create a self-contained deployment:
```bash
dotnet publish -c Release -r linux-x64 --self-contained
```

## Troubleshooting

- **Missing dependencies**: Ensure `deps.json` is up to date after adding new NuGet packages
- **Build failures**: Check that the project file path matches in `flake.nix`
- **Runtime errors**: Verify the correct .NET runtime version is specified
