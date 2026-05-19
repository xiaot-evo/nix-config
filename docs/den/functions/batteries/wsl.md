# den.batteries.wsl

**源文件**: `modules/aspects/batteries/wsl.nix`

## 用途

为 NixOS 主机启用 WSL（Windows Subsystem for Linux）支持。集成了 [NixOS-WSL](https://github.com/nix-community/NixOS-WSL) 项目，提供完整的 WSL 配置体验。

该电池注册：

| 注册项 | 说明 |
|---|---|
| `wsl` 类 | WSL 配置类，转发到主机 OS |
| `host-to-wsl-host` 策略 | 主机具有 wsl 功能时的自动解析 |
| `wsl-host-aspect` 方面 | 加载 WSL 模块并启用 wsl |
| `wsl-to-host` 策略 | 将 `wsl` 类内容路由到目标类 |

## 参数

电池本身无参数，但需要在 `den.hosts.<name>` 中配置：

| 主机选项 | 类型 | 默认值 | 说明 |
|---|---|---|---|
| `host.wsl.enable` | `bool` | `false` | 是否启用 WSL |
| `host.wsl.module` | `deferredModule` | `inputs.nixos-wsl.nixosModules.default` | 可自定义 WSL 模块 |

## 使用示例

### 单主机启用

```nix
{
  den.hosts.x86_64-linux.igloo = {
    hostName = "igloo";
    wsl.enable = true;           # 在此主机上启用 WSL
  };
}
```

### 全局启用（仅 NixOS 类主机生效）

```nix
{
  # 对所有 NixOS 主机启用 WSL
  den.schema.host.wsl.enable = true;
}
```

### 自定义 WSL 模块

```nix
{
  den.hosts.x86_64-linux.igloo = {
    wsl = {
      enable = true;
      # 使用自定义 fork 的 WSL 模块
      module = my-custom-wsl-package.nixosModules.default;
    };
  };
}
```

### 在 wsl 类中配置 WSL 选项

```nix
{
  den.aspects.igloo = {
    wsl.docker-desktop.enable = true;
    wsl.interop.register = false;
    nixos = { ... };
  };
}
```

## 实现简析

源文件 83 行，是较为复杂的电池之一，包含四个核心注册项。

### 主机选项定义

```nix
hostConf.options.wsl = {
  enable = lib.mkEnableOption "Enable WSL on this host";
  module = lib.mkOption {
    description = "The NixOS-WSL module";
    type = lib.types.deferredModule;
    default = inputs.nixos-wsl.nixosModules.default;
  };
};
```

定义了两个主机级选项：
- `enable`：开关，控制是否加载 WSL 模块
- `module`：可插拔的模块引用，默认使用 `inputs.nixos-wsl` 提供的模块

### `wsl-host-aspect`：WSL 主机方面

```nix
wsl-host-aspect = { host }: {
  name = "wsl/${host.name}";
  inherit description;
  ${host.class} = {
    imports = [ host.wsl.module ];
    wsl.enable = true;
  };
};
```

当启用了 WSL 的主机被解析时，此方面将该主机的 WSL 模块导入，并设置 `wsl.enable = true`。

### `host-to-wsl-host` 策略

```nix
den.policies.host-to-wsl-host = { host, ... }:
  lib.optionals (host.class == "nixos" && (host.wsl or {}).enable or false) [
    (den.lib.policy.resolve.to "wsl-host" { inherit host; })
    (den.lib.policy.include wsl-host-aspect)
  ];
```

守卫条件：
1. `host.class == "nixos"`——WSL 只在 NixOS 上支持
2. `(host.wsl or {}).enable or false`——用户显式启用了 WSL

当条件满足时，触发两个操作：
1. `den.lib.policy.resolve.to "wsl-host"`：解析 `wsl-host-aspect` 方面
2. `den.lib.policy.include wsl-host-aspect`：包含该方面

该策略通过 `den.schema.host.includes` 注册，在主机 schema 层面生效。

### `wsl-to-host` 策略（带 guard）

```nix
den.policies.wsl-to-host = { host, ... }:
  lib.optional ((host.wsl or {}).enable or false) (
    den.lib.policy.route {
      fromClass = "wsl";
      intoClass = host.class;
      path = [ "wsl" ];
      guard = { options, ... }: options ? wsl;
    }
  );
```

关键设计——`guard` 守卫：

```nix
guard = { options, ... }: options ? wsl;
```

这个 guard 确保 **只有在 WSL 模块已经加载**（即 `options` 中出现了 `wsl` 选项时），才执行路由。这防止了在非 WSL 主机上意外引用 WSL 选项导致错误。

`wsl-to-host` 通过 `den.default.includes` 注册，在所有作用域中生效（包括用户作用域）。这使得 `primary-user` 等电池可以在 `wsl` 类中写入 `defaultUser`，并能正确路由到主机。

### 执行流程

```
用户设置:
  den.hosts.x86_64-linux.igloo.wsl.enable = true
                              ↓
  host-to-wsl-host 策略检测到 host.class=="nixos" && wsl.enable==true
                              ↓
  解析 wsl-host-aspect → 导入 NixOS-WSL 模块，设置 wsl.enable=true
                              ↓
  wsl-to-host 策略检测到 options.wsl 存在 → 路由生效
                              ↓
  用户 wsl 类内容被路由到 nixos.wsl.*
```

## 关联电池

| 电池 | 关系 |
|---|---|
| `den.batteries.primary-user` | 在 `wsl` 类中写入 `defaultUser`，通过 `wsl-to-host` 路由 |
| `den.batteries.hostname` | 同样在 `wsl` 类中设置 hostname |
| `den.batteries.os-class` | `os` 类策略也会在 WSL 主机上生效 |
| `den.batteries.forward` | `wsl-to-host` 的 guard 机制与 forward 的 guard 类似 |
