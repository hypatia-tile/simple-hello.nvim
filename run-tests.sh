#!/bin/bash

# Set up LuaRocks paths (works both in nix-shell and regular environment)
if [ -d ".luarocks" ]; then
  eval $(luarocks --tree=.luarocks path --lua-version 5.1)
  export PATH="$PWD/.luarocks/bin:$PATH"
else
  eval $(luarocks path --bin)
fi

echo "Running unit tests..."
busted --verbose --run unit

echo ""
echo "Note: Functional tests require nlua with proper Lua version compatibility."
echo "For now, run unit tests only. Functional tests are available but need setup."
echo ""
echo "To enter the Nix development environment:"
echo "  nix develop"
