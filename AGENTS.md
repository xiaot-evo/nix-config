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

### Pi agent 配置

Pi agent 配置通过 Nix Home Manager 声明式管理，**不要使用 `pi install`**：

| 文件 | 职责 |
|------|------|
| `modules/features/dev/editors/pi-coding-agent/_packages.nix` | settings.json 的 packages 列表、上下文、模型配置 |
| `modules/features/dev/editors/pi-coding-agent/_home-files.nix` | 文件部署：mcp.json、本地扩展 |
| `modules/features/dev/editors/pi-coding-agent/pi-coding-agent.nix` | den aspect 定义 + imports |

修改后：`git add` → `nix flake check` → `nix run .#<host> -- switch`

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
| `noctalia` | `noctalia-dev/noctalia/cachix` | — | 平铺桌面环境/Shell |

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
| `ask_user` | 交互式提问（agent-skills 捆绑 pi-ask-user 提供）| 需求不明确时 |
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

## 可用技能

项目使用 `@chankov/agent-skills`（27 个工程化技能）和各自包内的技能。agent 会自动发现并按需加载。

### 常见场景速查

| 场景 | 推荐命令/技能 |
|------|--------------|
| 定义需求 | `/spec` 或 skill: spec-driven-development |
| 制定计划 | `/plan` 或 skill: planning-and-task-breakdown |
| 增量实现 | `/build` 或 skill: incremental-implementation |
| 测试驱动 | `/test` 或 skill: test-driven-development |
| 代码审查 | `/review` 或 skill: code-review-and-quality |
| 简化代码 | `/code-simplify` 或 skill: code-simplification |
| Bug 修复 | skill: debugging-and-error-recovery |
| 安全审计 | skill: security-and-hardening |
| 性能优化 | skill: performance-optimization |
| 安全发布 | `/ship` 或 skill: shipping-and-launch |

---


## 可用斜杠命令

| 命令 | 来源 | 用途 |
|------|------|------|
| `/spec` `/plan` `/build` `/test` `/review` `/ship` | agent-skills | 开发生命周期管理 |
| `/code-simplify` | agent-skills | 代码简化审查 |
| `/revise-agent-md` | agent-md-management | 会话学习捕获 → AGENTS.md 更新 |

## AGENTS.md 自动管理

`agent-md-management` 包提供 AGENTS.md 的审计与改进：

- `/revise-agent-md` — 会话结束后捕获学习，建议更新 AGENTS.md
- 工作流：发现变更 → 质量评估 → 生成 diff 建议 → 用户确认后更新 → `nix flake check` 验证

灵感来自 Anthropic 官方 claude-md-management 插件。

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
- **斜杠命令冲突**: 多个包可能注册同名 `/command`（如 plan-mode 和 agent-skills 的 `/plan`）。冲突时保留需要的，删掉另一个。
- **pi-subagents 版本**: 官方 `pi-subagents`（1 个 `subagent` 工具，轻量）vs `@tintinweb/pi-subagents`（3 个工具，FleetView + 会话查看器 UI，略重）。按需选用。
- **文件验证技巧**: 使用 `ctx_execute` / `ctx_execute_file` 处理大输出或文件分析，避免原始内容占用上下文。
