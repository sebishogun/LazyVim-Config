return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local harpoon = require("harpoon")
    harpoon:setup()
    vim.keymap.set("n", "<leader>a", function() if vim.bo.buftype == "" then harpoon:list():add() end end, { desc = "Harpoon add" })
    vim.keymap.set("n", "<leader>h", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = "Harpoon menu" })
    for i = 1, 9 do vim.keymap.set("n", "<leader>" .. i, function() harpoon:list():select(i) end, { desc = "Harpoon " .. i }) end
    vim.keymap.set("n", "<leader>0", function() harpoon:list():select(10) end, { desc = "Harpoon 10" })
    vim.keymap.set("n", "<leader>[", function() harpoon:list():prev() end, { desc = "Harpoon prev" })
    vim.keymap.set("n", "<leader>]", function() harpoon:list():next() end, { desc = "Harpoon next" })
  end,
}
