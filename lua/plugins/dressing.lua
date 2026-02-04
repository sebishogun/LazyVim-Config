return {
  "stevearc/dressing.nvim",
  lazy = false,
  opts = {
    input = { enabled = true, default_prompt = "Input:", border = "rounded", relative = "cursor", prefer_width = 40, max_width = { 140, 0.9 }, min_width = { 20, 0.2 } },
    select = { enabled = true, backend = { "telescope", "builtin" }, telescope = { layout_strategy = "vertical", layout_config = { vertical = { prompt_position = "top", mirror = true }, width = 0.6, height = 0.4 }, sorting_strategy = "ascending" }, builtin = { border = "rounded", relative = "editor" } },
  },
}
