# den.batteries.host-aspects

**源文件**: `modules/aspects/batteries/host-aspects.nix`

## 用途

将主机方面（host aspect）中定义的 `user.classes`（如 `homeManager`）下的内容投射到用户方面中。简单说：允许在主机方面中编写用户级配置，自动投射给用户。

典型场景：在主机方面中定义所有用户的公共 Home Manager 配置，每个用户只需 `includes = [ den.batteries.host-aspects ]` 即可继承。

## 参数

电池本身无参数，但依赖以下上下文：

| 上下文变量 | 说明 |
|---|---|
| `host` | 当前主机上下文，包含 `host.aspect`（主机方面的完整方面树） |
| `user` | 当前用户上下文，包含 `user.classes`（用户需要的类列表） |
| `user.classes` | 用户需要的类列表，默认为 `[ "homeManager" ]` |

## 返回值

返回一个方面（aspect），包含 `from-host` 函数，产出：

```nix
{
  name = "host-aspects/<userName>@<hostName>";
  homeManager = <从主机方面解析出的 homeManager 内容>;
  # ... 其他 user.classes 中列出的类
}
```

## 使用示例

### 基本用法

```nix
{
  # 在主机方面中定义用户的 homeManager 配置
  den.aspects.igloo = {
    provides.to-users.homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.htop pkgs.jq ];
      programs.git.enable = true;
    };
    nixos = { ... };
  };

  # 用户方面引用 host-aspects，自动继承主机投射的配置
  den.aspects.tux = {
    includes = [
      den.batteries.define-user
      den.batteries.primary-user
      den.batteries.host-aspects    # ← 关键：继承主机的 HM 配置
    ];
    homeManager = { ... };          # 用户专有配置
  };
}
```

### 使用 `user.classes` 指定非默认类

```nix
{
  # 指定用户需要的类（不仅仅是 homeManager）
  den.aspects.tux = {
    classes = [ "homeManager" "nixos" ];
    includes = [ den.batteries.host-aspects ];
  };

  # 也可以在 schema 级别设置默认
  den.schema.user.classes = [ "homeManager" "nixos" ];
}
```

### 多用户继承同一主机配置

```nix
{
  den.aspects.igloo = {
    provides.to-users = {
      homeManager = { ... };         # 所有用户的公共 HM 配置
    };
    nixos = { ... };
  };

  den.aspects.alice = {
    includes = [ den.batteries.define-user den.batteries.host-aspects ];
    homeManager = { ... };           # alice 专有配置
  };

  den.aspects.bob = {
    includes = [ den.batteries.define-user den.batteries.host-aspects ];
    homeManager = { ... };           # bob 专有配置
  };
}
```

### 不使用 host-aspects 的等价写法

```nix
# 使用 host-aspects 的方式
den.aspects.tux = {
  includes = [ den.batteries.host-aspects ];
};

# 手动等价的写法（不推荐，重复劳动）
den.aspects.tux = {
  homeManager = { pkgs, ... }: {
    home.packages = [ pkgs.htop pkgs.jq ];
    programs.git.enable = true;
  };
};
```

## 实现简析

源文件 41 行，虽短但概念密集。

### `from-host`：核心转发函数

```nix
from-host = { host, user }:
  let
    ctx = { inherit host user; };
    scopeHandlers = den.lib.aspects.fx.handlers.constantHandler ctx;
    aspectWithCtx = host.aspect // {
      __scopeHandlers = scopeHandlers;
    };
  in
  {
    name = "host-aspects/${user.userName}@${host.name}";
  }
  // lib.genAttrs (user.classes or [ "homeManager" ]) (
    class: den.lib.aspects.resolveImports class aspectWithCtx
  );
```

执行流程：

#### 步骤 1：添加上下文 `__scopeHandlers`

```nix
ctx = { inherit host user; };
scopeHandlers = den.lib.aspects.fx.handlers.constantHandler ctx;
aspectWithCtx = host.aspect // { __scopeHandlers = scopeHandlers; };
```

`host.aspect` 是主机方面的完整方面树。但原来的方面树可能在声明时使用了 `{ user, ... }` 参数。为了重新解析这些方面，需要注入 `host` 和 `user` 上下文。`__scopeHandlers` 是 Den 的 FX（方面扩展）管道的机制，`constantHandler` 创建一个始终返回固定上下文的处理器。

#### 步骤 2：重新解析各个方面

```nix
lib.genAttrs (user.classes or [ "homeManager" ]) (
  class: den.lib.aspects.resolveImports class aspectWithCtx
);
```

- `user.classes` 默认为 `[ "homeManager" ]`——大多数用户只使用 HM 类
- 对于每个类（如 `homeManager`），调用 `den.lib.aspects.resolveImports` 重新解析主机方面树，只提取属于该类的内容
- 使用 `lib.genAttrs` 将结果按类名组织成属性集

#### 步骤 3：产生输出

结果是一个方面，例如：

```nix
{
  name = "host-aspects/tux@igloo";
  homeManager = {
    home.packages = [ ... ];
    programs.git.enable = true;
  };
}
```

### 关于 `den.lib.aspects.resolveImports`

这是 Den 框架的内部函数，用于将方面树解析为指定类的模块列表。它处理：

- `includes` 展开
- 函数调用（传入上下文参数）
- `meta.__forward` 处理
- 类特定的选择

### 为什么需要 FX 管道

`host-aspects` 使用了 Den 的 FX（方面扩展）管道中的 `handlers`，这是因为主机方面可能包含参数化 includes，如：

```nix
den.aspects.igloo.provides.to-users.homeManager = { user, ... }: {
  home.username = user.userName;
};
```

在重新解析时，必须传入正确的 `user` 上下文才能正确求值。`constantHandler` 确保所有子方面都得到相同的 `{ host, user }` 上下文。

## 关联电池

| 电池 | 关系 |
|---|---|
| `den.batteries.define-user` | 本电池通常在 define-user 之后使用，为用户注入 HM 配置 |
| `den.batteries.primary-user` | 用户在添加主机投射的配置后，仍可叠加 primary-user |
| `den.batteries.user-shell` | 主机可在 `provides.to-users` 中设置默认 shell，用户通过 host-aspects 继承 |
| `den.batteries.import-tree` | 替代方案：import-tree 从文件系统导入，host-aspects 从主机方面投射 |
