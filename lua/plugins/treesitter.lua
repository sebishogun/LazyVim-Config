return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "javascript", "typescript", "tsx", "html", "css", "json", "yaml", "markdown", "markdown_inline", "bash", "go", "sql", "java", "python", "rust", "zig", "dockerfile", "toml", "make", "cmake", "regex" },
      highlight = { enable = true },
      indent = { enable = true },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    config = function()
      require("nvim-treesitter.configs").setup({
        textobjects = {
          select = { enable = true, lookahead = true, keymaps = { ["af"] = "@function.outer", ["if"] = "@function.inner", ["ac"] = "@class.outer", ["ic"] = "@class.inner", ["al"] = "@loop.outer", ["il"] = "@loop.inner", ["aa"] = "@parameter.outer", ["ia"] = "@parameter.inner" } },
          move = { enable = true, set_jumps = true, goto_next_start = { ["]m"] = "@function.outer", ["]]"] = "@class.outer" }, goto_next_end = { ["]M"] = "@function.outer", ["]["] = "@class.outer" }, goto_previous_start = { ["[m"] = "@function.outer", ["[["] = "@class.outer" }, goto_previous_end = { ["[M"] = "@function.outer", ["[]"] = "@class.outer" } },
        },
      })
    end,
  },
}
