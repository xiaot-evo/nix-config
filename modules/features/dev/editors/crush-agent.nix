{ den, inputs, ... }:
let
  charm = inputs.charmbracelet-nur;
in
{
  den.aspects.dev.editors.crush-agent = {
    # ──────────────────────────────────────────────
    # Crush — Charmbracelet 的终端 AI 编程助手
    # 声明式配置模板，通过 NUR (charmbracelet/nur) 管理
    # 文档: https://github.com/charmbracelet/crush
    #
    # 使用方式：在 host/user 的 includes 中添加：
    #   den.aspects.dev.editors.crush-agent
    #
    # API 密钥通过环境变量注入（不硬编码在配置中）：
    #   export ANTHROPIC_API_KEY="sk-..."
    #   export OPENAI_API_KEY="sk-..."
    # ──────────────────────────────────────────────

    homeManager = {
      imports = [ charm.homeModules.crush ];

      programs.crush = {
        enable = true;

        # ── 包覆盖（可选）─────────────────────────
        # 默认使用 charmbracelet/nur 提供的包
        # package = pkgs.crush;

        settings = {
          # ── 模型选择 ─────────────────────────────
          # large 模型用于代码编写，small 模型用于轻量任务
          # 需先在 providers 里配置对应提供商
          models = {
            large = {
              model = "claude-sonnet-4-20250514";
              provider = "anthropic";
              # reasoning_effort = "high";   # OpenAI 推理模型
              # think = true;                 # Anthropic 思考模式
              # max_tokens = 50000;
              # temperature = 0.7;
              # top_p = 0.9;
            };
            # small = {
            #   model = "claude-3-5-haiku-20241022";
            #   provider = "anthropic";
            # };
          };

          # ── AI 提供商 ────────────────────────────
          # 在 $ANTHROPIC_API_KEY / $OPENAI_API_KEY 等环境变量中设置 API 密钥
          #
          # 支持以下 type:
          #   openai, openai-compat, anthropic, google, bedrock, azure,
          #   google-vertex, ollama, llamacpp, lmstudio, litellm
          providers = { };

          # ── LSP 服务 ─────────────────────────────
          # Crush 使用 LSP 获取代码上下文以提供更准确的辅助
          lsp = {
            nix = {
              command = "nil";
              # disabled = false;
              # args = [ "--stdio" ];
              # timeout = 30;
            };
            # go = {
            #   command = "gopls";
            #   env = { GOTOOLCHAIN = "go1.24.5"; };
            # };
            # typescript = {
            #   command = "typescript-language-server";
            #   args = [ "--stdio" ];
            #   filetypes = [ "typescript" "typescriptreact" "javascript" "javascriptreact" ];
            # };
            # rust = {
            #   command = "rust-analyzer";
            #   root_markers = [ "Cargo.toml" "rust-project.json" ];
            # };
            # python = {
            #   command = "basedpyright-langserver";
            #   args = [ "--stdio" ];
            #   filetypes = [ "python" ];
            #   root_markers = [ "pyproject.toml" "setup.py" "requirements.txt" ];
            # };
          };

          # ── MCP 服务 ─────────────────────────────
          # 通过 Model Context Protocol 扩展工具能力
          mcp = { };

          # ── 全局选项 ─────────────────────────────
          options = {
            # 项目中自动加载的上下文文件
            context_paths = [
              # ".cursorrules"
              # "CLAUDE.md"
              # "AGENTS.md"
              # "CRUSH.md"
              # ".github/copilot-instructions.md"
            ];

            # 全局上下文文件（跨项目共享）
            # global_context_paths = [
            #   "~/.config/crush/CRUSH.md"
            #   "~/.config/AGENTS.md"
            # ];

            # Agent Skills 搜索路径
            # skills_paths = [
            #   "~/.config/crush/skills"
            #   "./project-skills"
            # ];

            # 项目初始化时自动生成的分析文件名
            # initialize_as = "AGENTS.md";

            # TUI 界面选项
            tui = {
              compact_mode = false;
              # diff_mode = "unified";    # 或 "split"
              # transparent = false;
              # scrollbar = "default";    # "always" / "never"
              completions = {
                max_depth = 0;
                max_items = 1000;
              };
            };

            # 调试
            debug = false;
            debug_lsp = false;

            # 通知
            # notification_style = "auto";   # native / osc / bell / disabled
            # disable_notifications = false;

            # 进度显示
            # progress = true;

            # 自动总结
            # disable_auto_summarize = false;

            # Git 提交属性
            attribution = {
              trailer_style = "assisted-by";    # co-authored-by / none
              generated_with = true;
            };

            # 禁用技能 / 禁用工具
            # disabled_skills = [ "crush-config" ];
            # disabled_tools = [ "bash" "sourcegraph" ];

            # 提供商自动更新
            # disable_provider_auto_update = false;
            # disable_default_providers = false;

            # 指标收集
            # disable_metrics = false;

            # LSP 自动发现
            auto_lsp = true;
          };

          # ── 免确认工具 ───────────────────────────
          # 列入白名单的工具在执行时无需用户确认
          permissions = {
            allowed_tools = [
              "view"
              "ls"
              "grep"
              # "edit"       # 谨慎添加写操作工具
              # "bash"       # 高风险
            ];
          };

          # ── 工具参数限制 ─────────────────────────
          tools = {
            ls = {
              # max_depth = 0;
              # max_items = 1000;
            };
            grep = {
              # timeout = 5;   # 秒
            };
            glob = {
              # timeout = 30;  # 秒
            };
          };

          # ── Hooks ────────────────────────────────
          # 在工具调用前后触发自定义脚本
          hooks = {
            # PreToolUse = [
            #   {
            #     name = "audit-edit";
            #     matcher = "edit|write|bash";
            #     command = ''echo "Tool $CRUSH_TOOL will run" >> /tmp/crush-audit.log'';
            #     timeout = 5;
            #   }
            # ];
          };
        };
      };
    };
  };
}
