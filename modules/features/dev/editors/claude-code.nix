{ den, ... }:
{
  den.aspects.dev.editors.claude-code = {
    includes = [
      den.batteries.inputs'
      (den.batteries.unfree [ "claude-code" ])
    ];
    # ──────────────────────────────────────────────
    # Claude Code — Anthropic 的终端 AI 编程助手
    # 使用 home-manager 原生 programs.claude-code 模块（nixpkgs 26.05+）
    #
    # 文档:
    #   https://code.claude.com/docs
    #   https://search.nixos.org/options?channel=26.05&query=programs.claude-code&source=home_manager
    #
    # 使用方式：在 host/user 的 includes 中添加：
    #   den.aspects.dev.editors.claude-code
    #
    # API 密钥通过环境变量注入（不硬编码在配置中）：
    #   export ANTHROPIC_API_KEY="sk-..."
    # ──────────────────────────────────────────────

    homeManager = { inputs', ... }: {
      programs.claude-code = {
        enable = true;

        # 使用 llm-agents-nix 提供的包（也可默认用 pkgs.claude-code 从 nixpkgs）
        package = inputs'.llm-agents-nix.packages.claude-code;

        # ── 用户级设置（写入 ~/.claude/settings.json）───────────────
        settings = {
          # 权限白名单
          permissions = {
            allow = [
              "Bash(nix *)"
              "Bash(git *)"
              "Bash(cargo *)"
              "Bash(ls *)"
              "Read(./**)"
              "Edit(./**)"
            ];
            deny = [
              "Bash(curl *)"
              "Read(./.env*)"
              "Read(./secrets/**)"
            ];
          };
        };

        # ── MCP 服务器（写入 .mcp.json）───────────────────────────
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

        # ── LSP 服务器（写入 .lsp.json）───────────────────────────
        lspServers = {
          nix = {
            command = "nil";
          };
        };

        # ── 全局上下文（写入 ~/.claude/CLAUDE.md）──────────────────
        context = ''
          请用中文回复。参考 AGENTS.md 了解项目结构、约定和完整技能表。
        '';

        # ── 自定义子代理 ──────────────────────────────────────────
        # agents = {
        #   code-reviewer = ''
        #     ---
        #     name: code-reviewer
        #     description: 代码审查专家
        #     ---
        #     你是一位资深代码审查工程师...
        #   '';
        # };

        # ── 自定义命令 ────────────────────────────────────────────
        # commands = {
        #   commit = ''
        #     ---
        #     allowed-tools: Bash(git *)
        #     description: 创建有意义的 git 提交
        #     ---
        #     基于当前变更创建提交...
        #   '';
        # };

        # ── 规则文件（~/.claude/rules/）───────────────────────────
        # rules = {
        #   nix-style = "# Nix 代码风格指南...";
        # };

        # ── 技能 ──────────────────────────────────────────────────
        # skills = {
        #   my-skill = ''
        #     ---
        #     name: my-skill
        #     description: 自定义技能
        #     ---
        #     技能指令...
        #   '';
        # };
      };
    };
  };
}
