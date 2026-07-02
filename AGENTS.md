# AGENTS.md — Nix flake

本项目的 **单一起源** 参考文档。Pi agent 在任务中应随时查阅此文件获取项目结构、约定和完整技能表。

---

## 全局原则

1. **用中文回复**：所有交互和文档使用中文。
2. **主动使用工具**：合理调用可用的 MCP、Skills 和内置工具。
3. **参考本文件**：AGENTS.md 是单一起源参考，包含项目结构、约定和技能表。
4. **修改后验证**：所有 `.nix` 文件修改后务必运行 `nix flake check`（需先 `git add`）。
5. **git add 新文件**：新建/删除 `.nix` 文件后必须先 `git add`，否则 flake 评估看不到变更。

---

## 快速命令

```console
nix run .#<host>                 # 构建
nix run .#<host> -- switch       # 部署
nix run .#vm                     # VM 测试
nix run .#write-flake            # 重新生成 flake.nix
nix flake update den             # 更新 den 框架输入
nix flake check                  # CI 门禁 — 修改后务必运行
```

内部使用 `nh`。可用主机列表见 `AGENTS_PROJECT.md`。

---

## 项目结构

```
├── flake.nix              # 自动生成 — 勿手动编辑
├── AGENTS.md              # 本文件（单一起源参考）
├── AGENTS_PROJECT.md      # 项目专属信息（主机、用户、功能）
├── README.md              # 项目概述
├── docs/
│   ├── den/               # Den 框架文档
│   └── superpowers/       # superpowers 技能文档
└── modules/               # import-tree 根目录（所有 .nix 自动导入）
    ├── defaults.nix       # 全局默认值
    ├── dendritic.nix      # flake-file 配置 + 输入声明
    ├── hosts/             # 主机和用户定义
    └── features/          # 按领域划分的可复用 aspect 模块
```

- **`flake.nix`** 由 `flake-file` 自动生成。编辑 `dendritic.nix`，然后运行 `nix run .#write-flake`。
- **`import-tree ./modules`** 递归导入 `modules/` 下所有 `.nix` 文件，新建文件无需手动注册。
- **前缀约定**：`_` 前缀的 `.nix` 文件会被 `import-tree` 跳过；`dir/dir.nix` 的 aspect 名称为 `dir`（去重）。

---

## Den 框架要点

此 flake 使用 **Den** 框架（`github:denful/den`）。文档见 `docs/den/` 或 <https://den.denful.dev>

### Aspect — 基本配置单元

`den.aspects.<path>.<name>`，path 对应 `modules/features/` 下的路径。

| 类型 | 说明 |
|---|---|
| **Static** | 固定配置，无参数。`den.aspects.my-feature = { homeManager = ...; }` |
| **Parametric** | 函数返回 aspect。`(system.boot { ... })` |
| **Forward** | 通过 `provides.to-*` 代理到另一个 aspect，实现跨类配置流 |
| **Conditional** | 基于主机/用户属性条件启用，在完整解析后求值 |

### 命名约定

| 文件路径 | Aspect 名称 |
|---|---|
| `apps/zen-browser.nix` | `den.aspects.apps.zen-browser` |
| `desktop/wm/niri.nix` | `den.aspects.desktop.wm.niri` |
| `system/hardware/nvidia.nix` | `den.aspects.system.hardware.nvidia` |

### `includes` / `provides` 模式

```
host (nixos class)
  ├── includes: hostname-battery, hardware-aspects, boot, nix, sound
  └── provides.to-users.homeManager → default home packages

user (homeManager class)
  ├── includes: define-user, primary-user, user-shell, features...
  └── provides.to-hosts.nixos → NixOS config extensions
```

### Batteries（内置便捷 aspect）

`den.batteries.*` — hostname、define-user、primary-user、user-shell、unfree、self'、系统服务等。

### Classes（配置目标）

默认：`[ "homeManager" ]`

- `nixos` — NixOS 系统配置
- `homeManager` — Home Manager 用户配置

### 严格模式

启用后（`den.schema.host.strict = true`），所有 aspect 必须显式 include。

### 数据流

```
dendritic.nix ──> flake.nix（自动生成）
                      │
            flake-parts + import-tree
                      │
                  modules/
                  ├── defaults.nix
                  ├── hosts/<hostname>/
                  └── features/
```

---

## Flake 输入

