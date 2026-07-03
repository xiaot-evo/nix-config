{ den, ... }:
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
            export CLAUDE_CODE_SUBAGENT_MODEL="deepseek-v4-flash"
            export CLAUDE_CODE_EFFORT_LEVEL="max"
            exec claude "$@"
          '')
        ];

        programs.claude-code = {
          enable = true;
          package = inputs'.llm-agents-nix.packages.claude-code;

          settings.permissions.allow = [
            "Bash(nix *)"
            "Bash(git *)"
            "Read(./**)"
            "Edit(./**)"
          ];

          mcpServers = {
            nixos = {
              type = "stdio";
              command = "nix";
              args = [
                "run"
                "github:utensils/mcp-nixos"
                "--"
              ];
            };
          };

          lspServers = {
            nix = {
              command = "nil";
            };
          };

          context = ''
            请用中文回复。参考 AGENTS.md 了解项目结构、约定和完整技能表。
          '';
        };
      };
  };
}
