{ pkgs, ... }: {
  programs.pi-coding-agent = {
    enable = true;
    extraPackages = with pkgs; [
      nodejs
      python3
      rtk          # pi-rtk-optimizer 依赖
    ];
    context = ''
      请用中文回复。

      ## 全局原则
      - 主动使用 MCP 和 Skills（详见 APPEND_SYSTEM.md）
      - 参考 AGENTS.md 了解项目结构和约定
      - 修改后运行 nix flake check（先 git add）
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
        "npm:pi-powerline-footer"             # Powerline 风格底栏（会话信息、上下文统计）
        "npm:pi-cache-optimizer"              # LLM KV 缓存命中率优化（prompt 缓存键、代理兼容提示）
        "npm:pi-rtk-optimizer"                # RTK 集成：命令重写 + 输出压缩降本（依赖 rtk 二进制）
        "npm:pi-web-access"                   # 网页搜索与内容获取（web_search / fetch_content）
        "npm:context-mode"                    # 上下文管理：FTS5 知识库、沙箱执行、搜索索引（ctx_* 工具族）
        "npm:pi-subagents"                    # 子 agent 编排：并行/链式/异步任务（subagent 工具）
        "npm:pi-mcp-adapter"                  # MCP 协议适配器：接入 MCP 服务器（mcp() 工具）
        "npm:@juicesharp/rpiv-ask-user-question"  # 结构化提问：多选项问卷（ask_user_question 工具）
        "npm:@juicesharp/rpiv-todo"           # 任务列表管理（todo 工具）
        "npm:pi-lens"                         # 代码透镜：LSP 诊断、AST 搜索、模块报告
        "npm:@plannotator/pi-extension"        # 草图/图表理解：识别图片中的流程和架构
        "npm:superpowers-zh"                  # superpowers 技能系统（中文版 20+ 技能）
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
  };
}
