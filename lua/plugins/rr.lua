-- rr Record & Replay debugging (Linux-only)
-- Time-travel debugging for Rust, C, C++, Zig via rr + cppdbg adapter
-- Requires: rr, gdb, Mason cpptools. Run scripts/linux-install-rr.sh to install.

-- Guard: only load on Linux with rr available
if vim.fn.has("linux") ~= 1 or vim.fn.executable("rr") ~= 1 then
  return {}
end

return {
  -- Virtual plugin: uses dir pointing at nvim config so it doesn't conflict with
  -- the main nvim-dap spec in dap.lua
  {
    dir = vim.fn.stdpath("config"),
    name = "rr-debug",
    dependencies = {
      "mfussenegger/nvim-dap",
      "jay-babu/mason-nvim-dap.nvim",
    },
    ft = { "rust", "c", "cpp", "zig" },
    config = function()
      local dap = require("dap")

      --------------------------------------------------------------------------
      -- MASON: ensure cpptools is installed
      --------------------------------------------------------------------------
      local mason_dap_ok, mason_dap = pcall(require, "mason-nvim-dap")
      if mason_dap_ok then
        local cfg = mason_dap.get_config and mason_dap.get_config() or {}
        local installed = cfg.ensure_installed or {}
        local has_cpptools = false
        for _, v in ipairs(installed) do
          if v == "cpptools" then
            has_cpptools = true
            break
          end
        end
        if not has_cpptools then
          -- Trigger Mason install of cpptools on first load
          vim.defer_fn(function()
            vim.cmd("MasonInstall cpptools")
          end, 2000)
        end
      end

      --------------------------------------------------------------------------
      -- CPPDBG ADAPTER
      --------------------------------------------------------------------------
      local cpptools_path = vim.fn.stdpath("data")
        .. "/mason/packages/cpptools/extension/debugAdapters/bin/OpenDebugAD7"

      if not dap.adapters.cppdbg then
        dap.adapters.cppdbg = {
          id = "cppdbg",
          type = "executable",
          command = cpptools_path,
        }
      end

      --------------------------------------------------------------------------
      -- HELPERS
      --------------------------------------------------------------------------
      --- Send a GDB command via the cppdbg evaluate interface
      local function rr_exec(cmd)
        local session = dap.session()
        if not session then
          vim.notify("No active DAP session", vim.log.levels.WARN)
          return
        end
        session:evaluate("-exec " .. cmd, function(err)
          if err then
            vim.notify("rr exec error: " .. vim.inspect(err), vim.log.levels.ERROR)
          end
        end)
      end

      --- Find project root by walking up from current file
      local function find_project_root(markers)
        local file_dir = vim.fn.expand("%:p:h")
        for _, marker in ipairs(markers) do
          local found = vim.fn.findfile(marker, file_dir .. ";")
          if found ~= "" then
            return vim.fn.fnamemodify(found, ":p:h")
          end
          local found_dir = vim.fn.finddir(marker, file_dir .. ";")
          if found_dir ~= "" then
            return vim.fn.fnamemodify(found_dir, ":p:h")
          end
        end
        return file_dir
      end

      --------------------------------------------------------------------------
      -- DAP CONFIGURATIONS (appended to existing ones from dap.lua)
      --------------------------------------------------------------------------
      local rr_base = {
        type = "cppdbg",
        request = "launch",
        miDebuggerServerAddress = "127.0.0.1:50505",
        miMode = "gdb",
        setupCommands = {
          { text = "set sysroot /", description = "Set sysroot", ignoreFailures = false },
          { text = "set print pretty on", description = "Pretty print", ignoreFailures = true },
        },
        stopAtEntry = true,
        cwd = "${workspaceFolder}",
      }

      -- Rust rr config
      local rust_rr = vim.tbl_deep_extend("force", rr_base, {
        name = "rr: Replay Binary (Rust)",
        program = function()
          local root = find_project_root({ "Cargo.toml", ".git" })
          return vim.fn.input("Path to executable: ", root .. "/target/debug/", "file")
        end,
        sourceFileMap = {
          ["/rustc/"] = "${env:HOME}/.rustup/toolchains/",
        },
      })

      -- C/C++ rr config
      local c_rr = vim.tbl_deep_extend("force", rr_base, {
        name = "rr: Replay Binary",
        program = function()
          local root = find_project_root({ "CMakeLists.txt", "Makefile", "compile_commands.json", ".git" })
          return vim.fn.input("Path to executable: ", root .. "/", "file")
        end,
      })

      -- Zig rr config
      local zig_rr = vim.tbl_deep_extend("force", rr_base, {
        name = "rr: Replay Binary (Zig)",
        program = function()
          local root = find_project_root({ "build.zig", "build.zig.zon", ".git" })
          return vim.fn.input("Path to executable: ", root .. "/zig-out/bin/", "file")
        end,
      })

      -- Append to existing configuration tables
      dap.configurations.rust = dap.configurations.rust or {}
      table.insert(dap.configurations.rust, rust_rr)

      dap.configurations.c = dap.configurations.c or {}
      table.insert(dap.configurations.c, c_rr)

      dap.configurations.cpp = dap.configurations.cpp or {}
      -- Only add if cpp isn't just a reference to c (dap.lua sets cpp = c)
      if dap.configurations.cpp ~= dap.configurations.c then
        table.insert(dap.configurations.cpp, vim.tbl_deep_extend("force", c_rr, {}))
      else
        -- cpp was set as alias to c, so we need a separate table
        local cpp_configs = vim.deepcopy(dap.configurations.c)
        table.insert(cpp_configs, vim.tbl_deep_extend("force", c_rr, {}))
        dap.configurations.cpp = cpp_configs
      end

      dap.configurations.zig = dap.configurations.zig or {}
      table.insert(dap.configurations.zig, zig_rr)

      --------------------------------------------------------------------------
      -- STATE
      --------------------------------------------------------------------------
      local replay_job_id = nil

      --------------------------------------------------------------------------
      -- USER COMMANDS
      --------------------------------------------------------------------------

      --- Detect project type and suggest binary path
      local function detect_binary()
        local cwd = vim.fn.getcwd()
        if vim.fn.filereadable(cwd .. "/Cargo.toml") == 1 then
          return cwd .. "/target/debug/"
        elseif vim.fn.filereadable(cwd .. "/build.zig") == 1 then
          return cwd .. "/zig-out/bin/"
        elseif vim.fn.filereadable(cwd .. "/Makefile") == 1 or vim.fn.filereadable(cwd .. "/CMakeLists.txt") == 1 then
          return cwd .. "/"
        end
        return cwd .. "/"
      end

      -- :RRRecord [binary] [args]
      vim.api.nvim_create_user_command("RRRecord", function(opts)
        local args = opts.fargs
        local binary, extra_args

        if #args >= 1 then
          binary = args[1]
          extra_args = table.concat(vim.list_slice(args, 2), " ")
        else
          local hint = detect_binary()
          binary = vim.fn.input("Binary to record: ", hint, "file")
          if binary == "" then
            vim.notify("RRRecord: no binary specified", vim.log.levels.WARN)
            return
          end
          extra_args = vim.fn.input("Arguments (optional): ")
        end

        local cmd = "rr record " .. vim.fn.shellescape(binary)
        if extra_args and extra_args ~= "" then
          cmd = cmd .. " " .. extra_args
        end

        -- Open a 15-line bottom terminal split
        vim.cmd("botright 15split | terminal " .. cmd)
        vim.cmd("startinsert")

        -- Notify on exit
        local term_buf = vim.api.nvim_get_current_buf()
        vim.api.nvim_create_autocmd("TermClose", {
          buffer = term_buf,
          once = true,
          callback = function()
            vim.schedule(function()
              vim.notify("rr record finished. Use :RRReplay to start the replay server.", vim.log.levels.INFO)
            end)
          end,
        })
      end, {
        nargs = "*",
        complete = "file",
        desc = "Record a binary with rr",
      })

      -- :RRReplay [port]
      vim.api.nvim_create_user_command("RRReplay", function(opts)
        local port = opts.fargs[1] or "50505"

        -- Kill previous replay if running
        if replay_job_id then
          pcall(vim.fn.jobstop, replay_job_id)
          replay_job_id = nil
        end

        replay_job_id = vim.fn.jobstart({ "rr", "replay", "-s", port, "-k" }, {
          detach = false,
          on_exit = function(_, code)
            replay_job_id = nil
            vim.schedule(function()
              if code ~= 0 then
                vim.notify("rr replay exited with code " .. code, vim.log.levels.ERROR)
              else
                vim.notify("rr replay server stopped", vim.log.levels.INFO)
              end
            end)
          end,
        })

        if replay_job_id <= 0 then
          vim.notify("Failed to start rr replay", vim.log.levels.ERROR)
          replay_job_id = nil
          return
        end

        -- Wait for gdbserver to be ready, then notify
        vim.defer_fn(function()
          vim.notify(
            "Replay server started on port " .. port .. ". Use <leader>dc and pick an rr config.",
            vim.log.levels.INFO
          )
        end, 500)
      end, {
        nargs = "?",
        desc = "Start rr replay server (default port 50505)",
      })

      -- :RRStop
      vim.api.nvim_create_user_command("RRStop", function()
        if replay_job_id then
          pcall(vim.fn.jobstop, replay_job_id)
          replay_job_id = nil
          vim.notify("rr replay server stopped", vim.log.levels.INFO)
        else
          vim.notify("No rr replay server running", vim.log.levels.WARN)
        end
      end, {
        desc = "Stop rr replay server",
      })

      --------------------------------------------------------------------------
      -- KEYBINDINGS: reverse debugging (leader-dR prefix)
      --------------------------------------------------------------------------
      local function map(key, gdb_cmd, desc)
        vim.keymap.set("n", "<leader>dR" .. key, function()
          rr_exec(gdb_cmd)
        end, { desc = desc })
      end

      map("c", "reverse-continue", "rr: Reverse Continue")
      map("i", "reverse-step", "rr: Reverse Step Into")
      map("o", "reverse-next", "rr: Reverse Step Over")
      map("O", "reverse-finish", "rr: Reverse Step Out")

      -- Register which-key group if available
      local wk_ok, wk = pcall(require, "which-key")
      if wk_ok then
        wk.add({
          { "<leader>dR", group = "rr reverse" },
        })
      end
    end,
  },
}
