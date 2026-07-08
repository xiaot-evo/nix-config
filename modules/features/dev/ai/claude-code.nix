{
  inputs,
  den,
  ...
}:
{
  den.aspects.dev.editors.claude-code = {
    includes = [
      den.batteries.inputs'
      (den.batteries.unfree [ "claude-code" ])
    ];

    homeManager =
      {
        inputs',
        pkgs,
        lib,
        ...
      }:
      {
        home.packages = [
          inputs'.llm-agents-nix.packages.cc-switch-cli
          (pkgs.writeShellScriptBin "cc-ds" ''
            export ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic"
            export ANTHROPIC_AUTH_TOKEN="''${DEEPSEEK_API_KEY:?DEEPSEEK_API_KEY 环境变量未设置}"
            export ANTHROPIC_MODEL="deepseek-v4-pro[1m]"
            export ANTHROPIC_DEFAULT_OPUS_MODEL="deepseek-v4-pro[1m]"
            export ANTHROPIC_DEFAULT_SONNET_MODEL="deepseek-v4-pro[1m]"
            export ANTHROPIC_DEFAULT_HAIKU_MODEL="deepseek-v4-flash"
            export ANTHROPIC_SMALL_FAST_MODEL="deepseek-v4-flash"
            export CLAUDE_CODE_SUBAGENT_MODEL="deepseek-v4-flash"
            export CLAUDE_CODE_EFFORT_LEVEL="max"
            exec claude "$@"
          '')
        ];

        programs.claude-code = {
          enable = true;
          package = inputs'.llm-agents-nix.packages.claude-code;

          # ── 权限配置 ─────────────────────────────────
          settings = {
            theme = "auto";
            includeCoAuthoredBy = true;

            permissions = {
              allow = [
                "Bash(nix *)"
                "Bash(git *)"
                "Bash(devenv *)"
                "WebSearch"
                "WebFetch"
                "Read(./**)"
                "Edit(./**)"
              ];
              deny = [
                "Read(./.env)"
                "Read(./.env.*)"
                "Read(./secrets/**)"
                "Read(./**/.env)"
                "Read(./**/secrets/**)"
                "Bash(rm:*)"
                "Bash(sudo:*)"
              ];
              defaultMode = "acceptEdits";
            };

            # ── 自动格式化 Hook ────────────────────────
            hooks = {
              PostToolUse = [
                {
                  matcher = "Edit|Write";
                  hooks = [
                    {
                      type = "command";
                      command = ''
                        FILE=$(echo "$CLAUDE_TOOL_INPUT" | ${pkgs.jq}/bin/jq -r '.tool_input.file_path // ""')
                        if [ -n "$FILE" ] && [ "''${FILE##*.}" = "nix" ]; then
                          ${pkgs.nixfmt}/bin/nixfmt "$FILE"
                        fi
                      '';
                    }
                  ];
                }
              ];
            };

            # ── 状态行 ──────────────────────────────────
            statusLine = {
              type = "command";
              command = ''
                input=$(cat)
                model=$(echo "$input" | ${pkgs.jq}/bin/jq -r '.model.display_name // "?"')
                dir=$(basename "$(echo "$input" | ${pkgs.jq}/bin/jq -r '.workspace.current_dir // ""')")
                echo "[$model] 📁 $dir"
              '';
              padding = 0;
            };
          };

          # ── LSP 服务器 ────────────────────────────────
          lspServers = {
            nix = {
              command = "nil";
            };
          };

          # ── 全局上下文指令 ──────────────────────────
          context = ''
            请用中文回复。参考 AGENTS.md 了解项目结构、约定和完整技能表。
          '';

          # ── 自定义斜杠命令 ──────────────────────────
          commands = {
            check = ''
              ---
              allowed-tools: Bash(nix *)
              description: Run nix flake check to validate configuration
              ---
              Run `nix flake check` and report the results clearly. If there are errors, explain them and suggest fixes.
            '';
            build = ''
              ---
              allowed-tools: Bash(nix *)
              description: Build the NixOS configuration for acer-swift
              ---
              Run `nix run .#acer-swift` to build the system configuration. Report any build errors with clear explanations.
            '';
            deploy = ''
              ---
              allowed-tools: Bash(nix *), Bash(sudo *)
              description: Build and deploy the NixOS configuration (requires sudo)
              ---

              ## Context
              - Current host: acer-swift
              - Deploy command: `nix run .#acer-swift -- switch`

              ## Task
              Run the deploy command to build and switch to the new NixOS configuration.
              Warn the user that this requires sudo privileges and will modify the running system.
              After deployment, confirm success and suggest checking system status.
            '';
          };

          # ── 声明式插件 ────────────────────────────────
          plugins = [
            "${inputs.claude-plugins-official}/plugins/claude-md-management"
            "${inputs.claude-plugins-official}/plugins/code-simplifier"
            "${inputs.claude-plugins-official}/plugins/code-review"
            "${inputs.claude-plugins-official}/plugins/skill-creator"
          ];

          # ── 插件市场 ──────────────────────────────────
          marketplaces = {
            claude-plugins-official = inputs.claude-plugins-official;
          };
        };
      };
  };
}
