# Busted Deep Dive for Neovim Plugin Testing

## What is Busted?

Busted is the de facto standard testing framework in the Lua community, modeled after RSpec. It provides a full-featured testing environment with:
- Descriptive test organization (describe/it blocks)
- Rich assertion library (luassert)
- Spies, mocks, and stubs
- Async testing support
- Test tagging and filtering
- Multiple output formats (terminal, JSON, TAP)
- Internationalization (11 languages)

## Why Busted Over Plenary for Neovim Plugins?

| Feature | Busted | Plenary.nvim |
|---------|--------|--------------|
| Setup/Teardown hooks | ✅ Full support | ❌ Limited |
| Test isolation (`insulate`/`expose`) | ✅ Yes | ❌ No |
| Test tagging | ✅ Yes | ❌ No |
| Async support | ✅ Full | ⚠️ Basic |
| Community standard | ✅ De facto Lua standard | ⚠️ Neovim-specific |
| CI integration | ✅ TAP/JSON output | ⚠️ Limited |
| Dependencies | LuaRocks managed | Neovim plugin |

**Key Innovation (Neovim 0.9+)**: The `nvim -l` flag allows Neovim to act as a LuaJIT interpreter with full API access, making Busted practical for plugin testing.

---

## Setup Guide

### Method 1: Using LuaRocks + nlua (Modern Approach)

**1. Install Dependencies**
```bash
# Install LuaRocks if not already installed
# macOS: brew install luarocks
# Ubuntu: apt install luarocks

# Install busted and nlua
luarocks install busted
luarocks install nlua
```

**2. Create Rockspec** (`simple-hello-scm-1.rockspec`)
```lua
rockspec_format = "3.0"
package = "simple-hello"
version = "scm-1"

source = {
   url = "git://github.com/hypatia-tile/simple-hello.nvim"
}

dependencies = {
   "lua >= 5.1",
}

test_dependencies = {
   "busted",
   "nlua"
}

test = {
   type = "busted"
}

build = {
   type = "builtin",
   modules = {
      ["simple-hello"] = "lua/simple-hello.lua"
   }
}
```

**3. Create `.busted` Configuration**
```lua
return {
   _all = {
      lua = "nlua",  -- Use Neovim as Lua interpreter
      lpath = "lua/?.lua;lua/?/init.lua"
   },
   unit = {
      ROOT = {"spec/unit/"}
   },
   integration = {
      ROOT = {"spec/integration/"}
   }
}
```

**4. Run Tests**
```bash
# Run all tests
luarocks test --local

# Or directly with busted
eval $(luarocks path --lua-version 5.1 --bin) && busted

# Run specific suite
busted --run unit
busted --run integration
```

### Method 2: Manual Shim (Maximum Control)

**1. Create `test/nvim-shim`**
```bash
#!/bin/sh

# Isolate test environment using XDG directories
export XDG_CONFIG_HOME='test/xdg/config/'
export XDG_STATE_HOME='test/xdg/local/state/'
export XDG_DATA_HOME='test/xdg/local/share/'

# Create temporary symlink for plugin loading
mkdir -p ${XDG_DATA_HOME}/nvim/site/pack/testing/start/
ln -s $(pwd) ${XDG_DATA_HOME}/nvim/site/pack/testing/start/simple-hello

# Run Neovim as Lua interpreter with plugin loaded
nvim --cmd 'set loadplugins' -l "$@"
exit_code=$?

# Cleanup
rm ${XDG_DATA_HOME}/nvim/site/pack/testing/start/simple-hello

exit $exit_code
```

Make it executable: `chmod +x test/nvim-shim`

**2. Create `.busted` Configuration**
```lua
return {
   _all = {
      lua = "./test/nvim-shim"
   },
   unit = {
      ROOT = {"spec/unit/"}
   },
   functional = {
      ROOT = {"spec/functional/"}
   }
}
```

**3. Run Tests**
```bash
eval $(luarocks path --lua-version 5.1 --bin) && busted
```

---

## Test Structure

### Basic Test Anatomy

