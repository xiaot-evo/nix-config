# 条件包含辅助

**源文件**: `nix/lib/aspects/fx/includes.nix`

## 概述

提供 `includeIf` 工具，用于根据运行时条件创建条件包含。这是管道中条件方面的主要入口点。

---

## `includeIf`

### 签名
```nix
includeIf : (Context -> Bool) -> [Aspect] -> Aspect
```

### 用途
创建一个条件方面，其子节点仅在守卫函数返回 `true` 时才被解析。当守卫条件在编译时无法确定时（如依赖于策略扩展的上下文），条件方面会被延迟并在上下文可用时重新解析。

### 参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `guardFn` | Context -> Bool | 守卫函数，接收作用域上下文并返回布尔值 |
| `aspects` | [Aspect] | 条件方面包含的方面列表 |

### 返回
具有 `meta.guard` 标记的条件方面。管道中的 `compileHandler` 检测到 `meta.guard` 并将其分派给 `compileConditionalHandler`。

```nix
{
  name = "<includeIf>";
  meta = {
    guard = guardFn;      # 守卫函数
    aspects = aspects;    # 包含的方面
  };
  includes = [ ];
}
```

### 示例
```nix
{
  includes = [
    (includeIf (ctx: ctx ? host && ctx.host.name == "igloo") [
      den.aspects.igloo-specific
    ])
    (includeIf (ctx: ctx ? user && ctx.user.name == "tux") [
      den.aspects.tux-specific
    ])
  ];
}
```

### 管道流程

`includeIf` 创建的方面在 `compileHandler`（形状路由器）中被检测为条件方面：

```nix
# 形状检测逻辑
hasGuard = aspect.meta.guard or null != null;
```

条件方面被分派到 `compileConditionalHandler`，后者：

1. **立即尝试守卫**：如果上下文可用，立即评估守卫
2. **守卫通过**：将 `meta.aspects` 作为子包含发射
3. **守卫失败或延迟**：调用 `deferConditionalHandler` 延迟条件
4. **延迟的条件**：稍后通过 `drainConditionalsHandler` 重新检查，此时上下文可能已经扩展

### 条件 vs 参量

| 特性 | `includeIf`（条件） | 参量方面（`__args`） |
|------|---------------------|---------------------|
| 用途 | 条件包含 | 参数绑定 |
| 标记 | `meta.guard` | `__fn` + `__args` |
| 延迟时机 | 守卫失败时 | 参数缺失时 |
| 重新检查 | 通过 `drainConditionalsHandler` | 通过 `drainHandler` |
| 形状 | `compile-conditional` | `compile-parametric` |

### 实现细节

```nix
includeIf = guardFn: aspects: {
  name = "<includeIf>";
  meta = {
    guard = guardFn;
    inherit aspects;
  };
  includes = [ ];
};
```

```nix
# 形态路由器（compileHandler）中的检测逻辑
isConditional = aspect.meta.guard or null != null && !aspect.meta.deferred or false;
```

```nix
# 条件编译器（compileConditionalHandler）中的守卫评估
if guardFn ctx then
  # 通过：发射 meta.aspects 为子包含
  fx.seq (map (a: fx.send "emit-include" a) (aspect.meta.aspects or [ ]))
else
  # 失败或延迟：发送 defer-conditional
  fx.send "defer-conditional" aspect
```
