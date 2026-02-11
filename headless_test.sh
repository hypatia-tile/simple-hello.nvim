#!/bin/sh
set -e

nvim --headless -u NONE \
  --cmd "set runtimepath+=$(pwd)" \
  -l test/headless_load.lua
