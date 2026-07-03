{ pkgs, ... }: {
  programs.pi-coding-agent = {
    enable = true;
    extraPackages = with pkgs; [
      nodejs
      python3
    ];
    context = ''
      请用中文回复。参考 AGENTS.md 了解项目结构、约定和完整技能表。

      【工具选择优先级】（从上到下优先）
      Nix 包/选项/版本查询 → mcp()                             首选 MCP 服务器
      大文件/目录分析       → ctx_execute / ctx_execute_file     沙箱处理，不进上下文
      并行调研/代码搜索    → Agent(Explore) 后台运行             不阻塞主任务
      代码理解              → module_report → read_symbol → read  逐层深入，避免全文读
      代码导航              → lsp_navigation（定义/引用/悬停）    阅读效率最高
      构建前检查            → lsp_diagnostics                     减少试错
      精确代码匹配          → ast_grep_search（优先于 grep 文本） 语义级匹配
      需求不明确/决策不清   → ask_user（用结构化问题确认后再行动） 避免猜测

      【Nix 工作流】
      1. edit → nixfmt → git add → nix flake check（每步不可跳过）
      2. 扁平化编辑：一次 edit 传多个 edits[]，而非多次单 edit
      3. 新建 .nix 文件必须先 git add，否则 flake 看不到
      4. 改 dendritic.nix → 运行 nix run .#write-flake

      【思考深度选择】
      简单查询/列目录 → low   日常开发 → medium   复杂 Nix/Den → high   架构/跨模块 → xhigh
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
