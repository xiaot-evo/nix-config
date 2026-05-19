# trace 模块

**源文件**: `nix/lib/aspects/fx/trace.nix`

## 概述

跟踪处理程序集合。提供两个层次的 FX 管道跟踪能力：`structuredTraceHandler`（最小跟踪——仅记录解析完成事件）和 `tracingHandler`（完整跟踪——记录解析、编译、类发射、管道效果注册和策略触发）。这些处理程序通过 `mkPipeline` 的 `extraHandlers` 参数接入，用于诊断、图表生成和调试。

---

## `structuredTraceHandler`

### 签名
```nix
structuredTraceHandler :: Handler
```

### 用途

最小跟踪处理程序。累积解析完成事件的条目，不进行消歧。用于轻量级诊断和构建基础跟踪数据集。

### 捕获的事件

| 效果键 | 事件 | 记录内容 |
|--------|------|----------|
| `resolve-complete` | 方面解析完成 | name、parent、entityKind、provider、excluded 状态 |

### 条目结构

每个跟踪条目包含：
```nix
{
  name = "entity-name";
  parent = "parent-scope-id";
  entityKind = "host" | "user" | "home" | ...;
  provider = [ "namespace" "aspects" "entity" ];
  excluded = false;
}
```

### 使用示例

```nix
# 在管道中启用结构化跟踪
let
  pipeline = den.lib.aspects.fx.pipeline.mkPipeline {
    class = "nixos";
    extraHandlers = {
      trace = den.lib.aspects.fx.trace.structuredTraceHandler;
    };
  };
  result = pipeline { self = myAspect; ctx = { }; };
in
result.state.scopedTrace
# → { scope-id = [ { name = "igloo"; entityKind = "host"; ... } ... ] }
```

---

## `tracingHandler`

### 签名
```nix
tracingHandler :: Handler
```

### 用途

完整跟踪处理程序。捕获管道执行期间的所有关键事件，包括解析、编译、类发射、管道效果注册和策略触发。对匿名条目使用实体类型标签进行消歧。

### 捕获的事件

| 效果键 | 事件 | 记录内容 |
|--------|------|----------|
| `resolve` | 开始解析 | 方面、身份、上下文、门控状态 |
| `resolve-complete` | 解析完成 | 名称、父作用域、实体类型、提供者、排除状态 |
| `emit-class` | 类模块发射 | 类名、模块内容 |
| `register-pipe-effect` | 管道效果注册 | 提供者/消费者信息 |
| `record-fired` | 策略触发 | 策略名称、触发上下文 |

### 匿名条目消歧

当实体没有显式名称时，`tracingHandler` 使用 `entityKind/resolve(aspect):provider` 格式生成消歧标签：

```nix
resolveEntityName = scopeContext: scopeContext.${entityKind}.name or (
  "${entityKind}/resolve(aspect):${formatProviders provider}"
);
```

这使得即使匿名条目也能在跟踪输出中区分。

### 条目结构

```nix
{
  # resolve-complete 条目
  name = "igloo";
  parent = "__unscoped";
  entityKind = "host";
  provider = [ "den" "aspects" "igloo" ];
  excluded = false;
  
  # 额外的 tracingHandler 字段
  producers = [ 1 2 3 ];     # 管道效果生产者
  consumers = [ 4 5 ];        # 管道效果消费者
  firedPolicies = [           # 已触发的策略
    { name = "myPolicy"; scope = "scope-id"; ... }
  ];
}
```

### 使用示例

```nix
# 启用完整跟踪进行调试
let
  pipeline = den.lib.aspects.fx.pipeline.mkPipeline {
    class = "nixos";
    extraHandlers = {
      trace = den.lib.aspects.fx.trace.tracingHandler;
    };
  };
  result = pipeline { self = myAspect; ctx = { }; };
in
result.state.scopedTrace
# → 包含所有解析、发射、注册和触发事件的完整跟踪
```

---

## `deriveEntityKind`

### 签名
```nix
deriveEntityKind :: AttrSet -> (String | Null)
```

### 用途

从方面条目的 `includes` 链中推导实体类型。遍历 includes 链并查找 `__entityKind` 标记。

### 实现简析

1. 检查条目本身是否有 `__entityKind`
2. 如果没有，遍历 `includes` 链
3. 对每个 include 递归调用 `deriveEntityKind`
4. 找到的第一个非空 `__entityKind` 即为结果

---

## `chainParent`

### 签名
```nix
chainParent :: AttrSet -> (String | Null)
```

### 用途

在包含链（includes chain）中找到最近的"有意义的"祖先作用域。跳过中间作用域，返回最近的具名祖先。

### 实现简析

1. 从当前条目开始，沿 `includes` 链向上查找
2. 对每个祖先，检查是否有可见的名称（`name` 属性）
3. 返回第一个有名称的祖先的 ID；如果没有，返回 `null`

---

## `mkBaseEntry`

### 签名
```nix
mkBaseEntry :: {
  name        :: String,
  parent      :: String,
  entityKind  :: String,
  provider    :: [String],
  excluded    :: Bool
} -> TraceEntry
```

### 用途

创建共享的跟踪条目基础结构。所有跟踪条目（无论来自哪个处理程序）共用的字段在此构建。

### 使用示例

```nix
mkBaseEntry {
  name = "igloo";
  parent = "__unscoped";
  entityKind = "host";
  provider = [ "den" "aspects" "igloo" ];
  excluded = false;
}
# → { name = "igloo"; parent = "__unscoped"; entityKind = "host"; ... }
```

---

## 实现简析

### 处理程序结构

两个跟踪处理程序都遵循标准 FX 处理程序签名：
```nix
{ param, state } -> { resume :: Any, state :: State }
```

状态中包含 `scopedTrace` 字段，按作用域 ID 累积跟踪条目。

### `structuredTraceHandler` vs `tracingHandler`

| 特性 | structuredTraceHandler | tracingHandler |
|------|----------------------|----------------|
| 捕获事件数 | 1（resolve-complete） | 5（resolve、resolve-complete、emit-class、register-pipe-effect、record-fired） |
| 匿名消歧 | 无 | entityKind 标签消歧 |
| 管道效果追踪 | 无 | 记录生产者/消费者 |
| 策略触发记录 | 无 | 记录触发策略 |
| 适用场景 | 轻量诊断、基础图 | 完整调试、图表生成 |

### 状态结构

```nix
{
  scopedTrace = {
    scope-id = [ entries ];
  };
}
```

每次事件触发时，将新条目追加到当前作用域的 `scopedTrace` 列表中。

---

## 关联函数

- `pipeline.md` — 管道编排器，跟踪处理程序通过 `extraHandlers` 参数接入
- `aspects/has-aspect.md` — has-aspect 检测，与跟踪的诊断用途相关
- `den.lib.diag` — 诊断库，使用跟踪数据进行图表生成和调试

## 关联文档

- [高级主题](../../../11-高级主题.md) — 代数效果管道的调试和诊断
- [管道与 Quirks](../../../08-管道与quirks.md) — 管道执行流程的完整说明
