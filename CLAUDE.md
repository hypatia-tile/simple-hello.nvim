# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a minimal Neovim plugin created as a learning project for understanding Neovim plugin development and testing methodologies. The plugin provides a simple `:SimpleHello` command that prints a greeting message.

## Architecture

The plugin follows the standard Neovim plugin structure:

- `plugin/simple-hello.lua` - Entry point that defines user-facing commands/keymaps/autocmds and delegates to the Lua module
- `lua/simple-hello.lua` - Core module implementing the actual functionality
- `test/` - Test scripts for validation

This separation follows the Neovim plugin convention where `plugin/` contains initialization code that runs automatically when Neovim starts, while `lua/` contains the reusable module code.

## Testing

### Run Smoke Test

```sh
nvim --clean -u NONE \
  --cmd "set runtimepath^=$(pwd)" \
  -l test/smoke.lua
```

This runs a simple assertion test that verifies the module can be loaded.

### Run Headless Test

```sh
./headless_test.sh
```

This runs a more comprehensive headless test that:
1. Loads the plugin in a clean Neovim instance
2. Validates buffer creation
3. Verifies the module loads without errors

Both test approaches use `nvim --clean -u NONE` to ensure a clean testing environment without user configuration interference, and manually add the plugin to the runtimepath with `set runtimepath^=$(pwd)`.
