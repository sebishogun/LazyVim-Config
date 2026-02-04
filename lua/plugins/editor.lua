return {
  { "kylechui/nvim-surround", version = "*", event = "VeryLazy", config = true },
  { "windwp/nvim-autopairs", event = "InsertEnter", config = true },
  { "numToStr/Comment.nvim", event = "BufReadPost", config = true },
  { "lukas-reineke/indent-blankline.nvim", main = "ibl", event = { "BufReadPost", "BufNewFile" }, opts = { indent = { char = "│" }, scope = { enabled = true } } },
  { "folke/todo-comments.nvim", dependencies = { "nvim-lua/plenary.nvim" }, lazy = false, opts = { signs = true }, keys = { { "]t", function() require("todo-comments").jump_next() end, desc = "Next todo" }, { "[t", function() require("todo-comments").jump_prev() end, desc = "Prev todo" }, { "<leader>xt", "<cmd>TodoTelescope<CR>", desc = "Search TODOs" } } },
}
