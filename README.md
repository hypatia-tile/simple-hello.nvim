# simple-hello.nvim

Simple Neovim plugin to learn test methods.

A minimal plugin that provides a `:SimpleHello` command to print a greeting message.

## Installation

Using your favorite plugin manager:

```lua
-- lazy.nvim
{ "hypatia-tile/simple-hello.nvim" }
```

## Usage

```vim
:SimpleHello
```

Prints: `Hello, from simple-hello.lua!`

## Development

### Quick Start (Recommended)

Using Nix flake for reproducible development environment:

```bash
# Enter development environment
nix develop

# Install test dependencies (first time only)
luarocks --tree=.luarocks install busted

# Run tests
./run-tests.sh
```

See [NIX_SETUP.md](./NIX_SETUP.md) for detailed information.

### Manual Testing

#### Busted Tests (Comprehensive)

```bash
# Run all unit tests
busted --run unit

# Verbose output
busted --verbose --run unit
```

See [TESTING_SETUP.md](./TESTING_SETUP.md) for test setup details.

#### Smoke Test (Basic)

```sh
nvim --clean -u NONE \
  --cmd "set runtimepath^=$(pwd)" \
  -l test/smoke.lua
```

#### Headless Test

```sh
./headless_test.sh
```

## Documentation

- [NIX_SETUP.md](./NIX_SETUP.md) - Nix flake development environment
- [TESTING_SETUP.md](./TESTING_SETUP.md) - Testing setup and running tests
- [BUSTED_GUIDE.md](./BUSTED_GUIDE.md) - Comprehensive Busted testing guide
- [CLAUDE.md](./CLAUDE.md) - Guide for Claude Code instances

## Test Status

✅ **6/6 unit tests passing**

Tests cover:
- Module loading and structure
- Function execution
- Output verification (spies and mocks)

## License

MIT
