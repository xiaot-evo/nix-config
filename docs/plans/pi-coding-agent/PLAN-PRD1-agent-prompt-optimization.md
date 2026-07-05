# Implementation Plan: Pi Coding Agent 提示词全面优化

## Overview

实现 PRD1 中定义的三个优化目标：(1) 充分利用所有 pi 能力，(2) 优化 Nix 工作流表现，(3) 提升提示词质量。涉及三个文件的修改和一个文件的创建，各自独立、互不阻塞。

## Architecture Decisions

| 决策 | 选择 | 理由 |
|------|------|------|
| Context vs AGENTS.md 分工 | Context = 核心策略速查表（工具选择、Nix 工作流、思考深度）；AGENTS.md = 完整参考（项目结构、Den 框架、技能表） | Context 始终在上下文窗口中，需简洁；AGENTS.md 按需加载，可更详尽 |
| Compaction 设置存放位置 | 修改 `_packages.nix`（全局）中的 `keepRecentTokens` 从 100000 → 32000 | compaction 已在全局设置中定义，无需拆分 |
| enabledModels 存放位置 | `_home-files.nix` 写入 `.pi/settings.json`（项目级） | 模型切换列表是项目特定的偏好，不污染全局设置 |
| `.pi/settings.json` 生成方式 | `builtins.toJSON`（与现有 mcp.json 一致的模式） | 保持代码风格统一，Nix 函数化去重 |

## Task List

### Phase 1: Foundation — Nix 配置文件

#### Task 1: 更新 \_packages.nix — context + compaction + 模型配置

**Description:** 重写 `_packages.nix` 的 `context` 提示词，加入工具选择优先级策略、Nix 工作流步骤和思考深度选择指南；调整 `compaction.keepRecentTokens` 到 32000；移除无实际效果的 `enabledModels`（opencode 无全局 filter 支持，改由 `.pi/settings.json` 项目级设置控制）。

**Acceptance criteria:**

- [ ] `context` 包含工具选择优先级（MCP > direct tools > skills 的决策树）
- [ ] `context` 包含 Nix 工作流步骤（edit → nixfmt → git add → nix flake check）
- [ ] `context` 包含思考深度选择指南（什么场景用什么 level）
- [ ] `context` 包含扁平化编辑提示（一次 edit 多个 edits[]）
- [ ] `compaction.keepRecentTokens` = 32000
- [ ] `compaction.reserveTokens` 保持 16384

**Verification:**

- [ ] `nix-instantiate --parse modules/features/dev/editors/pi-coding-agent/_packages.nix` 通过
- [ ] `nix flake check` 通过（需先 git add）

**Dependencies:** None

**Files likely touched:**

- `modules/features/dev/editors/pi-coding-agent/_packages.nix`

______________________________________________________________________

#### Task 2: 通过 \_home-files.nix 部署 .pi/settings.json

**Description:** 在 `_home-files.nix` 中添加 `.pi/settings.json` 的声明式部署内容。使用 `builtins.toJSON`（与现有 mcp.json 一致的模式），包含 `enabledModels`（`["deepseek-v4*"]`）和 `branchSummary` 等项目级设置。

**Acceptance criteria:**

- [ ] `.pi/settings.json` 通过 `builtins.toJSON` 生成
- [ ] `enabledModels` 设为 `["deepseek-v4*"]` 以支持 Ctrl+P 在 flash-free 和 pro 之间切换
- [ ] `branchSummary.skipPrompt` 设 `true`（减少 /tree 时的交互提示）
- [ ] `retry.provider.maxRetries` 设 `1`（DeepSeek 偶尔需要一次 SDK 级重试）

**Verification:**

- [ ] `nix flake check` 通过
- [ ] 生成的 JSON 语法正确：`echo '{"enabledModels":["deepseek-v4*"],"branchSummary":{"skipPrompt":true}}' | jq .`

**Dependencies:** None

**Files likely touched:**

- `modules/features/dev/editors/pi-coding-agent/_home-files.nix`

______________________________________________________________________

### Checkpoint 1: Nix 配置文件验证

