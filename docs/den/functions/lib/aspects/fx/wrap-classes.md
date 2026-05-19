# 后处理封装传递

**源文件**: `nix/lib/aspects/fx/wrap-classes.nix`

## 概述

`wrapCollectedClasses` 是后处理管道中的关键函数，负责将原始类条目（从 `emit-class` 效果收集）转换为最终准备导入的 NixOS 模块。它调用 `wrapClassModule` 并添加模块位置标记、去重键和参数剥离。

---

## `wrapCollectedClasses`

### 签名
```nix
wrapCollectedClasses : Context -> ClassImports -> ClassImports
```

### 用途
在后处理阶段 1 中，为每个作用域包装原始类条目。这是类模块最终组装的核心逻辑。

### 参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `enrichedCtx` | Context | 丰富后的作用域上下文（包括弯曲数据） |
| `classImports` | ClassImports | `{ class → [entries] }` 每个条目要么是原始条目（`__rawEntry = true`），要么是普通模块 |

### 返回
```nix
{
  nixos = [ mod1, mod2, ... ];
  homeManager = [ mod3, ... ];
  ...
}
```

### 分派逻辑

对于每个类中的每个条目：

1. **管道条目**（`__isPipeEntry`）：直接传递，不做包装
2. **非原始条目**（已经是模块）：直接传递
3. **原始条目**：通过 `processEntry` 处理

```nix
wrapCollectedClasses = enrichedCtx: classImports:
  lib.mapAttrs (class: entries:
    lib.concatMap (entry:
      if entry.__isPipeEntry or false then [ entry ]
      else if !(entry.__rawEntry or false) then [ entry ]
      else processEntry enrichedCtx class entry
    ) entries
  ) classImports;
```

---

## `processEntry`（条目处理管道）

### 流程

```
原始条目
  ├── 1. applyPipeTargeting：应用弯曲定向覆盖
  ├── 2. mergeEnrichment：合并充实键（不覆盖已有键）
  ├── 3. wrapClassModule：调用 wrapClassModule（上下文注入 + 碰撞处理）
  ├── 4. stripEnrichmentArgs：去除充实参数（避免 _module.args 探测崩溃）
  ├── 5. computeModuleIdentity：计算模块身份键
  ├── 6. wrapModule：应用位置标记 + 去重键
  └── 7. buildValidatorModule：构建碰撞验证器模块
```

---

## `applyPipeTargeting`

### 签名
```nix
applyPipeTargeting : Context -> Entry -> Context
```

### 用途
将弯曲定向覆盖（来自 `assemblePipes` 的 `__pipeTargeted`）应用于条目的上下文。按完整身份路径键匹配：

```nix
applyPipeTargeting = ctx: entry:
  let
    pipeTargeted = ctx.__pipeTargeted or { };
    entryId = entry.identity or "<anon>";
    baseId = baseIdentityFromEntry entryId;
    overrides = pipeTargeted.${baseId} or { };
  in
  if pipeTargeted == { } || overrides == { } then ctx
  else ctx // overrides;
```

---

## `mergeEnrichment`

### 签名
```nix
mergeEnrichment : Context -> Context -> { enrichmentKeys :: [String], ctx :: Context }
```

### 用途
将充实键合并到条目的上下文中，但**不**覆盖条目已有的键（如 `host`、`user` 等实体绑定）：

```nix
mergeEnrichment = enrichedCtx: entryCtx:
  let
    enrichmentKeys = lib.filterAttrs (k: _: !(entryCtx ? ${k})) enrichedCtx;
  in
  { enrichmentKeys = builtins.attrNames enrichmentKeys; ctx = entryCtx // enrichmentKeys; };
```

---

## `stripEnrichmentArgs`

### 签名
```nix
stripEnrichmentArgs : {
  module :: Module,
  wrapped :: Bool,
  enrichmentOnlyKeys :: [String],
  ctx :: Context
} -> Module
```

### 用途
从模块的 `__functionArgs` 中去除充实专用键。没有这个步骤，NixOS 会为每个广告参数探测 `_module.args.${name}`，当键不存在时崩溃。

### 实现

