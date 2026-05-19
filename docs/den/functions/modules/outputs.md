# flake 输出生成（Flake Output Generation）

**源文件**: `modules/outputs.nix`、`nix/flakeOutputs.nix`

## 概述

Den 的 flake 输出系统通过方面管道解析配置，生成 `nixosConfigurations`、`homeConfigurations`、`darwinConfigurations` 等 flake 输出。支持 flake-parts 和标准 flake 两种形式。

---

## flake 输出生成

**源文件**: `modules/outputs.nix`

`modules/outputs.nix` 是输出模块的核心。它导入 flake-level 方面，评估 flake 模块，并导出结果。

```nix
{ lib, den, inputs, ... }@args:
let
  # 是否启用 flake-parts
  no-flake-parts = !inputs ? flake-parts;
  has-flake-parts = !no-flake-parts && !(args ? __denTest);

  # 解析 flake 级方面
  flakeModule = den.lib.aspects.resolve "flake"
    (den.lib.resolveEntity "flake" { });
  
  # 评估 flake 模块
  flake = (lib.evalModules {
    modules = [
      flakeModule
      inputs.den.flakeOutputs.flake
    ];
    specialArgs.inputs = inputs;
  }).config.flake;
in {
  imports = lib.optional no-flake-parts inputs.den.flakeOutputs.flake;
  inherit flake;
}
// lib.optionalAttrs has-flake-parts {
  systems = den.systems;
  perSystem = {
    imports = [
      (den.lib.aspects.resolve "flake-parts"
        (den.lib.resolveEntity "flake-parts" { }))
    ];
  };
}
```

### 生成流程

```
1. den.lib.resolveEntity "flake" { }
   → 创建 flake 级方面（含所有主机/家庭的元数据）

2. den.lib.aspects.resolve "flake" flakeRoot
   → 通过方面管道解析 flake 级配置
   → 触发 flake-to-systems → system-to-os-outputs → host-to-users
   → 生成每系统的 flake 模块

3. lib.evalModules { modules = [ flakeModule flakeOutputs ]; }
   → 评估所有 flake 模块
   → 输出到 config.flake

4. flake = config.flake
   → 包含 nixosConfigurations, homeConfigurations 等
```

---

## nixosConfigurations

由 `den.policies.system-to-os-outputs` 策略生成。每个主机触发：

1. `resolve.to "host" { inherit host; }`
2. `den.lib.policy.instantiate host`

`instantiate` 根据 `host.class` 调用对应函数：
- `nixos` → `inputs.nixpkgs.lib.nixosSystem { modules = [ host.mainModule ]; }`
- `darwin` → `inputs.darwin.lib.darwinSystem { modules = [ host.mainModule ]; }`

输出路由由 `host.intoAttr` 控制：

```nix
host.intoAttr = ["nixosConfigurations" "igloo"];
# → flake.nixosConfigurations.igloo = nixosSystem { ... }
```

---

## homeConfigurations

由 `den.policies.system-to-hm-outputs` 策略生成。每个家庭触发：

1. `resolve.to "home" { inherit home; }`
2. `den.lib.policy.instantiate home`

`instantiate` 调用 `inputs.home-manager.lib.homeManagerConfiguration`。

绑定主机的家庭（`user@host`）自动传递 `osConfig`：

```nix
home.intoAttr = ["homeConfigurations" "alice@igloo"];
# → flake.homeConfigurations."alice@igloo" = homeManagerConfiguration { ... }
```

---

## darwinConfigurations

与 nixosConfigurations 共享同一策略。当 `host.class = "darwin"` 时，通过 `instantiate` 使用 `inputs.darwin.lib.darwinSystem`。

```nix
host.intoAttr = ["darwinConfigurations" "my-mac"];
# → flake.darwinConfigurations.my-mac = darwinSystem { ... }
```

---

## 自定义输出路径

通过设置 `host.intoAttr` 或 `home.intoAttr` 可实现自定义输出路径：

```nix
den.hosts."x86_64-linux".igloo = {
  intoAttr = ["customOsConfigs" "igloo"];
  # → flake.customOsConfigs.igloo = nixosSystem { ... }
};
```

`intoAttr` 是一个路径列表，`flake.<path>.<name>` 指向生成的配置。

---

## flake-parts 输出

当 `inputs.flake-parts` 可用时，Den 额外生成 flake-parts 输出：

```nix
// lib.optionalAttrs has-flake-parts {
  systems = den.systems;  # 声明支持的系统
  perSystem = {
    imports = [
      # flake-parts 级方面解析
    ];
  };
}
```

通过 `den.policies.system-to-flake-parts` 和 `den.policies.packages-to-flake-parts` 将 flake 输出路由到 flake-parts 范围。

---

## 自定义输出示例

### 自定义主机类

```nix
den.hosts."x86_64-linux".my-host = {
  class = "nixos";  # 或 "darwin"、"systemManager"
  instantiate = inputs.nixos-unstable.lib.nixosSystem;
  intoAttr = ["nixosConfigurations" "my-host"];
};
```

### 自定义家庭类

```nix
den.homes."x86_64-linux"."bob" = {
  class = "homeManager";
  instantiate = inputs.hm-unstable.lib.homeManagerConfiguration;
  intoAttr = ["homeConfigurations" "bob"];
};
```

---

## 关联

- **`modules/policies/flake.nix`**: 定义所有输出路由策略
- **`lib/entities/host.nix`**: `intoAttr`、`instantiate`、`mainModule` 选项
- **`lib/entities/home.nix`**: `intoAttr`、`instantiate`、`mainModule` 选项
- **`nix/flakeOutputs.nix`**: flake 输出模块实现
- **`modules/options.nix`**: `den.hosts`、`den.homes` 选项