- [ ] `nix flake check` 通过（需要 `git add` 所有变更后）
- [ ] 两个 `.nix` 文件均经 `nixfmt` 格式化
- [ ] 评审 Task 1 context 内容是否准确、完备
- [ ] 评审 Task 2 `.pi/settings.json` 的内容是否合理

______________________________________________________________________

### Phase 2: Core — AGENTS.md 重写

#### Task 3: 重写 AGENTS.md 为决策驱动结构

**Description:** 将 AGENTS.md 从"工具列表参考"升级为"决策驱动的工作指南"。保留技术参考信息（项目结构、Den 框架、Flake 输入等）但精简重组。新增工具选择决策流、Nix 工作流详细步骤、三级提示分类（规则/策略/参考）。

**新的结构（标记为「新增」的为新加或大幅重写的章节）：**

```
1. 全局原则                       ← 精简现有，加「规则/策略/参考」分类
2. 工具选择决策流（新增）          ← 新增：任务类型→首选工具决策表
3. Nix 工作流（新增）              ← 新增：完整工作流 + 常见错误处理
4. 快速命令                        ← 保留现有
5. 项目结构                        ← 保留现有，精简
6. Den 框架要点                    ← 保留现有
7. Pi agent 配置                   ← 保留现有
8. Flake 输入                      ← 拆入附录或保留精简版
9. 可用技能 / 斜杠命令 / 注意事项   ← 保留现有
10. 附录：主机、用户、Flake 输入    ← 新增：将 AGENTS_PROJECT.md 和 Flake 输入移入附录
```

**Acceptance criteria:**

- [ ] 包含工具选择决策表（任务类型 → 首选工具 → 备选 → 理由）
- [ ] 包含 Nix 工作流详细步骤（含常见错误场景处理）
- [ ] 使用三级分类标注（规则/策略/参考）
- [ ] 保留所有现有技术参考信息（简化的 Den 框架、项目结构等）
- [ ] AGENTS_PROJECT.md 内容不受影响
- [ ] 附录中保留完整 Flake 输入引用

**Verification:**

- [ ] 人工评审：章节完整、逻辑清晰、标注准确
- [ ] 无 markdown 语法错误
- [ ] 所有工具引用与实际安装的包一致

**Dependencies:** Task 1（确保 context 和 AGENTS.md 分工一致）, Task 2（`.pi/settings.json` 中的 enabledModels 在 AGENTS.md 中有引用）

**Files likely touched:**

- `AGENTS.md`

______________________________________________________________________

### Checkpoint 2: 最终验证

- [ ] `nix flake check` 通过
- [ ] AGENTS.md 结构完整、分类清晰
- [ ] Context 和 AGENTS.md 分工合理、内容一致
- [ ] `.pi/settings.json` 通过 Nix 生成且内容正确
- [ ] 所有修改已 `git add`
- [ ] 可部署执行：`nix run .#acer-swift -- switch`

## Risks and Mitigations

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| AGENTS.md 过长导致 agent 忽略 | 中 | 坚持 progressive disclosure：上下文用 context 速查表，AGENTS.md 作为参考按需加载 |
| context 提示词太冗长占用上下文 | 低 | 控制 context 在 20-30 行，只包含最关键的选择策略 |
| `.pi/settings.json` 覆盖全局设置产生意外行为 | 低 | 只覆盖明确需要的键（enabledModels, branchSummary, retry.provider），其他保持全局设置 |
| Nix flake check 因缓存或网络失败 | 低 | 提前 `git add`，必要时 `nix flake check --no-build` 仅检查评估 |

## Open Questions

- ~~pi-rtk-optimizer 与 context-mode 功能重叠？~~ → 留待后续评估，本次不涉及
- ~~pi-permission-system 与 cc-safety-net 功能重叠？~~ → 两者互补（permission=写操作策略，safety=命令语义拦截），本次不调整
- AGENTS.md 中 Den 框架部分是否保留详细说明，还是简化为引用 `docs/den/`？ → 保留精简版，详版引用外部文档