```nix
stripEnrichmentArgs = { module, wrapped, enrichmentOnlyKeys, ctx }:
  let
    rawFuncArgs = if wrapped then module.__functionArgs else builtins.functionArgs module;
    argsToStrip = if wrapped then enrichmentOnlyKeys
      else builtins.filter (k: rawFuncArgs.${k} or false && !(ctx ? ${k})) (builtins.attrNames rawFuncArgs);
  in
  if argsToStrip == [ ] then module
  else if wrapped then module // { __functionArgs = removeAttrs rawFuncArgs argsToStrip; }
  else lib.setFunctionArgs module (removeAttrs rawFuncArgs argsToStrip);
```

- **已包装的模块**：从 `__functionArgs` attrset 中剥离
- **未包装的函数**：使用 `lib.setFunctionArgs` 剥离

---

## `computeModuleIdentity`

### 签名
```nix
computeModuleIdentity : { entry :: Entry, isContextDependent :: Bool } -> {
  nodeIdentity :: String,
  isAnon :: Bool,
  finalIdentity :: String
}
```

### 实现

```nix
computeModuleIdentity = { entry, isContextDependent }:
  let
    nodeIdentity = entry.identity or "<anon>";
    isAnon = den.lib.aspects.fx.identity.isAnonIdentity nodeIdentity;
    finalIdentity = if isContextDependent then nodeIdentity
      else den.lib.aspects.fx.identity.stripCtxSuffix nodeIdentity;
  in { inherit nodeIdentity isAnon finalIdentity; };
```

- **上下文相关的**条目保留完整的 `{ctxId}` 后缀（如 `"postgres/{host=igloo}"`）
- **上下文无关的**条目剥离后缀以允许跨作用域去重

---

## `wrapModule`

### 签名
```nix
wrapModule : {
  class :: String,
  finalModule :: Module,
  isAnon :: Bool,
  finalIdentity :: String
} -> Module
```

### 实现

```nix
wrapModule = { class, finalModule, isAnon, finalIdentity }:
  let finalLoc = "${class}@${finalIdentity}"; in
  if isAnon then
    lib.setDefaultModuleLocation finalLoc finalModule
  else
    { key = finalLoc; _file = finalLoc; imports = [ finalModule ]; };
```

- **匿名模块**：使用 `lib.setDefaultModuleLocation` 设置默认位置
- **命名模块**：创建具有 `key` 的包装器，以便跨作用域去重可以匹配和消除重复

---

## `buildValidatorModule`

### 签名
```nix
buildValidatorModule : {
  class :: String,
  nodeIdentity :: String,
  result :: WrappedModule
} -> Module
```

### 用途
构建碰撞验证器子模块，当类模块参数与模块系统参数碰撞时发出警告/错误：

```nix
buildValidatorModule = { class, nodeIdentity, result }:
  let
    validatorLoc = "${class}@${nodeIdentity}/<collision-validator>";
    validatorModule = lib.setFunctionArgs result.validator
      (result.validatorAdvertisedArgs or result.advertisedArgs or { });
  in
  lib.setDefaultModuleLocation validatorLoc validatorModule;
```

---

## 完整示例

```nix
# 给定原始条目
{
  __rawEntry = true;
  class = "nixos";
  identity = "igloo/postgres";
  module = { pkgs, lib, ... }: { services.postgresql.enable = true; };
  ctx = { pkgs = ...; lib = ...; inputs = ...; host = ...; };
  aspectPolicy = null;
  globalPolicy = "error";
  isContextDependent = false;
}

# 处理后的结果（processEntry）
{
  key = "nixos@igloo/postgres";
  _file = "nixos@igloo/postgres";
  imports = [
    { pkgs, lib, config, ... }: { services.postgresql.enable = true; }
  ];
}
```

---

## 关联函数

- `fx.class-module` / `wrapClassModule` — 类模块封装的核心实现，wrapClasses 是其上层调度
- `fx.resolve` — 后处理组装阶段，wrapClasses 在 wrapPerScope 中被调用
- `fx.pipeline` — 管道编排器，wrapClasses 作用于管道输出的类导入上
- `fx.identity` — 身份路径用于跨作用域去重

## 关联文档

- [方面配置指南](../../../04-方面配置指南.md) — 类模块的扁平形式说明
- [核心概念](../../../02-核心概念.md) — 类的概念和扁平参数形式
