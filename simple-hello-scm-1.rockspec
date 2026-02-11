rockspec_format = "3.0"
package = "simple-hello"
version = "scm-1"

source = {
   url = "git://github.com/hypatia-tile/simple-hello.nvim"
}

description = {
   summary = "Simple Neovim plugin to learn test methods",
   detailed = [[
      A minimal Neovim plugin created as a learning project for
      understanding plugin development and testing methodologies.
   ]],
   homepage = "https://github.com/hypatia-tile/simple-hello.nvim",
   license = "MIT"
}

dependencies = {
   "lua >= 5.1",
}

test_dependencies = {
   "busted >= 2.0",
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
