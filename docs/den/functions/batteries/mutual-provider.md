# den.batteries.mutual-provider

**源文件**: `modules/aspects/batteries/mutual-provider.nix`

## 用途

启用主机（Host）和用户（User）之间的**双向配置提供**（mutual providing）。默认情况下，用户方面可以通过 `provides.to-hosts.nixos` 向主机提供 NixOS 配置；同时主机方面也可以通过 `provides.to-users.homeManager` 向用户提供 Home Manager 配置。

关键行为：
- 激活 `provides` 系统的双向通道
- 用户方面可以使用 `provides.to-hosts.nixos` 定义应注入到主机的 NixOS 模块
- 主机方面可以使用 `provides.to-users.homeManager` 定义应注入到用户的 HM 模块
- 需要显式通过 `includes` 选入（非默认启用）

## 使用示例

### 用户向主机提供配置

```nix
{
  den.hosts.x86_64-linux.igloo.users.tux = {};

  den.aspects.tux = {
    includes = [
      den.batteries.define-user
      den.batteries.primary-user
      den.batteries.mutual-provider  # 启用双向提供
    ];
    # 用户向主机提供 NixOS 配置
    provides.to-hosts.nixos = {
      services.openssh.enable = true;
    };
    homeManager = { ... };
  };
}
```

### 全局启用（推荐方式）

```nix
{
  # 所有用户默认启用 mutual-provider
  den.schema.user.includes = [
    den.batteries.mutual-provider
  ];
}
```

### 主机向用户提供配置

```nix
{
  den.aspects.igloo = {
    includes = [ den.batteries.host-aspects ];
    # 主机向用户提供默认 HM 配置
    provides.to-users.homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.vim ];
    };
  };

  den.aspects.tux = {
    includes = [
      den.batteries.define-user
      den.batteries.host-aspects  # 接收主机的 HM 提供
    ];
  };
}
```

## 实现简析

`mutual-provider` 电池注册了两个策略：

1. **`host-to-users` 策略**：在主机解析阶段，将主机方面中 `provides.to-users.*` 内容转发给该主机的用户
2. **`user-to-host` 策略**：在用户解析阶段，将用户方面中 `provides.to-hosts.*` 内容注入到主机的对应类中

这两个策略通过 Den 的 `route` 和 `provide` 效果实现，本质上是跨实体配置路由的基础设施。

该电池必须在相关方面中通过 `includes` 显式启用，因为双向提供涉及额外的策略分派开销。

## 关联电池

| 电池 | 关系 |
|---|---|
| `den.batteries.host-aspects` | 主机向用户提供配置的便捷封装，依赖 mutual-provider 的底层机制 |
| `den.batteries.define-user` | 在用户方面创建系统用户，常与 mutual-provider 配合使用 |
| `den.batteries.primary-user` | 为用户添加管理员权限，可与 mutual-provider 叠加使用 |

## 关联文档

- [核心概念](../../02-核心概念.md) — "前置方面（Forward）"一节描述通过 mutual-provider 实现的双向配置（参见"需要 `den.batteries.mutual-provider` 激活"）
- [方面配置指南](../../04-方面配置指南.md) — provides 机制的详细说明
