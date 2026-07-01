# diagram-demo 模板

**可视化诊断** — 展示 Den 的管道捕捉（Capture）和 den-diagram 的渲染两步式诊断管线。生成 Mermaid、PlantUML、DOT 等多种格式的方面解析图。

## 用途

- 可视化主机/用户的方面解析树和提供者关系
- 调试复杂的方面依赖和约束
- 作为 fleet 级可视化的参考实现

## 目录结构

```
templates/diagram-demo/
├── flake.nix              # 入口（flake-parts + import-tree）
├── flake.lock
└── modules/
    ├── diagrams.nix        # 捕捉 + den-diagram 渲染编排（487 行）
    ├── flake-parts.nix     # flake-parts 系统
    └── aspects/
        ├── defaults.nix    # 全局默认
        ├── den.nix         # 实体拓扑
        ├── hosts/          # 主机方面
        │   ├── laptop.nix      # laptop → workstation
        │   ├── devbox.nix      # devbox → 双角色（workstation + server）
        │   └── server.nix      # server → relay + 约束
        ├── users/          # 用户方面
        │   ├── alice.nix       # home 角色、hyprland、跨实体提供
        │   ├── bob.nix         # gnome、dev-tools
        │   └── deploy.nix      # 部署系统用户
        ├── roles/          # 角色组合
        │   ├── workstation.nix
        │   ├── server.nix
        │   └── relay.nix   # relay = server + mail
        └── features/       # 功能模块
            ├── desktop.nix, demo-shell.nix, dev-tools.nix
            ├── greeters.nix (regreet, gdm, sddm)
            ├── gnome.nix, hyprland.nix
            ├── mail.nix (parametric), backup.nix (parametric)
            ├── networking.nix, tailscale.nix
            ├── monitoring.nix (含子提供者)
            └── virtualization.nix (docker/podman)
```

## Flake 输入

| 输入 | 来源 | 用途 |
|------|------|------|
| `den` | path:../.. | Den 框架（本地） |
| `den-diagram` | github:denful/den-diagram | 渲染库 |
| `import-tree` | github:vic/import-tree | 递归导入 |
| `flake-parts` | github:hercules-ci/flake-parts | perSystem |
| `nixpkgs` | nixpkgs-unstable (tarball) | 包集合 |
| `home-manager` | github:nix-community/home-manager | 用户环境 |
| `files` | github:mightyiam/files | 文件处理 |

## 实体结构

```nix
den.hosts.x86_64-linux = {
  laptop .users.alice    = { };
  server .users.deploy   = { };
  devbox .users.alice    = { };
         .users.bob      = { };
};
den.homes.x86_64-linux.alice = { };
```

三主机（laptop、server、devbox）、三用户（alice、bob、deploy）、一 home（alice）。

## 诊断管线

### 两步式架构

**Step 1：捕捉**（Den 框架内，`diagrams.nix`）

```nix
fleetCapture = den.lib.capture.captureFleet { };
```

完整运行 FX 管道（resolve → compile → gate → classify → emit），附带追踪处理器，生成内部表示。

**Step 2：投影 + 渲染**（den-diagram 库）

```nix
diagram = inputs.den-diagram.lib;
mkHostEntity = host: diagram.projectScope {
  inherit fleetCapture;
  kind = "host";
  name = host.name;
};
```

`projectScope` 从 fleet 捕捉中切出单个实体的图 IR（有向无环图），然后通过 `entityEntries` 生成 Mermaid 源文件，再由 patched mermaid-cli 渲染为 SVG。

### 输出

```
nix run .#write-diagrams    # 写入源代码树
```

```
diagrams/
├── hosts/<host>/           # 每主机 17+ 视图
├── hosts/<host>/users/<user>/  # 每用户视图
├── homes/<safeName>/       # home 视图
└── fleet/                  # 7 个 fleet 级视图
```

### 视图类型

| 视图 | 描述 |
|------|------|
| `dag` | 有向无环图（完整方面树） |
| `aspects` | 方面分类视图 |
| `simple` | 简化视图 |
| `ctx` | 上下文绑定关系 |
| `scope-seq` | 作用域序列 |
| `scope-edges` | 作用域边界 |
| `providers` | 提供者关系 |
| `decisions` | 管道决策 |
| `class-*` | 按类分离的视图 |
| `diff-classes` | 跨类差异 |
| `c4component` | C4 组件图 |

## 方面分类

本模板展示了**所有四种方面形态**：

| 形态 | 示例 | 说明 |
|------|------|------|
| **静态** | `tailscale`、`networking` | 简单 attrset |
| **参数化** | `mail`、`backup` | 接收 `host` 上下文 |
| **前置** | `virtualization.provides.docker` | 通过 provides 代理 |
| **条件** | （可用但未使用） | meta.guard |

### 角色组合

```
laptop → workstation → networking + tailscale + desktop + podman
server → relay → server + mail → networking + monitoring + tailscale + backup
devbox → workstation + server（双角色）
```

### 约束类型

- `exclude`：排除单个方面
- `filterBy`：按前缀过滤多个方面
- `substitute`：替换方面（regreet → gdm）

### 子提供者模式

```nix
den.aspects.monitoring = {
  nixos.services.prometheus.enable = true;
  provides.node-exporter.nixos... = ...;
  provides.nginx-exporter.nixos... = ...;
  provides.alerting.nixos... = ...;
};
```

主机可以选择包含哪些子提供者，约束可以剪枝不需要的。
