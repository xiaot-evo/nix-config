# synthesizePolicies 模块

**源文件**: `nix/lib/synthesize-policies.nix`

## 概述

策略参数检查工具。提供了判断策略是否应该在特定上下文中触发的核心函数。

______________________________________________________________________

## den.lib.synthesizePolicies.resolveArgsSatisfied

**签名**: `(policy: function, ctx: attrset) → bool`

### 用途

检查策略的强制参数是否在上下文中全部满足。这是策略分发的核心判断——只有参数满足的策略才会在管道中触发。

### 参数说明

- `policy: function` — 策略函数（如 `{ host, user, ... }: [ ... ]`）
- `ctx: attrset` — 当前上下文（包含 `host`、`user` 等绑定）

### 返回值说明

`true` 表示策略所需的所有强制参数在 `ctx` 中都有对应项，策略应该触发。

### 使用示例

```nix
# 策略需要 host 参数
den.lib.synthesizePolicies.resolveArgsSatisfied
  ({ host, ... }: [ den.lib.policy.include myModule ])
  { host = { name = "igloo"; }; }
# → true

# 上下文缺少 host
den.lib.synthesizePolicies.resolveArgsSatisfied
  ({ host, ... }: [ ... ])
  { }
# → false

# 无参数策略总是触发
den.lib.synthesizePolicies.resolveArgsSatisfied
  (_: [ den.lib.policy.include myModule ])
  { }
# → true（`_` 没有强制参数）
```

### 实现简析

使用 `lib.functionArgs` 获取策略函数的参数声明，提取强制参数（值为 `false` 的参数），检查它们是否都在 `ctx` 中存在。

______________________________________________________________________

## 关联函数

- `den.lib.canTake.atLeast` — 使用相同的参数检测算法
- `den.lib.policyInspect.inspect` — 内部使用此函数查找匹配的策略
