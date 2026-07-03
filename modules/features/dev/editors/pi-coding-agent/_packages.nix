{ pkgs, ... }: {
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
        keepRecentTokens = 100000;
        reserveTokens = 16384;
      };

      packages = [
        # 核心工具
        "npm:pi-web-access" # 网页搜索与内容获取（web_search / fetch_content）
        "npm:context-mode" # 上下文管理：FTS5 知识库、沙箱执行、搜索索引（ctx_* 工具族）
        "npm:pi-mcp-adapter" # MCP 协议适配器：接入 MCP 服务器（mcp() 工具）
        "npm:pi-powerline-footer" # Powerline 风格底栏（会话信息、上下文统计、Working Vibes）
        "npm:@juicesharp/rpiv-todo" # 任务列表管理（todo 工具）
        "npm:@tintinweb/pi-subagents" # 子 agent 编排：Agent 工具 + FleetView 导航 + 会话查看器（Claude Code 风格）
        # 代码与开发
        "npm:pi-lens" # 代码透镜：LSP 诊断、AST 搜索、模块报告
        "npm:@chankov/agent-skills" # 27 个工程化技能 + 斜杠命令（/spec /plan /build /test /review /ship），捆绑 pi-ask-user
        "npm:@ayulab/pi-rewind" # 修改追踪与恢复：/rewind 交互式检查点导航，可回滚代码/对话
        # 安全与维护
        "npm:cc-safety-net" # 安全网：PreToolUse hook 语义分析，阻止破坏性 git/文件系统命令
        "npm:@lynskylate/agent-md-management" # AGENTS.md 审计改进：/revise-agent-md 命令 + agent-md-improver 技能
      ];
      retry = {
        enabled = true;
        maxRetries = 3;
      };
    };
    models.providers.deepseek.compat = {
      supportsLongCacheRetention = true;
      sendSessionAffinityHeaders = true;
    };
    models.providers.opencode.compat = {
      supportsLongCacheRetention = true;
      sendSessionAffinityHeaders = true;
      requiresReasoningContentOnAssistantMessages = true;
      thinkingFormat = "deepseek";
    };
  };
}
