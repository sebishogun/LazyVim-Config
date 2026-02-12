-- macOS brew-based LSP setup
-- On corporate macOS laptops, Mason can't download through the firewall.
-- This file disables Mason's auto-install so lspconfig uses system binaries
-- installed via brew/npm (see scripts/brew-install-tools.sh).
-- On Linux, this file is a no-op and Mason works normally.

if vim.fn.has("mac") ~= 1 then
  return {}
end

return {
  -- Disable Mason auto-install on macOS (opts function overrides merged lists)
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = {}
    end,
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    opts = function(_, opts)
      opts.ensure_installed = {}
      opts.automatic_installation = false
    end,
  },
}
