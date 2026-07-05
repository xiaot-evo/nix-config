# home-manager (自动注册模块)

**源文件**: `modules/aspects/batteries/home-manager.nix`

## 用途

Home Manager 集成的核心电池。自动将声明了 `homeManager` 类的用户转发到 Home Manager 模块系统，完成 Host→User 的配置路由。

关键行为：

- 注册 `homeManager` 类，描述为 "Home Manager user environment"
- 通过 `den.lib.home-env.makeHomeEnv` 构建
- `className = "homeManager"`，`optionPath = "home-manager"`
- Host 检测到有用户属于 `homeManager` 类后，自动启用
- 自动装载 `inputs.home-manager` 中对应 OS 的模块
- 提供 `hmHostBridge`，桥接 `den.schema.hm-host.includes` 中的策略

## 使用示例

本模块通过 `import-tree` 自动注册到 `den.schema.host.includes` 和 `den.schema.user.includes` 中，无需手动引入。只需要在用户 aspect 中使用 `den.batteries.define-user` 并将 `homeManager` 加入 `user.classes`：

```nix
den.aspects.alice = {
  includes = [
    den.batteries.define-user
    (den.batteries.user-shell "bash")
  ];
  homeManager = {
    # 此处的配置自动属于 home-manager.users.alice
    programs.bash.enable = true;
  };
};
```

## 实现简析

```
makeHomeEnv {
  className = "homeManager";
  ctxName   = "hm";
  optionPath = "home-manager";
  getModule  = { host, ... }:
    inputs.home-manager."${host.class}Modules".home-manager;
  forwardPathFn = { user, ... }: [ "home-manager" "users" user.userName ];
}
```

- `makeHomeEnv` 在 `nix/lib/home-env.nix` 中定义，生成三个产出：
  - **`battery`**: 包含 `host-to-hm-users` 策略，在 Host 解析阶段检测并转发用户
  - **`userDetect`**: 包含 `hm-user-detect` 策略，在 User 解析阶段处理
  - **`hostConf`**: 为 Host 添加 `<optionPath>.{enable,module}` 选项
- `hmHostBridge` 使用 `den.lib.policy.when` + `mkDetectHost` 条件判断，仅在 Host 存在 `homeManager` 用户时注入 `den.schema.hm-host.includes`
- `den.schema.host.imports = [ result.hostConf ]` 将 host 选项注册到 schema

## 关联电池

| 电池 | 关系 |
|---|---|
| `den.batteries.define-user` | 与 home-manager 配合创建完整的 OS + HM 用户 |
| `den.batteries.host-aspects` | 主机方面向用户提供 HM 配置，依赖 home-manager 电池 |
| `hjem` (自动注册模块) | Hjem 集成模块，同类替代方案 |
| `maid` (自动注册模块) | Nix-Maid 集成模块，同类替代方案 |

## 关联函数

- `den.lib.home-env.makeHomeEnv` — home-manager 电池的底层实现工厂函数
- `den.lib.policy.when` — 用于条件启用 HM 集成的策略效果

## 关联文档

- [内置电池](../../../05-%E5%86%85%E7%BD%AE%E7%94%B5%E6%B1%A0.md) — home-manager 电池的快速参考
- [Home Manager 集成](../../../06-home-manager%E9%9B%86%E6%88%90.md) — home-manager 集成的详细指南和完整示例
