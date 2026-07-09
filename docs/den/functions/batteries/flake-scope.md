# den.batteries.flake-scope

**源文件**: `modules/aspects/batteries/flake-scope.nix`

## 用途

向方面（aspect）管道函数暴露 flake 顶层作用域：`lib`、`inputs` 和 `den`。这使得在方面管道的策略函数（如 policy resolve）中可以直接使用这些值，无需通过模块系统间接引用。

关键行为：

- 使用 `collisionPolicy = "class-wins"`（通过 `pipelineOnly` 实现），确保模块系统原生值优先
- 通过 `den-flake-scope` 策略以 `resolve` 方式注入值
- 推荐通过 `den.default.includes` 全局启用

## 使用示例

```nix
# 全局启用（推荐）
den.default.includes = [ den.batteries.flake-scope ];
```

```nix
# 或按需启用
den.aspects.my-laptop.includes = [ den.batteries.flake-scope ];
```

启用后，在方面管道的 resolve 函数中可直接使用 `lib`、`inputs`、`den`：

```nix
den.aspects.my-laptop = {
  includes = [
    (den.lib.policy.resolve { myLib = lib; })
  ];
};
```

## 实现简析

```
den.batteries.flake-scope = {
  name = "flake-scope";
  policies.den-flake-scope = _: [
    (resolve {
      lib = pipelineOnly lib;
      inputs = pipelineOnly inputs;
      den = pipelineOnly den;
    })
  ];
  includes = [
    den.batteries.flake-scope.policies.den-flake-scope
  ];
};
```

- `pipelineOnly` 使用 `collisionPolicy = "class-wins"` 策略：如果模块系统自身已定义了某个值（如 NixOS 的 `_module.args.lib`），则以模块系统的值为准
- `resolve` 将值注入到方面管道的上下文中，使后续策略函数可以访问
- 自包含设计：电池本体既是定义者又是使用者，`includes` 引用了自身的 `policies`，无需外部注册

## 关联电池

| 电池 | 关系 |
|---|---|
| `den.batteries.self'` | 依赖 flake-scope 提供的基础设施，注入 `self'` 模块参数 |
| `den.batteries.inputs'` | 依赖 flake-scope 提供的基础设施，注入 `inputs'` 模块参数 |

## 关联文档

- [内置电池](../../../05-%E5%86%85%E7%BD%AE%E7%94%B5%E6%B1%A0.md) — flake-scope 电池的快速参考
