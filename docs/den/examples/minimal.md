# minimal 模板

**最简 Den 配置** — 仅 3 个依赖，手工编写 flake.nix，无 flake-parts、无 home-manager。

## 用途

- 从零搭建 Den 的最小起点
- 理解 Den 核心机制（aspect、entity、class）的最低要求
- 适合不需要 flake-parts、home-manager 的场景

## 目录结构

```
templates/minimal/
├── flake.nix              # 入口（evalModules + import-tree，手工编写）
├── flake.lock
├── README.md
└── modules/
    ├── den.nix             # 全部配置（Den 导入、实体、方面）
    └── nh.nix              # nh 构建命令
```

## Flake 输入

| 输入 | 来源 | 用途 |
|------|------|------|
| `nixpkgs` | nixpkgs-unstable (tarball) | 包集合 |
| `den` | github:denful/den | Den 框架 |
| `import-tree` | github:vic/import-tree | 递归模块导入 |

共 **3 个输入**——Den 生态中最少的。

## 实体结构

```nix
den.hosts.x86_64-linux.igloo.users.tux = {
  classes = [ "user" ];   # 注意：不是 "homeManager"
};
```

- 单个主机 `igloo`，一个用户 `tux`
- 用户使用 **`"user"` 类**（裸 NixOS 用户，无 home-manager）
- **无** `den.homes` 声明

## 关键模式

### evalModules 入口

```nix
outputs = inputs:
  (inputs.nixpkgs.lib.evalModules {
    modules = [ (inputs.import-tree ./modules) ];
    specialArgs = { inherit inputs; };
  }).config.flake;
```

直接使用 `nixpkgs.lib.evalModules`，无需经过 flake-parts。

### 单一配置模块

所有配置集中在 `modules/den.nix` 一个文件中：

```nix
{ inputs, den, ... }:
{
  imports = [ inputs.den.flakeModule ];

  den.hosts.x86_64-linux.igloo.users.tux = { classes = [ "user" ]; };
  den.aspects.igloo = { nixos = { ... }; };
  den.aspects.tux = { includes = [ den.batteries.primary-user ]; ... };
}
```

### nh 构建

```nix
flake.packages = lib.genAttrs lib.systems.flakeExposed (system:
  den.lib.nh.denPackages { fromFlake = true; } inputs.nixpkgs.legacyPackages.${system}
);
```

支持 `nix run .#igloo` 和 `nix run .#igloo -- switch`。

## 与其他模板对比

| 特性 | minimal | default | noflake |
|------|---------|---------|---------|
| flake-parts | ❌ | ✅ | ❌ |
| home-manager | ❌ | ✅ | ❌ (nix-maid/hjem) |
| flake.nix 生成 | 手工 | 自动 (write-flake) | 无 flake.nix |
| 用户类 | `"user"` | `"homeManager"` | `"maid"` / `"hjem"` |
| VM 工作流 | ❌ | ✅ | ❌ |
| 输入数 | **3** | 6 | 7 (npins) |
| 文件数 | 4 | 9 | 5 |
