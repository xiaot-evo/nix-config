# trace 模块

**源文件**: `nix/lib/aspects/fx/trace.nix`

## 概述

跟踪处理程序集合。提供两个层次的 FX 管道跟踪能力：`structuredTraceHandler`（最小跟踪——仅记录解析完成事件）和 `tracingHandler`（完整跟踪——记录解析、编译、类发射、管道效果注册和策略触发）。这些处理程序通过 `mkPipeline` 的 `extraHandlers` 参数接入，用于诊断、图表生成和调试。

______________________________________________________________________

## `structuredTraceHandler`

### 签名

```nix
structuredTraceHandler :: String -> Handler
```

### 用途

最小跟踪处理程序。累积解析完成事件的条目，不进行消歧。用于轻量级诊断和构建基础跟踪数据集。以 class 名为参数创建处理程序。

### 捕获的事件

| 效果键 | 事件 | 记录内容 |
|--------|------|----------|
| `resolve-complete` | 方面解析完成 | name、parent、entityKind、provider、excluded 等 |

### 条目结构

通过 `mkBaseEntry` 构建，每个条目包含 `class`、`provider`、`excluded`、`excludedFrom`、`replacedBy`、`isProvider`、`handlers`、`hasClass`、`isParametric`、`fnArgNames`，再加上处理程序添加的 `name`、`parent`、`entityKind`：

```nix
{
  name = "<anon>";
  parent = null;        # 或父作用域路径
  entityKind = "host";
  provider = [ "namespace" "aspects" "entity" ];
  excluded = false;
  class = "nixos";
  isProvider = true;
  hasClass = true;
}
```

### 使用示例

```nix
# 在管道中启用结构化跟踪
let
  pipeline = den.lib.aspects.fx.pipeline.mkPipeline {
    class = "nixos";
    extraHandlers = den.lib.aspects.fx.trace.structuredTraceHandler "nixos";
  };
  result = pipeline { self = myAspect; ctx = { }; };
in
result.state.entries
# → [ { name = "igloo"; entityKind = "host"; ... } ]
```

______________________________________________________________________

## `tracingHandler`

### 签名

```nix
tracingHandler :: String -> Handler
```

### 用途

完整跟踪处理程序。捕获管道执行期间的所有关键事件，包括解析、编译、管道效果注册和策略触发。对匿名条目使用实体类型标签进行消歧。以 class 名为参数创建处理程序。

### 捕获的事件

| 效果键 | 事件 | 记录内容 |
|--------|------|----------|
| `resolve` | 开始解析 | 将 entityKind 写入 entityKindMap |
| `resolve-complete` | 解析完成 | 名称、entityKind、entityInstance、父作用域、ctxTrace |
| `emit-class` | 管道类发射 | pipeName、aspectIdentity、scope（仅管道条目） |
| `register-pipe-effect` | 管道效果注册 | pipeName、hasCollect、stageTypes、scope |
| `record-fired` | 策略触发 | 策略名称、entityKind、entityInstance |

> 注意：模块内容的实际收集由 `class-collector` 处理程序的 `emit-class` 效果完成，而非 tracingHandler。

### 匿名条目消歧

当实体没有显式名称时，`tracingHandler` 使用以下消歧逻辑：

```nix
name =
  if isAnon && constraintOwner != null then "filter:${constraintOwner}"
  else if isAnon && entityKind != null then
    "${entityKind}/resolve${aspectTag}:${provTag}"
  else if isAnon && sourcePolicyName != null then "policy:${sourcePolicyName}"
  else if isParametricAnon then "<parametric:{${fnArgs}}>"
  else rawName;
```

这使得即使匿名条目也能在跟踪输出中区分。

> `resolveEntityName` 实际实现仅通过 `scopeCtx.${ek}.name or ek` 解析实体名称，不涉及消歧逻辑。消歧完全在上述 `name` 绑定中处理。

### 条目结构

```nix
{
  # resolve-complete 条目（由 mkBaseEntry 构建）
  name = "igloo";
  parent = "__unscoped";
  entityKind = "host";
  entityInstance = "host:igloo";
  class = "nixos";
  provider = [ "den" "aspects" "igloo" ];
  excluded = false;
  isProvider = true;
  hasClass = true;
}
```

此外，状态中独立维护：

- `state.pipeProducers` — `emit-class` 管道条目：`{ pipeName, aspectIdentity, scope }`
- `state.pipeConsumers` — `register-pipe-effect` 条目：`{ pipeName, hasCollect, scope, stageTypes }`
- `state.ctxTrace` — 按 entityKind 去重的上下文条目：`{ key, selfName, entityKind, ctxKeys }`

