# den.batteries.hostname

**源文件**: `modules/aspects/batteries/hostname.nix`

## 用途

从 `den.hosts.<name>.hostName` 读取主机名，自动写入对应操作系统类的 `networking.hostName`。支持 NixOS、Darwin、WSL 三种平台。

该电池是一个**静态方面**（static aspect），包含一个名为 `hostname/os` 的子方面 `setHostname`。只需在全局或具体主机方面中引用一次，即可完成主机名的自动配置。

## 参数

电池本身无参数。它读取约定好的上下文变量：

| 上下文变量 | 来源 | 说明 |
|---|---|---|
| `host.class` | Den 框架 | 当前主机的目标类（`nixos` / `darwin` / …） |
| `host.hostName` | `den.hosts.<name>.hostName` | 用户定义的主机名字符串 |

## 返回值

返回一个方面（aspect），包含一个 `includes` 列表，其中是 `setHostname` 函数。

`setHostname` 生成：

```
{
  name = "hostname/os";
  <host.class>.networking.hostName = <host.hostName>;
}
```

## 使用示例

### 全局启用（所有主机生效）

```nix
{
  den.default.includes = [ den.batteries.hostname ];
}
```

### 单主机启用

```nix
{
  den.aspects.igloo = {
    includes = [ den.batteries.hostname ];
    nixos = { ... };
  };
}
```

### 配合主机定义

```nix
{
  den.hosts.x86_64-linux.igloo = {
    hostName = "igloo";
    nixos = { ... };
  };

  # hostname 电池自动将 networking.hostName 设为 "igloo"
  den.default.includes = [ den.batteries.hostname ];
}
```

## 实现简析

源文件共 26 行，结构极为简洁：

```
{ ... }:                              # 无外部依赖
let
  description = "...";                # 文档字符串
  setHostname = { host, ... }: {      # 方面函数：提取 host 上下文
    name = "hostname/os";
    ${host.class}.networking.hostName = host.hostName;  # 动态类名写入
  };
in {
  den.batteries.hostname = {
    name = "hostname";
    inherit description;
    includes = [ setHostname ];       # 把 setHostname 作为子方面
  };
}
```

核心逻辑只有一行：

```nix
${host.class}.networking.hostName = host.hostName;
```

- `host.class` 由 Den 框架解析主机配置时确定，值为 `"nixos"`、`"darwin"` 等
- `host.hostName` 来自用户在 `den.hosts.<name>` 中声明的 `hostName`
- 通过 Nix 属性路径拼接（`${host.class}`），将 hostName 写入正确的类作用域

`setHostname` 是一个符合 Den 方面签名的函数：接收 `{ host, ... }`，返回带 `name` 和类属性的 attrset。它被放在 `includes` 中作为子方面，Den 的方面解析系统会自动展开并合并其输出。

## 关联电池

| 电池 | 关系 |
|---|---|
| `den.batteries.primary-user` | 同样使用 `host.class` 动态分发到不同目标类 |
| `den.batteries.wsl` | 也涉及 `host.class` 检测，但增加了守卫条件 |
| `den.batteries.forward` | 本电池的分发模式可视为一种最简单的静态转发 |
