# canTake 模块

**源文件**: `nix/lib/can-take.nix`

## 概述

函数参数检测工具。检查一个函数是否能接受特定参数集。Den 用它在管道中判断一个策略是否应在特定上下文中触发——如果策略的参数在上下文中全部存在，则触发策略。

---

## den.lib.canTake.atLeast

**签名**: `(params: attrset, func: function) → bool`

### 用途

检查函数是否能接受**至少**指定的参数。即函数所需的所有强制参数都包含在 `params` 中。

### 参数说明

- `params: attrset` — 候选参数集合（键为参数名，值为任意占位）
- `func: function` — 要检测的函数

### 返回值说明

`true` 表示函数的所有强制参数在 `params` 中都有对应项。

### 使用示例

```nix
den.lib.canTake.atLeast { host = true; } ({ host, ... }: { nixos = ...; })
# → true（函数需要 host，params 提供 host）

den.lib.canTake.atLeast { } ({ host, ... }: { nixos = ...; })
# → false（函数需要 host，但 params 为空）

den.lib.canTake.atLeast { host = true; } (_: { nixos = ...; })
# → true（`_` 函数没有强制参数）
```

### 实现简析

使用 `lib.functionArgs` 获取函数的参数声明，提取所有强制参数（值为 `false` 的），检查它们是否都在 `params` 中。

---

## den.lib.canTake.exactly

**签名**: `(params: attrset, func: function) → bool`

### 用途

检查函数是否恰好接受指定参数。即函数的强制参数集合与 `params` 的键集合完全相同。

### 参数说明

与 `atLeast` 相同。

### 返回值说明

`true` 表示强制参数与 `params` 键集合完全相等。

### 使用示例

```nix
den.lib.canTake.exactly { host = true; } ({ host, ... }: ...)
# → true

den.lib.canTake.exactly { host = true; user = true; } ({ host, ... }: ...)
# → false（函数只接受 host，不是 host+user）
```

---

## den.lib.canTake.upTo

**签名**: `(params: attrset, func: function) → bool`

### 用途

检查函数是否能接受**最多**指定参数。即函数至少有一个强制参数在 `params` 中，且所有强制参数都被满足。

### 参数说明

与 `atLeast` 相同。

### 返回值说明

`true` 表示函数至少有一个强制参数与 `params` 相交。

### 使用示例

```nix
# 在 types.nix 中用于检测子模块函数
den.lib.canTake.upTo { lib = true; config = true; options = true; } (
  { lib, config, ... }: { ... }
)
# → true（函数接受 lib/config/options，是子模块函数）
```

### 实现简析

检查满足条件（`satisfied`），且 `params` 和 `args` 之间有至少一个公共键（`intersect != {}`）。

---

## 关联函数

- `den.lib.synthesizePolicies.resolveArgsSatisfied` — 使用相同的检测逻辑检查策略参数
- `den.lib.aspects.types.isSubmoduleFn` — 使用 `canTake.upTo` 检测子模块函数