### 使用示例

```nix
# 启用完整跟踪进行调试
let
  pipeline = den.lib.aspects.fx.pipeline.mkPipeline {
    class = "nixos";
    extraHandlers = den.lib.aspects.fx.trace.tracingHandler "nixos";
  };
  result = pipeline { self = myAspect; ctx = { }; };
in
result.state.entries
# → 包含所有解析、注册和触发事件的完整跟踪
```

______________________________________________________________________

## `deriveEntityKind`

### 签名

```nix
deriveEntityKind :: State -> (String | Null)
```

### 用途

从管道状态的 `scopedIncludesChain` 中推导实体类型。在 entityKindMap 中查找祖先的 entityKind，回退到扫描已有 entries。

### 实现简析

1. 从 `state.scopedIncludesChain` 中获取当前作用域的包含链
1. 对链中每个身份：先查 `entityKindMap`，再在 entries 中按 `e.path or e.name` 匹配
1. 返回链中第一个非空 entityKind（从叶子向上）

______________________________________________________________________

## `chainParent`

### 签名

```nix
chainParent :: [String] -> String -> (String | Null)
```

### 用途

在包含链（includes chain）中找到最近的"有意义的"祖先作用域。跳过 selfPath 本身和匿名中间节点。

### 实现简析

1. 过滤掉 selfPath（避免自引用）
1. 在剩余条目中查找有意义名称（通过 `isMeaningfulName`）且不含 `<anon>` 的
1. 如有，返回最后一个（最近的）；如无，返回最后一个非 self 的；否则返回 `null`

______________________________________________________________________

## `mkBaseEntry`

### 签名

```nix
mkBaseEntry :: String -> Param -> TraceEntry
```

### 用途

创建共享的跟踪条目基础结构。从 `param.meta` 中提取所有跟踪条目共用的字段，而非接收独立参数。

### 字段来源

| 字段 | 来源 |
|------|------|
| `class` | `class` 参数 |
| `provider` | `param.meta.provider or [ ]` |
| `excluded` | `param.meta.excluded or false` |
| `excludedFrom` | `param.meta.excludedFrom or null` |
| `replacedBy` | `param.meta.replacedBy or null` |
| `isProvider` | `(param.meta.provider or [ ]) != [ ]` |
| `handlers` | `param.meta.handleWith or [ ]` |
| `hasClass` | `param ? ${class}` |
| `isParametric` | `param.meta.isParametric or false` |
| `fnArgNames` | `param.meta.fnArgNames or [ ]` |

### 使用示例

```nix
mkBaseEntry "nixos" {
  meta = {
    provider = [ "den" "aspects" "igloo" ];
    excluded = false;
  };
}
# → { class = "nixos"; provider = [ "den" "aspects" "igloo" ]; excluded = false; ... }
```

______________________________________________________________________

## 实现简析

### 处理程序结构

两个跟踪处理程序都遵循标准 FX 处理程序签名：

```nix
{ param, state } -> { resume :: Any, state :: State }
```

状态中包含 `entries` 字段，以列表形式累积跟踪条目。

### `structuredTraceHandler` vs `tracingHandler`

| 特性 | structuredTraceHandler | tracingHandler |
|------|----------------------|----------------|
| 捕获事件数 | 1（resolve-complete） | 5（resolve、resolve-complete、emit-class、register-pipe-effect、record-fired） |
| 匿名消歧 | 无 | entityKind 标签消歧 |
| 管道效果追踪 | 无 | 记录 pipeProducers/pipeConsumers |
| 策略触发记录 | 无 | 记录 policyDispatch 条目 |
| 适用场景 | 轻量诊断、基础图 | 完整调试、图表生成 |

### 状态结构

```nix
{
  entries = [ entry1 entry2 ... ];
}
```

每次事件触发时，将新条目追加到 `entries` 列表中。

______________________________________________________________________

## 关联函数

- `pipeline.md` — 管道编排器，跟踪处理程序通过 `extraHandlers` 参数接入
- `aspects/has-aspect.md` — has-aspect 检测，与跟踪的诊断用途相关
- `den.lib.diag` — 诊断库，使用跟踪数据进行图表生成和调试

## 关联文档

- [高级主题](../../../11-%E9%AB%98%E7%BA%A7%E4%B8%BB%E9%A2%98.md) — 代数效果管道的调试和诊断
- [管道与 Quirks](../../../08-%E7%AE%A1%E9%81%93%E4%B8%8Equirks.md) — 管道执行流程的完整说明
