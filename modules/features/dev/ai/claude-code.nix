{
  inputs,
  den,
  ...
}:
let
  # 插件源（fetchTree 避免污染 flake inputs）
  claude-plugins-official-src = builtins.fetchTree {
    type = "github";
    owner = "anthropics";
    repo = "claude-plugins-official";
    rev = "f3f92ab0303fbcc6f38a6e82d02c006311f9c557";
  };
  claude-hud-src = builtins.fetchTree {
    type = "github";
    owner = "jarrodwatts";
    repo = "claude-hud";
    rev = "b83b44593af24de1db6183788a51d08715501c02";
  };
in
{
  den.aspects.dev.ai.claude-code = {
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
          # inputs'.llm-agents-nix.packages.cc-switch-cli
          pkgs.python3
          pkgs.bun
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
            # ── 状态行 ────────────────────────────────────
            statusLine = {
              type = "command";
              command = ''
                bash -c 'cols=''${COLUMNS:-}; case "''${cols}" in ""|*[!0-9]*) cols=$(stty size </dev/tty 2>/dev/null | awk '"'"'{print $2}'"'"');; esac; case "''${cols}" in ""|*[!0-9]*) cols=120;; esac; export COLUMNS=$(( cols > 4 ? cols - 4 : 1 )); runtime=$(command -v bun 2>/dev/null); if [ -z "''${runtime}" ]; then runtime="/nix/store/r3k0n7fx6qjw9k9v2yy2h55lpl4kg0sd-bun-1.3.13/bin/bun"; fi; plugin_dir=$(ls -d "''${CLAUDE_CONFIG_DIR:-$HOME/.claude}"/plugins/cache/*/claude-hud/*/ 2>/dev/null | awk -F/ '"'"'{ print $(NF-1) "\t" $0 }'"'"' | grep -E '"'"'^[0-9]+\.[0-9]+\.[0-9]+[[:space:]]'"'"' | sort -t. -k1,1n -k2,2n -k3,3n -k4,4n | tail -1 | cut -f2-); if [ -z "''${plugin_dir}" ]; then plugin_dir="/nix/store/8qpw2h1riddi40f2ncjz14hk57m53qgf-source/"; fi; exec "''${runtime}" --env-file /dev/null "''${plugin_dir}src/index.ts"'
              '';
            };
          };

          # ── LSP 服务器 ────────────────────────────────
          lspServers = {
            nix = {
              command = "${pkgs.nixd}/bin/nixd";
              settings = {
                nixd = {
                  nixpkgs = {
                    expr = "import <nixpkgs> {}";
                  };
                  formatting = {
                    command = [ "nixfmt" ];
                  };
                  diagnostic = {
                    suppress = [ ];
                  };
                  options = {
                    nixos = {
                      expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.acer-swift.options";
                    };
                    home-manager = {
                      expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.acer-swift.options.home-manager.users.type.getSubOptions []";
                    };
                  };
                };
              };
            };
          };

          # ── MCP 服务器 ────────────────────────────────
          mcpServers = {
            nixos = {
              command = "nix";
              args = [
                "run"
                "github:utensils/mcp-nixos"
                "--"
              ];
            };
          };

          # ── 全局上下文指令 ──────────────────────────
          context = ''
            请用中文回复。参考 AGENTS.md 了解项目结构、约定和完整技能表。
          '';

          # ── 自定义斜杠命令 ──────────────────────────
          commands = {
            # check = ''
            #   ---
            #   allowed-tools: Bash(nix *)
            #   description: Run nix flake check to validate configuration
            #   ---
            #   Run `nix flake check` and report the results clearly. If there are errors, explain them and suggest fixes.
            # '';
            # build = ''
            #   ---
            #   allowed-tools: Bash(nix *)
            #   description: Build the NixOS configuration for acer-swift
            #   ---
            #   Run `nix run .#acer-swift` to build the system configuration. Report any build errors with clear explanations.
            # '';
            # deploy = ''
            #   ---
            #   allowed-tools: Bash(nix *), Bash(sudo *)
            #   description: Build and deploy the NixOS configuration (requires sudo)
            #   ---

            #   ## Context
            #   - Current host: acer-swift
            #   - Deploy command: `nix run .#acer-swift -- switch`

            #   ## Task
            #   Run the deploy command to build and switch to the new NixOS configuration.
            #   Warn the user that this requires sudo privileges and will modify the running system.
            #   After deployment, confirm success and suggest checking system status.
            # '';
          };

          # ── 声明式插件 ────────────────────────────────
          plugins = [
            "${claude-plugins-official-src}/plugins/claude-md-management"
            "${claude-plugins-official-src}/plugins/code-simplifier"
            "${claude-plugins-official-src}/plugins/code-review"
            "${claude-plugins-official-src}/plugins/skill-creator"
            "${claude-hud-src}"
          ];

          # ── 插件市场 ──────────────────────────────────
          marketplaces = {
            claude-plugins-official = claude-plugins-official-src;
          };
        };
      };
  };
}
