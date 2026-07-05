# AGENTS.md — Nix flake

> **单一起源参考文档。** 所有交互用中文。本文件分三级提示：
>
> - **规则** ⚠️ — 必须遵守，不可跳过
> - **策略** 💡 — 推荐做法，可根据场景灵活变通
> - **参考** 📖 — 知识库信息，按需加载

______________________________________________________________________

## 工具选择决策流

### 场景 → 首选工具

| 场景 | 首选 | 备选 | 理由 |
|------|------|------|------|
| **查 Nix 包/选项/版本** | `mcp({ server:"nixos", tool:"nixos_nix" })` | `grep -r` / `find` | MCP 有结构化数据 |
| **理解代码文件** | `module_report(path)` → `read_symbol(path, name)` | `read(path)` | 逐层深入，避免全文读 |
| **查定义/引用/类型** | `lsp_navigation(operation, path, line)` | `grep -r` | LSP 语义准确 |
| **精确代码搜索** | `ast_grep_search(pattern, lang)` | `grep` 文本搜索 | AST 语义级匹配 |
| **批量代码替换** | `ast_grep_replace(pattern, rewrite, lang)`（默认 dry-run） | `edit` | 安全批量重构 |
| **大文件/目录分析** | `ctx_execute(lang, code)` / `ctx_execute_file(path, code)` | `read offset/limit` | 沙箱处理，不进上下文 |
| **构建前检查** | `lsp_diagnostics(path)` | 直接构建 | 减少试错 |
| **需求不明确** | `ask_user(question, options)` | 猜测 | 避免做错方向 |
| **多步骤跟踪** | `todo(action, ...)` | 记忆 | 跨压实存活 |
| **并行调研** | `Agent(subagent_type:"Explore", run_in_background:true)` | 自己搜索 | 不阻塞主任务 |
| **网页搜索** | `web_search(queries:[...])` | `fetch_content(url)` | 多角度搜索更广 |
| **获取 URL/视频内容** | `fetch_content(url)` | `web_search` | 结构化提取 |
| **回滚错误修改** | `/rewind` | `/tree` | 交互式检查点导航 |

### 简短版（新手速查）

```
MCP 查 Nix → lens 读代码 → ctx 分析数据 → Agent 后台调研 → ask_user 确认需求
```

______________________________________________________________________

## Nix 工作流 ⚠️

### 编辑 → 验证 → 部署

```
1. edit 写入修改           (或 write 创建新文件)
2. nix fmt                 格式化所有修改的文件（.nix .json .md .yaml）
3. git add <file>          (新建/删除后必做，否则 flake 评估看不到)
4. nix flake check         CI 门禁 — 修改后必须运行
5. nix run .#<host> -- switch  部署
```

> `nix fmt -- --fail-on-change` 仅检查格式（CI 模式）。单文件快速格式化仍可用 `nixfmt <file>`。

### 常见陷阱

| 场景 | 正确做法 |
|------|---------|
| 新建 `.nix` 文件 | 先 `git add`，再 `nix flake check` |
| 修改 `dendritic.nix` | 运行 `nix run .#write-flake` 重新生成 `flake.nix` |
| 多个更改在同文件 | 一次 `edit` 传多个 `edits[]`，而非多次单 `edit` |
| 新增 flake 输入 | 在 `dendritic.nix` 添加 → `nix run .#write-flake` |

### 快速 Nix 验证（不用完整构建）

```console
nix-instantiate --parse <file>      # 仅检查语法
nix fmt -- --fail-on-change         # 格式检查（比 flake check 快）
nix flake check --no-build          # 只评估不构建
```

______________________________________________________________________

## 快速命令

| 命令 | 用途 |
|------|------|
| `nix run .#<host>` | 构建主机 |
| `nix run .#<host> -- switch` | 部署 |
| `nix fmt` | 格式化所有文件（nix/json/md/yaml） |
| `nix fmt -- --fail-on-change` | 仅检查格式（CI 模式） |
| `nix run .#write-flake` | 重新生成 flake.nix |
| `nix flake update den` | 更新 den 框架输入 |
| `nix flake check` | CI 门禁 |
| `pi -r` | 恢复最近会话 |

可用主机列表见 [AGENTS_PROJECT.md](AGENTS_PROJECT.md)。

______________________________________________________________________

## 项目结构

```
├── flake.nix              # 自动生成 — 勿手动编辑（由 dendritic.nix 驱动）
├── AGENTS.md              # 本文件
├── AGENTS_PROJECT.md      # 主机、用户、功能模块详情
├── docs/                  # 框架/架构文档
└── modules/               # import-tree 根目录（所有 .nix 自动导入）
    ├── defaults.nix       # 全局默认值
    ├── dendritic.nix      # flake-file 配置 + 输入声明
    ├── hosts/             # 主机和用户定义
    └── features/          # 按领域划分的可复用 aspect 模块
```

**import-tree 规则：**

- 递归导入 `modules/` 下所有 `.nix` 文件
- `_` 前缀的文件会被跳过
- `dir/dir.nix` 作为 aspect 名称为 `dir`（去重）

**Pi agent 配置：**

| 文件 | 职责 |
|------|------|
| `_packages.nix` | packages 列表、上下文、模型、compaction |
| `_home-files.nix` | 文件部署：mcp.json、本地扩展 |
| `pi-coding-agent.nix` | den aspect 定义 + imports |