```lua
-- spec/unit/simple-hello_spec.lua
describe("simple-hello module", function()
   local simple_hello

   before_each(function()
      -- Runs before each 'it' block
      simple_hello = require("simple-hello")
   end)

   after_each(function()
      -- Runs after each 'it' block
      -- Cleanup code here
   end)

   it("should be loadable", function()
      assert.is_not_nil(simple_hello)
   end)

   it("should have a hello function", function()
      assert.is_function(simple_hello.hello)
   end)
end)
```

### Lifecycle Hooks

```lua
describe("Lifecycle hooks demo", function()
   setup(function()
      -- Runs ONCE before all tests in this describe block
      print("Setup: runs once before all tests")
   end)

   teardown(function()
      -- Runs ONCE after all tests in this describe block
      print("Teardown: runs once after all tests")
   end)

   before_each(function()
      -- Runs before EACH test
      print("Before each test")
   end)

   after_each(function()
      -- Runs after EACH test
      print("After each test")
   end)

   finally(function()
      -- Lightweight cleanup without upvalue setup
      print("Finally: lightweight cleanup")
   end)

   it("test 1", function()
      assert.is_true(true)
   end)

   it("test 2", function()
      assert.is_true(true)
   end)
end)
```

**Output:**
```
Setup: runs once before all tests
Before each test
[test 1 runs]
After each test
Finally: lightweight cleanup
Before each test
[test 2 runs]
After each test
Finally: lightweight cleanup
Teardown: runs once after all tests
```

### Test Isolation with `insulate` and `expose`

```lua
-- insulate: Each test runs in a sandbox
insulate("isolated tests", function()
   _G.shared_state = 0

   it("test 1 modifies state", function()
      _G.shared_state = 100
      assert.equals(100, _G.shared_state)
   end)

   it("test 2 sees fresh state", function()
      -- State is reset between tests!
      assert.equals(0, _G.shared_state)
   end)
end)

-- expose: Tests share state (default behavior)
expose("shared state tests", function()
   _G.counter = 0

   it("increments counter", function()
      _G.counter = _G.counter + 1
      assert.equals(1, _G.counter)
   end)

   it("sees previous increment", function()
      -- State persists!
      assert.equals(1, _G.counter)
   end)
end)
```

---

## Assertions

### Basic Assertions

```lua
-- Equality
assert.equals(expected, actual)
assert.is.equal(expected, actual)  -- Alias
assert.is_not.equal(expected, actual)

-- Deep comparison (for tables)
assert.same({a = 1}, {a = 1})
assert.are.same(expected, actual)  -- Alias

-- Boolean checks
assert.is_true(value)
assert.is_false(value)
assert.is.truthy(value)   -- Any non-nil, non-false value
assert.is.falsy(value)    -- nil or false

-- Nil checks
assert.is_nil(value)
assert.is_not_nil(value)

-- Type checks
assert.is_string(value)
assert.is_number(value)
assert.is_table(value)
assert.is_function(value)
assert.is_boolean(value)
assert.is_userdata(value)
assert.is_thread(value)
```

### Error Assertions

```lua
-- Check that function throws error
assert.has_error(function()
   error("Something went wrong")
end)

-- Check error message
assert.has_error(function()
   error("File not found")
end, "File not found")

-- Check error doesn't occur
assert.has_no.error(function()
   return 1 + 1
end)
```

### Chainable Modifiers

```lua
-- Modifiers: is, is_not, are, are_not, has, has_no, was, was_not

assert.is.equal(1, 1)
assert.is_not.equal(1, 2)
assert.are.same({}, {})
assert.has.error(bad_function)
assert.has_no.errors(good_function)

-- Multiple chaining
assert.is_not.truthy(nil)
assert.are.not.same({a=1}, {b=2})
```

### Custom Assertions

```lua
local say = require("say")
local assert = require("luassert")

-- Define custom assertion
local function is_even(state, arguments)
   local value = arguments[1]
   return value % 2 == 0
end

-- Register with multilingual messages
say:set("assertion.is_even.positive", "Expected %s to be even")
say:set("assertion.is_even.negative", "Expected %s to not be even")
assert:register("assertion", "is_even", is_even,
   "assertion.is_even.positive", "assertion.is_even.negative")

-- Use it
assert.is_even(4)  -- passes
assert.is_even(5)  -- fails: "Expected 5 to be even"
```

