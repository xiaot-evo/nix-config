{ den, ... }:
{
  den.aspects.dev.editors.opencode = {
    homeManager = {
      programs.opencode = {

        enable = true;
        tui.theme = "opencode";
        settings = {
          plugin = [
            "opencode-antigravity-auth@latest"
            "@tarquinen/opencode-dcp@latest"
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
        };
      };
      xdg.configFile."opencode/oh-my-opencode-slim.json".text = ''
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
}
