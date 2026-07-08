# AGENTS.md — Nix flake 配置

> 本文件是所有智能体的通用参考文档。所有交互用中文。

______________________________________________________________________

## 项目概述

基于 [Den](https://den.denful.dev) 框架的 NixOS + home-manager 配置，管理单台物理机 `acer-swift`（AMD + NVIDIA，CachyOS 内核）及用户 `xiaot_evo`。

**关键设计：**

- `flake.nix` **自动生成**，由 `modules/dendritic.nix` 驱动，通过 `nix run .#write-flake` 重新生成
- 配置单元是 **aspect**（`den.aspects.<domain>.<name>`），定义在 `modules/features/` 下
- 主机和用户在 `modules/hosts/` 中通过 `includes` 列表组装所需 aspects
- 新建 `.nix` 文件后必须 `git add`，否则 flake 评估看不到（import-tree 依赖 git 跟踪）

详细主机/用户/模块清单见 [AGENTS_PROJECT.md](AGENTS_PROJECT.md)。

______________________________________________________________________

## Den 框架

### Aspect 类型

| 类型 | 说明 |
| ----------- | -------------------------------------------------------------------- |
| Static | 固定配置 `{ nixos = {...}; homeManager = {...}; }` |
| Parametric | 函数返回配置，如 `(system.hardware.nvidia { nvidiaBusId = "..."; })` |
| Forward | 跨 class 代理 |
| Conditional | 条件启用 |

**命名约定：** 文件路径即 aspect 名（点号分隔）— `features/desktop/wm/niri.nix` → `den.aspects.desktop.wm.niri`

### includes / provides 双向通信

```
host (nixos) ──includes──→ hardware, boot, nix, sound
  └──provides.to-users.homeManager──→ 全局包

user (homeManager) ──includes──→ dev, desktop, apps...
  └──provides.to-hosts.nixos──→ NixOS 扩展设置
```

### 新建 Feature Aspect

1. 在 `modules/features/<domain>/` 下创建 `<name>.nix`
1. 定义 `den.aspects.<domain>.<name>`（含 `nixos` 和/或 `homeManager` 属性）
1. 在 `modules/hosts/` 对应主机/用户的 `includes` 中添加引用
1. 如需新 flake 输入，修改 `dendritic.nix` 后运行 `nix run .#write-flake`
1. import-tree 自动发现新文件，无需手动注册

______________________________________________________________________

## 项目结构

```
├── flake.nix              # 自动生成 — 勿手动编辑
├── AGENTS.md              # 本文件
├── AGENTS_PROJECT.md      # 主机/用户/模块详情
├── docs/den/              # Den 框架中文文档
└── modules/
    ├── defaults.nix       # 全局默认值（stateVersion, strict schema）
    ├── dendritic.nix      # flake 输入声明 + flake-file 配置
    ├── treefmt.nix        # 多语言格式化（nixfmt + jsonfmt + mdformat + yamlfmt）
    ├── hosts/             # 主机和用户定义（aspect 组装点）
    └── features/          # 可复用 aspect 模块（按领域分目录）
```

**import-tree 规则：** 递归导入 `modules/` 下所有 `.nix` 文件；`_` 前缀文件跳过；`dir/dir.nix` 的 aspect 名为 `dir`（去重）。

______________________________________________________________________

## 常用命令

### 构建与部署

| 命令 | 用途 |
| ---------------------------- | --------------------------------------- |
| `nix run .#<host>` | 构建（不部署） |
| `nix run .#<host> -- switch` | 构建并部署 |
| `nix run .#write-flake` | 修改 dendritic.nix 后重新生成 flake.nix |

### 格式化与检查

| 命令 | 用途 |
| ----------------------------- | -------------------------------------- |
| `nix fmt` | 格式化所有文件（.nix .json .md .yaml） |
| `nix fmt -- --fail-on-change` | 仅检查格式，不修改（CI 模式） |
| `nix flake check` | CI 门禁（含格式检查），修改后必须通过 |

### 快速验证（不用完整构建）

```console
nix-instantiate --parse <file>      # 仅语法检查
nix fmt -- --fail-on-change         # 格式检查（比 flake check 快）
nix flake check --no-build          # 只评估不构建
```

### 包搜索

智能体在查找 nixpkgs 包时**必须使用 nh search 验证包是否存在**，不要凭记忆猜测包名和版本。

三个专用搜索技能覆盖不同场景：

| 技能 | 用途 |
| ---------------------- | --------------------------------------------- |
| `nix-package-search` | 关键词模糊搜索 nixpkgs 包，发现正确的 attr path |
| `nix-package-info` | 查看已知包的详细元数据（版本、license、平台等） |
| `nix-option-search` | 搜索 NixOS/home-manager 配置选项（非包搜索） |

**快速命令（当技能脚本需直接调用时）：**

| 命令 | 用途 |
| ------------------------------------------------------------------------- | ------------------------- |
| `.claude/skills/nix-package-search/scripts/nix-pkg-search <关键词>` | 精炼包搜索（AI 友好输出） |
| `.claude/skills/nix-package-info/scripts/nix-pkg-info <attr-path>` | 包详情查询 |
| `.claude/skills/nix-package-info/scripts/nix-pkg-info --compare <pkg>` | 跨 channel 版本对比 |
| `.claude/skills/nix-option-search/scripts/nix-opt-lookup <option-path>` | 本地 option 查询 |
| `nh search --channel nixos-24.11 <关键词>` | 指定 stable channel |

> 三个技能详情见 `.claude/skills/nix-package-search/SKILL.md`、`nix-package-info/SKILL.md`、`nix-option-search/SKILL.md`。

### 其他

| 命令 | 用途 |
| --------------------------------------- | ------------------------ |
| `nix flake update den` | 更新 Den 框架 |
| `nixfmt <file>` | 单文件快速格式化 |
| `nh os info` | 查看系统 generation 历史 |
| `nh clean all --keep 5 --keep-since 7d` | 清理旧 generation |

devenv shell 内还提供快捷别名：`flake-write`, `fmt`, `fmt-check`, `check`, `build`, `build-switch`（定义见 `devenv.nix`）。

______________________________________________________________________

## Nix 工作流

```
1. 编辑文件
2. nix fmt                       # 格式化
3. git add <file>                # 新建/删除后必做
4. nix flake check               # CI 门禁
5. nix run .#<host> -- switch    # 部署
```

### 常见陷阱

| 场景 | 正确做法 |
| --------------------- | ---------------------------------------------------------------- |
| 新建/删除 `.nix` 文件 | 先 `git add`，再 `nix flake check` |
| 修改 `dendritic.nix` | 运行 `nix run .#write-flake` |
| 新增 flake 输入 | 在 `dendritic.nix` 的 `flake-file.inputs` 中添加 → `write-flake` |
| 直接编辑 `flake.nix` | **禁止** — 修改 dendritic.nix 后运行 write-flake |

______________________________________________________________________

## 关键 flake 输入

| 输入 | 用途 |
| ----------------------------- | ---------------------- |
| `den` | Den 配置框架 |
| `home-manager` | 用户 home 目录管理 |
| `nix-cachyos-kernel` | CachyOS 优化内核 |
| `niri-nix` | niri 滚动窗口管理器 |
| `dms` + `dms-plugin-registry` | DankMaterialShell 桌面 |
| `treefmt-nix` | 代码格式化 |
| `zen-browser` | Zen 浏览器 |
| `daeuniverse` | dae 代理 |

二进制缓存配置见 `modules/dendritic.nix`。

______________________________________________________________________

## CI

- **GitHub Actions** 在 `ubuntu-latest` / `macos-latest` 上跑 `nix flake check`，CI 下 `_module.args.CI = true`

______________________________________________________________________

## 参考

- [AGENTS_PROJECT.md](AGENTS_PROJECT.md) — 主机/用户/模块完整清单
- [docs/den/](docs/den/) — Den 框架中文文档
- [ROLLBACK.md](ROLLBACK.md) — 部署回滚步骤
- <https://den.denful.dev> — Den 框架官网
