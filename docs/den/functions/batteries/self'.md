# den.batteries.self'

**源文件**: `modules/aspects/batteries/flake-parts/self.nix`

## 用途

提供 flake-parts 风格的 `self'`（预选了 system 参数的 flake self 输出）作为顶层模块参数 `_module.args.self'`。允许模块直接访问当前系统的 flake 输出，无需手动推导 `pkgs.stdenv.hostPlatform.system`。

三类上下文感知：

- **Host 上下文**：注入 `host.class._module.args.self'`
- **User 上下文**：为用户的每个类注入 `self'`
- **Home 上下文**：为 home 的类注入 `self'`

## 使用示例

```nix
# 全局启用（推荐）
den.default.includes = [ den.batteries.self' ];
```

```nix
# 或按需启用
den.aspects.my-laptop.includes = [ den.batteries.self' ];
```

启用后，在模块中可以直接使用：

```nix
{ self', ... }: {
  home.packages = [
    self'.packages.hello
  ];
}
```

## 实现简析

```
mkAspect = class: system:
  withSystem system ({ self', ... }: {
    ${class}._module.args.self' = self';
  });

osAspect = { host }: {
  name = "self'/os";
} // mkAspect host.class host.system;

userAspect = { user, host }: {
  name = "self'/user";
  includes = map (c: mkAspect c host.system) user.classes;
};

homeAspect = { home }: {
  name = "self'/home";
} // lib.optionalAttrs (home ? class) (mkAspect home.class home.system);
```

- `withSystem` 是 flake-parts 提供的函数，接收 system 返回对应系统的 flake 输出
- Host 上下文直接调用 `mkAspect host.class host.system`
- User 上下文遍历 `user.classes`，为每个类生成一个 `mkAspect`（一个用户可能同时属于多个类）
- Home 上下文检查 `home.class` 是否存在后调用
- 三个子方面通过 `includes` 组合为一个电池

## 关联电池

| 电池 | 关系 |
|---|---|
| `den.batteries.flake-scope` | self' 的基础设施，提供 `lib`/`inputs`/`den` 上下文 |
| `den.batteries.inputs'` | 同类模式：提供 `inputs'` 模块参数，实现结构相同 |

## 关联文档

- [内置电池](../../../05-%E5%86%85%E7%BD%AE%E7%94%B5%E6%B1%A0.md) — self' 电池的快速参考
