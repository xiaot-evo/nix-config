{ den, inputs, ... }:
let
  charm = inputs.charmbracelet-nur;
in
{
  den.aspects.dev.editors.crush = {
    includes = [
      den.batteries.inputs'
      (den.batteries.unfree [ "crush" ])
    ];
    # ──────────────────────────────────────────────
    # Crush — Charmbracelet 的终端 AI 编程助手
    # 声明式配置模板，通过 NUR (charmbracelet/nur) 管理
    # 文档: https://github.com/charmbracelet/crush
    #
    # 使用方式：在 host/user 的 includes 中添加：
    #   den.aspects.dev.editors.crush
    #
    # API 密钥通过环境变量注入（不硬编码在配置中）：
    #   export ANTHROPIC_API_KEY="sk-..."
    #   export OPENAI_API_KEY="sk-..."
    # ──────────────────────────────────────────────

    homeManager = { pkgs, inputs', ... }: {
      imports = [ charm.homeModules.crush ];

      programs.crush = {
        enable = true;

        # ── 包来源 ──────────────────────────────────
        package = inputs'.llm-agents-nix.packages.crush;

        settings = {
          # ── 模型选择 ─────────────────────────────
          models = {
            large = {
              model = "deepseek-v4-flash-free";
              provider = "opencode-zen";
              reasoning_effort = "high";
              think = true;
            };
            small = {
              model = "big-pickle";
              provider = "opencode-zen";
            };
          };

          # ── AI 提供商 ────────────────────────────
          # 支持: openai, openai-compat, anthropic, google, bedrock, azure,
          #       google-vertex, ollama, llamacpp, lmstudio, litellm
          # API 密钥通过环境变量设置（ANTHROPIC_API_KEY / OPENAI_API_KEY 等）
          providers = { };

          # ── LSP 服务 ─────────────────────────────
          lsp = {
            nix = {
              command = "nil";
            };
          };

          # ── MCP 服务 ─────────────────────────────
          mcp = {
            nixos = {
              type = "stdio";
              command = "nix";
              args = [
                "run"
                "github:jsiegel-supplyframe/mcp-nixos/nix-taco-sprint/den-source"
                "--"
              ];
            };
            github = {
              type = "http";
              url = "https://api.githubcopilot.com/mcp/";
              timeout = 120;
              disabled = true;
            };
          };

          # ── 全局选项 ─────────────────────────────
          options = {
            context_paths = [ "AGENTS.md" ];
            initialize_as = "AGENTS.md";

            tui = {
              transparent = true;
              completions = {
                max_depth = 0;
                max_items = 1000;
              };
            };

            notification_style = "auto";

            attribution = {
              trailer_style = "assisted-by";
              generated_with = true;
            };
          };

          # ── 免确认工具 ───────────────────────────
          permissions = {
            allowed_tools = [
              "view"
              "ls"
              "grep"
              "nixos"
              "github"
            ];
          };
        };
      };
    };
  };
}