---

## Spies, Stubs & Mocks

### Spies (Track Calls Without Changing Behavior)

```lua
describe("Spy example", function()
   it("tracks function calls", function()
      local t = {
         add = function(a, b) return a + b end
      }

      -- Spy on the function
      spy.on(t, "add")

      -- Call it
      local result = t.add(1, 2)

      -- Verify behavior
      assert.equals(3, result)
      assert.spy(t.add).was_called()
      assert.spy(t.add).was_called_with(1, 2)
      assert.spy(t.add).was_called(1)  -- Called exactly once
   end)

   it("creates standalone spy", function()
      local callback = spy.new(function() end)

      callback("arg1", "arg2")

      assert.spy(callback).was_called_with("arg1", "arg2")
   end)
end)
```

### Stubs (Replace Behavior)

```lua
describe("Stub example", function()
   it("replaces function behavior", function()
      local t = {
         get_user = function()
            -- This would normally make API call
            return {name = "Real User"}
         end
      }

      -- Stub the function
      stub(t, "get_user")
      t.get_user.returns({name = "Test User"})

      -- Use it
      local user = t.get_user()

      assert.equals("Test User", user.name)
      assert.stub(t.get_user).was_called()
   end)

   it("stubs multiple return values", function()
      local t = { fn = function() end }
      stub(t, "fn")
      t.fn.returns(1, 2, 3)

      local a, b, c = t.fn()
      assert.equals(1, a)
      assert.equals(2, b)
      assert.equals(3, c)
   end)
end)
```

### Mocks (Comprehensive Table Wrapping)

```lua
describe("Mock example", function()
   it("mocks entire API surface", function()
      local api = {
         create = function() end,
         read = function() end,
         update = function() end,
         delete = function() end
      }

      -- Mock entire table
      mock(api, true)

      api.create({name = "test"})
      api.read(123)

      assert.spy(api.create).was_called_with({name = "test"})
      assert.spy(api.read).was_called_with(123)
      assert.spy(api.update).was_not_called()
   end)
end)
```

### Matchers (Flexible Argument Matching)

```lua
local match = require("luassert.match")

describe("Matcher examples", function()
   it("uses type matchers", function()
      local fn = spy.new(function() end)

      fn("hello", 123, true)

      assert.spy(fn).was_called_with(
         match.is_string(),
         match.is_number(),
         match.is_boolean()
      )
   end)

   it("uses wildcard matcher", function()
      local fn = spy.new(function() end)

      fn("any", "values", "here")

      assert.spy(fn).was_called_with(match._, match._, match._)
   end)

   it("combines matchers", function()
      local fn = spy.new(function() end)

      fn({name = "test", id = 5})

      assert.spy(fn).was_called_with(
         match.is_table()
      )
   end)
end)
```

---

## Async Testing

```lua
describe("Async tests", function()
   it("handles async operations", function()
      async()  -- Mark test as async

      local result = nil

      -- Simulate async operation
      vim.defer_fn(function()
         result = "completed"
         done()  -- Signal completion
      end, 100)

      -- Test continues after done() is called
   end)

   it("validates async results", function()
      async()

      vim.defer_fn(function()
         assert.equals("expected", "expected")
         done()
      end, 50)
   end)
end)
```

---

## Test Tagging

```lua
-- Tag tests with #hashtags
describe("User management #unit #fast", function()
   it("creates user #database", function()
      -- test code
   end)

   it("validates email #validation", function()
      -- test code
   end)
end)

describe("API integration #integration #slow", function()
   it("fetches data #api #network", function()
      -- test code
   end)
end)
```

**Run specific tags:**
```bash
# Run only unit tests
busted --tags=unit

# Run all except slow tests
busted --exclude-tags=slow

# Multiple tags (OR logic)
busted --tags=database,api

# Combine inclusion and exclusion
busted --tags=unit --exclude-tags=slow
```

---

## Pending Tests

