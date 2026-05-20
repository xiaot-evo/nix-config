# den.batteries.mutual-provider

**源文件**: `modules/compat/mutual-provider-shim.nix`

## 用途

**惰性兼容垫片（inert compat shim）** — 跨实体路由（`to-users`、`to-hosts`、命名目标）已内置到 `emitAspectPolicies` 中。此电池保留下仅为避免已有配置中引用了 `den.batteries.mutual-provider` 的配置出错。

关键行为：
- 求值后产生一个不产生任何效果的惰性方面
- 不需要显式启用（包含它等于什么都没做）
- 真正实现双向配置提供的方式：直接使用 `den.lib.policy.include` 在策略中定义

## 使用示例

### 用户向主机提供配置（当前推荐方式）

```nix
{
  den.hosts.x86_64-linux.igloo.users.tux = {};

  den.aspects.tux.policies.to-igloo = { host, user, ... }:
    lib.optional (host.name == "igloo") (den.lib.policy.include {
      nixos.services.openssh.enable = true;
    });
  den.aspects.tux.includes = [ den.aspects.tux.policies.to-igloo ];

  den.aspects.tux.homeManager = { ... };
}
```

### 主机向用户提供配置（当前推荐方式）

```nix
{
  den.aspects.igloo.policies.to-tux = { host, user, ... }:
    lib.optional (user.name == "tux") (den.lib.policy.include {
      homeManager.home.packages = [ pkgs.vim ];
    });
  den.aspects.igloo.includes = [ den.aspects.igloo.policies.to-tux ];
}
```

### 兼容旧配置

```nix
{
  # 仍然可以用，但不产生任何效果
  den.schema.user.includes = [
    den.batteries.mutual-provider
  ];
}
```

## 实现简析

源文件位于 `modules/compat/mutual-provider-shim.nix`，内容极简：

```nix
{ ... }:
{
  den.batteries.mutual-provider = {
    name = "mutual-provider";
    description = "Inert compat shim — cross-entity routing is built-in.";
    __functor = _: _: {
      name = "mutual-provider";
      description = "Inert compat shim.";
    };
  };
}
```

- 定义了一个 `__functor`，无论传入什么参数都返回一个标记为 "Inert compat shim" 的方面
- 不会注册任何策略、不会产生任何 `route`/`provide` 效果
- 目的仅在于使已在 `includes` 中引用了 `den.batteries.mutual-provider` 的配置不会因该电池不存在而报错

真正的双向配置路由能力已集成到 Den 管道的 `emitAspectPolicies` 中，无需任何电池即可工作。用户/主机只需通过 `policies.<target>` 定义策略并使用 `den.lib.policy.include` 效果即可。

## 关联电池

| 电池 | 关系 |
|---|---|
| `den.batteries.host-aspects` | 主机向用户提供配置的便捷封装，不依赖 mutual-provider |
| `den.batteries.define-user` | 在用户方面创建系统用户 |
| `den.batteries.primary-user` | 为用户添加管理员权限 |

## 关联文档

- [核心概念](../../02-核心概念.md) — "前置方面（Forward）"一节描述双向配置（参见 `policies.<target>` 与 `den.lib.policy.include`）
- [方面配置指南](../../04-方面配置指南.md) — provides 与策略机制的详细说明
