return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        gopls = { settings = { gopls = { staticcheck = true, gofumpt = true, usePlaceholders = true, analyses = { unusedparams = true, shadow = true, fieldalignment = true, nilness = true, unusedwrite = true, useany = true }, hints = { assignVariableTypes = true, compositeLiteralFields = true, constantValues = true, functionTypeParameters = true, parameterNames = true, rangeVariableTypes = true } } } },
        rust_analyzer = {},
        zls = {},
        clangd = {},
        pyright = {},
        lua_ls = {},
        tsserver = {},
        eslint = {},
        html = {},
        cssls = {},
        tailwindcss = {},
        jsonls = {},
        yamlls = {},
        bashls = {},
        dockerls = {},
        marksman = {},
        sqlls = {},
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = { "gopls", "rust-analyzer", "zls", "clangd", "pyright", "lua-language-server", "typescript-language-server", "eslint-lsp", "html-lsp", "css-lsp", "tailwindcss-language-server", "json-lsp", "yaml-language-server", "bash-language-server", "dockerfile-language-server", "marksman", "sqlls", "stylua", "shfmt", "black", "prettier" },
    },
  },
}
