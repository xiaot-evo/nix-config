# flake-parts-modules 模板

**转发类（Forward Class）示例** — 展示如何将 Den 的面向配置与第三方 flake-parts 模块（treefmt、devshell、nix-unit 等）桥接，统一在方面系统中管理 perSystem 输出。

## 用途

- 在 Den 中集成 **devshell**、**treefmt-nix**、**nix-unit** 等 perSystem 工具
- 所有配置统一到 Den 的方面系统，无需在 perSystem 中额外编写
- 理解 Den 的**转发机制**（Forward Class / Policy Route）

## 目录结构

```
templates/flake-parts-modules/
├── flake.nix              # 入口（flake-parts + import-tree）
├── flake.lock
├── README.md
├── packages/
│   └── hola.nix           # 自定义包
└── modules/
    ├── den.nix            # Den 配置（实体、转发策略）
    ├── pkgs-by-name.nix   # 包注册
    ├── perSystem-from-hosts.nix  # 主机→perSystem 桥
    └── classes/
        ├── treefmt.nix    # treefmt-nix 集成
        ├── packages.nix   # 包输出集成
        ├── nix-unit.nix   # nix-unit 测试集成
        ├── files.nix      # files 集成
        └── devshell.nix   # devshell 集成
```

## Flake 输入

| 输入 | 来源 | 集成类 |
|------|------|--------|
| `nixpkgs` | github:nixos/nixpkgs/nixpkgs-unstable | — |
| `den` | github:denful/den | — |
| `import-tree` | github:vic/import-tree | — |
| `flake-parts` | github:hercules-ci/flake-parts | — |
| `treefmt-nix` | github:numtide/treefmt-nix | `treefmt` |
| `devshell` | github:numtide/devshell | `devshell` |
| `nix-unit` | github:nix-community/nix-unit | `tests` |
| `files` | github:mightyiam/files | `files` |
| `pkgs-by-name-for-flake-parts` | github:drupol/pkgs-by-name-for-flake-parts | `packages` |

## 转发类机制

### 核心模式

每个 `modules/classes/*.nix` 文件都执行以下步骤：

1. **注册新类**：`den.classes.<name> = { };`
1. **导入 flake-parts 模块**：`imports = [ inputs.<module>.flakeModule ];`
1. **定义路由策略**：`den.policies.<name>-to-flake-parts` 使用 `den.lib.policy.route`
1. **激活策略**：`den.schema.flake-parts.includes = [ den.policies.<name>-to-flake-parts ];`

### route 原语

```nix
den.lib.policy.route {
  fromClass = "treefmt";          # 读取哪个类的配置
  intoClass = "flake-parts";       # 注入到哪个类
  path = [ "treefmt" ];           # 注入到 perSystem 的路径
  adaptArgs = { config, ... }: config.allModuleArgs;
};
```

### 用户侧使用

在方面中直接写类键，配置自动路由到 perSystem：

```nix
den.aspects.myProject = {
  # 这些键会路由到 perSystem.treefmt.config.programs.*
  treefmt.programs.nixfmt.enable = true;

  # 这些键会路由到 perSystem.devshells.default.*
  devshell.commands = [ { package = "cowsay"; } ];

  # 这些键会路由到 perSystem.packages.*
  packages = { inherit (pkgs) htop; };

  # 这些键会路由到 perSystem.nix-unit.tests.*
  tests.test-math-works = { expr = 22 * 2; expected = 44; };
};
```

### 数据流

```
方面中的类键
  │ treefmt、devshell、packages、files、tests
  ▼
Den 管道 → 分类器 → 按类收集
  │
  ▼
策略路由（from <custom-class> → into "flake-parts"）
  │ path + adaptArgs 变换
  ▼
perSystem 输出
  │ perSystem.treefmt、perSystem.devshells.default、...
  ▼
实际 flake 输出
```

### 集成模块一览

| 类 | 输入 | 输出路径 |
|----|------|----------|
| `treefmt` | treefmt-nix | `perSystem.treefmt` |
| `devshell` | devshell | `perSystem.devshells.default` |
| `packages` | pkgs-by-name-for-flake-parts | `perSystem.packages` |
| `files` | files | `perSystem.files.*` |
| `tests` | nix-unit | `perSystem.nix-unit.tests` |

## 两个作用域桥接

本模板还展示了两个作用域的桥接：

- **flake-system 作用域**（行 107-111 of `den.nix`）：策略 `system-to-flake-parts` 将 flake-level 系统配置桥接到 flake-parts
- **flake-parts 作用域**（行 42）：直接在方面中读取 flake-parts 类的配置
- **perSystem-from-hosts.nix**：反向桥接——从主机方面读取 flake-parts 内容

## 与其他模板对比

| 特性 | flake-parts-modules | default/example |
|------|--------------------|-----------------|
| 核心关注 | **perSystem 工具集成** | NixOS/HM 系统配置 |
| 自定义类 | ✅ 5 个转发类 | ❌ |
| flake-parts 模块 | ✅ 深度集成 | ✅ 基础使用 |
| 主机方面 | 部分 | 完整 |
| 适用场景 | 开发工具链配置 | 系统配置 |
