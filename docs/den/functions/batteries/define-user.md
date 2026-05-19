# den.batteries.define-user

**源文件**: `modules/aspects/batteries/define-user.nix`

## 用途

在操作系统层和 Home Manager 层同时创建用户。一个电池解决三个配置点的用户定义：

- **NixOS**: `users.users.<userName>`，设置 `isNormalUser = true`
- **Darwin**: `users.users.<userName>`，设置 `home` 目录
- **Home Manager**: `home.username` + `home.homeDirectory`

自动检测上下文：在主机上下文（host context）中时按 NixOS/Darwin 写入，在独立 Home Manager 上下文（standalone home context）中时按 Home Manager 写入。

## 参数

电池本身无参数。它利用 Den 框架注入的上下文变量：

| 上下文变量 | 说明 |
|---|---|
| `host.system` | 系统标识（用于判断 Darwin/Linux） |
| `host.name` | 主机名 |
| `user.userName` | 用户名（来自方面名称或 `den.aspects.<name>`） |
| `home.system` | 独立 HM 上下文中的系统标识 |
| `home.userName` | 独立 HM 上下文中的用户名 |

## 返回值

返回一个方面（aspect），包含两个子方面函数：

| 子方面 | 触发条件 | 作用 |
|---|---|---|
| `userContext` | 主机上下文（有 `host` 和 `user`） | 写入 OS + HM 用户配置 |
| `hmContext` | 独立 HM 上下文（只有 `home`） | 仅写入 Home Manager 配置 |

## 使用示例

### 在主机方面中引用（NixOS/Darwin 场景）

```nix
{
  den.aspects.tux = {
    includes = [
      den.batteries.define-user          # 在 OS 和 HM 层创建 tux 用户
      den.batteries.primary-user
    ];
    homeManager = { ... };
  };
}
```

### 在独立 Home Manager 方面中引用

```nix
{
  den.aspects.my-home = {
    includes = [ den.batteries.define-user ];
    homeManager = { ... };
  };
}
```

### 全局默认启用

```nix
{
  den.default.includes = [ den.batteries.define-user ];
}
```

此时 Den 会根据上下文自动决定走 `userContext` 还是 `hmContext`。

## 实现简析

源文件 63 行，包含两个核心函数：

### `homeDir`：跨平台家目录路径

```nix
homeDir = host: user:
  if lib.hasSuffix "darwin" host.system
  then "/Users/${user.userName}"
  else "/home/${user.userName}";
```

检测逻辑：通过 `host.system` 字符串是否以 `"darwin"` 结尾来判断 macOS，路径规则与各平台惯例一致。

### `userContext`：主机上下文处理器

```nix
userContext = { host, user }: {
  name = "define-user/${user.userName}@${host.name}";
  nixos.users.users.${user.userName} = {
    name = user.userName;
    home = homeDir host user;
    isNormalUser = true;
  };
  darwin.users.users.${user.userName} = {
    name = user.userName;
    home = homeDir host user;
  };
  homeManager = {
    home.username = user.userName;
    home.homeDirectory = homeDir host user;
  };
};
```

同时输出三个类（`nixos`、`darwin`、`homeManager`），Den 会按目标主机的实际类提取对应内容。NixOS 主机取 `nixos` 部分，Darwin 主机取 `darwin` 部分，而 `homeManager` 始终通过 host-to-home 策略传递给用户级配置。

### `hmContext`：独立 Home Manager 上下文处理器

```nix
hmContext = { home }: userContext {
  host.system = home.system;
  user.userName = home.userName;
} // { name = "define-user/home"; };
```

通过构造一个虚拟的 `host`/`user` 对象调用 `userContext`，复用同一套逻辑。Den 在 standalone home 场景下不会传 `host` 参数，因此需要独立的 `hmContext`。

### 电池注册

```nix
den.batteries.define-user = {
  name = "define-user";
  inherit description;
  includes = [ userContext hmContext ];
};
```

两个子方面函数都放在 `includes` 中，Den 的方面解析器会依次尝试，只有参数匹配的才会生效。

## 关联电池

| 电池 | 关系 |
|---|---|
| `den.batteries.primary-user` | 通常在本电池之后使用，添加额外组和主用户标记 |
| `den.batteries.user-shell` | 在本电池之上设置用户默认 shell |
| `den.batteries.os-user` | 轻量级替代，只创建 OS 用户不涉及 HM |
| `den.batteries.host-aspects` | 可以将主机方面中的 HM 内容投射给本电池创建的用户 |
