# PlantUML 渲染器

**源文件**: `nix/lib/diag/plantuml.nix`

## 概述

将格式无关的图 IR 渲染为 PlantUML 字符串。发出 `skinparam` 指令以使输出的 SVG 与 Mermaid 和 DOT 使用相同的主题调色板。

---

## toPlantUMLWith — 带主题配置的 PlantUML 渲染

**签名**: `({ theme? }) → (graph: graphIR) → string`

### 参数说明

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `theme` | `theme` | `themes.defaultTheme` | Base16 派生主题 |

### 使用示例

```nix
umlString = diag.toPlantUMLWith { inherit theme; } graph;
```

---

## toPlantUML — 默认配置的 PlantUML 渲染

**签名**: `(graph: graphIR) → string`

简便调用：

```nix
umlString = diag.toPlantUML graph;
```

---

## 输出特点

### 图形设置

```plantuml
@startuml
left to right direction
skinparam {
  BackgroundColor <theme.background>
  FontColor <theme.foreground>
  Rectangle {
    BackgroundColor <theme.nodeBg>
    FontColor <theme.nodeText>
  }
  ...
}
rectangle "<rootName>" as <rootId> <rootColor>
...
@enduml
```

### 节点形状

| IR 形状 | PlantUML 形状 |
|---------|---------------|
| `rect` | `rectangle` |
| `hexagon` | `hexagon` |
| `trapezoid` | `card` |

### 边样式

| 样式 | PlantUML 箭头 |
|------|---------------|
| `normal` | `-->` |
| `excluded` | `..x` |
| `replaced` | `..>` |

### 实体类型子图

使用 `package` 实现：

```plantuml
package "<kind>" as ek_<kind> {
  rectangle "node" as nodeId
}
```

### 参数化方面标签

```
nodeLabel\n({ fnArgNames })
```

### 特殊字符转义

PlantUML 将 `<` 和 `>` 解释为构造型标记，因此 `<anon>` 等标签被转义为 `&lt;anon&gt;`。

---

## 样式细节

- 排除/替换节点：实心填充 + `;line.dashed` 虚线边框
- 每个节点的填充颜色来自 `visualFor`，基于主题分配
- `skinparamFor` 工具函数生成 `skinparam` 指令块
- 支持 `Rectangle`、`Hexagon`、`Card`、`Package`、`Note` 五种元素类型

---

## 关联

- **`mermaid.nix`**: Mermaid 渲染器
- **`dot.nix`**: DOT 渲染器
- **`c4.nix`**: C4 模型渲染器（也使用 PlantUML 的 C4 stdlib）
- **`render-util.nix`**: 共享渲染工具（`skinparamFor`、`visualFor`）
- **`themes.nix`**: 主题定义
