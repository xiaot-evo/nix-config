{ ... }: let
  appendSystemPrompt = builtins.toFile "append-system-prompt.md" ''
## MCP 调用

Nix/Den 相关优先用 MCP：
- `nixos_nix({ action: "info/search/browse" })` — 查包/选项/Den 文档
- `nixos_nix_versions({ package: "..." })` — 版本历史
- `mcp({ describe: "tool_name" })` — 看参数

## Skills 调用

| 时机 | 技能 |
|---|---|
| 创造性工作前 | brainstorming → writing-plans |
| 遇到 bug | systematic-debugging |
| 完成前验证 | verification-before-completion |
| 完成后 | requesting-code-review |
| 独立多任务 | dispatching-parallel-agents |

完整技能表见 AGENTS.md。
'';
in {
  home.file = {
    ".pi/agent/mcp.json".text = builtins.toJSON {
      mcpServers.nixos = {
        command = "nix";
        args = [ "run" "github:jsiegel-supplyframe/mcp-nixos/nix-taco-sprint/den-source" "--" ];
      };
    };
    ".pi/agent/APPEND_SYSTEM.md".source = appendSystemPrompt;
  };
}
