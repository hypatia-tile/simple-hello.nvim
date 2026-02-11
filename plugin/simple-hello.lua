-- definee commands/keymaps/autocmd here, then delegate to lua module
vim.api.nvim_create_user_command("SimpleHello", function()
  require("simple-hello").hello()
end, {})
