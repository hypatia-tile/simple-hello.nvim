# Nix Flake Setup

This document describes the Nix flake development environment for this Neovim plugin.

## Overview

The `flake.nix` provides a reproducible development environment with:
- **Lua 5.1** (compatible with Neovim's LuaJIT)
- **LuaRocks** for package management
- **Neovim** for testing
- **Local `.luarocks`** directory for project-specific packages

## Quick Start

### Enter Development Environment

```bash
# Enter the nix shell
nix develop

# Install test dependencies (first time only)
luarocks --tree=.luarocks install busted

# Run tests
./run-tests.sh
```

### One-Time Setup

If this is your first time using the flake:

```bash
# Enter the environment
nix develop

# Install testing dependencies
luarocks --tree=.luarocks install busted
luarocks --tree=.luarocks install nlua

# Run tests to verify
busted --run unit
```

## How It Works

### Flake Structure

The `flake.nix`:
1. Provides Lua 5.1 (Neovim compatible)
2. Configures LuaRocks to use local `.luarocks/` directory
3. Sets up PATH and Lua module paths automatically
4. Displays helpful information when entering the shell

### Local Package Installation

All LuaRocks packages are installed to `.luarocks/` in the project directory:

```
.luarocks/
├── bin/           # Executables (busted, etc.)
├── lib/           # Native libraries
└── share/lua/5.1/ # Lua modules
```

This directory is git-ignored and specific to your machine.

### Environment Variables

When you run `nix develop`, the shell hook automatically:
- Creates `.luarocks/` directory
- Sets up `LUA_PATH` and `LUA_CPATH` to find local packages
- Adds `.luarocks/bin` to `PATH`
- Configures everything for Lua 5.1 compatibility

## Commands

### Inside Nix Shell

```bash
# Install a package locally
luarocks --tree=.luarocks install <package>

# Run all unit tests
busted --run unit

# Run tests with verbose output
busted --verbose --run unit

# Run specific test file
busted spec/unit/simple-hello_spec.lua

# Use the convenience script
./run-tests.sh
```

### Outside Nix Shell

```bash
# Enter the environment
nix develop

# Run a single command without entering shell
nix develop --command busted --run unit

# Run tests via script (auto-detects environment)
./run-tests.sh
```

## Advantages of This Setup

### 1. Reproducibility
Everyone gets the exact same Lua 5.1 and LuaRocks versions, regardless of their system configuration.

### 2. Isolation
- No conflicts with system Lua or other projects
- Each project has its own `.luarocks/` directory
- Clean separation from nix-darwin or home-manager

### 3. Convenience
- One command (`nix develop`) sets up everything
- No manual PATH configuration needed
- Works on any machine with Nix installed

### 4. Lua Version Consistency
- Lua 5.1 matches Neovim's LuaJIT
- All tests run in the correct Lua environment
- No version mismatch issues

## Comparison with Previous Setup

### Before (Manual Installation)
```bash
# Different Lua versions on different systems
lua -v  # Could be 5.1, 5.2, 5.4, or LuaJIT

# Packages installed to ~/.luarocks
luarocks install --local busted

# Version conflicts possible
```

### After (Nix Flake)
```bash
# Always Lua 5.1
nix develop
lua -v  # Always: Lua 5.1.5

# Packages installed to .luarocks (project-local)
luarocks --tree=.luarocks install busted

# Reproducible across machines
```

## Troubleshooting

### "module not found" errors

Make sure you're in the nix shell:
```bash
nix develop
eval $(luarocks --tree=.luarocks path --lua-version 5.1)
```

### busted command not found

Install busted first:
```bash
nix develop
luarocks --tree=.luarocks install busted
```

### Want to reset everything

Remove the local packages and reinstall:
```bash
rm -rf .luarocks
nix develop
luarocks --tree=.luarocks install busted
```

## CI/CD Integration

For GitHub Actions, you can use:

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - uses: cachix/install-nix-action@v22
        with:
          github_access_token: ${{ secrets.GITHUB_TOKEN }}

      - name: Run tests
        run: |
          nix develop --command bash -c "
            luarocks --tree=.luarocks install busted
            busted --run unit
          "
```

## Files

- `flake.nix` - Nix flake configuration
- `flake.lock` - Locked dependency versions (tracked in git)
- `.luarocks/` - Local LuaRocks packages (git-ignored)
- `.gitignore` - Ignores `.luarocks/` and other artifacts

## Next Steps

To enable functional tests with full Neovim API support, you would:

1. Install nlua: `luarocks --tree=.luarocks install nlua`
2. Update `.busted` to use nlua for functional tests
3. Ensure the nvim-shim script works with the nix environment

## References

- [Nix Flakes](https://nixos.wiki/wiki/Flakes)
- [LuaRocks Documentation](https://github.com/luarocks/luarocks/wiki)
- [Busted Testing Framework](https://lunarmodules.github.io/busted/)
