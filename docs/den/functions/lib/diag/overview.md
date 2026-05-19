# 图表库总览（Diagram Library Overview）

**源文件**: `nix/lib/diag/default.nix`

## 概述

Den 的图表库（diag）是一个可组合的管线，用于将方面解析过程渲染为多种图表格式。支持 Mermaid、Graphviz DOT、PlantUML 和 C4 模型。

架构：

```
trace capture → graph IR → filter → render
   ↓              ↓           ↓        ↓
 capture.nix   graph.nix   filters/  mermaid.nix
                                    dot.nix
                                    plantuml.nix
                                    c4.nix
```

---

## 架构说明

### 1. 跟踪捕获（Trace Capture）

收集方面解析过程中的 `structuredTrace` 条目。框架的 fx 管道在执行过程中将每个步骤的输出记录为结构化条目。

### 2. 图 IR 构建（Graph IR Construction）

将结构化条目转换为格式无关的图中间表示（IR），包含节点、边、实体类型和实体类型转换。

### 3. 过滤（Filtering）

对图 IR 进行缩减和折叠操作：排除无意义节点、折叠包装器节点、按谓词过滤、计算差异等。

### 4. 渲染（Rendering）

将图 IR 输出为特定格式的字符串。每个渲染器接收主题记录和可选的渲染配置。

---

## 快速入门

### 最常见的主机场景

```nix
g = diag.hostContext { inherit host; };
rendered = diag.toMermaid (diag.graph.filterUserAspects g);
```

### 通用形式（任意实体类型）

```nix
root = den.lib.resolveEntity "user" { inherit host user; };
g = diag.context { inherit root; name = user.name; classes = [ "homeManager" ]; };
```

### 管线形式（精细控制）

```nix
root = den.lib.resolveEntity "host" { inherit host; };
entries = diag.captureAll ["nixos" "homeManager"] root;
g = diag.graph.build {
  inherit entries;
  rootName = host.name;
};
```

---

## 渲染器速查表

| 名称 | 格式 | 需要 mermaidConfig | 说明 |
|------|------|-------------------|------|
| `toMermaid` | Mermaid | 是 | 流程图 |
| `toDot` | Graphviz DOT | 否 | 有向图 |
| `toPlantUML` | PlantUML | 否 | UML 图 |
| `toSequenceMermaid` | Mermaid | 是 | 序列图 |
| `toSequenceMermaidExpanded` | Mermaid | 是 | 展开式序列图 |
| `toPolicySequenceMermaid` | Mermaid | 是 | 策略序列图 |
| `toScopeEdgesMermaid` | Mermaid | 是 | 作用域边图 |
| `toSankeyMermaid` | Mermaid | 是 | 桑基图 |
| `toFleetSankeyMermaid` | Mermaid | 是 | 舰队桑基图 |
| `toFanMetricsSankey` | Mermaid | 是 | 扇入/扇出桑基图 |
| `toTreemapMermaid` | Mermaid | 是 | 树图 |
| `toFleetTreemapMermaid` | Mermaid | 是 | 舰队树图 |
| `toFleetProviderMatrix` | Mermaid | 是 | 提供者矩阵 |
| `toC4Component` | PlantUML | 否 | C4 组件图 |
| `toC4Container` | PlantUML | 否 | C4 容器图 |
| `toC4Context` | PlantUML | 否 | C4 上下文图 |
| `toC4ComponentMermaid` | Mermaid | 是 | C4 组件（Mermaid） |
| `toC4ContainerMermaid` | Mermaid | 是 | C4 容器（Mermaid） |
| `toC4ContextMermaid` | Mermaid | 是 | C4 上下文（Mermaid） |
| `toMindmapMermaid` | Mermaid | 是 | 思维导图 |
| `toStateMermaid` | Mermaid | 是 | 状态图 |
| `toPipeFlowMermaid` | Mermaid | 是 | 管道流程图 |
| `toScopeTopologyMermaid` | Mermaid | 是 | 作用域拓扑图 |
| `toAspectMatrixMermaid` | Mermaid | 是 | 方面矩阵图 |
| `toPolicyResolutionMapMermaid` | Mermaid | 是 | 策略解析图 |
| `toPipeSequenceMermaid` | Mermaid | 是 | 管道序列图 |
| `toFleetDagMermaid` | Mermaid | 是 | 舰队 DAG 图 |

---

## 过滤器速查表

| 名称 | 文件 | 说明 |
|------|------|------|
| `closure.classSlice` | `filters/closure.nix` | 按类切片，包含祖先 |
| `closure.neighborhoodOf` | `filters/closure.nix` | 谓词邻居图 |
| `closure.adaptersOnly` | `filters/closure.nix` | 仅适配器 |
| `closure.parametricOnly` | `filters/closure.nix` | 仅参数方面 |
| `diff.diff` | `filters/diff.nix` | 合并两个图，标注 origin |
| `fold.foldWrappers` | `filters/fold.nix` | 折叠包装器节点 |
| `fold.foldProviders` | `filters/fold.nix` | 折叠提供者 |
| `fold.flattenEntityKinds` | `filters/fold.nix` | 展平实体类型 |
| `predicate.userDeclaredOnly` | `filters/predicate.nix` | 仅用户声明 |
| `predicate.pipelineOnly` | `filters/predicate.nix` | 仅管道元 |
| `predicate.crossClassOnly` | `filters/predicate.nix` | 跨类方面 |
| `predicate.orphansAndLeaves` | `filters/predicate.nix` | 孤儿/叶子节点 |
| `presence.hasAspectPresent` | `filters/presence.nix` | hasAspect 存在性 |
| `presence.hasAspectForAnyClass` | `filters/presence.nix` | 任一类的存在性 |
| `reshape.contextOnly` | `filters/reshape.nix` | 仅实体类型上下文 |
| `reshape.aspectsOnly` | `filters/reshape.nix` | 仅用户方面 |
| `reshape.providersOnly` | `filters/reshape.nix` | 仅提供者 |
| `reshape.decisionsView` | `filters/reshape.nix` | 决策视图 |
| `reshape.providersResolved` | `filters/reshape.nix` | 提供者解析视图 |
| `filterUserAspects` | `filters/default.nix` | 折叠 + 过滤无意义 |
| `simplified` | `filters/default.nix` | 简化的折叠 |
| `fanMetrics` | `filters/default.nix` | 扇入/扇出指标 |

---

## 主题系统

图表库使用基于 Base16 调色板的主题系统：

```nix
# 从 Base16 调色板创建主题
palette = diag.paletteFromBase16 { scheme = "catppuccin-mocha"; };
theme = diag.themeFromPalette palette;

# 一步到位
theme = diag.themeFromBase16 { scheme = "catppuccin-mocha"; };

# 使用默认主题
rendered = diag.toMermaidWith { theme = diag.defaultTheme; } graph;
```

---

## 关联

- **`capture.nix`**: 跟踪捕获实现
- **`graph.nix`**: 图 IR 构建
- **`filters/`**: 所有过滤器的目录
- **`mermaid.nix`**: Mermaid 渲染器
- **`dot.nix`**: DOT 渲染器
- **`plantuml.nix`**: PlantUML 渲染器
- **`c4.nix`**: C4 模型渲染器
- **`fleet.nix`**: 舰队级捕获
- **`themes.nix`**: 主题定义