```lua
describe("Feature under development", function()
   pending("will implement user login", function()
      -- Not implemented yet
   end)

   it("handles logout")  -- Missing function = pending

   it("existing feature works", function()
      assert.is_true(true)
   end)
end)
```

---

## Neovim-Specific Testing Patterns

### Unit Test (Testing Lua Modules)

```lua
-- spec/unit/simple-hello_spec.lua
describe("simple-hello", function()
   local simple_hello

   before_each(function()
      -- Fresh module for each test
      package.loaded["simple-hello"] = nil
      simple_hello = require("simple-hello")
   end)

   describe("hello function", function()
      it("exists", function()
         assert.is_function(simple_hello.hello)
      end)

      it("prints message", function()
         -- Mock print to capture output
         local printed = nil
         _G.print = function(msg)
            printed = msg
         end

         simple_hello.hello()

         assert.is_not_nil(printed)
         assert.matches("Hello", printed)
      end)
   end)
end)
```

### Functional Test (Testing Neovim Integration)

```lua
-- spec/functional/command_spec.lua
describe("SimpleHello command", function()
   local nvim

   before_each(function()
      -- Start embedded Neovim instance
      nvim = vim.fn.jobstart(
         {"nvim", "--embed", "--headless"},
         {rpc = true, width = 80, height = 24}
      )

      -- Load the plugin
      vim.fn.rpcrequest(nvim, "nvim_command",
         "set runtimepath+=" .. vim.fn.getcwd())
   end)

   after_each(function()
      vim.fn.jobstop(nvim)
   end)

   it("creates SimpleHello command", function()
      local commands = vim.fn.rpcrequest(nvim,
         "nvim_get_commands", {})

      assert.is_not_nil(commands.SimpleHello)
   end)

   it("executes without error", function()
      local result = vim.fn.rpcrequest(nvim,
         "nvim_command", "SimpleHello")

      -- No error means success
      assert.is_not_nil(result)
   end)
end)
```

### Testing Buffer Manipulation

```lua
describe("Buffer operations", function()
   before_each(function()
      vim.cmd("enew")  -- New buffer
   end)

   after_each(function()
      vim.cmd("bwipeout!")  -- Clean up
   end)

   it("writes to buffer", function()
      local buf = vim.api.nvim_get_current_buf()

      vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
         "Line 1",
         "Line 2"
      })

      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

      assert.equals(2, #lines)
      assert.equals("Line 1", lines[1])
      assert.equals("Line 2", lines[2])
   end)
end)
```

---

## Configuration & CLI

### `.busted` File (Full Example)

```lua
return {
   _all = {
      lua = "nlua",
      lpath = "lua/?.lua;lua/?/init.lua",
      pattern = "_spec",
      verbose = true,
      shuffle = false,
      coverage = false
   },

   unit = {
      ROOT = {"spec/unit/"},
      tags = "unit",
      output = "utfTerminal"
   },

   integration = {
      ROOT = {"spec/integration/"},
      tags = "integration",
      output = "TAP"
   },

   ci = {
      ROOT = {"spec/"},
      coverage = true,
      output = "json"
   }
}
```

### CLI Commands

```bash
# Run all tests
busted

# Run specific configuration
busted --run unit
busted --run integration

# Pattern matching
busted --pattern=_test  # Find *_test.lua files

# Specific directory
busted spec/unit/

# Specific file
busted spec/unit/simple-hello_spec.lua

# Output formats
busted --output=json
busted --output=TAP
busted --output=plainTerminal

# Coverage
busted --coverage

# Shuffle tests
busted --shuffle

# Verbose output
busted --verbose

# Filter by name
busted --filter="hello function"

# Repeat tests (find flaky tests)
busted --repeat=10
```

---

## CI/CD Integration

### GitHub Actions (Recommended)

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        neovim-version: ['stable', 'nightly']

    steps:
      - uses: actions/checkout@v3

      - name: Run tests
        uses: nvim-neorocks/nvim-busted-action@v1
        with:
          neovim-version: ${{ matrix.neovim-version }}
