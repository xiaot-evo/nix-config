# os-class (自动注册模块)

**源文件**: `modules/aspects/batteries/os-class.nix`

## 用途

提供 `os` 便利类（convenience class），允许用户在一个统一的作用域下编写配置，自动同时转发到 `nixos` 和 `darwin` 两个目标类。

核心价值：当你编写的配置在 NixOS 和 Darwin 上完全相同时（例如主机名、时区、locale 等），无需为每个平台分别编写。

**默认启用**，无需在 `includes` 中手动添加。

## 参数

无参数。电池本身不通过 `includes` 引入，它是一个基础设施级电池，默认加载到全局。

## 返回值

注册以下项：

| 注册项 | 类型 | 说明 |
|---|---|---|
| `den.classes.os` | class 定义 | 描述 `os` 类为"Convenience class forwarding to both nixos and darwin" |
| `den.policies.os-to-host` | policy | 策略函数，将 `os` 类内容路由到主机的实际目标类 |
| `den.default.includes` | policy 引用 | 将 `os-to-host` 策略默认加载 |

## 使用示例

### 在主机方面中使用 `os` 类

```nix
{
  den.aspects.igloo = {
    os.networking.hostName = "igloo";       # 同时在 nixos 和 darwin 生效
    os.time.timeZone = "Asia/Shanghai";
    os.i18n.defaultLocale = "zh_CN.UTF-8";
    nixos = { ... };                         # NixOS 专有配置
    darwin = { ... };                        # Darwin 专有配置
  };
}
```

### 与 `den.batteries.hostname` 对比

```nix
# 方式一：用 hostname 电池自动设置
den.default.includes = [ den.batteries.hostname ];
den.hosts.x86_64-linux.igloo.hostName = "igloo";

# 方式二：用 os 类显式设置（等价的）
den.aspects.igloo.os.networking.hostName = "igloo";
```

### 在用户作用域中使用

```nix
{
  den.aspects.tux = {
    # os 类也自动在用户作用域中可用
    os.environment.sessionVariables.FOO = "bar";
    homeManager = { ... };
  };
}
```

## 实现简析

源文件 40 行，实现了一个 Den policy 的经典范例。

### 类的注册

```nix
den.classes.os.description = "Convenience class forwarding to both nixos and darwin";
```

注册 `os` 类名为 Den 的类系统，可选的 `forwardTo` 等元数据可以在 `den.lib.classes` 中进一步定义。

### `os-to-host` 策略

```nix
den.policies.os-to-host = { host, ... }:
  lib.optional
    (builtins.elem host.class [ "nixos" "darwin" ])
    (
      den.lib.policy.route {
        fromClass = "os";
        intoClass = host.class;     # 动态：nixos 或 darwin
        path = [ ];                 # 同级合并（不嵌套子路径）
      }
    );
```

关键设计：

1. **守卫条件**：`builtins.elem host.class [ "nixos" "darwin" ]`——只在目标类为 nixos 或 darwin 时产生路由。WSL 或其他类的主机不会触发此策略。

2. **`den.lib.policy.route`**：Den 策略库的核心函数，创建一个路由条目：
   - `fromClass = "os"`：从 `os` 类读取内容
   - `intoClass = host.class`：写入主机的实际目标类（动态）
   - `path = [ ]`：同级合并，不嵌套。即 `os.foo` → `nixos.foo`（同级），而非 `nixos.os.foo`

3. **`lib.optional`**：当守卫为假时返回空列表 `[]`，策略不产生任何效果。

### 默认加载机制

```nix
den.default.includes = [ den.policies.os-to-host ];
```

Den 的 `den.default.includes` 在所有方面作用域中都生效（包括 host 和 user scope），因此 `os` 类在主机方面和用户方面的作用域中都可以使用。

### 执行流程

```
用户编写:
  den.aspects.igloo.os.networking.hostName = "igloo"
                              ↓
  den.policies.os-to-host 检测到 host.class = "nixos"
                              ↓
  den.lib.policy.route 生成路由: from="os" into="nixos" path=[]
                              ↓
  等价于: den.aspects.igloo.nixos.networking.hostName = "igloo"
```

## 关联电池

| 电池 | 关系 |
|---|---|
| `os-user` 模块 | 类似模式：提供 `user` 类转发到 `users.users.<name>` |
| `den.batteries.forward` | 通用转发机制，本电池的底层实现用了类似模式 |
| `den.batteries.hostname` | 替代方案：专用电池 vs 通用 os 类 |
