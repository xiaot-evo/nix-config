# 内置策略（Built-in Policies）

**源文件**: `modules/policies/`

## 概述

策略是上下文驱动的路由函数。它们在方面管道中触发，发出类型化效果（include、resolve、route）。策略在模式包含（schema includes）中注册，在管道中由策略引擎迭代。

三个策略模块：`core.nix`（核心）、`flake.nix`（flake 输出路由）、`flake-parts.nix`（flakeparts 集成）。

---

## 核心策略

### host-to-users

**文件**: `modules/policies/core.nix`

主机→用户扇出。对每个声明的用户，发出 `resolve.shared { inherit user; }`，如果主机方面有与用户名匹配的子键（非 provides 转发），也发出 `include aspect.<userName>`。

```nix
den.policies.host-to-users = { host, ... }: let
  aspect = host.aspect;
  forwarded = lib.genAttrs (aspect.__providesForwarded or []) (_: true);
  hasChild = name: builtins.isAttrs aspect && aspect ? ${name} && !(forwarded ? ${name});
in
lib.concatMap (user:
  [ (resolve.shared { inherit user; }) ]
  ++ lib.optional (hasChild user.name) (include aspect.${user.name})
) (lib.attrValues host.users);
```

**注册**: `den.schema.host.includes = [ den.policies.host-to-users ]`

这意味着每个主机自动获得主机→用户扇出策略。

---

## flake 策略

### flake-to-systems

**文件**: `modules/policies/flake.nix`

Flake→每系统扇出。对 `den.systems` 中每个系统发出 `resolve.to "flake-system" { inherit system; }`。

```nix
den.policies.flake-to-systems = _:
  map (system: resolve.to "flake-system" { inherit system; }) den.systems;
```

### system-to-os-outputs

Flake 系统→主机 OS 输出。对 `den.hosts.${system}` 中每个主机发出 `resolve.to "host" { inherit host; }` 和 `instantiate host`。

```nix
den.policies.system-to-os-outputs = { system, ... }:
  lib.concatMap (host:
    lib.optionals (host.intoAttr != []) [
      (resolve.to "host" { inherit host; })
      (den.lib.policy.instantiate host)
    ]
  ) (builtins.attrValues (den.hosts.${system} or {}));
```

### system-to-hm-outputs

Flake 系统→家庭管理器输出。与 system-to-os-outputs 类似，但处理 `den.homes`。

```nix
den.policies.system-to-hm-outputs = { system, ... }:
  lib.concatMap (home:
    lib.optionals (home.intoAttr != []) [
      (resolve.to "home" { inherit home; })
      (den.lib.policy.instantiate home)
    ]
  ) (builtins.attrValues (den.homes.${system} or {}));
```

### 输出路由策略（packages-to-flake, apps-to-flake, 等）

每系统输出类路由回 flake：

```nix
den.policies.packages-to-flake = mkOutputPolicy "packages";
den.policies.apps-to-flake = mkOutputPolicy "apps";
den.policies.checks-to-flake = mkOutputPolicy "checks";
den.policies.devShells-to-flake = mkOutputPolicy "devShells";
den.policies.legacyPackages-to-flake = mkOutputPolicy "legacyPackages";
```

`mkOutputPolicy` 使用 `den.lib.policy.route`：

```nix
mkOutputPolicy = output: { system, ... }:
  lib.optional (has-flake-output output) (
    den.lib.policy.route {
      fromClass = output;
      intoClass = "flake";
      path = ["flake" output system];
      adaptArgs = _: { pkgs = inputs.nixpkgs.legacyPackages.${system}; };
    }
  );
```

### 注册

```nix
den.schema.flake.includes = [ den.policies.flake-to-systems ];

den.schema.flake-system.includes = [
  den.policies.system-to-os-outputs
  den.policies.system-to-hm-outputs
] ++ map (output: den.policies."${output}-to-flake") systemOutputs;
```

### 额外类注册

flake 策略自动注册系统输出名作为类：

```nix
den.classes = lib.listToAttrs (map (output: {
  name = output;
  value.description = "Flake ${output} output class";
}) systemOutputs);
```

其中 `systemOutputs` = `["packages" "apps" "checks" "devShells" "legacyPackages"]`。

---

## flake-parts 策略

**文件**: `modules/policies/flake-parts.nix`

### system-to-flake-parts

将 flake system 路由到 flake-parts 类：

```nix
den.policies.system-to-flake-parts = { system, ... }: [
  (den.lib.policy.resolve.to "flake-parts" {
    flake-parts = {
      name = "flake-parts-${system}";
      aspect = {};
    };
  })
];
```

### packages-to-flake-parts

将 packages 输出路由到 flake-parts 范围：

```nix
den.policies.packages-to-flake-parts = _: [
  (den.lib.policy.route {
    fromClass = "packages";
    intoClass = "flake-parts";
    collectSubtree = true;
    path = ["packages"];
    adaptArgs = { config, ... }: config.allModuleArgs;
  })
];
```

### 注册与条件

```nix
# 仅当 inputs.flake-parts 可用时激活
lib.mkIf (inputs ? flake-parts) {
  den.schema.flake-parts.isEntity = true;
}
```

---

## 完整策略执行链

```
den.schema.flake.includes → flake-to-systems
  → den.schema.flake-system.includes
    → system-to-os-outputs → den.schema.host.includes
      → host-to-users → den.schema.user.includes
        → user 级策略...
    → system-to-hm-outputs → den.schema.home.includes
    → packages-to-flake (per output)
```

---

## 关联

- **`modules/options.nix`**: `den.policies`、`den.classes` 选项声明
- **`nix/nixModule/policies.nix`**: `den.policies` 选项类型
- **`modules/aspects/batteries/`**: 电池也定义策略（如 `flake-scope.nix`）
- **`modules/outputs.nix`**: 输出生成（消费策略结果）
- **`lib/policy-effects.nix`**: 策略效果原语（`resolve`、`include`、`route` 等）
