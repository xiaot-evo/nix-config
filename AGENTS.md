# AGENTS.md — Nix flake

本项目的 **单一起源** 参考文档。Pi agent 在任务中应随时查阅此文件获取项目结构、构建命令和约定。

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
├── AGENTS.md              # 本文件
├── AGENTS_PROJECT.md      # 项目专属信息（主机、用户、功能）
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
| `zen-browser` | `0xc000022070/zen-browser-flake` | nixpkgs, home-manager | 浏览器 |

---

## 新建 feature 模块

1. 在 `modules/features/` 下创建 `<domain>/<name>.nix`
2. 定义 `den.aspects.<domain>.<name>`（`{ nixos = ...; }` 或 `{ homeManager = ...; }`）
3. 在 `modules/hosts/` 中对应主机/用户的 `includes` 里添加
4. 如需新输入则运行 `nix run .#write-flake`
5. `import-tree` 自动发现新 `.nix` 文件

---

## MCP 工具

| MCP 工具 | 用途 |
|---|---|
| `nixos_nix` | 查询 NixOS/HM/Darwin/Den 包、选项、文档（支持 `action: info/search/browse`） |
| `nixos_nix_versions` | 获取包版本历史 |

MCP 数据源（`source` 参数）：`nixos`、`home-manager`、`darwin`、`flakes`、`den`、`nixvim`、`noogle`、`nixhub`、`wiki`。

---

## Superpowers Skills

项目使用 **superpowers**（`github:obra/superpowers`）技能系统。Pi agent 应主动调用合适的技能：

| 技能 | 何时使用 |
|---|---|
| `brainstorming` | 任何创造性工作前 — 功能、改动、新模块。**始终从这里开始** |
| `writing-plans` | brainstorming 完成后创建实施计划 |
| `systematic-debugging` | 遇到 bug、测试失败或意外行为时 |
| `requesting-code-review` | 工作完成后、合并前 |
| `verification-before-completion` | 声明完成前 — 运行验证 |
| `dispatching-parallel-agents` | 遇到 2+ 无共享状态的独立任务 |
| `subagent-driven-development` | 执行实施计划时含独立子任务 |
| `finishing-a-development-branch` | 实现完成后决定合并/PR/清理 |

### 标准工作流

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

---

## 注意事项

- **CI**: `nix flake check` 是门禁。会设置 `_module.args.CI = true`。
- **git add**: 新建/删除 `.nix` 文件后必须先 `git add`，否则 flake 评估看不到变更。
- **import-tree**: `_` 前缀的 `.nix` 文件会被跳过；`dir/dir.nix` 的 aspect 名称为 `dir`（去重）。
- **插件**: 添加 pi npm 包时检查功能重叠，确认是否需要系统二进制依赖。
