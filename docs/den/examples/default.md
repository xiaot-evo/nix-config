# default 模板

**标准入门模板** — Den 框架推荐的起始点，集成了 flake-parts、home-manager、VM 工作流和 nh 构建。

## 用途

- 大多数 Den 新用户的推荐起点
- 展示 Den 的核心工作流：实体声明 → 方面定义 → 跨类配置
- 包含了完整的开发循环（VM 测试、部署）

## 目录结构

```
templates/default/
├── flake.nix              # 自动生成（DO-NOT-EDIT，由 flake-file 管理）
├── flake.lock
├── README.md
├── .github/workflows/test.yml
└── modules/
    ├── defaults.nix        # 全局默认（stateVersion、class 配置）
    ├── dendritic.nix       # flake-file + den 配置声明
    ├── hosts.nix           # 实体拓扑（hosts/users/homes）
    ├── igloo.nix           # 主机方面（NixOS + provides.to-users）
    ├── tux.nix             # 用户方面（includes + homeManager + provides.to-hosts）
    ├── vm.nix              # VM 开发循环（nix run .#vm）
    └── nh.nix              # nh 部署命令
```

## Flake 输入

| 输入 | 来源 | Follows | 用途 |
|------|------|---------|------|
| `nixpkgs` | nixpkgs-unstable (tarball) | — | 包集合 |
| `den` | github:denful/den | — | Den 框架 |
| `import-tree` | github:vic/import-tree | — | 递归导入 |
| `flake-parts` | github:hercules-ci/flake-parts | nixpkgs-lib → nixpkgs | perSystem |
| `home-manager` | github:nix-community/home-manager | nixpkgs | 用户环境 |
| `flake-file` | github:vic/flake-file | — | flake.nix 自动生成 |

共 **6 个输入**。

## 实体结构

```nix
den.hosts.x86_64-linux.igloo.users.tux = { };
```

- 单个主机 `igloo`（x86_64-linux），一个用户 `tux`
- 用户使用 `"homeManager"` 类（由 `defaults.nix` 配置）
- 注释展示了 darwin、多用户、`den.homes` 示例

## 关键模式

### includes / provides 模式

**主机方面**（`igloo.nix`）向用户提供默认包：

```nix
den.aspects.igloo = {
  nixos = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.hello ];
  };
  provides.to-users.homeManager = { pkgs, ... }: {
    home.packages = [ pkgs.vim ];
  };
};
```

**用户方面**（`tux.nix`）包含电池，并向主机提供扩展：

```nix
den.aspects.tux = {
  includes = [
    den.batteries.define-user
    den.batteries.primary-user
    den.batteries.user-shell "fish"
  ];
  homeManager = { pkgs, ... }: {
    home.packages = [ pkgs.htop ];
  };
  provides.to-hosts.nixos = {
    # 可在此添加供主机使用的 NixOS 配置
  };
};
```

### VM 开发循环

```nix
nix run .#vm    # 启动 igloo 的 QEMU VM（无需重启测试）
nix run .#vm -- switch  # 构建但不切换
```

由 `modules/vm.nix` 实现，使用 `tty-autologin` 自动登录。

### auto-generated flake.nix

`flake.nix` 由 `flake-file` 自动生成。运行 `nix run .#write-flake` 重新生成。

### CI

`.github/workflows/test.yml` 在 ubuntu-latest 和 macos-latest 上运行 `nix flake check`，并创建 `modules/ci-runtime.nix` 供条件判断。

## 数据流

```
flake.nix (auto-generated)
    │
    └─ inputs.import-tree ./modules
        │
        ├── dendritic.nix      ← flake-file + Den 框架配置
        ├── defaults.nix       ← 全局默认设置
        ├── hosts.nix          ← 实体拓扑
        ├── igloo.nix          ← 主机方面
        │   ├── nixos          → NixOS 系统配置
        │   └── provides.to-users.homeManager → 向用户提供默认包
        ├── tux.nix            ← 用户方面
        │   ├── homeManager    → home-manager 配置
        │   ├── includes       → DM/primary/user-shell 电池
        │   └── provides.to-hosts.nixos → 向主机提供扩展
        ├── vm.nix             ← VM 开发包
        └── nh.nix             ← nh 构建命令
```

## 与其他模板对比

| 特性 | default | minimal | noflake |
|------|---------|---------|---------|
| 推荐用途 | **新用户起点** | 最小配置 | 非 flake 环境 |
| 模块分离 | ✅ 职责分明 | ❌ 单文件 | ✅ |
| VM 开发 | ✅ | ❌ | ❌ |
| 自动生成 flake.nix | ✅ (write-flake) | ❌ 手工 | ❌ 无 flake.nix |
| CI 配置 | ✅ GitHub Actions | ❌ | ❌ |
