# 图过滤器（Graph Filters）

**源文件**: `nix/lib/diag/filters/`（目录）

## 概述

过滤器对图 IR 进行剪枝和折叠操作。所有过滤器通过 `diag.graph.*` 访问，存在于 `filters/default.nix`（桶文件）中。

---

## closure 家族 — 基于闭包的过滤

**源文件**: `filters/closure.nix`

### classSlice

按类切片：从有 `perClass.<className>.hasClass = true` 的节点开始，包含所有可达祖先。

```nix
nixosOnly = diag.graph.classSlice "nixos" graph;
```

### neighborhoodOf

谓词邻居图：保留匹配谓词的节点及其直接图邻居（一跳）。

```nix
# 保留与谓词匹配的节点及其邻居
neighborhood = diag.graph.neighborhoodOf (n: n.hasClass) graph;
```

### adaptersOnly

仅适配器视图：有处理器的方面及其邻居。

```nix
adapters = diag.graph.adaptersOnly graph;
```

### parametricOnly

仅参数化方面视图。

```nix
parametric = diag.graph.parametricOnly graph;
```

---

## diff — 图差异

**源文件**: `filters/diff.nix`

### diff

合并两个图 A 和 B，在节点和边上标注 `origin` 标签：`"a"`（仅 A）、`"b"`（仅 B）、`"both"`。

```nix
diffGraph = diag.graph.diff {
  a = graphBefore;
  b = graphAfter;
};
# diffGraph.nodes[0].origin == "both" | "a" | "b"
```

---

## fold 家族 — 折叠/重写

**源文件**: `filters/fold.nix`

### foldWrappers

将包装器节点折叠到其子节点中。包装器节点（如 `host`、`default`、`user` 等上下文节点和阶段模式标签）被移除，其父子边重写到子节点。包含环检测。

```nix
folded = diag.graph.foldWrappers graph;
```

可折叠的标签：`host`、`default`、`hm-host`、`hm-user`、`user` 以及 `isWrapper` 标签。

### foldProviders

将提供者子方面折叠到父提供者中。`providerPath = ["p", "sub"]` 的节点如果父提供者存在，则被移除，边重写到父节点。链式折叠（a→b→c 全部折叠到 c）。

```nix
providersFolded = diag.graph.foldProviders graph;
```

### flattenEntityKinds

移除实体类型子图分组，使所有节点渲染为单一平面 DAG。

```nix
flat = diag.graph.flattenEntityKinds graph;
```

---

## predicate 家族 — 谓词过滤

**源文件**: `filters/predicate.nix`

### userDeclaredOnly

仅保留 `hasClass = true` 的节点。剔除管道内部节点。

```nix
userOnly = diag.graph.userDeclaredOnly graph;
```

### pipelineOnly

仅保留包装器/管道节点。隐藏用户方面，显示解析机制。

```nix
pipeline = diag.graph.pipelineOnly graph;
```

### crossClassOnly

仅保留贡献 2+ 类的节点。即跨 nixos + homeManager（或更多）的桥接方面。

```nix
crossClass = diag.graph.crossClassOnly graph;
```

### orphansAndLeaves

孤立节点（无入边，非根）和叶子节点（无出边）。用于发现死代码。

```nix
lint = diag.graph.orphansAndLeaves graph;
```

---

## presence 家族 — 存在性过滤

**源文件**: `filters/presence.nix`

### hasAspectPresent

保留在指定类的路径集中存在的节点。路径集来自 `captureWithPaths`。

```nix
present = diag.graph.hasAspectPresent { class = "nixos"; } graph;
```

### hasAspectPresentWith

使用显式路径集（而非从图 IR 中查找）：

```nix
present = diag.graph.hasAspectPresentWith pathSet graph;
```

### hasAspectForAnyClass

保留在任一指定类的路径集中存在的节点的并集：

```nix
present = diag.graph.hasAspectForAnyClass ["nixos" "homeManager"] graph;
```

---

## reshape 家族 — 结构重写

**源文件**: `filters/reshape.nix`

### contextOnly

将图重写为仅实体类型层次结构。实体类型成为节点，方面内容被丢弃。

```nix
ctxOnly = diag.graph.contextOnly graph;
```

### aspectsOnly

仅保留用户方面，折叠包装器，移除提供者溯源边。

```nix
aspects = diag.graph.aspectsOnly graph;
```

### providersOnly

重写为真正的提供者层次结构树。每个 `providerPath` 节点获得指向其直接父提供者的边。

```nix
providers = diag.graph.providersOnly graph;
```

### decisionsView

分组显示排除节点及其排除源（`excludedFrom`）。适配器所有者显示在排除节点旁。

```nix
decisions = diag.graph.decisionsView graph;
```

### providersResolved

显示每个提供者方面及其解析输出。提供者源通过提供者边链接到其解析子节点。

```nix
resolved = diag.graph.providersResolved graph;
```

---

## default.nix 中的组合过滤器

### filterUserAspects

`foldWrappers + filterMeaningful` 的组合。过滤无意义标签，折叠包装器。

### simplified

`foldProviders + flattenEntityKinds + aspectsOnly` 的组合。最简洁的视图。

### fanMetrics

计算扇入/扇出指标。返回按总连接数排序的记录列表。

```nix
metrics = diag.graph.fanMetrics graph;
# [{ id, label, fullLabel, entityKind, class, fanIn, fanOut, total }]
```

---

## 关联

- **`graph.nix`**: 图 IR 构建（过滤器操作的输入）
- **`default.nix`**: 图表库总览（桶文件）
- 各渲染器消费过滤后的图 IR
