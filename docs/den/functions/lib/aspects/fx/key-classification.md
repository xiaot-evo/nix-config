# 键分类系统

**源文件**: `nix/lib/aspects/fx/key-classification.nix`

## 概述

键分类系统决定了方面 attrset 中每个非结构键的去向。当方面通过管道编译时，其键被分为三个类别：类键、嵌套键和管道键。这个分类决定了方面内容如何传递给下游消费者。

---

## `classifyKeys`

### 签名
```nix
classifyKeys : targetClass :: StringOrNull -> Aspect -> {
  classKeys :: [String],
  nestedKeys :: [String],
  pipeKeys :: [String],
  unregisteredClassKeys :: [String]
}
```

### 用途
将方面 attrset 中的键分为三类。这是管道中 `classify` 效果的核心逻辑。

### 分类算法

```
1. 过滤结构键和转发的 provides（pre-filter）
2. 如果注册表为空 → 所有键都是类键（向后兼容）
3. 否则：
   管道键 = 匹配 pipeRegistry (den.quirks)
   类键 = 匹配 classRegistry (den.classes) 或 == targetClass
   其余部分 = 在嵌套键和未注册类键之间分割
```

### 注册表
- **`classRegistry`**：`den.classes or {}`——注册的类名（如 `nixos`、`darwin`、`homeManager`）
- **`pipeRegistry`**：`den.quirks or {}`——注册的管道键（弯曲输出桶）

### 示例
```nix
# 给定 den.classes = { nixos = {...}; homeManager = {...}; }
# den.quirks = { myPipe = {...}; }

classifyKeys "nixos" {
  nixos = { ... };        # → classKeys (匹配类注册表)
  homeManager = { ... };  # → classKeys (匹配类注册表)
  myPipe = "data";         # → pipeKeys (匹配管道注册表)
  nested = {               # → nestedKeys (包含子方面)
    nixos = { ... };
  };
  someKey = "plain";      # → unregisteredClassKeys (不是类也不是嵌套)
}
```

---

## `structuralKeysSet`

### 定义
```nix
structuralKeysSet = lib.genAttrs [
  "name" "description" "meta" "includes" "excludes"
  "provides" "policies" "into" "classes"
  "__fn" "__args" "__functor" "__functionArgs"
  "__scopeHandlers" "__ctxId" "__entityKind"
  "__parametricResolvedArgs"
  "__contentValues" "__provider" "__providesForwarded"
  "_module" "_"
] (_: true);
```

这些键由管道本身处理，永远不会被分派为类或嵌套键。

---

## 嵌套键检测

### `looksLikeClassContent`
```nix
looksLikeClassContent = v:
  lib.isFunction v
  || (builtins.isAttrs v && v ? __contentValues)
  || (builtins.isAttrs v && builtins.any
    (k: builtins.isAttrs v.${k} || lib.isFunction v.${k})
    (builtins.attrNames v));
```

确定一个值是否"像类内容"（模块或配置 attrset）而不是纯数据。拒绝恰好位于注册类名下的扁平标量 attrset。

### `hasRecognizedSubKeys`
```nix
hasRecognizedSubKeys = depth: val:
  builtins.isAttrs val
  && builtins.any (sk:
    (classRegistry ? ${sk} && looksLikeClassContent val.${sk})
    || (depth > 0 && builtins.isAttrs (val.${sk} or null)
      && hasRecognizedSubKeys (depth - 1) val.${sk})
  ) (builtins.attrNames val);
```

递归检查（深度最多 3 层）值是否包含任何注册的类键作为子键。

### `isNestedKey`
```nix
isNestedKey = aspect: k:
  hasRecognizedSubKeys 3 (
    den.lib.aspects.fx.contentUtil.unwrapContentValuesForClassification aspect.${k}
  );
```

如果键的值（在通过 `__contentValues` 展开后）包含深度最多 3 层的注册类子键，则该键被视为嵌套键。

---

## 分类输出结构

```nix
{
  classKeys = [ "nixos" "homeManager" ];    # → 直接发射为类模块
  nestedKeys = [ "features" "roles" ];       # → 在 compile-static 中标记但不会自动遍历
  pipeKeys = [ "myPipe" ];                    # → 作为管道条目发射（非类模块包装）
  unregisteredClassKeys = [ "other" ];       # → 作为类键发射（警告：未注册）
}
```

---

## 键分类如何决定方面内容的去向

```
方面 attrset
     │
     ├── 结构键 ──→ 管道内部处理
     │
     ├── __providesForwarded ──→ 跳过（由 mergeWithAspectMeta 转发）
     │
     ├── 管道键 ──→ emit-classes → 作为 __isPipeEntry 条目收集
     │                  → assemblePipes 处理
     │                  → 不通过 wrapClassModule
     │
     ├── 类键 ──→ emit-classes → 作为 __rawEntry 类模块收集
     │                  → wrapClassModule（碰撞处理、上下文注入）
     │                  → 最终导入
     │
     └── 剩余键
              ├── 嵌套键 ──→ 在 compile-static 中标记
              │        → 不会被自动遍历（必须显式 include）
              │
              └── 未注册类键 ──→ 作为类键发射（保守做法）
```

---

## `pipeRegistry`

从 `den.quirks` 直接导出，供 `assemblePipes.nix` 使用：

```nix
pipeRegistry = den.quirks or { };
```

---

## 与 provides 转发的交互

`mergeWithAspectMeta` 在 `types.nix` 中将 `provides` 的子键转发到方面顶层。`classifyKeys` 过滤掉这些转发的键以避免双重发射：

```nix
forwardedSet = lib.genAttrs (aspect.__providesForwarded or [ ]) (_: true);
allKeys = builtins.filter (k: !(structuralKeysSet ? ${k}) && !(forwardedSet ? ${k})) (...);
```

这确保：
- `aspect.docker`（在顶层）→ 跳过分类（已通过 `provides.docker` 处理）
- `aspect.nixos`（在顶层）→ 分类为类键 → 发射

---

## 关联函数

- `fx.pipeline` — 管道编排器，classify 效果在 compile-static 阶段被调用
- `fx.assemble-pipes` — 管道数据组装，pipeKeys 的条目通过 assemblePipes 处理
- `fx.class-module` — 类模块封装，classKeys 的条目通过 wrapClassModule 处理
- `den.lib.aspects.types` — 方面类型系统，classifyKeys 依赖 classRegistry 和 pipeRegistry
- `den.lib.aspects` — 顶层方面引擎，导出类注册表

## 关联文档

- [方面配置指南](../../../04-方面配置指南.md) — 类键、嵌套键、管道键的概念
- [管道与 Quirks](../../../08-管道与quirks.md) — 管道键（pipeKeys）的分类和应用
