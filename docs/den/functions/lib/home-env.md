# home-env 模块

**源文件**: `nix/lib/home-env.nix`

## 概述

家庭环境集成电池。提供了一套完整的模式来将 home-manager 或类似服务集成到 Den 的主机配置中——包括主机级别开关、用户级别的自动路由和策略。

______________________________________________________________________

## den.lib.home-env.makeHomeEnv

**签名**: `(config: attrset) → { battery, userDetect, hostConf }`

### 用途

创建 home-manager 风格服务的集成电池。自动处理：

- 主机级别的开关（enable + module 选项）
- 用户级别的自动检测和转发
- 主机作用域和用户作用域的策略分发

### 参数说明

- `config: attrset`:
  - `className: string` — 目标类名（如 `"homeManager"`）
  - `ctxName: string（可选）` — 上下文名称（默认同 `className`）
  - `supportedOses: [string]（可选）` — 支持的操作系统（默认 `["nixos", "darwin"]`）
  - `optionPath: string` — 配置选项路径（如 `"hm"`）
  - `getModule: ({ host, inputs }) → module` — 获取服务模块的函数
  - `forwardPathFn: ({ host, user }) → [string]` — 目标路径函数

### 返回值说明

返回一个 attrset：

- `battery` — 主机作用域的电池方面（包含策略和 includes）
- `userDetect` — 用户作用域的策略方面
- `hostConf` — 主机级别选项（enable + module）

### 使用示例

```nix
# 集成 home-manager
den.lib.home-env.makeHomeEnv {
  className = "homeManager";
  optionPath = "hm";
  getModule = { host, inputs }: inputs.home-manager.darwinModules.home-manager;
  forwardPathFn = { host, user }: [ "users" user.name ];
}
```

```nix
# 集成 hjem
den.lib.home-env.makeHomeEnv {
  className = "hjem";
  optionPath = "hjem";
  getModule = { host, inputs }: inputs.hjem.darwinModules.default;
  forwardPathFn = { host, user }: [ "users" user.name ];
}
```

### 实现简析

1. 创建主机级别的策略函数：检测用户、为每个匹配用户发出 `resolve` 效果
1. 创建用户级别的策略函数：在用户作用域内检测并发出转发
1. 创建主机选项（enable + module）
1. 返回三部分供 `den.schema.host.includes` 和 `den.schema.user.includes` 分别使用

### 辅助函数

`mkDetectHost` — 检测主机是否应该启用服务：

- 检查操作系统是否支持
- 检查 `host.${optionPath}.enable`
- 检查主机是否有用户属于目标类

`mkIntoClassUsers` — 获取主机中属于目标类的用户列表：

- 签名：`(className: string) → ({ host }) → [{ host, user }]`

______________________________________________________________________

## 关联函数

- `den.lib.policy.resolve` — 在策略中创建解析效果
- `den.lib.policy.include` — 包含模块
- `den.lib.forward.forwardItem` / `den.lib.forward.forwardEach` — 转发用户模块
- `den.lib.resolveEntity` — 创建用户实体
