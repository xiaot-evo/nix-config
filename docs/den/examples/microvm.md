# microvm 模板

**MicroVM 集成** — 展示如何使用 Den 的管道管理 MicroVM（微型虚拟机），包括独立可运行 VM 和主机托管式 VM 两种模式。

## 用途

- 在 Den 中运行 MicroVM（基于 `github:microvm-nix/microvm.nix`）
- 学习独立的管道策略链（`host → microvm-host → microvm-guest`）
- 理解 Den 的隔离解析（`intoAttr`、自定义类、`den.lib.aspects.resolve`）

## 目录结构

```
templates/microvm/
├── .gitignore
├── flake.nix              # 入口（evalModules + import-tree）
├── flake.lock
├── README.md
└── modules/
    ├── den.nix                      # Den 实体声明 + 包注册
    ├── microvm-integration.nix      # 核心：Den↔MicroVM 集成层
    ├── microvm-runners.nix          # 可运行包暴露器
    ├── runnable-example.nix         # 模式 A：独立可运行 VM
    └── guests-example.nix           # 模式 B：主机托管式 VM
```

## Flake 输入

| 输入 | 来源 | 用途 |
|------|------|------|
| `nixpkgs` | github:nixos/nixpkgs/nixpkgs-unstable | 包集合 |
| `den` | github:denful/den | Den 框架 |
| `import-tree` | github:vic/import-tree | 递归导入 |
| `microvm` | github:microvm-nix/microvm.nix | MicroVM 框架 |

## 两种模式

### 模式 A：独立可运行 VM

```nix
den.hosts.x86_64-linux.runnable-microvm = {
  intoAttr = [ "microvms" "runnable-microvm" ];
};
```

- 普通 NixOS 配置 + `inputs.microvm.nixosModules.microvm`
- `intoAttr` 将输出放在 `flake.microvms` 下（而非 `nixosConfigurations`）
- `nix run .#runnable-microvm` 直接启动 QEMU VM

### 模式 B：主机托管式 VM

```nix
den.hosts.x86_64-linux.server.microvm.guests = [
  den.hosts.x86_64-linux.guest-microvm
];
den.hosts.x86_64-linux.guest-microvm = {
  intoAttr = [ ];  # 不产生 flake 输出
};
```

Guest VM 的配置被解析并注入到主机的 `microvm.vms.<name>` 下。

## 核心集成层

### 自定义类

```nix
den.classes.microvm.description = "MicroVM guest configuration";
```

将 guest 配置分为两个桶：`nixos`（guest 自己的 OS 配置）和 `microvm`（元数据如 autostart）。

### 策略链

```
host (server)
  │
  ├── Policy: host-to-microvm-host
  │     resolve → "microvm-host" scope
  │     include → microvm 主机模块
  │
  ├── Policy: microvm-host-to-microvm-guest
  │     每 guest → "microvm-guest" scope
  │
  └── Policy: microvm-guest-resolve-vm
        隔离解析 → provide 到 host.microvm.vms
```

### 隔离解析

```nix
# 在隔离管道中解析 guest，不污染主机的 NixOS 配置
vmResolved = den.lib.aspects.resolve vm.class (den.lib.resolveEntity "host" { host = vm; });
microvmResolved = den.lib.aspects.resolve "microvm" vm.aspect;

# 将结果注入主机配置
policy.provide {
  path = [ "microvm" "vms" vm.name ];
  config = vmResolved // microvmResolved;
};
```

## 实体结构

```nix
# 模式 A
den.hosts.x86_64-linux.runnable-microvm  # → flake.microvms.*

# 模式 B
den.hosts.x86_64-linux.server            # 宿主机
  └── microvm.guests = [ den.hosts.x86_64-linux.guest-microvm ]
        └── guest-microvm (intoAttr = [])
              ├── nixos class → server.microvm.vms.<name>.config
              └── microvm class → server.microvm.vms.<name>
```

## 关键模式

1. **`intoAttr = []`**：guest VM 不产生任何 flake 输出，仅作为路由配置存在于宿主机内
1. **三层策略链**：`host → microvm-host → microvm-guest`，每层增加解析深度
1. **隔离解析**：guest 在独立管道中解析，防止模块泄漏
1. **跨实体提供**：resolved config 通过 `policy.provide` 注入宿主机
1. **自定义类**：`microvm` 类将 guest 元数据与 OS 配置分离

## 与其他模板对比

| 特性 | microvm | terranix-demo |
|------|---------|--------------|
| 自定义类 | `microvm` | `terranix` |
| 策略数量 | 3 | 1 |
| 策略用途 | scope 链 | 实例化 |
| 隔离解析 | ✅ `den.lib.aspects.resolve` | ❌ 管道自动 |
| 外部工具 | microvm.nix | terranix |
| 构建产物 | QEMU VM | Terraform JSON |
