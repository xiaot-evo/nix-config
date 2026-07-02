# Pi Coding Agent 插件概览

> 本文档汇总了已安装的 Pi 插件及其功能用法，帮助了解和正确使用每个插件。

---

## 目录

1. [pi-powerline-footer](#1-pi-powerline-footer)—Powerline 风格底栏
2. [pi-cache-optimizer](#2-pi-cache-optimizer)—LLM KV 缓存命中率优化
3. [pi-rtk-optimizer](#3-pi-rtk-optimizer)—命令重写 + 输出压缩
4. [pi-web-access](#4-pi-web-access)—网页搜索与内容获取
5. [context-mode](#5-context-mode)—上下文管理：FTS5 知识库 + 沙箱执行
6. [pi-subagents](#6-pi-subagents)—子 agent 编排
7. [pi-mcp-adapter](#7-pi-mcp-adapter)—MCP 协议适配器
8. [rpiv-ask-user-question](#8-rpiv-ask-user-question)—结构化提问
9. [rpiv-todo](#9-rpiv-todo)—任务列表管理
10. [pi-lens](#10-pi-lens)—代码透镜
11. [superpowers-zh](#11-superpowers-zh)—技能系统
12. [@ayulab/pi-rewind](#12-ayulabpi-rewind)—修改追踪与恢复
13. [@gotgenes/pi-permission-system](#13-gotgenespi-permission-system)—权限管理

---

## 1. pi-powerline-footer

**作用**：自定义 Pi 编辑器底栏，替换默认的简单状态栏为 Powerline 风格。

### 主要功能

| 功能 | 说明 |
|------|------|
| **状态栏** | 显示当前模型、思考级别、路径、git 状态、上下文用量、token 数、费用等 |
| **预设切换** | `/powerline default` / `minimal` / `compact` / `full` / `nerd` / `ascii` |
| **Editor Stash** | `Alt+S` 暂存编辑器内容，清空输入框，agent 完成后自动恢复 |
| **Working Vibes** | `/vibe star trek` 让"Working..."变成主题化加载语，支持 pirate / zen / noir 等 |
| **欢迎覆盖** | 启动时显示品牌 Logo、模型信息、键盘快捷键、统计数据 |
| **Git 集成** | 异步获取分支、暂存/未暂存/未跟踪文件计数 |
| **上下文感知** | 70%（黄）和 90%（红）时颜色警告 |
| **Bash 模式** | `Ctrl+Shift+B` 切换，保持持久 shell 会话，流式输出到编辑器下方 |
| **Shell 幽灵建议** | 基于项目历史自动补全命令 |

### 常用命令

```
/powerline                    # 打开设置
/powerline default            # 切换预设
/powerline fixed-editor on    # 固定编辑器
/vibe star trek               # 设置加载语主题
/Alt+S                        # 暂存编辑器内容
/Ctrl+Shift+B                 # 切换 Bash 模式
```

### 设置

```json
{
  "powerline": {
    "preset": "default",
    "fixedEditor": true
  },
  "workingVibe": "star trek"
}
```

---

## 2. pi-cache-optimizer

**作用**：优化 LLM 的 KV / prompt 缓存命中率，减少重复 token 消耗，降低 API 费用。

### 主要功能

- **缓存优化**：将稳定的系统提示词前置，压缩技能列表，减少动态上下文波动
- **缓存键回退**：为 OpenAI 兼容代理添加 `prompt_cache_key` 回退
- **代理诊断**：检测第三方代理（LiteLLM / OneAPI 等）缺少会话亲和性配置并警告
- **Anthropic 自适应思考检测**：检测 opus-4.6+ / sonnet-4.6+ 模型缺少 `forceAdaptiveThinking` 配置
- **自动修复**：`/cache-optimizer fix` 可自动修复兼容性问题（需确认）
- **底栏统计**：显示缓存命中率（如 `DS cache 3/10 · 0.002M/0.005M tok (40%)`）

### 常用命令

```
/cache-optimizer              # 交互式菜单
/cache-optimizer enable       # 启用优化
/cache-optimizer doctor       # 诊断当前模型/提供商的缓存状态
/cache-optimizer compat       # 显示兼容性建议
/cache-optimizer stats        # 显示今日缓存统计
/cache-optimizer fix          # 自动修复兼容问题（需确认）
/cache-optimizer reset        # 重置本地统计
```

### 配置

当前配置已设置 DeepSeek 的 `supportsLongCacheRetention` 和 `sendSessionAffinityHeaders`。

---

## 3. pi-rtk-optimizer

**作用**：自动将 bash 命令重写为 `rtk` 等效命令，并压缩工具输出（bash / read / grep）以减少 token 消耗。

### 主要功能

| 模块 | 说明 |
|------|------|
| **命令重写** | 自动将 `git diff` → `rtk git diff` 等，或仅建议模式 |
| **ANSI 剥离** | 移除终端颜色/格式化代码 |
| **测试聚合** | 汇总测试运行器的通过/失败计数 |
| **构建过滤** | 从构建输出中提取错误/警告 |
| **Git 压缩** | 压缩 `git status`、`git log`、`git diff` 输出 |
| **Linter 聚合** | 汇总 lint 工具输出 |
| **搜索分组** | 按文件分组 `grep`/`rg` 结果 |
| **源码过滤** | `none` / `minimal` / `aggressive` 三级源码注释/空白移除 |
| **智能截断** | 保留文件边界和重要行 |
| **硬截断** | 最终字符数强制限制（默认 12000） |

### 常用命令

```
/rtk                          # 打开设置弹窗
/rtk show                     # 显示当前配置和运行时状态
/rtk verify                   # 检查 rtk 二进制是否可用
/rtk stats                    # 显示输出压缩指标
/rtk reset                    # 重置所有设置为默认值
```

### 配置

```json
{
  "enabled": true,
  "mode": "rewrite",
  "outputCompaction": {
    "readCompaction": { "enabled": false },
    "sourceCodeFiltering": "none",
    "truncate": { "enabled": true, "maxChars": 12000 }
  }
}
```

> ⚠️ `readCompaction` 默认为关闭，确保代码读取精确。如需开启请注意可能引起文件编辑 mismatch。

### 依赖

需要 `rtk` 二进制（已通过 Nix `extraPackages` 安装）。

---

## 4. pi-web-access

**作用**：提供网页搜索、内容提取、GitHub 仓库克隆、YouTube 视频理解和本地视频分析功能。

### 工具

#### web_search — 网页搜索

```typescript
web_search({ query: "rust async" })
web_search({ queries: ["q1", "q2"], provider: "openai" })
web_search({ query: "...", numResults: 10, recencyFilter: "week" })
web_search({ query: "...", includeContent: true })
web_search({ query: "...", workflow: "auto-summary" })
```

| 参数 | 说明 |
|------|------|
| `query` / `queries` | 单个/多个搜索查询 |
| `numResults` | 每查询结果数（默认 5，最大 20） |
| `recencyFilter` | `day` / `week` / `month` / `year` |
| `domainFilter` | 限制域名（`-github.com` 排除） |
| `provider` | `auto`（默认）/ `openai` / `brave` / `parallel` / `tavily` / `exa` / `perplexity` / `gemini` |
| `includeContent` | 异步获取页面全文 |
| `workflow` | `none`（跳过浏览器策展）/ `summary-review`（打开策展器并自动摘要，默认）/ `auto-summary`（生成摘要不打开策展器） |

#### fetch_content — 内容获取

```typescript
fetch_content({ url: "https://example.com" })
fetch_content({ urls: ["url1", "url2"] })
fetch_content({ url: "https://github.com/owner/repo" })
fetch_content({ url: "https://youtube.com/watch?v=abc", prompt: "视频里讲了什么？" })
```

自动检测：GitHub 仓库（克隆本地）、YouTube（Gemini 视频理解）、PDF（提取文本）、本地视频文件。

#### get_search_content — 检索存储内容

从之前的搜索或获取中提取已存储的完整内容。

### 自动回退链

```
web_search: OpenAI → Exa(direct) → Exa(MCP) → Brave → Parallel → Tavily → Perplexity → Gemini API → Gemini Web
fetch_content: Readability → Jina Reader → Gemini 提取
```

零配置即可使用（Exa MCP 无需 API key），也可在 `~/.pi/web-search.json` 配置各服务的 API key。

---

## 5. context-mode

**作用**：上下文窗口管理——通过沙箱工具、FTS5 知识库和智能搜索，将工具输出减少 98%。

### 核心哲学

**Think in Code**：让 AI 编写分析代码，只 `console.log()` 结果，而不是将大量原始数据读入上下文。

```javascript
// ❌ 之前：47 次 Read() = 700 KB
// ✅ 之后：1 次 ctx_execute() = 3.6 KB
ctx_execute("javascript", `
  const files = fs.readdirSync('src').filter(f => f.endsWith('.ts'));
  files.forEach(f => console.log(f + ': ' + fs.readFileSync('src/'+f,'utf8').split('\\n').length + ' lines'));
`);
```

### 工具族

| 工具 | 说明 |
|------|------|
| `ctx_execute()` | 沙箱执行代码（JS/Python/Shell 等），输出自动索引 |
| `ctx_execute_file()` | 对单个文件运行分析代码，文件内容不进上下文 |
| `ctx_index()` | 将内容（字符串或文件）存储到 FTS5 知识库 |
| `ctx_search()` | BM25 搜索知识库，支持多策略排序和拼写纠错 |
| `ctx_fetch_and_index()` | 获取 URL 内容并存入知识库 |
| `ctx_batch_execute()` | 批量执行命令，输出自动索引并支持一次查询 |
| `ctx_stats()` | 显示上下文使用统计 |
| `ctx_doctor()` | 诊断 context-mode 安装状态 |
| `ctx_upgrade()` | 升级到最新版本 |
| `ctx_purge()` | 永久删除索引内容 |
| `ctx_insight()` | 打开 hosted Insight 仪表盘 |

### 核心功能

- **沙箱隔离**：代码在沙箱中运行，只有 `console.log()` 的内容进入上下文
- **会话连续性**：文件编辑、git 操作、任务、错误、用户决策都记录在 SQLite 中。压实后通过 FTS5 检索，不丢失上下文
- **自动压实**：自动管理上下文窗口，保留最近内容，压缩历史
- **多客户端支持**：Claude Code / Gemini CLI / VS Code Copilot / OpenCode / Cursor 等 17+ 客户端

---

## 6. pi-subagents

**作用**：将工作委派给专注的子 agent——代码审查、调研、实现、并行审计等。

### 内置 agent

| Agent | 用途 | 适用场景 |
|-------|------|---------|
| `scout` | 快速代码库侦察 | 理解代码结构、入口点、数据流、风险 |
| `researcher` | 网络/文档调研 | 查找官方文档、规范、基准测试 |
| `planner` | 制定实施计划 | 阅读 -> 规划（不编辑代码） |
| `worker` | 执行实现 | 编辑文件、验证、上报未批准决策 |
| `reviewer` | 代码审查 | 检查实现是否符合任务/计划，测试用例，边界条件 |
| `context-builder` | 构建更强上下文 | 收集代码上下文，编写 handoff 材料 |
| `oracle` | 第二意见 | 挑战假设、发现漂移、推荐安全方案 |
| `delegate` | 通用委托 | 行为接近父会话的通用子 agent |

### 使用方式

```text
# 自然语言触发
"Use reviewer to review this diff."
"Ask oracle for a second opinion on my current plan."
"Run parallel reviewers: one for correctness, one for tests."

# 链式工作流
"Use scout to understand the auth flow, then have planner turn that into an implementation plan."

# 后台运行
"Run this in the background."

# 循环审查
"Run a review loop on this change until reviewers stop finding fixes worth doing, max 3 rounds."
```

---

## 7. pi-mcp-adapter

**作用**：在 Pi 中使用 MCP 服务器，同时避免大量工具定义消耗上下文窗口。

### 特点

- **懒加载**：服务器只在真正使用时才连接，工具元数据缓存供搜索
- **单代理工具**：所有 MCP 工具通过一个 `mcp()` 工具调用（~200 tokens），代替数百个工具定义
- **自动发现**：自动读取 `.mcp.json`、`~/.config/mcp/mcp.json` 等标准 MCP 配置文件

### 配置文件优先级

1. `~/.config/mcp/mcp.json` — 用户全局共享
2. `~/.pi/agent/mcp.json` — Pi 全局覆盖
3. `.mcp.json` — 项目本地共享
4. `.pi/mcp.json` — Pi 项目覆盖

### 常用命令

```
mcp({ })                                    # 查看服务器状态
mcp({ server: "nixos" })                    # 列出服务器工具
mcp({ search: "query" })                    # 搜索工具
mcp({ describe: "tool_name" })              # 查看工具详情
mcp({ tool: "name", args: '{"key":"val"}' }) # 调用工具
/mcp setup                                  # 从其他主机导入 MCP 配置
```

当前已配置 `nixos` MCP 服务器，提供 `nixos_nix` 和 `nixos_nix_versions` 两个工具。

---

## 8. rpiv-ask-user-question

**作用**：让 agent 向用户发起结构化多选项问卷，避免猜测用户意图。

### 工具

`ask_user_question()`

```typescript
ask_user_question({
  questions: [{
    question: "选择认证方式？",
    header: "Auth",
    options: [
      { label: "OAuth", description: "使用 OAuth 2.0" },
      { label: "API Key", description: "使用 API Key" }
    ]
  }]
})
```

### 特点

- 每个问题支持 2-4 个选项
- 支持 `multiSelect: true` 多选
- 支持 `preview` 预览（代码片段/图表对比）
- 用户可自定义输入或选择"Chat about this"
- 内置"Type something."自由文本行

---

## 9. rpiv-todo

**作用**：为 agent 提供任务列表管理，跨 /reload 和会话压实存活。

### 工具

`todo()` — 任务列表管理

```typescript
todo({ action: "create", subject: "调研 API", description: "..." })
todo({ action: "update", id: 1, status: "in_progress" })
todo({ action: "list" })
todo({ action: "get", id: 1 })
todo({ action: "delete", id: 1 })
```

### 使用模式

```
1. 收到复杂任务 → 创建 task 列表 capture requirements
2. 开始任务 → mark in_progress
3. 完成后 → mark completed
4. 阻塞时 → 使用 blockedBy 表达依赖
```

### 状态机

`pending` → `in_progress` → `completed`，另有 `deleted` 墓碑状态。

---

## 10. pi-lens

**作用**：代码反馈透镜——在 agent 编写/编辑代码时提供快速、语言感知的反馈。

### 主要工具

| 工具 | 说明 |
|------|------|
| `lsp_diagnostics()` | 获取 LSP 诊断（错误/警告） |
| `lsp_navigation()` | 代码导航（定义/引用/悬停/rename） |
| `ast_grep_search()` | AST 模式搜索 |
| `ast_grep_replace()` | AST 模式替换（dry-run 默认） |
| `ast_grep_outline()` | 代码结构大纲 |
| `ast_grep_dump()` | 转储 AST 节点类型 |
| `module_report()` | 结构化模块概览（符号、复杂度、引用） |
| `read_symbol()` | 读取特定符号的代码体 |
| `read_enclosing()` | 读取包含指定行的最小函数/回调 |
| `lens_diagnostics()` | 查询诊断状态 |

### 功能

- LSP 诊断和导航
- 语言特定的 linter、类型检查器
- AST-grep 和 tree-sitter 结构规则（正确性/安全）
- 审查图智能（谁使用了什么）
- 读后卫和自动补丁支持
- 后台安全/依赖扫描

---

## 11. superpowers-zh

**作用**：superpowers（`github:obra/superpowers`）的中文增强版技能系统，提供 20 个预定义工作流技能。在 Nix 项目上下文中，agent 应主动调用合适的技能。

### 全部技能列表

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

### 标准开发工作流

```
1. brainstorming          → 探索、澄清、设计、批准
2. writing-plans          → 创建实施计划
3. 实现                   → 编码 + nix flake check
4. requesting-code-review → 验证满足需求
5. finishing-a-development-branch → 合并/PR/清理
```

### 调试工作流

```
1. systematic-debugging   → 诊断根因
2. 修复 + nix flake check
3. verification-before-completion → 确认修复
```

### 技能分类速查

| 场景 | 技能链 |
|------|--------|
| 新功能开发 | brainstorming → writing-plans → subagent-driven-development / executing-plans → verification-before-completion → requesting-code-review → finishing-a-development-branch |
| Bug 修复 | systematic-debugging → writing-plans → 修复 → verification-before-completion |
| 并行任务 | dispatching-parallel-agents（每个子任务内运行完整开发工作流） |
| TDD | test-driven-development → 写测试 → 实现 → 验证 |
| 创建新技能 | writing-skills → test-driven-development → 完成 |
| MCP 集成 | mcp-builder → 开发 → 验证 |

---

## 12. @ayulab/pi-rewind

**源仓库**：`github:ayulab/pi-rewind`  
**作用**：修改追踪与恢复——交互式检查点导航，支持代码/对话回滚。

### 主要功能

| 功能 | 说明 |
|------|------|
| **/rewind 命令** | 交互式检查点列表，显示文件变更统计 |
| **三种恢复模式** | ① 恢复代码+对话 ② 仅恢复对话 ③ 仅恢复代码 |
| **/checkpoint 管理器** | `Current Folder` / `All` 视图，`Ctrl+D` 删除 |
| **/tree 集成** | 树导航时可选同步文件状态（`restoreOnTree: ask/never/always`）|
| **Fork/Clone 集成** | 自动复制检查点存储，支持叉出时恢复代码 |
| **会话恢复** | `/resume` 和 `pi -r` 可选恢复文件状态 |

### 常用命令

```
/rewind                     # 打开交互式检查点导航
/checkpoint                 # 查看检查点存储状态
/tree                       # 树导航（集成文件同步）
```

### 配置

```json
{
  "ayu": {
    "rewind": {
      "restoreOnTree": "ask"
    },
    "checkpoint": {
      "restoreOnResume": false,
      "restoreOnFork": false,
      "restoreOnClone": false
    }
  }
}
```

### 与 git-checkpoint 的关系

git-checkpoint.ts（已移除）是 Pi 官方的最小示例扩展。@ayulab/pi-rewind 是其功能完整的替代品，提供交互式 TUI、存储管理和更细粒度的恢复控制。

---

## 13. @gotgenes/pi-permission-system

**源仓库**：`github:gotgenes/pi-packages`  
**作用**：集中式权限管理——allow/ask/deny 三级策略，在工具调用和 bash 执行前进行权限检查。

### 主要功能

| 功能 | 说明 |
|------|------|
| **三级策略** | `allow`（允许）/ `ask`（询问）/ `deny`（拒绝）|
| **工具隐藏** | 拒绝的工具在 agent 启动前就隐藏，不浪费轮次 |
| **Bash 命令控制** | 通配符模式匹配：`git *: ask`、`rm -rf *: deny` |
| **路径保护** | `.env`、`~/.ssh/*`、`.git/*` 等敏感路径自动 deny |
| **外部目录守卫** | 操作超出 `cwd` 时弹窗确认 |
| **子 agent 集成** | 子 session 自动注册权限策略，`ask` 状态转发到父 UI |

### 当前配置

当前通过 Nix 配置部署了以下策略：

```json
{
  "permission": {
    "*": "allow",
    "path": {
      "*": "allow",
      "*.env": { "action": "deny", "reason": "环境变量文件包含凭证" },
      "*.env.*": { "action": "deny", "reason": "环境变量文件包含凭证" },
      ".git/*": { "action": "deny", "reason": ".git 内部文件不应直接修改" },
      "~/.ssh/*": { "action": "deny", "reason": "SSH 密钥文件受保护" }
    },
    "bash": {
      "*": "allow",
      "rm -rf *": "deny",
      "rm -rf /*": "deny",
      "sudo *": "ask",
      "chmod 777 *": "ask",
      "chmod -R 777 *": "ask",
      "> *": "ask",
      ">>*": "ask",
      "dd *": "deny",
      "mkfs*": "deny",
      "reboot": "deny",
      "shutdown": "deny"
    },
    "external_directory": "ask"
  }
}
```

---

## TS 扩展

除了 npm 包，还有以下 TypeScript 扩展直接部署在 `~/.pi/agent/extensions/` 中：

### notify.ts

**源仓库**：`github:earendil-works/pi`（官方示例）  
**作用**：agent 完成任务后发送原生终端通知。

- 支持 Ghostty / iTerm2 / WezTerm（OSC 777）
- 支持 Kitty（OSC 99）
- 支持 Windows Terminal（PowerShell toast）
- 自动检测终端类型

### plan-mode

**源仓库**：`github:earendil-works/pi`（官方示例）  
**作用**：只读计划模式——安全代码分析和步骤化执行。

- `/plan` 或 `Ctrl+Shift+P` 切换计划模式
- 计划模式下禁用 edit/write 工具
- 提取 `Plan:` 章节中的编号步骤
- `[DONE:n]` 标记完成步骤

---

## 参考来源

- 各插件 README：位于 `~/.pi/agent/npm/node_modules/<pkg>/README.md`
- Pi 官方文档：`/nix/store/.../pi-monorepo/docs/`
- Pi 设置参考：`~/.pi/agent/settings.json`
- MCP 配置：`~/.pi/agent/mcp.json`
