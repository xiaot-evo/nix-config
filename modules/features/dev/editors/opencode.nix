{ den, ... }:
{
  den.aspects.dev.editors.opencode = {
    homeManager = {
      programs.opencode = {

        enable = true;
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
        text = ''
          {
            "$schema": "https://unpkg.com/oh-my-opencode-slim@latest/oh-my-opencode-slim.schema.json",

            "preset": "deepseek-zen",
            "disabled_agents": ["observer"],

            "presets": {
              "deepseek-zen": {
                "orchestrator": {
                  "model": ["deepseek/deepseek-v4-flash", "opencode/nemotron-3-ultra-free"],
                  "variant": "medium",
                  "skills": ["*"],
                  "mcps": ["*", "!context7"]
                },
                "oracle": {
                  "model": ["deepseek/deepseek-v4-pro", "opencode/mimo-v2.5-free"],
                  "variant": "high",
                  "skills": ["simplify"],
                  "mcps": []
                },
                "council": {
                  "model": "opencode/north-mini-code-free",
                  "variant": "low",
                  "skills": [],
                  "mcps": []
                },
                "librarian": {
                  "model": "opencode/big-pickle",
                  "variant": "low",
                  "skills": [],
                  "mcps": ["websearch", "context7", "gh_grep"]
                },
                "explorer": {
                  "model": "opencode/north-mini-code-free",
                  "variant": "low",
                  "skills": [],
                  "mcps": []
                },
                "designer": {
                  "model": "opencode/mimo-v2.5-free",
                  "variant": "medium",
                  "skills": [],
                  "mcps": []
                },
                "fixer": {
                  "model": ["opencode/north-mini-code-free", "opencode/deepseek-v4-flash-free"],
                  "variant": "low",
                  "skills": [],
                  "mcps": []
                }
              },

              "deepseek-pro": {
                "orchestrator": {
                  "model": "deepseek/deepseek-v4-pro",
                  "variant": "medium",
                  "skills": ["*"],
                  "mcps": ["*", "!context7"]
                },
                "oracle": {
                  "model": "deepseek/deepseek-v4-pro",
                  "variant": "max",
                  "skills": ["simplify"],
                  "mcps": []
                },
                "council": {
                  "model": "opencode/nemotron-3-ultra-free",
                  "variant": "medium",
                  "skills": [],
                  "mcps": []
                },
                "librarian": {
                  "model": "opencode/big-pickle",
                  "variant": "low",
                  "skills": [],
                  "mcps": ["websearch", "context7", "gh_grep"]
                },
                "explorer": {
                  "model": "opencode/north-mini-code-free",
                  "variant": "low",
                  "skills": [],
                  "mcps": []
                },
                "designer": {
                  "model": "opencode/mimo-v2.5-free",
                  "variant": "medium",
                  "skills": [],
                  "mcps": []
                },
                "fixer": {
                  "model": "deepseek/deepseek-v4-flash",
                  "variant": "low",
                  "skills": [],
                  "mcps": []
                }
              },

              "zen-free": {
                "orchestrator": {
                  "model": "opencode/nemotron-3-ultra-free",
                  "variant": "medium",
                  "skills": ["*"],
                  "mcps": ["*", "!context7"]
                },
                "oracle": {
                  "model": "opencode/mimo-v2.5-free",
                  "variant": "high",
                  "skills": ["simplify"],
                  "mcps": []
                },
                "council": {
                  "model": "opencode/north-mini-code-free",
                  "variant": "low",
                  "skills": [],
                  "mcps": []
                },
                "librarian": {
                  "model": "opencode/big-pickle",
                  "variant": "low",
                  "skills": [],
                  "mcps": ["websearch", "context7", "gh_grep"]
                },
                "explorer": {
                  "model": "opencode/north-mini-code-free",
                  "variant": "low",
                  "skills": [],
                  "mcps": []
                },
                "designer": {
                  "model": "opencode/mimo-v2.5-free",
                  "variant": "medium",
                  "skills": [],
                  "mcps": []
                },
                "fixer": {
                  "model": ["opencode/north-mini-code-free", "opencode/deepseek-v4-flash-free"],
                  "variant": "low",
                  "skills": [],
                  "mcps": []
                }
              }
            },

            "council": {
              "default_preset": "quick",
              "councillor_execution_mode": "serial",
              "councillor_retries": 2,
              "timeout": 180000,
              "presets": {
                "quick": {
                  "councillor": {
                    "model": "opencode/north-mini-code-free",
                    "variant": "low"
                  }
                },
                "deep": {
                  "councillor-A": {
                    "model": "opencode/nemotron-3-ultra-free",
                    "variant": "medium"
                  },
                  "councillor-B": {
                    "model": "opencode/mimo-v2.5-free",
                    "variant": "medium"
                  },
                  "councillor-C": {
                    "model": "opencode/north-mini-code-free",
                    "variant": "medium"
                  }
                }
              }
            }
          }
        '';
      };
    };
  };
}
