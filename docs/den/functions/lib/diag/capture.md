# 跟踪捕获（Trace Capture）

> **⚠️ 移到 `den.lib.capture`**：捕获函数现位于 `den.lib.capture`（`nix/lib/aspects/fx/trace.nix`），不再是独立的 diag 库的一部分。diag 渲染功能已提取到 [`den-diagram`](https://github.com/denful/den-diagram)。

**源文件**: `nix/lib/diag/capture.nix`（已移除，新位置: `nix/lib/aspects/fx/`）

## 概述

收集方面解析过程中的结构化跟踪条目。通过 fx 管道的 `tracingHandler`，框架在执行过程中记录每个步骤的输出，支持后续的图分析和渲染。

---

## capture — 捕获单个类的跟踪

**签名**: `(class: string, root: aspect) → [structuredTraceEntry]`

### 参数说明

| 参数 | 类型 | 说明 |
|------|------|------|
| `class` | `string` | 目标类名（如 `"nixos"`、`"homeManager"`） |
| `root` | `aspect` | 根方面值 |

### 返回值

`structuredTraceEntry` 列表。每个条目包含：名称、类、父节点、提供者路径、排除标记、适配器标记、参数标记等。

### 使用示例

```nix
entries = diag.capture "nixos" rootAspect;
```

### 实现过程

1. 创建 fx 计算：`nxFx.send "resolve" { aspect = root; identity = ...; ctx = {}; }`
2. 用 `tracingHandler` 组合默认处理器
3. 执行计算，收集 `state.entries`

---

## captureAll — 捕获多个类的条目

**签名**: `(classes: [string], root: aspect) → [structuredTraceEntry]`

### 参数说明

| 参数 | 类型 | 说明 |
|------|------|------|
| `classes` | `[string]` | 类名列表 |
| `root` | `aspect` | 根方面值 |

### 返回值

合并后的 `structuredTraceEntry` 列表。同一方面在多个类中的条目会被分别捕获。

### 使用示例

```nix
entries = diag.captureAll ["nixos" "homeManager"] rootAspect;
```

### 实现

```nix
captureAll = classes: root:
lib.concatMap (class: capture class root) classes;
```

---

## captureWithPaths — 带路径集的捕获

**签名**: `(classes: [string], root: aspect) → { entries, pathsByClass, ctxTrace }`

### 返回值

| 字段 | 类型 | 说明 |
|------|------|------|
| `entries` | `[entry]` | 所有类的条目列表 |
| `pathsByClass` | `attrset` | 每个类的路径集 |
| `ctxTrace` | `[ctxItem]` | 上下文跟踪 |

### 使用示例

```nix
result = diag.captureWithPaths ["nixos"] rootAspect;
# result.entries — 跟踪条目
# result.pathsByClass.nixos — 该类的路径集
```

---

## captureWithPathsWith — 带选项的捕获

**签名**: `({ classes, root, ctx?, extraHandlers? }) → { entries, pathsByClass, ctxTrace }`

### 参数说明

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `classes` | `[string]` | — | 类名列表 |
| `root` | `aspect` | — | 根方面 |
| `ctx` | `attrset` | `{}` | 上下文 |
| `extraHandlers` | `attrset` | `{}` | 额外处理器 |

### 使用示例

```nix
result = diag.captureWithPathsWith {
  classes = ["nixos"];
  root = rootAspect;
  ctx = { host = myHost; };
};
```

---

## captureFleet — 舰队级捕获

**签名**: `({ class?, extraHandlers? }) → { entries, ctxTrace, scopeParent, scopeEntityKind, ... }`

### 用途

从 flake 根开始执行完整管道，覆盖整个 flake 作用域树：
`flake → fleet → environment → host → user`

### 参数说明

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `class` | `string` | `"nixos"` | 主类 |
| `extraHandlers` | `attrset` | `{}` | 额外处理器 |

### 返回值

| 字段 | 说明 |
|------|------|
| `entries` | 跟踪条目 |
| `ctxTrace` | 上下文跟踪 |
| `scopeParent` | 作用域父级映射 |
| `scopeContexts` | 作用域上下文 |
| `scopeEntityKind` | 作用域实体类型 |
| `scopedPipeEffects` | 管道效果 |
| `scopedClassImports` | 类导入 |
| `pipeProducers` | 管道生产者 |
| `pipeConsumers` | 管道消费者 |

### 使用示例

```nix
fleetData = diag.captureFleet {};
# 完整的 flake 范围管道跟踪
```

---

## 结构化跟踪条目字段

每个条目包含：

| 字段 | 类型 | 说明 |
|------|------|------|
| `name` | `string` | 方面名称 |
| `class` | `string` | 当前类 |
| `parent` | `nullOr string` | 父方面名称 |
| `provider` | `[string]` | 提供者路径 |
| `excluded` | `bool` | 是否被排除 |
| `excludedFrom` | `nullOr string` | 排除源 |
| `replacedBy` | `nullOr string` | 替换者 |
| `isProvider` | `bool` | 是否是提供者 |
| `handlers` | `[string]` | 处理器列表 |
| `hasClass` | `bool` | 是否有类内容 |
| `isParametric` | `bool` | 是否是参数化方面 |
| `fnArgNames` | `[string]` | 函数参数名 |
| `entityKind` | `nullOr string` | 实体类型 |
| `entityInstance` | `nullOr string` | 实体实例 |

---

## 关联

- **`default.nix`**: 图表库总览
- **`graph.nix`**: 图 IR 构建（消费 capture 输出）
- **`fleet.nix`**: 舰队级捕获（调用本模块的 capture）
- **fx 管道**: `den.lib.aspects.fx.trace.tracingHandler`
