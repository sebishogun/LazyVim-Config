-- 99.lua - ThePrimeagen's AI Agent for Neovim
-- Fork: https://github.com/sebishogun/99
-- Added CopilotCLIProvider support

return {
  {
    -- Use local fork with CopilotCLIProvider support
    dir = "~/neovim-configs/99",
    -- Alternatively, use the remote fork:
    -- "sebishogun/99",
    config = function()
      -- Ensure queries directory is in runtime path for treesitter
      local plugin_path = vim.fn.expand("~/neovim-configs/99")
      if not vim.tbl_contains(vim.opt.runtimepath:get(), plugin_path) then
        vim.opt.runtimepath:append(plugin_path)
      end

      -- Protected require - bail out gracefully if plugin not found
      local ok, _99 = pcall(require, "99")
      if not ok then
        vim.notify("99 plugin not found at " .. plugin_path, vim.log.levels.WARN)
        return
      end

      -- Get the cwd basename for log file naming
      local cwd = vim.uv.cwd()
      local basename = vim.fs.basename(cwd)

      -- Helper: check if copilot CLI is available
      local function is_copilot_available()
        return vim.fn.executable("copilot") == 1
      end

      -- Auto-detect best available AI CLI provider
      -- Priority: OpenCode > Claude Code > Copilot CLI
      local function detect_provider()
        if vim.fn.executable("opencode") == 1 then
          return _99.Providers.OpenCodeProvider, "anthropic/claude-opus-4-6"
        elseif vim.fn.executable("claude") == 1 then
          return _99.Providers.ClaudeCodeProvider, "claude-opus-4-6"
        elseif is_copilot_available() then
          return _99.Providers.CopilotCLIProvider, "claude-opus-4.6"
        end
        -- Fallback to OpenCode (will error if not installed, prompting user to install)
        return _99.Providers.OpenCodeProvider, "anthropic/claude-opus-4-6"
      end

      local default_provider, default_model = detect_provider()

      _99.setup({
        -- Logger configuration
        logger = {
          level = _99.INFO, -- Change to _99.DEBUG for troubleshooting
          path = "/tmp/" .. basename .. ".99.debug",
          print_on_error = true,
        },

        -- Auto-detected provider (OpenCode > Claude > Copilot)
        provider = default_provider,
        model = default_model,

        -- Completion settings for cmp autocomplete
        -- NOTE: Set source = "cmp" if you have nvim-cmp installed and want @ completion
        completion = {
          source = nil, -- Disable cmp integration for now
          custom_rules = {
            -- Add custom rules directories here if needed
            -- "scratch/custom_rules/",
          },
        },

        -- Auto-add AGENT.md files from project directories
        md_files = {
          "AGENT.md",
          "AGENTS.md",
        },

        -- Display errors in virtual text
        display_errors = true,

        -- Auto-add skills when @ is used in prompts
        auto_add_skills = true,
      })

      -- ╭──────────────────────────────────────────────────────────╮
      -- │                      Keymaps                             │
      -- ╰──────────────────────────────────────────────────────────╯

      -- Fill in function - AI generates function body
      vim.keymap.set("n", "<leader>9f", function()
        _99.fill_in_function()
      end, { desc = "99: Fill in function" })

      -- Fill in function with custom prompt
      vim.keymap.set("n", "<leader>9F", function()
        _99.fill_in_function_prompt()
      end, { desc = "99: Fill in function (with prompt)" })

      -- Visual selection - AI processes selected code
      -- NOTE: Only works in visual mode to prevent using stale selections
      vim.keymap.set("v", "<leader>9v", function()
        _99.visual()
      end, { desc = "99: Process visual selection" })

      -- Visual selection with custom prompt
      vim.keymap.set("v", "<leader>9V", function()
        _99.visual_prompt()
      end, { desc = "99: Process selection (with prompt)" })

      -- Stop all active requests
      vim.keymap.set("n", "<leader>9s", function()
        _99.stop_all_requests()
      end, { desc = "99: Stop all requests" })

      -- View logs from last request
      vim.keymap.set("n", "<leader>9l", function()
        _99.view_logs()
      end, { desc = "99: View logs" })

      -- Navigate logs
      vim.keymap.set("n", "<leader>9[", function()
        _99.prev_request_logs()
      end, { desc = "99: Previous request logs" })

      vim.keymap.set("n", "<leader>9]", function()
        _99.next_request_logs()
      end, { desc = "99: Next request logs" })

      -- Show plugin info
      vim.keymap.set("n", "<leader>9i", function()
        _99.info()
      end, { desc = "99: Show info" })

      -- Previous requests to quickfix list
      vim.keymap.set("n", "<leader>9q", function()
        _99.previous_requests_to_qfix()
      end, { desc = "99: Requests to quickfix" })

      -- Clear previous requests
      vim.keymap.set("n", "<leader>9c", function()
        _99.clear_previous_requests()
      end, { desc = "99: Clear previous requests" })

      -- ╭──────────────────────────────────────────────────────────╮
      -- │                 Model Fetching                           │
      -- ╰──────────────────────────────────────────────────────────╯

      -- Cached models for current provider
      local cached_models = {}
      local current_provider_name = ""

      -- Helper to sync local cache to global
      local function sync_cache()
        _G._99_cached_models = cached_models
      end

      -- Fetch models from CLI (async)
      local function fetch_models(provider_name, callback)
        local cmd = nil
        if provider_name == "OpenCodeProvider" then
          cmd = { "opencode", "models" }
        elseif provider_name == "GeminiProvider" then
          cached_models = {
            "gemini-3-pro-preview",
            "gemini-3-flash",
            "gemini-2.5-pro",
            "gemini-2.5-flash",
            "gemini-2.0-flash",
          }
          current_provider_name = provider_name
          sync_cache()
          if callback then callback() end
          return
        elseif provider_name == "ClaudeCodeProvider" then
          cached_models = {
            "claude-opus-4-6",
            "claude-opus-4-5",
            "claude-sonnet-4-5",
            "claude-sonnet-4",
            "claude-haiku-4-5",
            "opus",
            "sonnet",
          }
          current_provider_name = provider_name
          sync_cache()
          if callback then callback() end
          return
        elseif provider_name == "CodexProvider" then
          cached_models = {
            "gpt-codex-5.3",
            "gpt-codex-5.2",
            "gpt-5.2-codex",
            "gpt-5.1-codex-max",
            "gpt-5.1-codex",
            "o3",
            "o4-mini",
          }
          current_provider_name = provider_name
          sync_cache()
          if callback then callback() end
          return
        elseif provider_name == "CopilotCLIProvider" then
          cached_models = {
            "claude-opus-4.6",
            "claude-opus-4.5",
            "claude-sonnet-4.5",
            "claude-sonnet-4",
            "claude-haiku-4.5",
            "gpt-5.2-codex",
            "gpt-5.2",
            "gpt-5.1-codex-max",
            "gpt-5.1-codex",
            "gpt-5.1",
            "gpt-5",
            "gemini-3-pro-preview",
          }
          current_provider_name = provider_name
          sync_cache()
          if callback then callback() end
          return
        else
          cached_models = {}
          current_provider_name = provider_name
          sync_cache()
          if callback then callback() end
          return
        end

        -- Run async for OpenCode
        vim.system(cmd, { text = true }, function(obj)
          vim.schedule(function()
            if obj.code == 0 and obj.stdout then
              cached_models = {}
              for line in obj.stdout:gmatch("[^\r\n]+") do
                if line ~= "" then
                  table.insert(cached_models, line)
                end
              end
              current_provider_name = provider_name
              sync_cache()
              if callback then callback() end
            end
          end)
        end)
      end

      -- ╭──────────────────────────────────────────────────────────╮
      -- │                 Provider Switching                       │
      -- ╰──────────────────────────────────────────────────────────╯

      -- Available providers for completion
      local available_providers = {
        { name = "opencode", provider = "OpenCodeProvider", model = "anthropic/claude-opus-4-6" },
        { name = "claude", provider = "ClaudeCodeProvider", model = "claude-opus-4-6" },
        { name = "copilot", provider = "CopilotCLIProvider", model = "claude-opus-4.6" },
        { name = "gemini", provider = "GeminiProvider", model = "gemini-3-pro-preview" },
        { name = "codex", provider = "CodexProvider", model = "gpt-codex-5.3" },
        { name = "cursor", provider = "CursorAgentProvider", model = "sonnet-4.5" },
        { name = "kiro", provider = "KiroProvider", model = "claude-sonnet-4.5" },
      }

      -- Provider completion function
      function _G.NNProviderComplete(arg_lead, cmd_line, cursor_pos)
        local matches = {}
        for _, p in ipairs(available_providers) do
          if arg_lead == "" or p.name:lower():find(arg_lead:lower(), 1, true) then
            table.insert(matches, p.name)
          end
        end
        return table.concat(matches, "\n")
      end

      -- Switch provider with completion
      vim.api.nvim_create_user_command("NNProvider", function(opts)
        if opts.args and opts.args ~= "" then
          local provider_name = opts.args:lower()
          for _, p in ipairs(available_providers) do
            if p.name == provider_name then
              local state = _99.__get_state()
              state.provider_override = _99.Providers[p.provider]
              state.model = p.model
              fetch_models(p.provider, function()
                print("99: Switched to " .. p.name .. " (" .. p.model .. ") - " .. #cached_models .. " models")
              end)
              return
            end
          end
          print("99: Unknown provider: " .. opts.args)
        else
          print("99: Available providers: opencode, claude, copilot, gemini, codex, cursor, kiro")
        end
      end, {
        nargs = "?",
        desc = "Switch AI provider",
        complete = "customlist,v:lua.NNProviderComplete",
      })

      -- Quick provider switch commands
      vim.api.nvim_create_user_command("NNOpenCode", function()
        local state = _99.__get_state()
        state.provider_override = _99.Providers.OpenCodeProvider
        state.model = "anthropic/claude-opus-4-6"
        fetch_models("OpenCodeProvider", function()
          print("99: Switched to OpenCode (claude-opus-4-6) - " .. #cached_models .. " models available")
        end)
      end, { desc = "Switch to OpenCode provider" })

      vim.api.nvim_create_user_command("NNOpenAI", function()
        local state = _99.__get_state()
        state.provider_override = _99.Providers.OpenCodeProvider
        state.model = "openai/gpt-codex-5.3"
        fetch_models("OpenCodeProvider", function()
          print("99: Switched to OpenCode (gpt-codex-5.3) - " .. #cached_models .. " models available")
        end)
      end, { desc = "Switch to OpenCode with OpenAI model" })

      vim.api.nvim_create_user_command("NNClaude", function()
        local state = _99.__get_state()
        state.provider_override = _99.Providers.ClaudeCodeProvider
        state.model = "claude-opus-4-6"
        fetch_models("ClaudeCodeProvider", function()
          print("99: Switched to Claude Code (claude-opus-4-6) - " .. #cached_models .. " models available")
        end)
      end, { desc = "Switch to Claude Code provider" })

      vim.api.nvim_create_user_command("NNCopilot", function()
        local state = _99.__get_state()
        state.provider_override = _99.Providers.CopilotCLIProvider
        state.model = "claude-opus-4.6"
        fetch_models("CopilotCLIProvider", function()
          print("99: Switched to Copilot CLI (claude-opus-4.6) - " .. #cached_models .. " models available")
        end)
      end, { desc = "Switch to Copilot CLI provider" })

      vim.api.nvim_create_user_command("NNCursor", function()
        local state = _99.__get_state()
        state.provider_override = _99.Providers.CursorAgentProvider
        state.model = "sonnet-4.5"
        cached_models = { "sonnet-4.5", "opus-4.5", "gpt-4o" }
        current_provider_name = "CursorAgentProvider"
        sync_cache()
        print("99: Switched to Cursor Agent")
      end, { desc = "Switch to Cursor Agent provider" })

      vim.api.nvim_create_user_command("NNKiro", function()
        local state = _99.__get_state()
        state.provider_override = _99.Providers.KiroProvider
        state.model = "claude-sonnet-4.5"
        cached_models = { "claude-sonnet-4.5" }
        current_provider_name = "KiroProvider"
        sync_cache()
        print("99: Switched to Kiro")
      end, { desc = "Switch to Kiro provider" })

      vim.api.nvim_create_user_command("NNGemini", function()
        local state = _99.__get_state()
        state.provider_override = _99.Providers.GeminiProvider
        state.model = "gemini-3-pro-preview"
        fetch_models("GeminiProvider", function()
          print("99: Switched to Gemini (gemini-3-pro-preview) - " .. #cached_models .. " models available")
        end)
      end, { desc = "Switch to Gemini provider" })

      vim.api.nvim_create_user_command("NNCodex", function()
        local state = _99.__get_state()
        state.provider_override = _99.Providers.CodexProvider
        state.model = "gpt-codex-5.3"
        fetch_models("CodexProvider", function()
          print("99: Switched to Codex (gpt-codex-5.3) - " .. #cached_models .. " models available")
        end)
      end, { desc = "Switch to Codex provider" })

      -- Model completion function
      function _G.NNModelComplete(arg_lead, cmd_line, cursor_pos)
        local models = _G._99_cached_models or {}
        local matches = {}
        for _, model in ipairs(models) do
          if arg_lead == "" or model:lower():find(arg_lead:lower(), 1, true) then
            table.insert(matches, model)
          end
        end
        return table.concat(matches, "\n")
      end

      -- Set custom model with dynamic completion from cached models
      vim.api.nvim_create_user_command("NNModel", function(opts)
        if opts.args and opts.args ~= "" then
          _99.set_model(opts.args)
          print("99: Model set to " .. opts.args)
        else
          local state = _99.__get_state()
          print("99: Current model: " .. state.model)
          if #cached_models > 0 then
            print("99: Available models (" .. current_provider_name .. "):")
            for i, model in ipairs(cached_models) do
              if i <= 10 then
                print("  " .. model)
              elseif i == 11 then
                print("  ... and " .. (#cached_models - 10) .. " more (use Tab for completion)")
                break
              end
            end
          end
        end
      end, {
        nargs = "?",
        desc = "Set or show current model",
        complete = "customlist,v:lua.NNModelComplete",
      })

      -- Show current provider and available providers
      vim.api.nvim_create_user_command("NNStatus", function()
        local state = _99.__get_state()
        local provider_name = "Unknown"
        if state.provider_override then
          provider_name = state.provider_override._get_provider_name and state.provider_override:_get_provider_name() or "Custom"
        elseif default_provider then
          provider_name = default_provider._get_provider_name and default_provider:_get_provider_name() or "Default"
        end
        
        print("99 AI Agent Status:")
        print("  Provider: " .. provider_name)
        print("  Model: " .. state.model)
        print("  Cached models: " .. #cached_models)
        print("")
        print("Available CLIs:")
        print("  OpenCode: " .. (vim.fn.executable("opencode") == 1 and "✓" or "✗"))
        print("  Claude:   " .. (vim.fn.executable("claude") == 1 and "✓" or "✗"))
        print("  Copilot:  " .. (is_copilot_available() and "✓" or "✗"))
        print("  Gemini:   " .. (vim.fn.executable("gemini") == 1 and "✓" or "✗"))
        print("  Codex:    " .. (vim.fn.executable("codex") == 1 and "✓" or "✗"))
      end, { desc = "Show 99 plugin status" })

      -- Pre-populate model cache for the default provider on startup
      local default_provider_name = default_provider._get_provider_name and default_provider:_get_provider_name() or "OpenCodeProvider"
      fetch_models(default_provider_name)
    end,
  },
}
