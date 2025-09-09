{
  description = "C# development environment with .NET SDK";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        
        dotnet = pkgs.dotnet-sdk_8;
        
        myApp = pkgs.buildDotnetModule rec {
          pname = "my-csharp-app";
          version = "1.0.0";
          
          src = ./.;
          
          projectFile = "src/MyApp.csproj";
          nugetDeps = ./deps.json;
          
          dotnet-sdk = dotnet;
          dotnet-runtime = pkgs.dotnet-runtime_8;
          
          executables = [ "MyApp" ];
        };
      in
      {
        packages = {
          default = myApp;
        };
        
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            dotnet
            omnisharp-roslyn
            netcoredbg
            nuget-to-json
          ];
          
          shellHook = ''
            echo "C# Development Environment"
            echo "------------------------"
            echo "dotnet SDK: ${dotnet.version}"
            echo ""
            echo "Available commands:"
            echo "  dotnet build        - Build the project"
            echo "  dotnet run          - Run the application"
            echo "  dotnet test         - Run tests"
            echo "  dotnet restore      - Restore dependencies"
            echo "  dotnet publish      - Publish the application"
            echo ""
            echo "To regenerate nuget dependencies for Nix:"
            echo "  nuget-to-json src/MyApp.csproj > deps.json"
            echo ""
            echo "To build with Nix:"
            echo "  nix build"
            echo ""
          '';
        };
      });
}