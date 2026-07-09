# 图 IR 构建（Graph IR Construction）

**源文件**: `nix/lib/diag/graph.nix`

## 概述

将结构化跟踪条目转换为格式无关的图中间表示（IR）。IR 包含节点、边、实体类型和实体类型转换信息。所有视觉相关的内容（主题、颜色、布局）在渲染器中处理，不在 IR 中。

______________________________________________________________________

## graph.build — 从条目构建图 IR

**签名**: `({ entries, rootName, ctxTrace?, direction? }) → graphIR`

### 参数说明

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `entries` | `[entry]` | — | 结构化跟踪条目 |
| `rootName` | `string` | — | 根节点名称 |
| `ctxTrace` | `[ctxItem]` | `[]` | 上下文跟踪数据 |
| `direction` | `"LR" | "TD"` | `"LR"` | 图方向（左→右或上→下） |

### 返回值

图 IR 包含：

| 字段 | 类型 | 说明 |
|------|------|------|
| `rootName` | `string` | 根节点名称 |
| `rootId` | `string` | 根节点 ID |
| `direction` | `string` | 图方向 |
| `nodes` | `[node]` | 节点列表 |
| `edges` | `[edge]` | 边列表 |
| `entityKinds` | `[entityKind]` | 实体类型列表 |
| `entityEdges` | `[edge]` | 实体类型转换边 |
| `entityInstances` | `[entityInstance]` | 实体实例列表 |

### 使用示例

```nix
g = diag.graph.build {
  entries = diag.captureAll ["nixos" "homeManager"] rootAspect;
  rootName = host.name;
};
```

### 实现细节

**去重策略**：`captureAll` 为每个类遍历一次方面树。同一方面可能在多个类中出现。去重逻辑（`groupedByName` + `classesByName`）合并 `hasClass = true` 的条目，确保每个方面在 IR 中只出现一次，且类的信息被合并。

**作用域限定**：当同一方面名在不同实体作用域中出现时，使用 `fullName|entityInstance` 作为去重键。跨作用域节点通过 `@entityInstance` 后缀在 ID 中区分。

**节点形状分类**：

- `rect`（矩形）— 普通方面
- `hexagon`（六边形）— 参数化方面
- `trapezoid`（梯形）— 提供者方面

**节点样式分类**：

- `default`— 默认
- `replaced`— 被替换
- `excluded`— 被排除
- `adapter`— 有处理器
- `policy`— 策略调度点
- `terminal`— 解析产物（叶子节点）

______________________________________________________________________

## graph.ofHost — 从主机构建图

对 `context.nix` 中 `hostContext` 的精简封装，去除了 `rootAspect`、`pathSets`、`classes` 等辅助字段，仅返回纯图 IR。

```nix
# 等同于：
g = builtins.removeAttrs (diag.hostContext { inherit host; }) [ "rootAspect" "pathSets" "classes" ];
```

简便调用，自动封装：

1. 调用 `resolveEntity "host" { inherit host; }`
1. 调用 `captureWithPathsWith` 捕获所有类及路径集
1. 调用 `buildGraph` 构建 IR
1. 去除辅助字段后返回纯图

______________________________________________________________________

## graph.ofNamespace — 命名空间图

**源文件**: `nix/lib/diag/namespace.nix`

构建命名空间的方面树图。命名空间是 `den.ful` 中定义的内部方面树。

```nix
g = diag.graph.ofNamespace namespaceAspect;
```

______________________________________________________________________

## graph.filterUserAspects — 过滤用户方面

过滤出有意义的用户方面（折叠包装器后）。实际上是 `foldWrappers + filterMeaningful` 的组合。

```nix
filtered = diag.graph.filterUserAspects graph;
```

______________________________________________________________________

## 节点数据结构

```nix
{
  id = "sanitized-node-id";
  label = "显示标签";        # 短标签（唯一时）或全路径
  fullLabel = "a/b/c";      # 完整提供者路径
  pathKey = "a/b/c";        # 规范键，匹配 identity.pathKey
  shape = "rect|hexagon|trapezoid";
  style = "default|replaced|excluded|adapter|policy|terminal";
  entityKind = null;         # 实体类型
  entityInstance = null;     # 实体实例
  classes = ["nixos"];       # 实际贡献的类
  class = "";                # 类（连接字符串）
  perClass = {};             # 每个类的元数据
  fnArgNames = [];           # 参数名（参数化方面）
  isParametric = false;      # 是否参数化方面
  isProvider = false;        # 是否提供者方面
  providerPath = [];         # 提供者路径
  hasClass = false;          # 是否有类内容
  isExcluded = false;        # 是否被排除
  isReplaced = false;        # 是否被替换
  isPolicyDispatch = false;  # 是否策略调度点
  policyName = null;         # 策略名
  from = null;               # 来源实体类型
  to = null;                 # 目标实体类型
}
```

______________________________________________________________________

## 边数据结构

```nix
{
  from = "source-node-id";
  to = "target-node-id";
  style = "normal|excluded|replaced|provide|policy";
  label = null;              # 可选的边标签
}
```

______________________________________________________________________

## 关联

- **`capture.nix`**: 跟踪捕获（图 IR 的输入）
- **`context.nix`**: `hostContext`、`userContext`、`homeContext` 等快捷函数
- **`namespace.nix`**: 命名空间图构建
- **`filters/`**: 图过滤操作
- **渲染器**: `mermaid.nix`、`dot.nix`、`plantuml.nix`、`c4.nix`
