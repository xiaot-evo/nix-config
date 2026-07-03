{ den, ... }:
let
  # Common librarian preset (shared across all presets)
  librarianAgent = {
    model = "opencode/big-pickle";
    variant = "low";
    skills = [ ];
    mcps = [
      "websearch"
      "context7"
      "gh_grep"
    ];
  };

  # Build a complete preset from per-agent model/variant configs.
  # Each agent gets common skills/mcps merged with its unique model/variant.
  mkPreset =
    {
      orchestrator,
      oracle,
      council,
      explorer,
      designer,
      fixer,
    }:
    {
      orchestrator = orchestrator // {
        skills = [ "*" ];
        mcps = [
          "*"
          "!context7"
        ];
      };
      oracle = oracle // {
        skills = [ "simplify" ];
        mcps = [ ];
      };
      council = council // {
        skills = [ ];
        mcps = [ ];
      };
      librarian = librarianAgent;
      explorer = explorer // {
        skills = [ ];
        mcps = [ ];
      };
      designer = designer // {
        skills = [ ];
        mcps = [ ];
      };
      fixer = fixer // {
        skills = [ ];
        mcps = [ ];
      };
    };
in
{
  den.aspects.dev.editors.opencode = {
    includes = [
      den.batteries.inputs'
    ];
    homeManager = { pkgs, inputs', ... }: {
      programs.opencode = {

        enable = true;
        # 使用 llm-agents.nix 提供的包
        package = inputs'.llm-agents-nix.packages.opencode;
        tui.theme = "opencode";
        settings = {
          plugin = [
            "@cortexkit/opencode-magic-context"
            "opencode-antigravity-auth@latest"
            "superpowers@git+https://github.com/obra/superpowers.git"
            "oh-my-opencode-slim@latest"
          ];
          compaction = {
            auto = false;
            prune = false;
          };
          mcp.nixos = {
            enabled = true;
            type = "local";
            command = [
              "nix"
              "run"
              "github:utensils/mcp-nixos"
              "--"
            ];
          };
          agent = {
            explore.disable = true;
            general.disable = true;
          };
          lsp = true;
        };
      };
      # Force overwrite instead of creating backups — prevents ".bak would be clobbered" on re-deploy
      xdg.configFile."opencode/tui.json".force = true;
      xdg.configFile."opencode/opencode.json".force = true;
      home.sessionVariables = {
        OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS = "true";
      };
      xdg.configFile."opencode/oh-my-opencode-slim.json" = {
        force = true;
        text = builtins.toJSON {
          "$schema" = "https://unpkg.com/oh-my-opencode-slim@latest/oh-my-opencode-slim.schema.json";
          preset = "deepseek-zen";
          disabled_agents = [ "observer" ];
          presets = {
            "deepseek-zen" = mkPreset {
              orchestrator = {
                model = [
                  "deepseek/deepseek-v4-flash"
                  "opencode/nemotron-3-ultra-free"
                ];
                variant = "medium";
              };
              oracle = {
                model = [
                  "deepseek/deepseek-v4-pro"
                  "opencode/mimo-v2.5-free"
                ];
                variant = "high";
              };
              council = {
                model = "opencode/north-mini-code-free";
                variant = "low";
              };
              explorer = {
                model = "opencode/north-mini-code-free";
                variant = "low";
              };
              designer = {
                model = "opencode/mimo-v2.5-free";
                variant = "medium";
              };
              fixer = {
                model = [
                  "opencode/north-mini-code-free"
                  "opencode/deepseek-v4-flash-free"
                ];
                variant = "low";
              };
            };
            "deepseek-pro" = mkPreset {
              orchestrator = {
                model = "deepseek/deepseek-v4-pro";
                variant = "medium";
              };
              oracle = {
                model = "deepseek/deepseek-v4-pro";
                variant = "max";
              };
              council = {
                model = "opencode/nemotron-3-ultra-free";
                variant = "medium";
              };
              explorer = {
                model = "opencode/north-mini-code-free";
                variant = "low";
              };
              designer = {
                model = "opencode/mimo-v2.5-free";
                variant = "medium";
              };
              fixer = {
                model = "deepseek/deepseek-v4-flash";
                variant = "low";
              };
            };
            "zen-free" = mkPreset {
              orchestrator = {
                model = "opencode/nemotron-3-ultra-free";
                variant = "medium";
              };
              oracle = {
                model = "opencode/mimo-v2.5-free";
                variant = "high";
              };
              council = {
                model = "opencode/north-mini-code-free";
                variant = "low";
              };
              explorer = {
                model = "opencode/north-mini-code-free";
                variant = "low";
              };
              designer = {
                model = "opencode/mimo-v2.5-free";
                variant = "medium";
              };
              fixer = {
                model = [
                  "opencode/north-mini-code-free"
                  "opencode/deepseek-v4-flash-free"
                ];
                variant = "low";
              };
            };
          };
          council = {
            default_preset = "quick";
            councillor_execution_mode = "serial";
            councillor_retries = 2;
            timeout = 180000;
            presets = {
              quick = {
                councillor = {
                  model = "opencode/north-mini-code-free";
                  variant = "low";
                };
              };
              deep = {
                "councillor-A" = {
                  model = "opencode/nemotron-3-ultra-free";
                  variant = "medium";
                };
                "councillor-B" = {
                  model = "opencode/mimo-v2.5-free";
                  variant = "medium";
                };
                "councillor-C" = {
                  model = "opencode/north-mini-code-free";
                  variant = "medium";
                };
              };
            };
          };
        };
      };
    };
  };
}
