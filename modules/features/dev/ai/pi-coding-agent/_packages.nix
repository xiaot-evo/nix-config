{ pkgs, ... }:
let
  commonCompat = {
    supportsLongCacheRetention = true;
    sendSessionAffinityHeaders = true;
  };
in
{
  programs.pi-coding-agent = {
    enable = true;
    extraPackages = with pkgs; [
      nodejs
      python3
    ];
    context = ''
      请用中文回复。参考 AGENTS.md 了解项目结构、约定和完整技能表。
    '';
    settings = {
      defaultProvider = "opencode";
      defaultModel = "deepseek-v4-flash-free";
      defaultThinkingLevel = "high";
      compaction = {
        enabled = true;
        keepRecentTokens = 32000;
        reserveTokens = 16384;
      };

      packages = [
        # 核心工具
        "npm:pi-web-access"
        "npm:context-mode"
        "npm:pi-mcp-adapter"
        "npm:pi-powerline-footer"
        "npm:@juicesharp/rpiv-todo"
        "npm:@tintinweb/pi-subagents"
        # 技能与工作流
        "npm:@chankov/agent-skills"
        "npm:@ayulab/pi-rewind"
        # 维护
        "npm:@lynskylate/agent-md-management"
      ];
      retry = {
        enabled = true;
        maxRetries = 3;
      };
    };
    models.providers.deepseek.compat = commonCompat;
    models.providers.opencode.compat = commonCompat // {
      requiresReasoningContentOnAssistantMessages = true;
      thinkingFormat = "deepseek";
    };
  };
}
