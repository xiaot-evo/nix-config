# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

基于 [Den](https://den.denful.dev) 框架的 NixOS + home-manager 配置 flake，管理单台物理机 `acer-swift`（AMD CPU + NVIDIA GPU）及其用户 `xiaot_evo`。

详细主机/用户/模块清单见 [AGENTS_PROJECT.md](AGENTS_PROJECT.md)，Den 框架完整文档见 [AGENTS.md](AGENTS.md)。

## 会话行为

Claude Code 的 `context` 指令设置为「请用中文回复。参考 AGENTS.md 了解项目结构、约定和完整技能表。」——所有回复用中文，AGENTS.md 是权威参考。

本环境加载了以下 Claude Code 插件/技能：

- **claude-md-management** — CLAUDE.md/AGENTS.md 审计改进
- **code-simplifier** — 代码简化审查
- **code-review** — 代码审查（`/code-review`、`/review`）
- **skill-creator** — 技能创建与管理
- **superpowers** — 20 个工程化技能（brainstorming、TDD、debugging、code-review 等）

插件市场 `claude-plugins-official` 已注册，可通过 `/plugin` 发现和安装更多插件。

## 常用命令

```console
# 构建（不部署）
nix run .#acer-swift

# 构建并部署
nix run .#acer-swift -- switch

# 重新生成 flake.nix（修改 dendritic.nix 后）
nix run .#write-flake

# 格式化所有文件（.nix .json .md .yaml）
nix fmt

# 仅检查格式（不修改文件）
nix fmt -- --fail-on-change

# CI 门禁 — 修改后必须通过
nix flake check

# 快速语法检查（不构建）
nix-instantiate --parse <file>

# 格式化单个 Nix 文件（快速，无需 flake 评估）
nixfmt <file>

# 更新 Den 框架
nix flake update den

# 仅评估不构建（比 flake check 更快）
nix flake check --no-build
```

### devenv 快捷脚本

在 `devenv shell` 内可使用以下快捷命令（定义在 `devenv.nix`）：

| 命令 | 等同于 |
|------|--------|
| `flake-write` | `nix run .#write-flake` |
| `fmt` | `nix fmt`（treefmt-nix：nixfmt + jsonfmt + mdformat + yamlfmt） |
| `fmt-check` | `nix fmt -- --fail-on-change`（CI 模式，仅检查不修改） |
| `check` | `nix flake check`（含格式化检查） |
| `build` | `nix run .#<hostname> --impure` |
| `build-switch` | `nix run .#<hostname> -- switch --impure` |

> **注意：** devenv 脚本使用 `--impure` 是因为脚本通过 `builtins.readFile /etc/hostname` 获取主机名。直接使用 `nix run .#acer-swift -- switch` 通常不需要 `--impure`。

## 架构核心

### Den Aspects 模式

所有配置以 **aspect** 为基本单元，定义在 `modules/features/<domain>/<name>.nix`，aspect 名 = 文件路径点号分隔：

| 文件 | Aspect 名 |
|------|----------|
| `features/desktop/wm/niri.nix` | `den.aspects.desktop.wm.niri` |
| `features/dev/editors/helix/helix.nix` | `den.aspects.dev.editors.helix` |

主机和用户在 `modules/hosts/` 中通过 `includes` 列表组装所需 aspects。

### includes / provides 双向通信

```
host (nixos) ──includes──→ hardware, boot, nix, sound
  └──provides.to-users.homeManager──→ 全局包

user (homeManager) ──includes──→ dev, desktop, apps...
  └──provides.to-hosts.nixos──→ NixOS 扩展设置
```

### 关键文件

| 文件 | 职责 | 注意事项 |
|------|------|---------|
| `flake.nix` | flake 入口 | **自动生成，勿手动编辑** |
| `modules/dendritic.nix` | flake 输入声明 + flake-file 配置 | 修改后运行 `nix run .#write-flake` |
| `modules/defaults.nix` | 全局默认值（stateVersion, strict schema） | |
| `modules/treefmt.nix` | 多语言格式化（nixfmt + jsonfmt + mdformat + yamlfmt） | |
| `modules/hosts/acer-swift/acer-swift.nix` | 主机 aspect（硬件+系统） | |
| `modules/hosts/acer-swift/xiaot_evo.nix` | 用户 aspect（应用+桌面+开发） | |
| `modules/hosts/acer-swift/hardware.nix` | 硬件配置 | |
| `modules/features/` | 可复用功能模块 | import-tree 自动发现 |
| `devenv.nix` | devenv 开发环境（快捷脚本 + LSP + MCP） | |

### import-tree 规则

- 递归导入 `modules/` 下所有 `.nix` 文件
- `_` 前缀文件会被跳过（如 `_packages.nix`、`_settings.nix`）
- `dir/dir.nix` 作为 aspect 名称为 `dir`（去重）

## 可用的 MCP 工具

本环境配置了两个 MCP 服务器，提供比手动搜索更高效的工具：

### nixos 服务器

查询 Nix 包、NixOS/Home Manager 选项、flake、二进制缓存、store 路径。**优先于 `nix search` 或手动浏览 search.nixos.org。**

常用场景：

- 查包：`mcp__nixos__nix({ action: "search", query: "包名" })`
- 查选项：`mcp__nixos__nix({ action: "search", query: "选项名", type: "options" })`
- 查 Home Manager 选项：`mcp__nixos__nix({ action: "search", source: "home-manager", query: "..." })`
- 查二进制缓存：`mcp__nixos__nix({ action: "cache", query: "包名" })`
- 读 `/nix/store` 路径：`mcp__nixos__nix({ action: "store", type: "read", query: "/nix/store/..." })`

### devenv 服务器

管理 devenv 进程（查看日志、启停服务）：

- `mcp__devenv__list_processes()` — 列出所有进程状态
- `mcp__devenv__get_process_logs({ name: "进程名" })` — 查看进程日志

## 二进制缓存

项目配置了以下 substituters（在 `dendritic.nix` 中），构建时会自动从这些缓存获取：

| 缓存 | 用途 |
|------|------|
| `mirrors.tuna.tsinghua.edu.cn` | 清华大学 TUNA 镜像 |
| `nix-community.cachix.org` | nix-community 社区缓存 |
| `cache.numtide.com` | Numtide 官方缓存（llm-agents-nix 等） |
| `niri-nix.cachix.org` | niri WM 缓存 |
| `cache.nixos-cuda.org` | CUDA 相关包缓存 |
| `noctalia.cachix.org` | Noctalia 桌面缓存 |

## 开发工作流

```
1. 编辑文件
2. nix fmt                       # 格式化所有修改的文件（.nix .json .md .yaml）
3. git add <file>                # 新建/删除后必做，否则 flake 评估看不到
4. nix flake check               # CI 门禁（含格式化检查）
5. nix run .#acer-swift -- switch  # 部署
```

> **快速格式检查：** `nix fmt -- --fail-on-change` 仅检查格式不修改，比 `nix flake check` 快。
> **单文件格式化：** `nixfmt <file>` 直接格式化单个 `.nix` 文件，无需 flake 评估。

### 常见陷阱

- **新建 `.nix` 文件后必须先 `git add`**，再运行 `nix flake check`
- **不要直接编辑 `flake.nix`**——修改 `modules/dendritic.nix` 然后运行 `nix run .#write-flake`
- 新增 flake 输入：在 `dendritic.nix` 的 `flake-file.inputs` 中添加，然后运行 `write-flake`
- 文件名 `_` 前缀的文件不会被 import-tree 导入
- **`nix flake check` 评估时文件必须已被 git 跟踪**，未跟踪的新文件会被忽略

## Den Aspect 类型

- **Static**: 固定配置 `{ nixos = {...}; homeManager = {...}; }`
- **Parametric**: 函数返回配置，如 `(system.hardware.nvidia { nvidiaBusId = "..."; })`
- **Conditional**: 条件启用
- **Forward**: 跨 class 代理

## 关键输入

| 输入 | 用途 |
|------|------|
| `den` | Den 配置框架 |
| `home-manager` | 用户 home 目录管理 |
| `nix-cachyos-kernel` | CachyOS 优化内核 |
| `niri-nix` | niri 滚动窗口管理器 |
| `dms` + `dms-plugin-registry` | DankMaterialShell 桌面 |
| `llm-agents-nix` | AI 编程 agent 包（claude-code, pi, opencode 等） |
| `treefmt-nix` | 代码格式化 |
| `zen-browser` | Zen 浏览器 |
| `daeuniverse` | dae 代理 |
| `noctalia` | Noctalia 桌面环境（备选） |
| `claude-plugins-official` | Claude Code 官方插件集（非 flake） |
| `superpowers` | Claude Code Superpowers 技能库（非 flake） |

## 添加新 Feature

1. 在 `modules/features/<domain>/` 下创建 `<name>.nix`
1. 定义 `den.aspects.<domain>.<name>`（包含 `nixos` 和/或 `homeManager` 属性）
1. 在 `modules/hosts/` 中对应主机/用户的 `includes` 列表里添加引用
1. 如需新 flake 输入，在 `dendritic.nix` 中添加后运行 `nix run .#write-flake`
1. import-tree 自动发现新文件，无需手动注册

## CI

GitHub Actions 在 `ubuntu-latest` 和 `macos-latest` 上运行 `nix flake check`。CI 会创建 `modules/ci-runtime.nix` 设置 `_module.args.CI = true`，可在模块中按条件判断。

## 部署回滚

部署失败时三种回滚方式（详见 [ROLLBACK.md](ROLLBACK.md)）：

```console
# 方式一：切换到上一个 NixOS Generation（最快，< 1 分钟）
sudo nix-env --list-generations -p /nix/var/nix/profiles/system
sudo nix-env --switch-generation <N> -p /nix/var/nix/profiles/system
sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch

# 方式二：Git revert + 重建（< 5 分钟）
git revert HEAD --no-edit
sudo nixos-rebuild switch --flake .#acer-swift

# 方式三：systemd-boot 引导菜单选择上一个 generation（需重启）
```

## Claude Code 自身配置

本项目通过 `den.aspects.dev.editors.claude-code` aspect 管理 Claude Code 的声明式配置（`modules/features/dev/editors/claude-code.nix`），包括：

- 权限白名单/黑名单
- MCP 服务器（nixos）
- LSP 服务器（nil）
- 包来源：`llm-agents-nix` 输入
- 插件：claude-md-management、code-simplifier、code-review、skill-creator、superpowers
- 插件市场：claude-plugins-official
- `cc-switch-cli` 切换 CLI 版本
- `cc-ds` DeepSeek 一键启动（通过 `ANTHROPIC_BASE_URL` 指向 DeepSeek API）

修改该文件后走标准工作流：格式化 → git add → flake check → 部署。

## 参考

- [AGENTS.md](AGENTS.md) — Den 框架详细文档、Pi agent 工具链、技能列表
- [AGENTS_PROJECT.md](AGENTS_PROJECT.md) — 主机/用户/模块完整清单
- [docs/den/](docs/den/) — Den 框架中文文档
- [ROLLBACK.md](ROLLBACK.md) — 部署回滚步骤
