# den.batteries.inputs'

**源文件**: `modules/aspects/batteries/flake-parts/inputs.nix`

## 用途

提供 flake-parts 风格的 `inputs'`（预选了 system 参数的 flake inputs 输出）作为顶层模块参数 `_module.args.inputs'`。与 `den.batteries.self'` 结构相同，但提供的是 `inputs'` 而非 `self'`。

三类上下文感知（与 `den.batteries.self'` 完全一致）：
- **Host 上下文**：注入 `host.class._module.args.inputs'`
- **User 上下文**：为用户的每个类注入 `inputs'`
- **Home 上下文**：为 home 的类注入 `inputs'`

## 使用示例

```nix
# 全局启用（推荐）
den.default.includes = [ den.batteries.inputs' ];
```

```nix
# 或按需启用
den.aspects.my-laptop.includes = [ den.batteries.inputs' ];
```

启用后，在模块中可以直接使用：

```nix
{ inputs', ... }: {
  home.packages = [
    inputs'.nixpkgs.legacyPackages.hello
  ];
}
```

## 实现简析

```
mkAspect = class: system:
  withSystem system ({ inputs', ... }: {
    ${class}._module.args.inputs' = inputs';
  });

osAspect = { host }: {
  name = "inputs'/os";
} // mkAspect host.class host.system;

userAspect = { user, host }: {
  name = "inputs'/user";
  includes = map (c: mkAspect c host.system) user.classes;
};

hmAspect = { home }: {
  name = "inputs'/home";
} // lib.optionalAttrs (home ? class) (mkAspect home.class home.system);
```

- 结构与 `den.batteries.self'` 几乎完全一致，区别是注入 `inputs'` 而非 `self'`
- 同样使用 `withSystem` 获取系统相关的 `inputs'`
- 三上下文感知模式是 Den 框架中 flake-parts 兼容性电池的通用模式
- 推荐全局使用：`den.default.includes = [ den.batteries.inputs' ]`

## 关联电池

| 电池 | 关系 |
|---|---|
| `den.batteries.flake-scope` | inputs' 的基础设施，提供 `lib`/`inputs`/`den` 上下文 |
| `den.batteries.self'` | 同类模式：提供 `self'` 模块参数，实现结构几乎完全一致 |

## 关联文档

- [内置电池](../../../05-内置电池.md) — inputs' 电池的快速参考