```

### Manual CI Setup

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Install Neovim
        run: |
          sudo add-apt-repository ppa:neovim-ppa/unstable
          sudo apt-get update
          sudo apt-get install neovim

      - name: Install LuaRocks
        run: |
          sudo apt-get install luarocks

      - name: Install dependencies
        run: |
          luarocks install busted
          luarocks install nlua

      - name: Run tests
        run: |
          eval $(luarocks path --lua-version 5.1 --bin)
          busted --output=TAP
```

---

## Best Practices

### 1. Test Organization

```
spec/
├── unit/              # Fast, isolated tests
│   ├── utils_spec.lua
│   └── module_spec.lua
├── integration/       # Feature tests
│   └── plugin_spec.lua
└── fixtures/          # Test data
    └── sample.txt
```

### 2. Use Descriptive Names

```lua
-- ❌ Bad
describe("test", function()
   it("works", function()
      assert.is_true(true)
   end)
end)

-- ✅ Good
describe("simple-hello.hello()", function()
   it("prints greeting message to command line", function()
      assert.is_true(true)
   end)
end)
```

### 3. One Assertion per Test (When Possible)

```lua
-- ❌ Testing multiple behaviors
it("creates and configures user", function()
   local user = create_user("test")
   assert.is_not_nil(user)
   assert.equals("test", user.name)
   assert.is_true(user.active)
end)

-- ✅ Separate concerns
describe("create_user", function()
   it("returns user object", function()
      local user = create_user("test")
      assert.is_not_nil(user)
   end)

   it("sets user name", function()
      local user = create_user("test")
      assert.equals("test", user.name)
   end)

   it("activates user by default", function()
      local user = create_user("test")
      assert.is_true(user.active)
   end)
end)
```

### 4. Clean Up Resources

```lua
describe("File operations", function()
   local temp_file

   before_each(function()
      temp_file = "/tmp/test_" .. os.time()
   end)

   after_each(function()
      if temp_file then
         os.remove(temp_file)
      end)
   end)

   it("creates file", function()
      -- test code
   end)
end)
```

### 5. Use Tags Strategically

```lua
-- Fast tests run on every save
describe("validation #unit #fast", function() end)

-- Slow tests run in CI only
describe("API integration #integration #slow", function() end)

-- Skip broken tests temporarily
describe("broken feature #skip", function() end)
```

---

## Troubleshooting

### Tests Not Found

```bash
# Check pattern matches your files
busted --pattern=_spec --verbose

# Verify ROOT directories in .busted
cat .busted
```

### Module Not Found

```lua
-- Ensure lpath is correct in .busted
return {
   _all = {
      lpath = "lua/?.lua;lua/?/init.lua"
   }
}
```

### Neovim API Not Available

```bash
# Ensure using nlua or custom shim
# Check .busted configuration
lua = "nlua"  # or lua = "./test/nvim-shim"
```

### Spy/Mock Not Working

```lua
-- Revert mocks after each test
after_each(function()
   mock.revert(my_module)
end)
```

---

## Learning Resources

- **Official Docs**: https://lunarmodules.github.io/busted/
- **Luassert Docs**: https://github.com/lunarmodules/luassert
- **nlua**: https://github.com/mfussenegger/nlua
- **nvim-busted-action**: https://github.com/nvim-neorocks/nvim-busted-action
- **Example Plugin**: https://github.com/nvim-neorocks (search for plugins with busted tests)

---

## Quick Reference

### Common Assertions
```lua
assert.equals(expected, actual)
assert.same(table1, table2)
assert.is_true(value)
assert.is_nil(value)
assert.is_function(value)
assert.has_error(fn, "message")
```

### Spies & Stubs
```lua
spy.on(table, "method")
stub(table, "method")
mock(table, true)
assert.spy(fn).was_called()
assert.spy(fn).was_called_with(arg1, arg2)
```

### Test Structure
```lua
describe("group", function()
   before_each(function() end)
   after_each(function() end)
   it("test", function() end)
   pending("todo", function() end)
end)
```

### CLI
```bash
busted                          # Run all
busted --tags=unit             # Tagged tests
busted --exclude-tags=slow     # Exclude tags
busted --output=TAP            # CI output
busted --coverage              # Coverage report
```