| input | 来源 | follows | 用途 |
|---|---|---|---|
| `den` | `github:denful/den` | — | 框架 |
| `nixpkgs` | nixpkgs-unstable | — | 包集 |
| `home-manager` | `nix-community/home-manager` | nixpkgs | 用户环境 |
| `flake-parts` | `hercules-ci/flake-parts` | nixpkgs-lib → nixpkgs | perSystem |
| `import-tree` | `vic/import-tree` | — | 递归模块导入 |
| `flake-file` | `vic/flake-file` | — | flake.nix 生成 |
| `nix-cachyos-kernel` | `xddxdd/nix-cachyos-kernel/release` | — | 自定义内核 |
| `niri-nix` | `codeberg.org/BANanaD3V/niri-nix` | — | niri HM 模块 |
| `daeuniverse` | `daeuniverse/flake.nix` | — | dae/daed 代理 |
| `dms` | `AvengeMedia/DankMaterialShell/stable` | nixpkgs | 桌面 shell |
| `dms-plugin-registry` | `AvengeMedia/dms-plugin-registry` | nixpkgs | DMS 插件注册表 |
| `llm-agents-nix` | `github:numtide/llm-agents.nix` | nixpkgs | pi-coding-agent 包 |
| `zen-browser` | `0xc000022070/zen-browser-flake` | nixpkgs, home-manager | 浏览器 |

---

## 工具调用指南

### MCP 调用

Nix/Den 相关优先用 MCP 服务器：

```typescript
// 查询包/选项/文档
mcp({ tool: "nixos_nix", args: '{"action": "info/search/browse", ...}' })

// 版本历史
mcp({ tool: "nixos_nix_versions", args: '{"package": "..."}' })

// 查看 MCP 工具参数
mcp({ describe: "tool_name" })

// 列出服务器工具
mcp({ server: "nixos" })

// 查看服务器状态
mcp({})
```

MCP 数据源（`source` 参数）：`nixos`、`home-manager`、`darwin`、`flakes`、`den`、`nixvim`、`noogle`、`nixhub`、`wiki`。

### Skills 调用

| 时机 | 技能 | 说明 |
|------|------|------|
| 创造性工作前 | `brainstorming` → `writing-plans` | 探索、设计、批准 |
| 遇到 bug | `systematic-debugging` | 系统化调试 |
| 完成前验证 | `verification-before-completion` | 运行验证 |
| 工作完成后 | `requesting-code-review` | 代码审查 |
| 独立多任务 | `dispatching-parallel-agents` | 并行分派 |
| 实施计划 | `subagent-driven-development` | 子 agent 驱动 |
| 分支完成 | `finishing-a-development-branch` | 合并/PR/清理 |

### Pi 内置工具

| 工具 | 用途 | 优先场景 |
|------|------|----------|
| `read` | 读取文件内容 | 需要查看代码时 |
| `bash` | 执行 bash 命令 | ls, grep, find, 构建等 |
| `edit` | 精确文本替换编辑 | 修改已读文件 |
| `write` | 创建或覆写文件 | 新文件或大幅修改 |
| `web_search` | 网页搜索 | 需要外部信息时 |
| `fetch_content` | 获取 URL/视频/GitHub 内容 | 文档、仓库、视频分析 |
| `mcp` | MCP 网关 | Nix/Den 查询优先用 MCP |
| `ask_user_question` | 结构化问卷 | 需求不明确时 |
| `todo` | 任务列表管理 | 多步骤任务跟踪 |

### Pi-lens 代码分析工具

| 工具 | 用途 |
|------|------|
| `lsp_diagnostics` | LSP 诊断（构建前检查） |
| `lsp_navigation` | 代码导航（定义/引用/悬停） |
| `ast_grep_search` | AST 模式搜索 |
| `ast_grep_replace` | AST 模式替换（dry-run 默认） |
| `ast_grep_outline` | 代码结构大纲 |
| `module_report` | 结构化模块概览 |
| `read_symbol` | 读取特定符号体 |
| `read_enclosing` | 读取包含行的最小函数 |
| `lens_diagnostics` | 查询诊断状态 |

### Context-mode 上下文管理工具

| 工具 | 用途 |
|------|------|
| `ctx_execute` | 沙箱执行代码（JS/Python/Shell） |
| `ctx_execute_file` | 对单个文件运行分析 |
| `ctx_index` | 存储内容到知识库 |
| `ctx_search` | BM25 搜索知识库 |
| `ctx_stats` | 上下文使用统计 |

