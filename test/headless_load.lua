local ok, mod = pcall(require, "simple-hello")
if not ok then
  error("failed to load simple-hello module")
  return
end

vim.cmd("enew")
assert(vim.api.nvim_buf_is_valid(0), "no buffer")
