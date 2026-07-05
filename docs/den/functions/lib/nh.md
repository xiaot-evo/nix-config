# nh 模块

**源文件**: `nix/lib/nh.nix`

## 概述

nh 工具集成。提供基于 nh 的构建/部署/切换应用的生成函数，自动为所有已注册的主机和家庭创建命令。

______________________________________________________________________

## den.lib.nh.denPackages

**签名**: `(args: attrset, pkgs: pkgs) → attrset`

### 用途

创建 nh-based apps 的 attrset，包含所有主机和家庭的应用。适用于 `flake.nix` 中的 `packages` 输出。

### 参数说明

- `args: attrset` — 配置：
  - `outPrefix: [string]（可选）` — 输出属性前缀
  - `fromFlake: bool（可选）` — 是否从 flake 引用（默认 `true`）
  - `fromPath: string（可选）` — flake 路径（默认 `"."`）
  - `defaultAction: string（可选）` — 默认动作（默认 `"build"`）
  - `defaultArgs: [string]（可选）` — 默认参数
- `pkgs: pkgs` — nixpkgs 集合

### 返回值说明

`{ <app-name> = <package>; ... }` 格式的 attrset。

### 使用示例

```nix
{
  packages.x86_64-linux = den.lib.nh.denPackages { } pkgs;
  # → {
  #   igloo = <writeShellApplication>;
  #   tux-hm = <writeShellApplication>;
  #   ...
  # }
}
```

______________________________________________________________________

## den.lib.nh.denShell

**签名**: `(args: attrset, pkgs: pkgs) → derivation`

### 用途

创建包含 nh 和所有主机/家庭应用的 dev shell。

### 参数说明

与 `denPackages` 相同。

### 返回值说明

一个 `mkShell` derivation，包含 `pkgs.nh` 和所有主机/家庭应用。

### 使用示例

```nix
{
  devShells.x86_64-linux.default = den.lib.nh.denShell { } pkgs;
}
```

______________________________________________________________________

## den.lib.nh.hostApps

**签名**: `(args: attrset, pkgs: pkgs) → [package]`

### 用途

仅生成主机级别的 nh apps。

### 返回值说明

主机应用列表。

### 使用示例

```nix
den.lib.nh.hostApps { } pkgs
```

______________________________________________________________________

## den.lib.nh.homeApps

**签名**: `(args: attrset, pkgs: pkgs) → [package]`

### 用途

仅生成家庭（home-manager）级别的 nh apps。

### 返回值说明

家庭应用列表。

### 使用示例

```nix
den.lib.nh.homeApps { } pkgs
```

______________________________________________________________________

## 实现简析

### 内部辅助：`mkApp`

`mkApp` 根据主机类（`nixos`/`darwin`）生成不同的 nh 命令：

| 主机类 | nh 命令 |
|---|---|
| `nixos` | `nh os` |
| `darwin` | `nh darwin` |
| home | `nh home -c <name>` |

生成的 shell 脚本支持自定义动作：

```bash
nh <command> <action> <flake-path>#<attr> [args...]
```

默认动作是 `build`，用户可以通过第一个参数覆盖：

```bash
# 构建
nix run .#igloo

# 切换（部署）
nix run .#igloo switch
```

______________________________________________________________________

## 关联函数

- `den.hosts` / `den.homes` — 提供主机和家庭列表
- `modules/features/nh.nix` — 在模块系统中使用 nh