---

## Superpowers Skills — 完整技能表（20 个）

项目使用 **superpowers**（`github:obra/superpowers`）技能系统。Pi agent 应主动调用合适的技能。

### 全部技能

| 技能 | 分类 | 用途 | 触发时机 |
|------|------|------|----------|
| `brainstorming` | 设计 | 创造性工作前探索、澄清、设计、批准 | **任何创造性工作前** |
| `writing-plans` | 设计 | 创建实施计划 | brainstorming 之后 |
| `executing-plans` | 开发 | 执行实施计划 | 计划批准后 |
| `subagent-driven-development` | 开发 | 含独立子任务的计划执行 | 实施计划含独立子任务 |
| `dispatching-parallel-agents` | 开发 | 并行分派独立任务 | 2+ 无共享状态的任务 |
| `test-driven-development` | 开发 | 测试驱动开发工作流 | 需要测试优先的场景 |
| `systematic-debugging` | 调试 | 系统化诊断根因 | **遇到 bug / 测试失败** |
| `requesting-code-review` | 审查 | 请求代码审查 | 工作完成后、合并前 |
| `receiving-code-review` | 审查 | 接收并处理代码审查反馈 | 收到审查意见后 |
| `chinese-code-review` | 审查 | 中文代码审查 | 需要中文审查反馈 |
| `verification-before-completion` | 验证 | 完成前运行验证 | **声明完成前** |
| `finishing-a-development-branch` | 交付 | 决定合并/PR/清理 | 实现完成后 |
| `writing-skills` | 工具 | 创建/编辑 superpowers 技能 | 需要新技能时 |
| `mcp-builder` | 工具 | 构建 MCP 工具 | 需要 MCP 集成时 |
| `workflow-runner` | 工具 | 运行工作流 | 多步骤自动化工作流 |
| `chinese-documentation` | 文档 | 中文文档编写 | 需要中文文档时 |
| `chinese-commit-conventions` | 文档 | 中文提交规范 | 格式化提交信息 |
| `chinese-git-workflow` | 文档 | 中文 Git 工作流 | Git 操作需要中文指引 |
| `using-superpowers` | 元 | 使用 superpowers 技能系统的指南 | 初次使用或需要帮助时 |
| `using-git-worktrees` | 工具 | Git 工作树管理 | 并行开发分支 |

### 标准工作流

```
1. brainstorming          → 探索、澄清、设计、批准
2. writing-plans          → 创建实施计划
3. 实现                   → 编码 + nix flake check
4. requesting-code-review → 验证满足需求
5. finishing-a-development-branch → 合并/PR/清理
```

### 场景化技能链

| 场景 | 技能链 |
|------|--------|
| **新功能开发** | brainstorming → writing-plans → subagent-driven-development / executing-plans → verification-before-completion → requesting-code-review → finishing-a-development-branch |
| **Bug 修复** | systematic-debugging → writing-plans → 修复 → verification-before-completion |
| **并行任务** | dispatching-parallel-agents（每个子任务内运行完整开发工作流） |
| **TDD** | test-driven-development → 写测试 → 实现 → 验证 |
| **创建新技能** | writing-skills → test-driven-development → 完成 |
| **MCP 集成** | mcp-builder → 开发 → 验证 |
| **多步骤自动化** | workflow-runner（编排多个 phase）|

---

## 新建 feature 模块

1. 在 `modules/features/` 下创建 `<domain>/<name>.nix`
2. 定义 `den.aspects.<domain>.<name>`（`{ nixos = ...; }` 或 `{ homeManager = ...; }`）
3. 在 `modules/hosts/` 中对应主机/用户的 `includes` 里添加
4. 如需新输入则运行 `nix run .#write-flake`
5. `import-tree` 自动发现新 `.nix` 文件

---

## 注意事项

- **CI**: `nix flake check` 是门禁。会设置 `_module.args.CI = true`。
- **git add**: 新建/删除 `.nix` 文件后必须先 `git add`，否则 flake 评估看不到变更。
- **import-tree**: `_` 前缀的 `.nix` 文件会被跳过；`dir/dir.nix` 的 aspect 名称为 `dir`（去重）。
- **插件**: 添加 pi npm 包时检查功能重叠，确认是否需要系统二进制依赖。
