# Pi Coding Agent 插件概览

> 本文档汇总了已安装的 Pi 插件及其功能用法，帮助了解和正确使用每个插件。

---

## 目录

1. [context-mode](#1-context-mode)
2. [pi-subagents](#2-pi-subagents)
3. [pi-mcp-adapter](#3-pi-mcp-adapter)
4. [rpiv-todo](#4-rpiv-todo)
5. [pi-lens](#5-pi-lens)
6. [@chankov/agent-skills](#6-chankov-agent-skills)
7. [@ayulab/pi-rewind](#7-ayulab-pi-rewind)
8. [cc-safety-net](#8-cc-safety-net)
9. [@lynskylate/agent-md-management](#9-lynskylate-agent-md-management)

---

## 1. context-mode

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

## 2. @tintinweb/pi-subagents

**源仓库**：`github:tintinweb/pi-subagents`  
**作用**：Claude Code 风格的子 agent 编排——Agent 工具、FleetView 导航、会话查看器、中途引导。

### 工具

| 工具 | 用途 |
|------|------|
| `Agent` | 启动子 agent（支持 foreground / background / cron 调度）|
| `get_subagent_result` | 检查后台 agent 状态和结果 |
| `steer_subagent` | 中途引导运行中的 agent |

### 内置 agent

| Agent | 用途 |
|-------|------|
| `general-purpose` | 父 session 双子——继承全部 system prompt 和规则 |
| `Explore` | 快速代码库探索（只读，haiku 模型）|
| `Plan` | 架构规划（只读）|

### 主要功能

- **FleetView** — 编辑器下方导航列表，↑↓ 选择，Enter 打开会话查看器
- **Conversation viewer** — 实时滚动覆盖层，查看子 agent 对话
- **中途引导** — 运行时注入消息重定向 agent
- **定时调度** — cron / interval / 一次性调度
- **自定义 agent** — 通过 `.pi/agents/*.md` YAML frontmatter 定义
- **优雅终止** — wrap-up 警告再中止，不丢失结果
- **工作树隔离** — 每个 agent 在独立 git worktree 中运行
- **agent 记忆** — 项目/用户/本地三级持久化记忆

### 常用命令

```
/agents          # 交互式管理菜单（运行中 agent、agent 类型、设置）
```

### 使用方式

```text
Agent({ subagent_type: "Explore", prompt: "Find auth files", description: "Scan auth", run_in_background: true })
```

---

## 3. pi-mcp-adapter

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

## 4. rpiv-todo

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

## 5. pi-lens

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

## 6. @chankov/agent-skills

**源仓库**：`github:chankov/agent-skills`  
**作用**：27 个工程化技能 + 8 个斜杠命令，覆盖完整开发生命周期。

Fork 自 addyosmani/agent-skills，专为 pi / Claude Code / OpenCode 打包。

### 斜杠命令

| 命令 | 用途 |
|------|------|
| `/spec` | 编写 PRD（目标、结构、测试策略） |
| `/plan` | 分解为小颗粒度可验证任务 |
| `/build` | 增量实现（垂直切片、测试驱动） |
| `/test` | 测试驱动开发（红-绿-重构） |
| `/review` | 五维代码审查 |
| `/code-simplify` | 代码简化（保留功能） |
| `/webperf` | Web 性能审计 |
| `/ship` | 安全发布 |

### 27 个技能

| 阶段 | 技能 |
|------|------|
| **Define** | interview-me, idea-refine, spec-driven-development |
| **Plan** | planning-and-task-breakdown |
| **Build** | incremental-implementation, test-driven-development, context-engineering, source-driven-development, doubt-driven-development, frontend-ui-engineering, api-and-interface-design |
| **Verify** | browser-testing-with-devtools, debugging-and-error-recovery |
| **Review** | code-review-and-quality, code-simplification, security-and-hardening, performance-optimization |
| **Ship** | git-workflow-and-versioning, ci-cd-and-automation, deprecation-and-migration, documentation-and-adrs, observability-and-instrumentation, shipping-and-launch |
| **Orchestrate** | orchestration-verification |
| **Meta** | using-agent-skills, designing-agents, guided-workspace-setup |

### 特点

- **Process, not prose**——技能是可执行的工作流，不是参考文档
- **Anti-rationalization**——每个技能包含常见的 agent 偷懒借口及反驳
- **Verification is non-negotiable**——每个技能以验证证据结束
- **Progressive disclosure**——`SKILL.md` 是入口，引用文档按需加载

### Bundled 依赖

内置 `pi-ask-user`（提供 `ask_user` 工具），无需额外安装。

### 注意

由于项目约定用中文回复，部分技能输出可能为英文。遇到中文场景可手动提示 agent 使用中文。

---

## 7. @ayulab/pi-rewind

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

## 8. cc-safety-net

**源仓库**：`github:kenryu42/cc-safety-net`  
**作用**：PreToolUse hook — 在命令执行前拦截并阻止破坏性 git 和文件系统命令。

与原先的 `pi-permission-system`（通配符匹配）不同，cc-safety-net 进行 **语义分析**：指令重排、shell wrapper、解释器 one-liner 都无法绕过。

### 为什么替换 pi-permission-system

| 场景 | pi-permission-system | cc-safety-net |
|------|---------------------|---------------|
| `git checkout -b feature`（安全） | 被 `git checkout:*` 阻止 ❌ | 允许 ✅ |
| `git checkout -- file`（危险） | 被阻止 ✅ | 被阻止 ✅ |
| `rm -rf /tmp/cache`（安全） | 被 `rm -rf *` 阻止 ❌ | 允许 ✅ |
| `rm -r -f /`（危险） | 允许（flag 顺序绕过）❌ | 被阻止 ✅ |
| `bash -c 'git reset --hard'` | 允许（wrapper）❌ | 被阻止 ✅ |
| `python -c 'os.system("rm -rf /")'` | 允许（解释器）❌ | 被阻止 ✅ |

### 主要功能

| 功能 | 说明 |
|------|------|
| **语义分析** | 基于命令意图而非字符串模式判断，flag 重排/变体无法绕过 |
| **Shell wrapper 检测** | 递归分析 `bash -c`、`sh -c` 等 wrapper（最多 10 层） |
| **解释器 one-liner** | 检测 `python -c`、`node -e` 等内部的破坏性命令 |
| **默认 fail-closed** | 输入无效/解析失败时阻止而非放行 |
| **审计日志** | 所有被阻止的命令记录到 `~/.cc-safety-net/logs/` |
| **秘密脱敏** | 阻止消息自动遮盖 token、密码、API key |

### 被阻止的命令

**Git 破坏性操作：**

| 命令模式 | 危险原因 |
|---------|---------|
| `git checkout -- files` | 永久丢弃未提交变更 |
| `git restore files` | 丢弃未提交的工作区变更 |
| `git reset --hard` | 销毁所有未提交变更 |
| `git clean -f` | 永久删除未跟踪文件 |
| `git push --force / -f` | 销毁远程历史 |
| `git branch -D` | 强制删除分支（无 merge 检查） |
| `git stash drop / clear` | 永久删除 stash |

**文件系统破坏性操作：**

| 命令模式 | 危险原因 |
|---------|---------|
| `rm -rf /` / `~` / `$HOME` | 根目录/主目录删除 |
| `find ... -delete` | 永久删除匹配文件 |
| `xargs rm -rf` | 动态输入不可预测 |
| `dd` 写入块设备 | 覆盖磁盘/分区 |
| `mkfs` 块设备 | 格式化磁盘/分区 |
| `shred` | 永久销毁文件内容 |

### 安全性概览

cc-safety-net 工作在 PreToolUse hook 层级（在权限系统 **之前** 运行）。它充当 "hard technical constraint"，而 AGENTS.md 中的规则是 "soft rules"——两者结合提供纵深防御。

默认模式已足够保护日常工作流。如需更严格的控制，可通过环境变量启用：

- `CC_SAFETY_NET_STRICT=1` — 严格模式，无法解析的命令也阻止
- `CC_SAFETY_NET_PARANOID=1` — 偏执模式，阻止 cwd 内的 `rm -rf` 和解释器 one-liner
- `CC_SAFETY_NET_WORKTREE=1` — 工作树模式，在 linked worktree 内放松本地 git discard 规则

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

---

## 9. @lynskylate/agent-md-management

**源仓库**：`github:Lynskylate/agent-md-management`  
**作用**：AGENTS.md 审计与改进——审计质量、捕获会话学习、保持项目记忆更新。

灵感来自 Anthropic 官方 claude-md-management 插件。

### 功能

| 组件 | 触发方式 | 用途 |
|------|---------|------|
| **agent-md-improver（skill）** | `"审计我的 AGENTS.md"` | 审计 AGENTS.md 与代码库一致性 |
| **/revise-agent-md（命令）** | 手动调用 | 捕获本次会话学习，生成更新建议 |

### 审计标准

| 标准 | 权重 | 检查内容 |
|------|------|----------|
| 命令完整性 | 高 | 构建/测试/部署命令是否存在且可用？ |
| 架构清晰度 | 高 | agent 能否理解代码库结构？ |
| 非显式模式 | 中 | 是否记录了 gotchas 和常见陷阱？ |
| 简洁性 | 中 | 排除冗长解释和显而易见的信息？ |
| 时效性 | 高 | 是否反映当前代码库状态？ |
| 可执行性 | 高 | 指令是否可操作而非模糊？ |

---

## 参考来源

- 各插件 README：位于 `~/.pi/agent/npm/node_modules/<pkg>/README.md`
- Pi 官方文档：`/nix/store/.../pi-monorepo/docs/`
- Pi 设置参考：`~/.pi/agent/settings.json`
- MCP 配置：`~/.pi/agent/mcp.json`
