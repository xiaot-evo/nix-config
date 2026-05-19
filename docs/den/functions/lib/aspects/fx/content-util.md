# contentUtil 模块

**源文件**: `nix/lib/aspects/fx/content-util.nix`

## 概述

内容工具函数。提供方面内容的底层展开和转换操作，用于管道中类发射、键分类和 provide 处理。主要处理 `__contentValues` 包装器、`__fn`/`__functor` 包装函数以及 `includes` 属性集的展开。

---

## `unwrapContentValuesList`

### 签名
```nix
unwrapContentValuesList :: Any -> [Any]
```

### 用途

将原始值展开为列表。这是方面内容的最基础展开操作——所有管道下游消费都基于此工具将非规范化的输入归一化为列表。

### 处理逻辑

| 输入类型 | 行为 | 示例 |
|----------|------|------|
| 列表 | 直接透传 | `[ a b ] → [ a b ]` |
| `__contentValues` attrset | 提取 `__contentValues` 值并去重 | `{ __contentValues = [ a b a ]; } → [ a b ]` |
| 其他值 | 包装为单元素列表 | `"x" → [ "x" ]` |

### 使用示例

```nix
unwrapContentValuesList [ 1 2 3 ]
# → [ 1 2 3 ]

unwrapContentValuesList { __contentValues = [ 1 2 2 3 ]; }
# → [ 1 2 3 ]  （已去重）

unwrapContentValuesList "hello"
# → [ "hello" ]
```

### 实现简析

```nix
unwrapContentValuesList = v:
  if builtins.isList v then v
  else if builtins.isAttrs v && v ? __contentValues then
    lib.unique v.__contentValues
  else [ v ];
```

1. 首先检查是否为列表——直接返回
2. 检查是否为带有 `__contentValues` 属性的 attrset——提取并去重
3. 其他所有值——包装在单元素列表中

---

## `unwrapContentValuesForClassification`

### 签名
```nix
unwrapContentValuesForClassification :: Any -> Any
```

### 用途

为键分类（key classification）展开内容值。与 `unwrapContentValuesList` 不同，此函数处理的是 attrset 值而非列表——合并 `__contentValues` 中的 attrset 条目以进行子键检测。

### 处理逻辑

| 输入类型 | 行为 | 示例 |
|----------|------|------|
| 非 attrset | 返回 `null` | `"str" → null` |
| 普通 attrset | 直接返回 | `{ a = 1; } → { a = 1; }` |
| `__contentValues` attrset | 合并所有内容值 | `{ __contentValues = [ { a = 1; } { b = 2; } ]; } → { a = 1; b = 2; }` |

### 使用示例

```nix
unwrapContentValuesForClassification { a = 1; b = 2; }
# → { a = 1; b = 2; }

unwrapContentValuesForClassification {
  __contentValues = [ { nixos.enable = true; } { homeManager.enable = true; } ];
}
# → { nixos.enable = true; homeManager.enable = true; }

unwrapContentValuesForClassification "hello"
# → null
```

### 实现简析

此函数专为 `key-classification.nix` 中的 `isNestedKey` 检测设计。当方面键的值通过 `__contentValues` 包装时，分类系统需要"透视"这个包装来检测内部是否有注册的子键。合并而不是去重保留了所有子键信息。

---

## `applyProvide`

### 签名
```nix
applyProvide :: AttrSet -> AttrSet -> AttrSet
```

### 用途

展开一个 provides 值，通过检测其形状并应用上下文来生成最终输出。这是 provides 处理的核心展开函数。

### 形状检测与处理

| 输入形状 | 处理方式 |
|----------|----------|
| `__fn` attrset | 作为函数调用，传入上下文参数 |
| `__functor` attrset | 作为 functor 调用 |
| 裸函数 | 直接调用，传入上下文 |
| `includes` attrset | 展开 `includes` 中的条目 |
| 普通 attrset | 直接作为值使用 |

### 使用示例

```nix
# __fn 包装
applyProvide
  { __fn = ctx: ctx.host.name; __args = { host = true; }; }
  { host = { name = "igloo"; }; }
# → "igloo"

# 裸函数
applyProvide
  (ctx: { services.nginx.enable = true; })
  { host = { name = "igloo"; }; }
# → { services.nginx.enable = true; }

# includes 属性集
applyProvide
  { includes = [ module1 module2 ]; }
  { }
# → { includes = [ module1 module2 ]; }

# 普通 attrset
applyProvide
  { services.nginx.enable = true; }
  { }
# → { services.nginx.enable = true; }
```

### 实现简析

```nix
applyProvide = ctx: value:
  if builtins.isAttrs value then
    if value ? __fn then value.__fn (ctx // value.__args or { })
    else if value ? __functor then value.__functor ctx
    else if value ? includes then value
    else value
  else if builtins.isFunction value then
    value ctx
  else value;
```

1. attrset 值按形状分派：`__fn` → 函数调用、`__functor` → functor 调用、`includes` → 直接传递、其他 → 原样返回
2. 函数值直接调用上下文
3. 非 attrset 非函数值原样返回

---

## 关联函数

- `key-classification.md` — 键分类系统，使用 `unwrapContentValuesForClassification` 进行子键检测
- `emit-classes.md` — 类发射模块，使用 `unwrapContentValuesList` 展开类模块条目
- `den.lib.aspects.types` — 方面类型系统，`provides` 的处理与 `applyProvide` 联动
- `aspect/provide.nix` — provide 处理，`applyProvide` 是 provides 展开的核心

## 关联文档

- [方面配置指南](../../../04-方面配置指南.md) — provides 和 __contentValues 的概念说明
