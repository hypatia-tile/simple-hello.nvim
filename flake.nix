{
  description = "Simple Neovim plugin development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Use Lua 5.1 for Neovim compatibility (LuaJIT compatible)
        lua = pkgs.lua5_1;

        # LuaRocks is already set up for lua5_1 in nixpkgs
        luarocks = pkgs.luarocks;

      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            # Lua and LuaRocks
            lua
            luarocks

            # Neovim for testing
            pkgs.neovim

            # Development tools
            pkgs.git
          ];

          shellHook = ''
            echo "=========================================="
            echo "Neovim Plugin Development Environment"
            echo "=========================================="
            echo "Lua version: $(lua -v)"
            echo "LuaRocks version: $(luarocks --version | head -n 1)"
            echo "Neovim version: $(nvim --version | head -n 1)"
            echo ""
            echo "Setting up local LuaRocks environment..."

            # Create local luarocks directory
            mkdir -p .luarocks

            # Set up Lua paths for local rocks using --tree flag
            eval $(luarocks --tree="$PWD/.luarocks" path --lua-version 5.1)

            # Add local bin to PATH
            export PATH="$PWD/.luarocks/bin:$PATH"

            echo ""
            echo "Commands:"
            echo "  ./run-tests.sh          - Run unit tests"
            echo "  luarocks install busted - Install busted locally"
            echo "  busted --run unit       - Run unit tests directly"
            echo ""
            echo "To install test dependencies:"
            echo "  luarocks install busted"
            echo "  luarocks install nlua"
            echo "=========================================="
          '';
        };
      }
    );
}
