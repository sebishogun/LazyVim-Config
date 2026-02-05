-- Debug Adapter Protocol (DAP) - Full debugging support
-- Languages: Go, Rust, C, C++, Zig, Python, JavaScript, TypeScript, Java
return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      { "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },
      "theHamsta/nvim-dap-virtual-text",
      { "jay-babu/mason-nvim-dap.nvim", dependencies = { "mason-org/mason.nvim" } },
      "leoluz/nvim-dap-go",
      "mxsdev/nvim-dap-vscode-js",
      { "microsoft/vscode-js-debug", build = "npm install --legacy-peer-deps && npx gulp dapDebugServer && mv dist out" },
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      -- Mason DAP setup
      require("mason-nvim-dap").setup({
        ensure_installed = { "delve", "codelldb", "python", "js", "javadbg", "javatest" },
        automatic_installation = true,
      })

      -- DAP UI setup
      dapui.setup({
        icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
        layouts = {
          { elements = { { id = "scopes", size = 0.25 }, { id = "breakpoints", size = 0.25 }, { id = "stacks", size = 0.25 }, { id = "watches", size = 0.25 } }, size = 40, position = "left" },
          { elements = { { id = "repl", size = 0.5 }, { id = "console", size = 0.5 } }, size = 10, position = "bottom" },
        },
        floating = { border = "rounded", mappings = { close = { "q", "<Esc>" } } },
      })

      -- Virtual text
      require("nvim-dap-virtual-text").setup({ enabled = true, highlight_changed_variables = true, show_stop_reason = true })

      -- Go debugging
      require("dap-go").setup({ delve = { path = vim.fn.stdpath("data") .. "/mason/bin/dlv" } })

      -- Auto open/close UI
      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end

      -- Signs
      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DapBreakpoint" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "●", texthl = "DapBreakpointCondition" })
      vim.fn.sign_define("DapLogPoint", { text = "◆", texthl = "DapLogPoint" })
      vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DapStopped", linehl = "DapStoppedLine" })
      vim.fn.sign_define("DapBreakpointRejected", { text = "○", texthl = "DapBreakpointRejected" })

      -- Highlights
      vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = "#e51400" })
      vim.api.nvim_set_hl(0, "DapBreakpointCondition", { fg = "#ff9e64" })
      vim.api.nvim_set_hl(0, "DapLogPoint", { fg = "#61afef" })
      vim.api.nvim_set_hl(0, "DapStopped", { fg = "#98c379" })
      vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = "#2e4d3d" })
      vim.api.nvim_set_hl(0, "DapBreakpointRejected", { fg = "#656565" })

      ------------------------------------------------------------------------------
      -- RUST / C / C++ (codelldb)
      ------------------------------------------------------------------------------
      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = vim.fn.stdpath("data") .. "/mason/bin/codelldb",
          args = { "--port", "${port}" },
        },
      }

      dap.configurations.rust = {
        {
          name = "Launch",
          type = "codelldb",
          request = "launch",
          program = function() return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/target/debug/", "file") end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
        },
        {
          name = "Launch (Release)",
          type = "codelldb",
          request = "launch",
          program = function() return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/target/release/", "file") end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
        },
      }
      dap.configurations.c = dap.configurations.rust
      dap.configurations.cpp = dap.configurations.rust

      ------------------------------------------------------------------------------
      -- ZIG (codelldb)
      ------------------------------------------------------------------------------
      dap.configurations.zig = {
        {
          name = "Launch Zig",
          type = "codelldb",
          request = "launch",
          program = function() return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/zig-out/bin/", "file") end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
        },
      }

      ------------------------------------------------------------------------------
      -- PYTHON (debugpy)
      ------------------------------------------------------------------------------
      dap.adapters.python = {
        type = "executable",
        command = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python",
        args = { "-m", "debugpy.adapter" },
      }

      dap.configurations.python = {
        {
          type = "python",
          request = "launch",
          name = "Launch file",
          program = "${file}",
          pythonPath = function()
            local venv = os.getenv("VIRTUAL_ENV")
            if venv then return venv .. "/bin/python" end
            local cwd_venv = vim.fn.getcwd() .. "/venv/bin/python"
            if vim.fn.executable(cwd_venv) == 1 then return cwd_venv end
            return "/usr/bin/python3"
          end,
        },
        {
          type = "python",
          request = "launch",
          name = "Launch with arguments",
          program = "${file}",
          args = function() return vim.split(vim.fn.input("Arguments: "), " ") end,
          pythonPath = function() return os.getenv("VIRTUAL_ENV") and (os.getenv("VIRTUAL_ENV") .. "/bin/python") or "/usr/bin/python3" end,
        },
      }

      ------------------------------------------------------------------------------
      -- JAVASCRIPT / TYPESCRIPT (vscode-js-debug)
      ------------------------------------------------------------------------------
      require("dap-vscode-js").setup({
        debugger_path = vim.fn.stdpath("data") .. "/lazy/vscode-js-debug",
        adapters = { "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" },
      })

      for _, lang in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact" }) do
        dap.configurations[lang] = {
          -- Node.js
          {
            type = "pwa-node",
            request = "launch",
            name = "Launch file (Node)",
            program = "${file}",
            cwd = "${workspaceFolder}",
          },
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach to Node process",
            processId = require("dap.utils").pick_process,
            cwd = "${workspaceFolder}",
          },
          -- Jest
          {
            type = "pwa-node",
            request = "launch",
            name = "Debug Jest Tests",
            runtimeExecutable = "node",
            runtimeArgs = { "./node_modules/jest/bin/jest.js", "--runInBand" },
            rootPath = "${workspaceFolder}",
            cwd = "${workspaceFolder}",
            console = "integratedTerminal",
            internalConsoleOptions = "neverOpen",
          },
          -- Chrome
          {
            type = "pwa-chrome",
            request = "launch",
            name = "Launch Chrome",
            url = "http://localhost:3000",
            webRoot = "${workspaceFolder}",
          },
        }
      end

      ------------------------------------------------------------------------------
      -- JAVA (jdtls)
      ------------------------------------------------------------------------------
      dap.configurations.java = {
        {
          type = "java",
          request = "attach",
          name = "Attach to Java process",
          hostName = "127.0.0.1",
          port = 5005,
        },
        {
          type = "java",
          request = "launch",
          name = "Launch Java file",
          mainClass = function() return vim.fn.input("Main class: ") end,
          cwd = "${workspaceFolder}",
        },
      }

      ------------------------------------------------------------------------------
      -- KEYBINDINGS
      ------------------------------------------------------------------------------
      vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
      vim.keymap.set("n", "<leader>dB", function() dap.set_breakpoint(vim.fn.input("Condition: ")) end, { desc = "Debug: Conditional Breakpoint" })
      vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Debug: Continue/Start" })
      vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Debug: Step Into" })
      vim.keymap.set("n", "<leader>do", dap.step_over, { desc = "Debug: Step Over" })
      vim.keymap.set("n", "<leader>dO", dap.step_out, { desc = "Debug: Step Out" })
      vim.keymap.set("n", "<leader>dr", dap.restart, { desc = "Debug: Restart" })
      vim.keymap.set("n", "<leader>dt", dap.terminate, { desc = "Debug: Terminate" })
      vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Debug: Toggle UI" })
      vim.keymap.set({ "n", "v" }, "<leader>de", dapui.eval, { desc = "Debug: Evaluate" })
      vim.keymap.set("n", "<leader>dl", dap.run_last, { desc = "Debug: Run Last" })
      vim.keymap.set("n", "<leader>dp", dap.pause, { desc = "Debug: Pause" })
    end,
  },
}
