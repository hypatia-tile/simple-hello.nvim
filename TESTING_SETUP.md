# Testing Setup Summary

## What We Accomplished

Successfully set up Busted testing framework for the simple-hello.nvim plugin with comprehensive unit tests.

## Installation

```bash
# Installed via LuaRocks (locally)
luarocks install --local busted
luarocks install --local nlua
```

**Installed packages:**
- busted 2.3.0-1 (with all dependencies)
- nlua 0.3.1-1

## Project Structure

```
simple-hello.nvim/
├── .busted                          # Busted configuration
├── simple-hello-scm-1.rockspec     # LuaRocks package spec
├── run-tests.sh                     # Convenience test runner
├── test/
│   └── nvim-shim                    # Neovim test shim (for future use)
└── spec/
    ├── unit/
    │   └── simple-hello_spec.lua    # Unit tests (working)
    └── functional/
        └── command_spec.lua         # Functional tests (needs setup)
```

## Running Tests

### Quick Method
```bash
./run-tests.sh
```

### Manual Method
```bash
# Set up LuaRocks paths
eval $(luarocks path --bin)

# Run all unit tests
busted --run unit

# Run with verbose output
busted --verbose --run unit
```

### Using LuaRocks
```bash
luarocks test --local
```

## Test Results

✅ **Unit Tests: 6/6 passing**

Tests implemented:
1. Module can be required
2. Module is a table
3. Module has hello function
4. hello() executes without error
5. hello() calls print with message (spy test)
6. hello() prints exact expected message (mock test)

## Known Limitations

### Functional Tests
The functional tests in `spec/functional/command_spec.lua` are written but currently not running due to Lua version compatibility between:
- System Lua (5.2 from Nix)
- LuaJIT/Lua 5.1 (used by Neovim)
- LuaRocks packages installed for Lua 5.2

**Solutions to explore:**
1. Use a separate LuaJIT installation for LuaRocks
2. Install LuaRocks packages for Lua 5.1 specifically
3. Use Nix shell with proper Lua 5.1 environment
4. Use GitHub Actions with nvim-busted-action (handles all setup)

## Test Features Demonstrated

### Basic Assertions
```lua
assert.is_not_nil(value)
assert.is_table(value)
assert.is_function(value)
assert.has_no.errors(function)
```

### Spies (Track function calls)
```lua
local print_spy = spy.on(_G, "print")
simple_hello.hello()
assert.spy(print_spy).was_called()
assert.spy(print_spy).was_called(1)  -- exactly once
```

### Mocks (Replace function behavior)
```lua
local captured = nil
_G.print = function(msg)
   captured = msg
end
simple_hello.hello()
assert.equals("Hello, from simple-hello.lua!", captured)
```

### Test Lifecycle
```lua
before_each(function()
   -- Runs before each test
   package.loaded["simple-hello"] = nil
   simple_hello = require("simple-hello")
end)
```

## Configuration Files

### `.busted`
Defines test configurations:
- Unit tests: Use system Lua (no vim API)
- Functional tests: Use nvim-shim (has vim API) - pending setup

### `simple-hello-scm-1.rockspec`
LuaRocks package specification:
- Defines dependencies
- Specifies test dependencies (busted, nlua)
- Configures build system

## Next Steps

To enable functional tests:
1. Set up proper Lua 5.1/LuaJIT environment
2. Reinstall LuaRocks packages for Lua 5.1
3. Or use CI/CD with GitHub Actions (easiest)

## References

- [BUSTED_GUIDE.md](./BUSTED_GUIDE.md) - Comprehensive Busted documentation
- [Busted Official Docs](https://lunarmodules.github.io/busted/)
- [Testing Neovim Plugins with Busted](https://hiphish.github.io/blog/2024/01/29/testing-neovim-plugins-with-busted/)
