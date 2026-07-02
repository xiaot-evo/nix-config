# XiaoT_Evo's Pi 使用教程

> 基于 [Nix flake](https://github.com/xiaot-evo/nix) 配置的 [Pi Coding Agent](https://pi.mariozechner.at/) 完整使用指南。
>
> 本文档面向 **最终用户**，说明如何与配置好的 Pi agent 高效协作。

---

## 目录

1. [快速上手](#1-快速上手)
2. [核心交互模式](#2-核心交互模式)
3. [可用工具详解](#3-可用工具详解)
4. [插件功能与命令](#4-插件功能与命令)
5. [Superpowers 工作流](#5-superpowers-工作流)
6. [项目特定约定](#6-项目特定约定)
7. [常见问题](#7-常见问题)

---

## 1. 快速上手

### 启动 Pi

```bash
# 在当前项目目录启动
pi

# 启动时进入计划模式（只读探索）
pi --plan

# 打开已有会话
pi -r <session-name>
```

### 基本交互

Pi agent 的工作原理：

```
你输入任务描述 → agent 理解需求 → 调用工具/技能 → 展示结果 → 你反馈
     ↑                                                             |
     └───────────────────── 循环迭代 ──────────────────────────────┘
```

**黄金法则**：

- **说清楚想要什么** — 越具体越好，但不必一次说完，可以迭代
- **指出关键约束** — "用 Den aspect 实现"、"运行 nix flake check"
- **利用技能** — 复杂任务前说"先 brainstorm"，调试时说"用 systematic-debugging"
- **遇到不确定** — agent 会用问卷 `ask_user_question` 向你确认

### 首次使用检查

```bash
# 验证 rtk 二进制（输出压缩依赖）
/rtk verify

# 查看缓存优化状态
/cache-optimizer doctor

# 查看 MCP 服务器状态
mcp({})
```

---

## 2. 核心交互模式

### 2.1 直接委托

最常用的模式——直接把任务描述给 agent：

```
帮我给 system/network.nix 添加 NetworkManager DNS 配置
```

agent 会自动：

1. 读取相关文件
2. 理解结构
3. 编写修改
4. 等待你确认后应用

### 2.2 计划-执行模式

适合复杂任务（多个步骤、多个文件）：

```
用 brainstorming 探索一下 network.nix 可以怎么优化
```

brainstorming 完成后：

```
好，方案不错，用 writing-plans 创建实施计划
```

计划创建后，agent 会按步骤执行。

### 2.3 多任务并行

适合独立的任务：

```
用 dispatching-parallel-agents 同时做两件事：
1. 检查所有 host 配置里的 time.timeZone 是否一致
2. 列出所有未使用的 flake 输入
```

### 2.4 调试模式

遇到 bug 时：

```
systematic-debugging，nix flake check 报错了
```

### 2.5 后台运行

长任务可以后台执行：

```
在后台运行 nix flake update，完成后告诉我结果
```

---

## 3. 可用工具详解

### 3.1 文件操作

| 工具 | 语法 | 用途 | 提示 |
|------|------|------|------|
| `read` | `read("path")` | 读取文件 | 指定 offset/limit 分段读大文件 |
| `write` | `write("path", content)` | 创建/覆写文件 | 自动创建父目录 |
| `edit` | `edit({path, edits})` | 精确替换 | 一次可做多个不重叠替换 |
| `bash` | `bash("command")` | 执行命令 | ls, grep, find, nix 等 |

> **注意**：`edit` 和 `write` 受 @gotgenes/pi-permission-system 保护。写操作前可能弹窗确认。

### 3.2 代码分析（Pi Lens）

| 工具 | 用途 | 使用场景 |
|------|------|----------|
| `lsp_diagnostics(path)` | 获取 LSP 错误/警告 | **构建前检查** |
| `lsp_navigation({operation, path, line})` | 跳转定义/引用 | 理解代码结构 |
| `ast_grep_search({pattern, lang})` | AST 模式搜索 | 精确代码模式匹配 |
| `ast_grep_replace({pattern, rewrite, lang})` | AST 模式替换 | 安全批量重构（默认 dry-run）|
| `module_report(path)` | 模块结构概览 | 快速理解文件结构 |
| `read_symbol(path, symbol)` | 读取函数/类体 | 聚焦特定符号 |
| `read_enclosing(path, line)` | 读取所在函数 | 从报错行定位代码 |
| `lens_diagnostics({mode})` | 诊断状态查询 | 查看当前所有问题 |

### 3.3 上下文管理（Context Mode）

这些工具帮助 agent 高效管理信息，避免把大量原始数据塞入对话窗口。

| 工具 | 用途 | 示例 |
|------|------|------|
| `ctx_execute(lang, code)` | 沙箱执行代码 | `ctx_execute("javascript", "fs.readdirSync('.').filter(f=>f.endsWith('.nix'))")` |
| `ctx_execute_file(path, code)` | 对单个文件运行分析 | `ctx_execute_file("config.nix", "...")` |
| `ctx_batch_execute(commands)` | 批量执行 | 一次跑多个分析命令 |
| `ctx_index(content)` | 存入知识库 | 把文档/笔记存入 FTS5 |
| `ctx_search(query)` | 搜索知识库 | 从索引中检索信息 |
| `ctx_fetch_and_index(url)` | 获取 URL 并索引 | 网页内容自动索引 |
| `ctx_stats()` | 查看上下文统计 | 了解使用情况 |

**Think in Code 哲学**：

```javascript
// ❌ 不好：47 次 Read() = 700 KB 上下文
// ✅ 好：1 次 ctx_execute() = 3.6 KB

ctx_execute("javascript", `
  const files = fs.readdirSync('modules/features')
    .filter(f => f.endsWith('.nix'));
  files.forEach(f => {
    const content = fs.readFileSync('modules/features/'+f, 'utf8');
    const lines = content.split('\\n').length;
    console.log(f + ': ' + lines + ' lines');
  });
`);
```

### 3.4 网页搜索与内容获取（Web Access）

| 工具 | 用途 | 示例 |
|------|------|------|
| `web_search({query})` | 网页搜索 | `web_search({queries: ["nixos pipewire config", "home-manager options"]})` |
| `fetch_content({url})` | 获取页面/视频/GitHub | `fetch_content({url: "https://github.com/owner/repo"})` |

### 3.5 MCP 网关

Nix/Den 相关优先使用：

```typescript
// 查询包
mcp({ tool: "nixos_nix", args: '{"action": "search", "query": "pipewire"}' })

// 查选项
mcp({ tool: "nixos_nix", args: '{"action": "browse", "path": "services.pipewire"}' })

// 查版本历史
mcp({ tool: "nixos_nix_versions", args: '{"package": "pipewire"}' })

// 查看可用工具
mcp({ server: "nixos" })
mcp({ describe: "nixos_nix" })
```

### 3.6 交互工具

| 工具 | 用途 | 说明 |
|------|------|------|
| `ask_user_question({questions})` | 结构化问卷 | 2-4 选项，支持多选和预览 |
| `todo({action, subject})` | 任务列表 | 跨 /reload 和压实存活 |

---

### 3.7 切换思考深度

Pi 的思考深度（thinking level）控制 AI 推理时投入的 token 量。深度越高，推理越仔细但响应越慢越贵。

支持级别：`off` → `minimal` → `low` → `medium` → `high` → `xhigh`

**在会话中切换（三种方式）：**

| 方式 | 操作 | 说明 |
|------|------|------|
| 快捷键 | `Shift+Tab` | **最快** — 循环切换 off → minimal → low → medium → high → xhigh |
| 设置界面 | `/settings` → Thinking level | 可视化选择 |
| 模型选择 | `Ctrl+L` 或 `/model` | 选择模型时可调整思考级别 |

**启动时指定：**

```bash
pi --thinking medium
pi --thinking high -- "帮我重构这个模块"
pi --model deepseek-v4-flash-free:medium    # CLI 支持 :level 语法
```

**当前默认值：** `high`（在 `_packages.nix` 中配置）。复杂任务默认高思考，简单问题（查文件、列目录）可 `Shift+Tab` 快速切到 `low` 或 `medium` 省 token。编辑器边框颜色同步变化：蓝色=低、黄色=中、红色=高。

---

## 4. 插件功能与命令

当前配置了 **13 个 npm 插件 + 2 个 TS 扩展**。

### 4.1 界面：Powerline Footer

自定义底部状态栏，显示模型、token、git 状态等信息。

```
/powerline                    # 打开设置
/powerline default            # 切换预设（minimal/compact/full/nerd）
/vibe star trek               # 设置加载语主题（趣味功能）
/Alt+S                        # 暂存编辑器内容
/Ctrl+Shift+B                 # 切换 Bash 模式（持久 shell 会话）
```

趣味 `/vibe` 主题：`default`、`star trek`、`pirate`、`zen`、`noir`。

### 4.2 缓存优化：Cache Optimizer

优化 LLM 的 KV 缓存命中率，减少重复 token 消耗。

```
/cache-optimizer              # 交互式菜单
/cache-optimizer doctor       # 诊断缓存状态
/cache-optimizer stats        # 今日缓存统计
/cache-optimizer fix          # 自动修复兼容问题
```

### 4.3 输出压缩：RTK Optimizer

自动将 bash 命令重写为 `rtk` 等效命令，压缩工具输出。

```
/rtk                          # 打开设置
/rtk verify                   # 验证 rtk 二进制
/rtk stats                    # 输出压缩指标
```

### 4.4 子 Agent：Subagents

将工作委派给专精的子 agent。

| Agent | 用途 | 适用场景 |
|-------|------|---------|
| `scout` | 快速代码库侦察 | 理解结构、入口点、风险 |
| `researcher` | 网络调研 | 查文档、规范、基准测试 |
| `planner` | 制定计划 | 只读+写计划，不编辑代码 |
| `worker` | 执行实现 | 编辑文件、验证 |
| `reviewer` | 代码审查 | 检查实现、边界条件 |
| `oracle` | 第二意见 | 挑战假设、推荐安全方案 |

```text
"用 reviewer 审查这个 diff"
"Ask oracle for a second opinion"
"后台跑一个 scout 分析这个目录"
```

### 4.5 检查点：Pi Rewind

交互式导航到任意历史轮次。

```
/rewind                       # 打开检查点列表
/checkpoint                   # 查看存储状态
```

三种恢复模式：

1. **恢复代码+对话** — 同时回滚文件和对话
2. **仅恢复对话** — 重新探索旧思路，不改文件
3. **仅恢复代码** — 文件回滚，对话保持

### 4.6 权限系统：Permission System

写操作前根据策略判断是否弹窗确认。

受保护的操作示例：

- `sudo *` — **询问**
- `rm -rf *` — **拒绝**
- `chmod 777 *` — **询问**
- 读写 `.env`、`.git/*`、`~/.ssh/*` — **拒绝**

### 4.7 通知：Notify

agent 完成后自动发送桌面通知。

支持终端：Ghostty、iTerm2、WezTerm、Kitty、Windows Terminal。

### 4.8 计划模式：Plan Mode

只读探索模式，用于安全分析代码。

```
Ctrl+Shift+P                  # 切换计划模式
/plan                         # 同上
```

计划模式下禁用 edit/write，提取 `Plan:` 中的编号步骤。
标记 `[DONE:1]` 可逐一标记完成进度。

---

## 5. Superpowers 工作流

项目配置了 **20 个 superpowers 技能**，覆盖完整开发周期。

### 5.1 标准开发工作流

```
你                            agent
 │                              │
 ├─ "用 brainstorming 探索..."  → 探索/澄清/设计/方案
 │                              │
 ├─ "好，writing-plans"        → 创建实施计划
 │                              │
 ├─ 确认计划                   → 逐步实现 + nix flake check
 │                              │
 ├─ "requesting-code-review"   → 审查代码
 │                              │
 └─ "finishing"                → 合并/PR/清理
```

### 5.2 场景速查

| 场景 | 怎么说 |
|------|--------|
| 新功能 | "brainstorming，我想添加一个蓝牙模块" |
| Bug 修复 | "systematic-debugging，这个报错看不懂" |
| 并行任务 | "dispatching-parallel-agents，同时做这两个独立任务" |
| TDD | "test-driven-development，先写测试再实现" |
| 创建技能 | "writing-skills，我想创建一个新技能" |
| MCP 集成 | "mcp-builder，帮我集成一个 Git MCP 服务器" |
| 代码审查 | "requesting-code-review，检查我刚刚的改动" |

### 5.3 完整技能表

| 技能 | 分类 | 用途 |
|------|------|------|
| `brainstorming` | 设计 | 创造性工作前探索、澄清、设计、批准 |
| `writing-plans` | 设计 | 创建实施计划 |
| `executing-plans` | 开发 | 执行实施计划 |
| `subagent-driven-development` | 开发 | 子 agent 驱动开发 |
| `dispatching-parallel-agents` | 开发 | 并行分派独立任务 |
| `test-driven-development` | 开发 | 测试驱动开发 |
| `systematic-debugging` | 调试 | 系统化诊断根因 |
| `requesting-code-review` | 审查 | 请求代码审查 |
| `receiving-code-review` | 审查 | 接收审查反馈 |
| `chinese-code-review` | 审查 | 中文代码审查 |
| `verification-before-completion` | 验证 | 完成前运行验证 |
| `finishing-a-development-branch` | 交付 | 合并/PR/清理 |
| `writing-skills` | 工具 | 创建/编辑技能 |
| `mcp-builder` | 工具 | 构建 MCP 工具 |
| `workflow-runner` | 工具 | 运行多步骤工作流 |
| `chinese-documentation` | 文档 | 中文文档编写 |
| `chinese-commit-conventions` | 文档 | 中文提交规范 |
| `chinese-git-workflow` | 文档 | 中文 Git 工作流 |
| `using-superpowers` | 元 | 技能系统使用指南 |
| `using-git-worktrees` | 工具 | Git 工作树管理 |

---

## 6. 项目特定约定

### 6.1 Nix 项目约定

```
# 修改后必须运行
nix flake check              # CI 门禁

# 新建 .nix 文件后
git add <new-file>           # 否则 flake 看不到

# 修改 dendritic.nix 后
nix run .#write-flake        # 重新生成 flake.nix

# 更新 den 框架
nix flake update den
```

### 6.2 文件结构约定

- `modules/features/<domain>/<name>.nix` — 功能模块
- `modules/hosts/<hostname>/` — 主机配置
- Aspect 名 = 文件路径点号分隔，如 `desktop.wm.niri`
- `_` 前缀的文件被 `import-tree` 跳过
- 新建 `.nix` 文件不需要手动注册

### 6.3 插件添加原则

添加 pi npm 包时：

1. 检查与现有插件的功能重叠
2. 确认是否需要系统二进制依赖
3. 添加到 `_packages.nix` 的 `settings.packages` 列表
4. 更新 `docs/plugins-overview.md`

---

## 7. 常见问题

### 7.1 如何让 agent 理解大型项目？

使用 **Context Mode** 的 Think in Code 哲学：

```javascript
// 让 agent 写脚本来分析，而不是读大文件
ctx_execute("javascript", `
  const files = fs.readdirSync('modules').filter(f => f.endsWith('.nix'));
  // ... 分析代码
  console.log(JSON.stringify(results));
`);
```

### 7.2 如何撤销 agent 的错误修改？

使用 **Pi Rewind**：

```
/rewind
# 选择要回滚到的检查点
# 选择恢复模式：代码+对话 / 仅对话 / 仅代码
```

### 7.3 提示词从哪里来？

所有提示词整合在项目根目录的 `AGENTS.md` 中，这是 **单一起源参考文档**。agent 启动时自动加载其中的全局原则、技能表和约定。

### 7.4 如何扩展 Pi 的功能？

Pi 使用 **npm 包** 作为插件系统：

```bash
# 安装新插件
pi install npm:<package-name>

# 安装后需要在 _packages.nix 的 settings.packages 中添加
# 并运行 nix run .#write-flake 重新生成配置
```

### 7.5 Pi 会用哪些语言来写分析脚本？

Context Mode 的沙箱支持：JavaScript、Python、Shell。推荐用 JavaScript（Node.js 内置 API，如 `fs`、`path`、`child_process`）。

### 7.6 如何检查 agent 工作状态？

```
/cache-optimizer stats        # 今日缓存命中统计
/rtk stats                    # 输出压缩节省量
/checkpoint                   # 检查点存储状态
ctx_stats()                   # 上下文使用统计
```

---

## 参考

| 资源 | 位置 |
|------|------|
| AGENTS.md | 项目根目录 — 单一起源参考 |
| 插件文档 | `modules/features/dev/editors/pi-coding-agent/docs/plugins-overview.md` |
| Pi 官方文档 | `~/.pi/agent/npm/node_modules/@earendil-works/pi-coding-agent/docs/` |
| 各插件 README | `~/.pi/agent/npm/node_modules/<pkg>/README.md` |
| 设置参考 | `~/.pi/agent/settings.json` |
| Den 框架 | `docs/den/` 或 <https://den.denful.dev> |
| Superpowers | `docs/superpowers/README.md` |
