# den.batteries.forward

**源文件**: `modules/aspects/batteries/forward.nix`

**底层库**: `nix/lib/forward.nix`

## 用途

用于创建自定义类的转发（forwarding）方面。当需要将某个类中的所有内容转发到另一个类的指定路径时，使用 `den.batteries.forward`。

典型应用场景：
- `homeManager` 类（官方实现）
- `os-user` 类的 `user` → `users.users.<name>` 转发
- 自定义用户环境类（如 `nix-maid`、`hjem`）

简而言之：**`den.batteries.forward` 是创建类转发基础设施的工具**。

## 签名

```nix
den.batteries.forward
```

返回一个 `__functor`（可调用属性），实际调用 `den.lib.forward.forwardEach`。

### `forwardEach` 参数

通过 `forward` 调用时传递一个参数集：

| 参数 | 类型 | 说明 | 必填 |
|---|---|---|---|
| `each` | `list` | 要转发的条目列表 | 是 |
| `fromClass` | `String \| (item -> String)` | 源类名（或从条目中提取的函数） | 是 |
| `intoClass` | `String \| (item -> String)` | 目标类名（或从条目中提取的函数） | 否，默认从 `den.classes.<fromClass>.forwardTo` 读取 |
| `intoPath` | `[String] \| (item -> [String])` | 目标路径（或函数）| 否，默认从 `den.classes.<fromClass>.forwardTo.path` 读取 |
| `fromAspect` | `(item -> aspect)` | 如何从条目中提取源方面 | 否，默认 `item.resolved or item` |
| `guard` | `({options,...}: bool)` | 守卫条件，仅在条件满足时转发 | 否 |
| `adaptArgs` | `(args -> args)` | 参数适配函数，用于注入额外上下文 | 否 |
| `adapterModule` | `module` | 适配器模块，需要额外配置时使用 | 否 |
| `mapModule` | `(item -> module -> module)` | 模块映射函数 | 否 |
| `fromCtx` | `(item -> attrs)` | 从条目中提取上下文 | 否 |
| `evalConfig` | `bool` | 是否提前 eval 配置 | 否 |

## 使用示例

### 创建自定义类转发

```nix
{
  den.batteries.my-class-forward = den.batteries.forward {
    each = [ "some-item" ];
    fromClass = "myClass";
    intoClass = "nixos";
    intoPath = [ "some" "nested" "path" ];
  };
}
```

### 带 guard 的转发

```nix
{
  den.batteries.safe-forward = den.batteries.forward {
    each = myItems;
    fromClass = "special";
    intoClass = "nixos";
    intoPath = [ "services" "special" ];
    guard = { options, ... }: options ? services.special;
  };
}
```

当目标模块不存在 `services.special` 选项时，转发被跳过——防止因选项不存在而报错。

### 官方用法示例：home-manager 集成

参考 `modules/batteries/home-manager.nix` 和 `hm-integration.nix`：

```nix
# 伪代码：homeManager 类的实现使用了 forward 模式
den.batteries.forward {
  each = users;
  fromClass = "homeManager";
  intoClass = "home-manager";
  # ...
};
```

### 与 os-user 的比较

```nix
# os-user 使用 den.lib.policy.route（一种内置转发）
den.lib.policy.route {
  fromClass = "user";
  intoClass = host.class;
  path = [ "users" "users" user.userName ];
}

# 如果用 forward 实现相同的功能（示意，非精确等价）
den.batteries.forward {
  each = users;
  fromClass = "user";
  intoClass = host.class;
  intoPath = [ "users" "users" user.userName ];
}
```

## 实现简析

### forward.nix（电池包装）

```nix
den.batteries.forward = {
  inherit description;
  __functor = _self: den.lib.forward.forwardEach;
};
```

使用 `__functor` 使得 `den.batteries.forward` 可以直接作为函数调用——Nix 中的 `__functor` 属性使属性集可调用。

### forwardEach（底层库）

```nix
forwardEach = fwd: {
  includes = map (item: forwardItem (fwd // { inherit item; })) fwd.each;
};
```

遍历 `each` 中的每个条目，为每个条目调用 `forwardItem`，产生一个包含 `includes` 列表的方面。

### forwardItem 的核心逻辑

每个转发的条目都生成一个 `meta.__forward` 属性集，包含完整的转发元数据：

```nix
meta.__forward = {
  inherit fromClass intoClass intoPath guardFn adaptArgsFn ...;
};
```

Den 的方面解析器在遇到 `meta.__forward` 时会根据这些元数据执行：
1. 从 `fromClass` 读取源方面
2. 调用 `guardFn` 检查守卫条件
3. 使用 `adaptArgsFn` 调整参数
4. 将源模块通过 `intoPath` 写入目标类

### 关于 `guard` 的设计

`guard` 参数可以是：
- **函数**：接收 `{ options, config, ... }`，返回 `bool`
- **null**：不设守卫

当 guard 返回 `true` 时正常转发，否则跳过。在 `wsl.nix` 中可以看到其使用场景：

```nix
guard = { options, ... }: options ? wsl;
```

这个 guard 确保只在 WSL 模块加载后才执行转发。

## 关联电池

| 电池 | 关系 |
|---|---|
| `den.batteries.os-user` | 使用 `den.lib.policy.route`（底层与 forward 共享机制）实现 `user` 类转发 |
| `den.batteries.wsl` | 使用 guard 机制的 forward 模式 |
| `den.batteries.os-class` | 使用 `route` 实现 `os` 类转发 |
| `den.batteries.define-user` | 不使用 forward，直接写入多个类 |
| `den.batteries.import-tree` | 互补工具：import 进入模块，forward 分发内容 |
