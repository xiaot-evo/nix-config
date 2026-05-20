# 管道数据组装

**源文件**: `nix/lib/aspects/fx/assemble-pipes.nix`

## 概述

`assemblePipes` 是后处理阶段中在模块包装之前的管道数据组装步骤。它从 `scopedClassImports` 收集弯曲（quirk）条目，应用策略注册的管道效果（过滤、变换、折叠、收集、暴露），并将结果注入到每个作用域的上下文中，以便通过 `wrapClassModule` 传递给类模块。

---

## `assemblePipes`

### 签名
```nix
assemblePipes : {
  scopeContexts :: AttrSet ScopeId Context,
  scopedClassImports :: AttrSet ScopeId (AttrSet ClassName [Entry]),
  scopedPipeEffects ? :: AttrSet ScopeId [PipeEffect],
  scopeParent ? :: AttrSet ScopeId ScopeId,
  scopeEntityKind ? :: AttrSet ScopeId String,
  hostConfigs ? :: AttrSet ScopeId Config
} -> AttrSet ScopeId Context
```

### 用途
为每个作用域组装完整的管道承载上下文。将弯曲数据（来自 `den.quirks` 注册的键）和处理后的效果合并到作用域上下文中。

### 返回
```nix
{
  "host=igloo" = {
    host = ...;
    user = ...;
    pkgs = ...;
    # ← 弯曲数据注入如下：
    myPipe = [ value1, value2, ... ];
    # ← 定向覆盖：
    __pipeTargeted = {
      "aspect/name" = { myPipe = [ ... ]; };
    };
    # ← 配置 thunk 标记：
    __pipeConfigThunks = { myPipe = true; };
  };
  ...
}
```

---

## 管道效果阶段类型

| 阶段 | 键 | 说明 |
|------|-----|------|
| `filter` | `__pipeStage = "filter"` | 按谓词过滤值 |
| `transform` | `__pipeStage = "transform"` | 变换每个值 |
| `fold` | `__pipeStage = "fold"` | 折叠为单个值（带 init） |
| `append` | `__pipeStage = "append"` | 追加静态值 |
| `for` | `__pipeStage = "for"` | 自定义函数作用在值列表上 |
| `collect` | `__pipeStage = "collect"` | 从同级作用域收集值 |
| `withProvenance` | `__pipeStage = "withProvenance"` | 将值标记为带有来源信息 |
| `to` | `__pipeStage = "to"` | 路由到特定方面（定向） |
| `as` | `__pipeStage = "as"` | 重命名管道 |
| `expose` | `__pipeStage = "expose"` | 向上暴露到父作用域 |

---

## 主要阶段

### `collect` — 收集

从匹配谓词的同级作用域收集弯曲值：

```nix
collectFromPeers = {
  scopeContexts, scopeParent, scopeEntityKind,
  scopedClassImports, currentScopeId, pipeName, hostConfigs
} predicate:
  ...
```

- 使用 `findMatchingSiblings` 找到共享相同父作用域的同级
- 收集它们对该管道的弯曲条目
- 解析配置依赖的 thunk（当 `hostConfigs` 可用时）

### `transform` — 变换

对每个值应用变换函数：

```nix
applyStage = values: stage:
  if stage.__pipeStage == "transform" then
    map (v: if v ? __configThunk then v else stage.fn v) values
```

配置 thunk 在变换过程中被保留——它们稍后在 `wrapClassModule` 内部解决。

### `expose` — 暴露

将管道值从子作用域向上暴露到父作用域。在所有子作用域处理完后，以自底向上的顺序收集：

```nix
collectAllExposed = { scopeContexts, scopedClassImports, scopedPipeEffects, scopeParent }:
  let
    processTree = exposedPool: scopeId:
      let
        children = childrenOf scopeId;
        afterChildren = builtins.foldl' processTree exposedPool children;
        # 收集此作用域的 expose 效果
        exposeEffects = ...;
      in
      # 处理并将结果放入父作用域的暴露池中
      afterChildren // { ${parentId} = ...; };
  in
  builtins.foldl' processTree { } rootScopes;
```

---

## 值解析

### 管道参数值

`isPipelineParametric` 检测需要管道上下文（如 `host`、`user`）但不需要 `config` 的函数。这些在 `assemblePipes` 期间被急切地解决：

```nix
resolveLocalParametric = scopeCtx: val:
  if isPipelineParametric val then
    let
      thunkArgs = builtins.functionArgs val;
      ctxArgs = lib.genAttrs
        (builtins.filter (k: scopeCtx ? ${k}) (builtins.attrNames thunkArgs))
        (k: scopeCtx.${k});
      result = val (ctxArgs // { inherit lib; });
    in
    if builtins.isList result then result else [ result ]
  else [ val ];
```