______________________________________________________________________

## Den 框架要点

此 flake 使用 **Den** 框架（`github:denful/den`）。文档见 `docs/den/` 或 <https://den.denful.dev>

### Aspect — 基本配置单元

`den.aspects.<path>.<name>`，path 对应 `modules/features/` 下的路径。

**类型：** Static（固定配置）、Parametric（函数返回）、Forward（跨类代理）、Conditional（条件启用）

**命名约定：** 文件路径 = aspect 名称点号分隔

| 文件 | Aspect 名称 |
|------|------|
| `apps/zen-browser.nix` | `den.aspects.apps.zen-browser` |
| `desktop/wm/niri.nix` | `den.aspects.desktop.wm.niri` |

**includes / provides 模式：**

```
host (nixos class) → includes: hardware, boot, nix, sound
  └→ provides.to-users.homeManager → default packages

user (homeManager class) → includes: features...
  └→ provides.to-hosts.nixos → NixOS extensions
```

**内置便捷 aspect：** `den.batteries.*`（hostname、define-user、primary-user、user-shell、unfree...）

**Classes：** 默认 `["homeManager"]`，可选 `nixos`

### 新建 feature aspect

1. 在 `modules/features/<domain>/` 下创建 `<name>.nix`
1. 定义 `den.aspects.<domain>.<name>`（`{ nixos = ...; }` 或 `{ homeManager = ...; }`）
1. 在 `modules/hosts/` 中对应主机/用户的 `includes` 里添加
1. 如需新输入则运行 `nix run .#write-flake`
1. `import-tree` 自动发现新文件（无需手动注册）

______________________________________________________________________

## 可用能力 💡

### 斜杠命令

| 命令 | 来源 | 用途 |
|------|------|------|
| `/spec` `/plan` `/build` `/test` `/review` `/ship` | agent-skills | 开发生命周期 |
| `/code-simplify` | agent-skills | 代码简化审查 |
| `/revise-agent-md` | agent-md-management | AGENTS.md 审计改进 |
| `/rewind` / `/checkpoint` | pi-rewind | 检查点回滚 |
| `/agents` | pi-subagents | 子 agent 管理 |

### 工程化技能场景速查

| 场景 | 推荐 |
|------|------|
| 定义需求 | skill: spec-driven-development |
| 制定计划 | skill: planning-and-task-breakdown |
| 增量实现 | skill: incremental-implementation |
| 测试驱动 | skill: test-driven-development |
| Bug 修复 | skill: debugging-and-error-recovery |
| 代码审查 | skill: code-review-and-quality |

### 思考深度选择 💡

```
f.lux/简单查询   → low
日常开发          → medium
复杂 Nix/Den 逻辑 → high
架构/跨模块设计   → xhigh
```

快捷键 `Shift+Tab` 循环切换，`/settings` 可视化选择。

### Context-mode 技巧 💡

> **Think in Code：** 让分析代码在沙箱中跑，只 `console.log()` 结果进上下文。

```javascript
// ❌ 47 次 Read() → 700 KB 上下文
// ✅ 1 次 ctx_execute() → 3.6 KB
ctx_execute("javascript", `
  const files = fs.readdirSync('modules').filter(f => f.endsWith('.nix'));
  console.log(JSON.stringify(files));
`);
```

______________________________________________________________________

## 注意事项 ⚠️

- **CI 门禁：** `nix flake check` 是必须通过的。会设置 `_module.args.CI = true`。
- **git add 必须先行：** 新建/删除 `.nix` 文件后必须先 `git add`。
- **禁止 pi install：** 所有包通过 Nix 声明式管理（修改 `_packages.nix`）。
- **插件不重复：** 添加 pi npm 包时检查功能重叠和系统依赖需求。
- **文件名前缀 `_`：** `import-tree` 会跳过 `_` 前缀文件。
- **安全纵深：** cc-safety-net（语义拦截）+ pi-permission-system（写策略）→ 双重保护。

______________________________________________________________________

## 附录：主机与用户 💡

**主机：** `acer-swift`（x86_64-linux，AMD CPU + NVIDIA GPU，CachyOS 内核，pipewire，btrfs）

**用户：** `xiaot_evo`（fish shell，niri WM，DMS 桌面，zen-browser，fcitx5 输入法，daed 代理）

详细配置见 [AGENTS_PROJECT.md](AGENTS_PROJECT.md)。

### 已安装 pi 包

| 包 | 用途 |
|------|------|
| `pi-web-access` | 网页搜索与内容获取 |
| `context-mode` | FTS5 知识库 + 沙箱执行 + 上下文索引 |
| `pi-mcp-adapter` | MCP 协议适配器（已配 nixos 服务器） |
| `pi-powerline-footer` | Powerline 状态栏 |
| `@juicesharp/rpiv-todo` | 任务列表管理 |
| `@tintinweb/pi-subagents` | 子 agent 编排（Agent / FleetView） |
| `pi-lens` | LSP 诊断 + AST 搜索 + 模块报告 |
| `@chankov/agent-skills` | 27 个工程化技能 |
| `@ayulab/pi-rewind` | 检查点回滚 |
| `cc-safety-net` | 破坏性命令拦截 |
| `@lynskylate/agent-md-management` | AGENTS.md 审计改进 |
