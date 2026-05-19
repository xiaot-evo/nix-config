# Graphviz DOT 渲染器

**源文件**: `nix/lib/diag/dot.nix`

## 概述

将格式无关的图 IR 渲染为 Graphviz DOT 有向图字符串。所有颜色来自主题记录，渲染时的配置（非 IR 级别）。

---

## toDotWith — 带主题配置的 DOT 渲染

**签名**: `({ theme? }) → (graph: graphIR) → string`

### 参数说明

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `theme` | `theme` | `themes.defaultTheme` | Base16 派生主题 |

### 使用示例

```nix
# 带主题
dotString = diag.toDotWith { inherit theme; } graph;

# 默认主题
dotString = diag.toDot graph;
```

---

## toDot — 默认配置的 DOT 渲染

**签名**: `(graph: graphIR) → string`

简便调用，使用默认主题：

```nix
dotString = diag.toDot graph;
```

---

## 输出特点

### 图形设置

```dot
digraph {
  rankdir=LR;
  bgcolor="<theme.background>";
  color="<theme.foreground>";
  fontcolor="<theme.foreground>";
  node [style=filled, fillcolor="<theme.nodeBg>", ...];
  edge [color="<theme.edgeColor>", ...];
  <rootId> [label="<rootName>", shape=box, style="rounded,filled", ...];
  ...
}
```

### 节点形状

| IR 形状 | DOT 形状 |
|---------|----------|
| `rect` | `box` |
| `hexagon` | `hexagon` |
| `trapezoid` | `trapezium` |

### 边样式

| 样式 | DOT 表示 |
|------|----------|
| `normal` | `->` |
| `excluded` | `-> [style=dashed, color=excludedStroke]` |
| `replaced` | `-> [style=dashed, color=replacedStroke, label="replaced"]` |

### 实体类型子图

使用 `subgraph cluster_*` 实现：

```dot
subgraph cluster_ctx_host {
  label="host { hostName, system }";
  style=dashed;
  color="<theme.clusterBorder>";
  ...
}
```

### 参数化方面标签

```
nodeLabel\n({ fnArgNames })
```

---

## 与 Mermaid 的区别

| 特性 | DOT | Mermaid |
|------|-----|---------|
| 方向 | `rankdir=LR\|TB` | `graph LR\|TD` |
| 子图 | `subgraph cluster_*` | `subgraph *` |
| 主题 | 无前导元数据 | YAML frontmatter |
| 实体转换边 | 不支持（DOT 限制） | 支持实体子图间边 |

DOT 渲染器不发出实体转换边，因为 DOT 无法使用 cluster 名称作为边端点（除非使用 `lhead`/`ltail` 锚点技巧）。

---

## 关联

- **`mermaid.nix`**: Mermaid 渲染器（类似但更丰富的输出）
- **`plantuml.nix`**: PlantUML 渲染器
- **`render-util.nix`**: 共享渲染工具
- **`themes.nix`**: 主题定义
