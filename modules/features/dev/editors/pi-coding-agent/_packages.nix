{ pkgs, ... }: {
  programs.pi-coding-agent = {
    enable = true;
    extraPackages = with pkgs; [
      nodejs
      python3
      rtk # pi-rtk-optimizer 依赖
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
        "npm:pi-powerline-footer" # Powerline 风格底栏（会话信息、上下文统计）
        "npm:pi-cache-optimizer" # LLM KV 缓存命中率优化（prompt 缓存键、代理兼容提示）
        "npm:pi-rtk-optimizer" # RTK 集成：命令重写 + 输出压缩降本（依赖 rtk 二进制）
        "npm:pi-web-access" # 网页搜索与内容获取（web_search / fetch_content）
        "npm:context-mode" # 上下文管理：FTS5 知识库、沙箱执行、搜索索引（ctx_* 工具族）
        "npm:pi-subagents" # 子 agent 编排：并行/链式/异步任务（subagent 工具）
        "npm:pi-mcp-adapter" # MCP 协议适配器：接入 MCP 服务器（mcp() 工具）
        "npm:@juicesharp/rpiv-ask-user-question" # 结构化提问：多选项问卷（ask_user_question 工具）
        "npm:@juicesharp/rpiv-todo" # 任务列表管理（todo 工具）
        "npm:pi-lens" # 代码透镜：LSP 诊断、AST 搜索、模块报告
        "npm:superpowers-zh" # superpowers 技能系统（中文版 20+ 技能）
        "npm:@ayulab/pi-rewind" # 修改追踪与恢复：/rewind 交互式检查点导航，可回滚代码/对话
        "npm:@gotgenes/pi-permission-system" # 权限管理：allow/ask/deny 三级策略，写操作前弹窗确认
        "npm:pi-intercom" # pi-subagents 伴侣：实时 supervisor 决策、进度更新、分组结果交付
        "npm:pi-prompt-template-model" # pi-subagents 伴侣：可复用 prompt-template 工作流，支持 model/thinking/skill/subagent frontmatter
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
