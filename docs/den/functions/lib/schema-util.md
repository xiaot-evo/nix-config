# schemaUtil 模块

**源文件**: `nix/lib/schema-util.nix`

## 概述

模式（Schema）工具函数。提供实体类型的分类信息——哪些 schema 键被视为实体，哪些是参数键等。

______________________________________________________________________

## den.lib.schemaUtil.schemaEntityKinds

**签名**: `(implicit: config 驱动) → [string]`

### 用途

返回所有实体类型的键名称列表。实体是带有 `isEntity = true` 标记的 schema 条目。

### 过滤规则

排除了以下类型的 schema 键：

- `"conf"` — 配置项
- 以 `_` 开头的私有键
- `den.schema.${k}.isEntity` 不为 `true` 的条目

### 返回值说明

字符串列表，如 `["host", "user", "home", "default"]`。

### 使用示例

```nix
den.lib.schemaUtil.schemaEntityKinds
# → ["host", "user", "home", ...]
```

______________________________________________________________________

## den.lib.schemaUtil.schemaEntityKindsSet

**签名**: `(自动计算) → attrset`

将 `schemaEntityKinds` 转为 attrset 用于快速查询：

```nix
{ host = true; user = true; home = true; ... }
```

______________________________________________________________________

## den.lib.schemaUtil.schemaArgKinds

**签名**: `(自动计算) → [string]`

所有类 schema 的参数名（排除了 `conf`、`aspect` 和私有键），**不要求** `isEntity` 标记。这用于 `class-module.nix` 中的警告检测——检查类模块函数是否缺少 den 参数。

### 返回值说明

字符串列表，比 `schemaEntityKinds` 更宽松。

______________________________________________________________________

## 使用示例

```nix
# 在 resolve-entity.nix 中用于决定哪些实体类型获得自提供
let
  aspectKinds = builtins.filter (k: k != "default") den.lib.schemaUtil.schemaEntityKinds;
  aspectKindSet = lib.genAttrs aspectKinds (_: true);
in
# ...

# 在 policy-inspect.nix 中用于推断 resolve 效果的目标类型
let
  targetKey = lib.findFirst (k: builtins.elem k schemaKinds) "host" newKeys;
in
# ...
```

______________________________________________________________________

## 关联函数

- `den.lib.resolveEntity` — 使用 `schemaEntityKinds` 确定哪些类型获得自提供
- `den.lib.policyInspect.inspect` — 使用 `schemaEntityKinds` 推断目标类型
