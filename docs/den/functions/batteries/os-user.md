# den.batteries.os-user

**源文件**: `modules/aspects/batteries/os-user.nix`

## 用途

提供轻量级 `user` 类，允许用户在 OS 层面配置 `users.users.<userName>` 下的选项，而不需要引入 Home Manager 依赖。

对比 `den.batteries.define-user`：

| 特性 | `os-user` | `define-user` |
|---|---|---|
| 依赖 | 仅 nixpkgs | 需要 home-manager 输入 |
| 创建用户 | 通过 `user` 类转发 | 直接写入 OS |
| Home Manager | 不支持 | 同时配置 HM |
| 适用场景 | 纯 NixOS/Darwin 用户管理 | 完整 HM 集成场景 |

## 参数

无参数。电池默认启用，注册 `user` 类和 `user-to-host` 策略。

## 返回值

| 注册项 | 类型 | 说明 |
|---|---|---|
| `den.classes.user` | class 定义 | 描述 `user` 类为"Lightweight user environment forwarding to OS users.users" |
| `den.policies.user-to-host` | policy | 将 `user` 类内容路由到 `users.users.<userName>`，注入 `osConfig` |

## 使用示例

### 基本用法

```nix
{
  den.aspects.alice = {
    # 使用 user 类配置用户，无需 home-manager
    user = { pkgs, ... }: {
      packages = [ pkgs.hello ];
      extraGroups = [ "wheel" ];
    };
  };
}
```

这等价于：

```nix
{
  den.aspects.alice.nixos = { pkgs, ... }: {
    users.users.alice = {
      packages = [ pkgs.hello ];
      extraGroups = [ "wheel" ];
    };
  };
}
```

### 完整用户配置

```nix
{
  den.aspects.xiaot_evo = {
    includes = [
      (den.batteries.user-shell "fish")
    ];
    user = { pkgs, ... }: {
      shell = pkgs.fish;      # 会被 user-shell 覆盖，此处仅是示例
      extraGroups = [ "wheel" "networkmanager" "docker" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAA..."
      ];
    };
    nixos = { ... };          # 其他系统级配置
  };
}
```

### 对比 Home Manager 类

```nix
# 轻量方式（仅 OS 层）
den.aspects.alice.user.extraGroups = [ "wheel" ];

# 完整方式（OS + HM）
den.aspects.alice.homeManager = { ... };
```

## 实现简析

源文件 57 行，结构清晰。

### 类注册

```nix
den.classes.user.description = "Lightweight user environment forwarding to OS users.users";
```

### `user-to-host` 策略

```nix
den.policies.user-to-host = { user, host, ... }: [
  (den.lib.policy.route {
    fromClass = "user";
    intoClass = host.class;                   # 写入 nixos 或 darwin
    path = [ "users" "users" user.userName ]; # 嵌套路径
    adaptArgs = args: args // {
      osConfig = args.config;                 # 注入 osConfig
    };
  })
];
```

关键设计：

1. **路径嵌套**：`path = [ "users" "users" user.userName ]`——`user` 类的内容被完全嵌套写入 `users.users.<userName>` 下。即 `user.packages` → `nixos.users.users.alice.packages`

2. **`adaptArgs`**：通过 `adaptArgs` 注入 `osConfig`，使得 `user` 类模块中可以使用 `osConfig` 引用父级 NixOS/Darwin 配置（例如读取 `networking.hostName` 等）

3. **`ensureEntry` 机制**：Den 的 `route` 有一个 `ensureEntry` 机制（由 Den 的路由实现保证），即使 `user` 类中没有内容，也会创建 `users.users.<name>` 条目。这允许 home-manager 模块引用的用户条目存在。

### 执行流程

```
用户编写:
  den.aspects.alice.user.extraGroups = [ "wheel" ]
                              ↓
  den.policies.user-to-host 读取 user = { userName = "alice"; }
                              ↓
  den.lib.policy.route 生成路由: from="user" into="nixos" path=["users","users","alice"]
                              ↓
  等价于: den.aspects.alice.nixos.users.users.alice.extraGroups = [ "wheel" ]
```

### 与 `define-user` 的区别

`define-user` 是一个方面电池（aspect battery），需要在 `includes` 中引用，且会创建 `isNormalUser = true` 等基础结构。`os-user` 是一个类电池（class battery），不创建用户条目，只提供转发机制——用户需要自行在 `user` 类中编写完整配置。

## 关联电池

| 电池 | 关系 |
|---|---|
| `den.batteries.define-user` | 完整用户创建方案，依赖 home-manager |
| `den.batteries.primary-user` | 可在 `user` 类之上添加主要用户组 |
| `den.batteries.user-shell` | 可在 `user` 类之上设置 shell |
| `den.batteries.os-class` | 同类模式：提供便利类 + 策略转发 |
| `den.batteries.forward` | 底层机制，本电池的 `route` 调用本质上是 forward 的一种 |
