# den.batteries.user-shell

**源文件**: `modules/aspects/batteries/user-shell.nix`

## 用途

设置用户的默认 shell，同时在操作系统层和 Home Manager 层启用该 shell。一次调用即可完成：

| 层 | 效果 |
|---|---|
| **NixOS** | `programs.<shell>.enable = true` + `users.users.<name>.shell = pkgs.<shell>` |
| **Darwin** | 同 NixOS（Darwin 下 `programs` 同样适用） |
| **Home Manager** | `programs.<shell>.enable = true` |

## 签名

```nix
den.batteries.user-shell shellName
```

| 参数 | 类型 | 说明 |
|---|---|---|
| `shellName` | `String` | shell 的程序名，例如 `"fish"`、`"zsh"`、`"bash"` |

## 返回值

返回一个方面（aspect），包含两个子方面函数：

| 子方面 | 上下文 | 作用 |
|---|---|---|
| `{ host, user }` | 主机上下文 | 在 OS 层启用 shell 并设置为用户的默认 shell |
| `{ home }` | 独立 HM 上下文 | 在 Home Manager 层启用 shell |

## 使用示例

### 为单个用户设置 fish shell

```nix
{
  den.aspects.tux = {
    includes = [
      den.batteries.define-user
      den.batteries.primary-user
      (den.batteries.user-shell "fish")      # tux 的默认 shell 设为 fish
    ];
    homeManager = { ... };
  };
}
```

### 多用户不同 shell

```nix
{
  den.aspects.alice = {
    includes = [
      den.batteries.define-user
      (den.batteries.user-shell "zsh")
    ];
  };

  den.aspects.bob = {
    includes = [
      den.batteries.define-user
      (den.batteries.user-shell "bash")
    ];
  };
}
```

### 全局默认 shell（所有用户）

```nix
{
  den.default.includes = [
    (den.batteries.user-shell "fish")
  ];
}
```

## 实现简析

源文件 40 行，属于较为简洁的实现。

### `userShell`：核心逻辑

```nix
userShell = shell: user:
  let
    nixos = { pkgs, ... }: {
      programs.${shell}.enable = true;
      users.users.${user.userName}.shell = pkgs.${shell};
    };
    darwin = nixos;                # Darwin 与 NixOS 完全一致
    homeManager.programs.${shell}.enable = true;
  in
  { inherit nixos darwin homeManager; };
```

两个关键点：

1. **NixOS/Darwin 共享实现**：`darwin = nixos` 因为两者使用同一套 Nixpkgs 模块系统，`programs.<shell>` 和 `users.users` 在这两个平台上都可用
1. **Home Manager 只启用**：HM 侧只做 `programs.<shell>.enable`，不设置登录 shell（因为登录 shell 是 OS 层的概念）

### 电池注册与柯里化

```nix
den.batteries.user-shell = shell: {
  inherit description;
  includes = [
    ({ host, user }: { name = "user-shell/${user.userName}@${host.name}"; } // userShell shell user)
    ({ home }: { name = "user-shell/${home.name}"; } // userShell shell home)
  ];
};
```

`user-shell` 是一个**柯里化函数**：`shell -> aspect`。调用 `den.batteries.user-shell "fish"` 产生一个具体的方面实例。这是因为 shell 必须在引用时由用户指定，不能硬编码。

两个 includes 分别处理：

- **主机上下文**（`{ host, user }`）：OS 层设置 + HM 层设置
- **Home 上下文**（`{ home }`）：仅 HM 层设置（standalone HM 场景）

### 关于 `pkgs.${shell}` 的查找

`nixos` 模块中的 `pkgs.${shell}` 使用 Nixpkgs 属性名查找。这意味着：

- `"fish"` 对应 `pkgs.fish`
- `"zsh"` 对应 `pkgs.zsh`
- `"bash"` 对应 `pkgs.bash`

这要求传入的 shell 名称与 Nixpkgs 中的包属性名一致。

## 关联电池

| 电池 | 关系 |
|---|---|
| `den.batteries.define-user` | 前置依赖，必须先定义用户才能设置其 shell |
| `den.batteries.primary-user` | 常配合使用，设置主用户的默认 shell |
| `den.batteries.hostname` | 同为基础配置电池，本电池偏重用户层面 |
