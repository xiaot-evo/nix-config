# den.batteries.primary-user

**源文件**: `modules/aspects/batteries/primary-user.nix`

## 用途

将用户设为主要用户（primary user），根据平台自动添加对应的权限组和系统配置：

| 平台 | 效果 |
|---|---|
| **NixOS** | 加入 `wheel` 和 `networkmanager` 组 |
| **Darwin** | 设置 `system.primaryUser` |
| **WSL** | 设置 `wsl.defaultUser` |

该电池是一个**上下文函数**（`userToHostContext`），意味着它直接从用户上下文向主机上下文写入配置——它本身就是一个方面函数而非包含子方面列表的方面容器。

## 签名

```nix
den.batteries.primary-user
```

无参——直接引用即可。它被定义为 `den.batteries.primary-user = userToHostContext;`，而非 `{ name = "..."; includes = [...]; }` 形式。

## 返回值

返回一个方面函数，签名 `{ user, host, ... }`，产出：

```nix
{
  name = "primary-user(<userName>@<hostName>)";
  description = "...";
  darwin.system.primaryUser = <userName>;
  wsl.defaultUser = <userName>;
  nixos.users.users.<userName> = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
  };
}
```

## 使用示例

### 基本用法

```nix
{
  den.aspects.tux = {
    includes = [
      den.batteries.define-user
      den.batteries.primary-user    # tux 成为主要用户
    ];
    homeManager = { ... };
  };
}
```

### 多个用户场景

```nix
{
  den.aspects.alice = {
    includes = [
      den.batteries.define-user
      # alice 不加 primary-user，因此是普通用户
    ];
    homeManager = { ... };
  };

  den.aspects.bob = {
    includes = [
      den.batteries.define-user
      den.batteries.primary-user    # bob 是主要用户
    ];
    homeManager = { ... };
  };
}
```

## 实现简析

源文件 35 行，结构与其他电池不同：

### 独特之处：直接作为方面函数

```nix
den.batteries.primary-user = userToHostContext;
```

大多数电池定义为：

```nix
den.batteries.xxx = {
  name = "xxx";
  description = "...";
  includes = [ ... ];
};
```

而 `primary-user` 直接赋值为一个函数（`userToHostContext`），因为它只需要在主机上下文中执行一次，不需要独立的主机上下文和 home 上下文两个分支。

### `userToHostContext` 函数

```nix
userToHostContext = { user, host, ... }: {
  name = "primary-user(${user.userName}@${host.name})";
  inherit description;
  darwin.system.primaryUser = user.userName;
  wsl.defaultUser = user.userName;
  nixos.users.users.${user.userName} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
  };
};
```

三个关键行为：

1. **NixOS**: 将用户加入 `wheel`（sudo 权限）和 `networkmanager`（网络管理）组
2. **Darwin/macOS**: 使用 `system.primaryUser` 标记主用户（macOS 特定的系统选项）
3. **WSL**: 设置 `wsl.defaultUser`，使 WSL 默认以该用户登录

注意：NixOS 下 `extraGroups` 与 `define-user` 中的 `isNormalUser = true` 是兼容的——`define-user` 已经创建了用户条目，`primary-user` 只需补充 `extraGroups`。Den 的方面合并机制会正确处理两个来源的同一个 `users.users.<name>` 属性集的内容合并。

由于同时输出 `nixos`、`darwin`、`wsl` 三个类，Den 在解析时只会提取与当前主机类匹配的部分，其他部分被忽略。

### 没有 homeContext 变体

与 `define-user` 不同，`primary-user` 不提供独立的 home 上下文处理器。这是因为"主要用户"概念仅在操作系统层面有意义——Home Manager 本身没有 primary user 的概念。

## 关联电池

| 电池 | 关系 |
|---|---|
| `den.batteries.define-user` | 前置依赖，必须先创建用户才能设置为主用户 |
| `den.batteries.user-shell` | 常配合使用，设置主用户的默认 shell |
| WSL 模块 | 本电池的 `wsl.defaultUser` 需要在 WSL 模块加载后才生效 |
| `den.batteries.hostname` | 同为主机层配置电池 |
