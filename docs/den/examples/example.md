# example 模板

**跨平台示例模板** — 展示 Den 在 NixOS + nix-darwin（macOS）上的完整用法，是学习 Den 高级功能的最佳教程模板。

## 用途

- 学习 Den 的**跨平台**模式（一个方面同时适用于 NixOS 和 macOS）
- 了解 **namespace**、**policies**、**hasAspect**、**meta.handleWith** 等高级功能
- 作为深度教程而非快速起点（README 指出深入学习应看 `templates/ci`）

## 目录结构

```
templates/example/
├── flake.nix              # 自动生成（flake-file + flake-parts）
├── flake.lock
├── README.md
├── .github/workflows/test.yml
└── modules/
    ├── dendritic.nix       # flake-file 配置
    ├── den.nix             # 实体拓扑（igloo + apple + alice）
    ├── inputs.nix          # 输入声明（含 darwin 输入）
    ├── namespace.nix       # eg 命名空间导出
    ├── nh.nix              # nh 构建
    ├── vm.nix              # VM 工作流
    ├── tests.nix           # 跨平台 CI 测试
    └── aspects/
        ├── defaults.nix    # 全局默认 + 电池
        ├── igloo.nix       # 主机方面（policies.to-alice）
        ├── alice.nix       # 用户方面（policies.to-igloo）
        ├── hasAspect-examples.nix  # hasAspect 示例 + meta.handleWith
        └── eg/             # 命名空间：可复用的方面模块
            ├── autologin.nix
            ├── ci-no-boot.nix
            ├── vm-bootable.nix
            ├── vm.nix
            └── xfce-desktop.nix
```

## Flake 输入

| 输入 | 来源 | 用途 |
|------|------|------|
| `nixpkgs` | nixpkgs-unstable | 包集合 |
| `den` | github:denful/den | Den 框架 |
| `import-tree` | github:vic/import-tree | 递归导入 |
| `flake-parts` | github:hercules-ci/flake-parts | perSystem |
| `flake-file` | github:vic/flake-file | flake.nix 生成 |
| `home-manager` | github:nix-community/home-manager | 用户环境 |
| `darwin` | github:nix-darwin/nix-darwin | macOS 配置 |

## 实体结构

```nix
den.hosts.x86_64-linux.igloo.users.alice    = { };  # NixOS 主机
den.hosts.aarch64-darwin.apple.users.alice  = { };  # macOS 主机
den.homes.x86_64-linux.alice                = { };  # 独立 home-manager
```

- 双平台：`igloo`（NixOS x86_64）+ `apple`（nix-darwin aarch64）
- 共享用户 `alice` 在两个平台上工作
- 独立 home-manager 主机 `alice`

## 关键模式

### 跨平台方面

```nix
# 一个方面同时适用于 NixOS 和 macOS
den.aspects.base = {
  nixos = { ... };    # NixOS 专用
  darwin = { ... };   # macOS 专用
  homeManager = { ... };  # 通用 home-manager
};
```

### 命名空间（Namespace）

`modules/namespace.nix` 将 `eg/` 目录下的方面导出为可复用的 flake 输出：

```nix
den.lib.namespace "eg" [
  inputs.den  # 将 den 自身作为源
  true        # 标志：同时导出为 flake 输出
];
```

其他 flake 可以通过 `inputs.your-flake.denful.eg` 引用这些方面。

### Policy 跨实体提供

**主机→用户**（`igloo.nix`）：

```nix
den.aspects.igloo.policies.to-alice = {
  fire = { host, ... }: den.lib.policy.include {
    inherit host;
    to = "user";
    name = "alice";
  };
};
```

**用户→主机**（`alice.nix`）：

```nix
den.aspects.alice.policies.to-igloo = {
  fire = den.lib.policy.provide {
    to = "host";
    name = "igloo";
  };
};
```

### meta.handleWith 与 hasAspect

`hasAspect-examples.nix` 展示了如何使用 `den.lib.aspects.has-aspect` 进行循环安全的方面存在查询，以及如何使用 `meta.handleWith` 和 `meta.guard` 进行结构性约束。

### CI 测试

`tests.nix` 使用 `lib.systems.flakeExposed` 条件性地检查不同平台：

```nix
# Linux 上只构建 igloo，macOS 上只构建 apple
config.flake.checks = lib.optionalAttrs (system == "x86_64-linux") {
  igloo-builds = ...;
} // lib.optionalAttrs (system == "aarch64-darwin") {
  apple-builds = ...;
};
```

## 展示的功能

| 功能 | 位置 | 说明 |
|------|------|------|
| 跨平台配置 | `den.nix`, `igloo.nix`, `alice.nix` | NixOS + nix-darwin 双平台 |
| 命名空间导出 | `namespace.nix`, `eg/*` | 可复用方面模块 |
| Policy 路由 | `igloo.nix`, `alice.nix` | 跨实体提供 |
| Den 电池 | `defaults.nix` | define-user, hostname, primary-user |
| 参数化方面 | `alice.nix` (cooper/setHost) | 按上下文分发 |
| meta.handleWith | `hasAspect-examples.nix` | 结构性约束 |
| 条件编译 | `eg/ci-no-boot.nix` | CI 环境下禁用 grub |
| VM 工作流 | `vm.nix` | nix run .#vm |
