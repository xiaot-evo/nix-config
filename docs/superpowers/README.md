# Superpowers 技能系统

本项目使用 [superpowers](https://github.com/obra/superpowers) 的中文增强版 `superpowers-zh`，提供 20 个预定义工作流技能。

> 完整技能表见 [AGENTS.md](../../AGENTS.md#superpowers-skills--完整技能表20-个)。

---

## 技能分类

### 设计（2 个）

- **`brainstorming`** — 创造性工作前探索、澄清、设计、批准。任何新功能、改动、模块设计前**始终从这里开始**。
- **`writing-plans`** — brainstorming 完成后创建实施计划。

### 开发（4 个）

- **`executing-plans`** — 执行实施计划。按计划逐步实现。
- **`subagent-driven-development`** — 实施计划含独立子任务时，使用子 agent 并行执行。
- **`dispatching-parallel-agents`** — 遇到 2+ 无共享状态的独立任务时，并行分派。
- **`test-driven-development`** — 测试驱动开发：先写测试，再实现，最后验证。

### 调试（1 个）

- **`systematic-debugging`** — 遇到 bug、测试失败或意外行为时，系统化诊断根因。

### 审查（3 个）

- **`requesting-code-review`** — 工作完成后、合并前，请求代码审查。
- **`receiving-code-review`** — 接收并处理代码审查反馈。
- **`chinese-code-review`** — 中文代码审查。

### 验证（1 个）

- **`verification-before-completion`** — 声明完成前运行验证。

### 交付（1 个）

- **`finishing-a-development-branch`** — 实现完成后决定合并/PR/清理。

### 工具（5 个）

- **`writing-skills`** — 创建/编辑 superpowers 技能。
- **`mcp-builder`** — 构建 MCP 工具。
- **`workflow-runner`** — 运行多步骤自动化工作流。
- **`using-git-worktrees`** — Git 工作树管理，用于并行开发分支。
- **`using-superpowers`** — 使用 superpowers 技能系统的指南。

### 文档（3 个）

- **`chinese-documentation`** — 中文文档编写。
- **`chinese-commit-conventions`** — 中文提交规范。
- **`chinese-git-workflow`** — 中文 Git 工作流。

---

## 工作流速查

| 场景 | 技能链 |
|------|--------|
| 新功能开发 | `brainstorming` → `writing-plans` → `subagent-driven-development` / `executing-plans` → `verification-before-completion` → `requesting-code-review` → `finishing-a-development-branch` |
| Bug 修复 | `systematic-debugging` → `writing-plans` → 修复 → `verification-before-completion` |
| 并行任务 | `dispatching-parallel-agents`（每个子任务内运行完整开发工作流）|
| TDD | `test-driven-development` → 写测试 → 实现 → 验证 |
| 创建新技能 | `writing-skills` → `test-driven-development` → 完成 |
| MCP 集成 | `mcp-builder` → 开发 → 验证 |
| 多步骤自动化 | `workflow-runner`（编排多个 phase）|

---

## 技能文件位置

超级技能定义位于 pi 的 npm 包中：

```
~/.pi/agent/npm/node_modules/superpowers-zh/skills/
├── brainstorming/
├── chinese-code-review/
├── chinese-commit-conventions/
├── chinese-documentation/
├── chinese-git-workflow/
├── dispatching-parallel-agents/
├── executing-plans/
├── finishing-a-development-branch/
├── mcp-builder/
├── receiving-code-review/
├── requesting-code-review/
├── subagent-driven-development/
├── systematic-debugging/
├── test-driven-development/
├── using-git-worktrees/
├── using-superpowers/
├── verification-before-completion/
├── workflow-runner/
├── writing-plans/
└── writing-skills/
```

---

## 参考

- [AGENTS.md](../../AGENTS.md) — 单一起源参考
- [superpowers 官方文档](https://github.com/obra/superpowers)
- [`superpowers-zh` npm 包](https://www.npmjs.com/package/superpowers-zh)