### 配置依赖值

`isConfigDependent` 检测需要 `config` 参数的函数。这些被包装为 thunk，稍后在 `wrapClassModule` 内部解决：

```nix
isConfigDependent = val: builtins.isFunction val && (builtins.functionArgs val) ? config;

markConfigThunk = v:
  if isConfigDependent v then
    { __configThunk = true; __fn = v; }
  else v;
```

### 跨主机解析

`resolveEntry` 处理跨主机收集的值，使用目标主机的实例化配置：

```nix
resolveEntry = hostConfigs: scopeContexts: sourceScopeId: entry:
  if isConfigDependent entry then
    let
      result = entry (ctxArgs // { config = hostConfigs.${sourceScopeId} or { }; inherit lib; });
    in ...
  else if isPipelineParametric entry then
    ...  # 使用作用域上下文急切地解决
  else [ entry ];
```

---

## 效果应用

### `applyPipeEffects`

对一个管道的基值应用未定向的管道效果。多个效果并发生成，结果被连接：

```nix
applyPipeEffects = { ... }: pipeName: scopeId: baseValues: effects:
  let
    forEffects = builtins.filter (e: hasForStage e) effects;
    # pipe.for 唯一性验证（最多一个）
    ...
  in
  if forCount == 1 then
    applyStages baseValues (forEffects.stages)
  else
    lib.concatLists (map (e: applyStages baseValues (e.stages)) effects);
```

### `buildTargetedData`

从定向效果构建按方面分开的管道数据。使用 `pipe.to` 阶段的目标方面身份键：

```nix
buildTargetedData = { ... }: baseValues: effects:
  let
    pairs = lib.concatMap (effect:
      let
        targets = getToTargets effect;  # 从 pipe.to 阶段提取
        transformed = applyEffectStages { ... } baseValues (effect.stages);
      in map (name: { name; values = transformed; }) targets
    ) effects;
  in
  # 按方面名称分组
  builtins.foldl' (acc: entry:
    acc // { ${entry.name} = (acc.${entry.name} or []) ++ entry.values; }
  ) { } pairs;
```

---

## `pipe.as` 重命名

`pipe.as` 效果允许将管道数据从一个管道名称重命名到另一个管道名称。这为策略提供了数据路由的灵活性：

```nix
# 查找从其他管道重命名到此管道的效果
asInbound = builtins.filter (e:
  hasAsStage e && !hasToStage e && !hasExposeStage e
  && getAsTarget e == pipeName && e.pipeName != pipeName
) scopeEffects;

# 针对源管道的基值处理
asResults = lib.concatMap (e:
  let combinedSrc = mkCombinedBase e.pipeName; in
  applyEffectStages { ... } combinedSrc (stripAsStage (e.stages))
) asInbound;
```

`pipe.as` 不能自引用——这会被检测并抛出错误：

```nix
assertNoSelfAs = effect:
  let target = getAsTarget effect; in
  if target != null && target == effect.pipeName then
    throw "den: pipe.as targets its own pipe '${effect.pipeName}' — this is a no-op that silently drops data. Remove the pipe.as stage or target a different pipe."
  else true;
```

---

## 完整示例

```nix
# 假设如下注册：
# den.quirks.myPipe = {};

# 作用域 "host=igloo" 有弯曲条目：
scopedClassImports."host=igloo".myPipe = [
  { module = { addr = "10.0.0.1"; }; __isPipeEntry = true; }
  { module = { addr = "10.0.0.2"; }; __isPipeEntry = true; }
];

# 策略注册效果：
scopedPipeEffects."host=igloo" = [
  {
    pipeName = "myPipe";
    stages = [
      { __pipeStage = "filter"; fn = v: v.addr != "10.0.0.1"; }
      { __pipeStage = "transform"; fn = v: v // { resolved = true; }; }
    ];
    __pipePolicyName = "my-filter-policy";
  }
];

# assemblePipes 结果：
# "host=igloo" 上下文获得：
# myPipe = [ { addr = "10.0.0.2"; resolved = true; } ];
```

---

## 关联函数

- `fx.resolve` — 后处理组装阶段，assemblePipes 在其中被调用
- `fx.class-module` / `wrapClassModule` — 管道数据组装后，类模块通过 wrapClassModule 接收上下文
- `fx.pipeline` — 管道编排器，assemblePipes 是管道执行后的关键步骤
- `fx.key-classification` — 键分类决定哪些键被收集为管道条目
- `fx.identity` — 身份路径用于管道路由和定向数据

## 关联文档

- [管道与 Quirks](../../../08-管道与quirks.md) — 管道数据流的概念说明和使用场景
- [方面配置指南](../../../04-方面配置指南.md) — 方面中的怪癖（quirk）数据声明
