return {
  { "mfussenegger/nvim-dap",
    dependencies = {
      { "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },
      "theHamsta/nvim-dap-virtual-text",
      { "jay-babu/mason-nvim-dap.nvim", dependencies = { "williamboman/mason.nvim" } },
      "leoluz/nvim-dap-go",
    },
    config = function()
      local dap, dapui = require("dap"), require("dapui")
      require("mason-nvim-dap").setup({ ensure_installed = { "delve", "codelldb", "python", "js", "javadbg", "javatest" }, automatic_installation = true })
      dapui.setup({ icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" }, layouts = { { elements = { { id = "scopes", size = 0.25 }, { id = "breakpoints", size = 0.25 }, { id = "stacks", size = 0.25 }, { id = "watches", size = 0.25 } }, size = 40, position = "left" }, { elements = { { id = "repl", size = 0.5 }, { id = "console", size = 0.5 } }, size = 10, position = "bottom" } }, floating = { border = "rounded", mappings = { close = { "q", "<Esc>" } } } })
      require("nvim-dap-virtual-text").setup({ enabled = true, highlight_changed_variables = true, show_stop_reason = true })
      require("dap-go").setup({ delve = { path = vim.fn.stdpath("data") .. "/mason/bin/dlv" } })
      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DapBreakpoint" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "●", texthl = "DapBreakpointCondition" })
      vim.fn.sign_define("DapLogPoint", { text = "◆", texthl = "DapLogPoint" })
      vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DapStopped", linehl = "DapStoppedLine" })
      vim.fn.sign_define("DapBreakpointRejected", { text = "○", texthl = "DapBreakpointRejected" })
      vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = "#e51400" })
      vim.api.nvim_set_hl(0, "DapBreakpointCondition", { fg = "#ff9e64" })
      vim.api.nvim_set_hl(0, "DapLogPoint", { fg = "#61afef" })
      vim.api.nvim_set_hl(0, "DapStopped", { fg = "#98c379" })
      vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = "#2e4d3d" })
      vim.api.nvim_set_hl(0, "DapBreakpointRejected", { fg = "#656565" })
      dap.adapters.codelldb = { type = "server", port = "${port}", executable = { command = vim.fn.stdpath("data") .. "/mason/bin/codelldb", args = { "--port", "${port}" } } }
      dap.configurations.rust = { { name = "Launch", type = "codelldb", request = "launch", program = function() return vim.fn.input("Executable: ", vim.fn.getcwd() .. "/target/debug/", "file") end, cwd = "${workspaceFolder}" } }
      dap.configurations.c, dap.configurations.cpp = dap.configurations.rust, dap.configurations.rust
      dap.configurations.zig = { { name = "Launch", type = "codelldb", request = "launch", program = function() return vim.fn.input("Executable: ", vim.fn.getcwd() .. "/zig-out/bin/", "file") end, cwd = "${workspaceFolder}" } }
      dap.adapters.python = { type = "executable", command = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python", args = { "-m", "debugpy.adapter" } }
      dap.configurations.python = { { type = "python", request = "launch", name = "Launch", program = "${file}", pythonPath = function() return os.getenv("VIRTUAL_ENV") and (os.getenv("VIRTUAL_ENV") .. "/bin/python") or "/usr/bin/python3" end } }
      vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Breakpoint" })
      vim.keymap.set("n", "<leader>dB", function() dap.set_breakpoint(vim.fn.input("Condition: ")) end, { desc = "Conditional Breakpoint" })
      vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Continue" })
      vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Step Into" })
      vim.keymap.set("n", "<leader>do", dap.step_over, { desc = "Step Over" })
      vim.keymap.set("n", "<leader>dO", dap.step_out, { desc = "Step Out" })
      vim.keymap.set("n", "<leader>dr", dap.restart, { desc = "Restart" })
      vim.keymap.set("n", "<leader>dt", dap.terminate, { desc = "Terminate" })
      vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Toggle UI" })
      vim.keymap.set({ "n", "v" }, "<leader>de", dapui.eval, { desc = "Evaluate" })
      vim.keymap.set("n", "<leader>dl", dap.run_last, { desc = "Run Last" })
      vim.keymap.set("n", "<leader>dp", dap.pause, { desc = "Pause" })
    end,
  },
}
