# 舰队图（Fleet Diagram）

**源文件**: `nix/lib/diag/fleet.nix`、`nix/lib/diag/fleet-ir.nix`、`nix/lib/diag/fleet-views.nix`

## 概述

舰队级图覆盖整个 Den flake，显示所有主机、用户及其关系。包含三个组件：

1. **`fleet.nix`** — 从 `den.hosts` 注册表构建轻量级舰队记录
1. **`fleet-ir.nix`** — 构建完整的联合图 IR（含作用域层次结构和管道流）
1. **`fleet-views.nix`** — 多种舰队可视化（管道流、作用域拓扑、方面矩阵等）

______________________________________________________________________

## fleet.of — 舰队数据

**源文件**: `fleet.nix`

### 签名

`({ hosts?, flakeName? }) → { flakeName, hosts, users, relations, providerSubAspects }`

### 参数说明

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `hosts` | `attrset` | `den.hosts` | 主机注册表 |
| `flakeName` | `string` | `"den flake"` | Flake 名称 |

### 返回值

| 字段 | 类型 | 说明 |
|------|------|------|
| `flakeName` | `string` | Flake 名称 |
| `hosts` | `[{name, description}]` | 主机列表 |
| `users` | `[{name}]` | 唯一用户列表 |
| `relations` | `[{from, to, label}]` | 用户→主机关系（类边） |
| `providerSubAspects` | `[list]` | 惰性计算：每个主机的提供者子方面 |

### 使用示例

```nix
fleet = diag.fleet.of {};
# { flakeName = "den flake";
#   hosts = [{ name = "igloo"; description = "x86_64-linux"; }];
#   users = [{ name = "tux"; }];
#   relations = [{ from = "tux"; to = "igloo"; label = "uses"; }];
# }
```

______________________________________________________________________

## 舰队 IR（fleet-ir.nix）

**源文件**: `fleet-ir.nix`

### buildFleetIR

联合图的完整 IR。组合每个主机的图 IR，添加命名空间和作用域层次结构。

**签名**: `({ fleetCapture, hostGraphs }) → fleetGraphIR`

### 参数说明

| 参数 | 类型 | 说明 |
|------|------|------|
| `fleetCapture` | `attrset` | `captureFleet` 的输出 |
| `hostGraphs` | `attrset` | `{ "hostName": graphIR, ... }` 每个主机的图 IR |

### 舰队 IR 结构

```nix
{
  rootName = "fleet";
  direction = "LR";
  scopes = [{ id, kind, name, label, parent, children, ctxKeys }];
  nodes = [
    { id, label, host, scope, pipes: { produces }, ... }
    # 作用域节点 + 主机方面节点
  ];
  edges = [
    # 作用域层次边 + 主机内部边 + 主机根边 + 管道流边
  ];
  pipes = {
    <pipeName>: {
      producers = [{ host, aspect, scope }];
      consumers = [{ host, scope, stages, hasCollect }];
      flows = [{ from, to, pipeName }];
    };
  };
  entityInstances = [{ id, kind, name, label, parent }];
}
```

### 特点

- **主机命名空间 ID**：每个主机的节点 ID 添加 `hostName__` 前缀，避免跨主机冲突
- **散射层次结构节点**：`scope_*` 节点表示 fleet→environment→host→user 链
- **管道流边**：跨主机管道生产/消费边

### toFleetJSON

`buildFleetIR → JSON string`：直接序列化为 JSON。

______________________________________________________________________

## 舰队视图（fleet-views.nix）

**源文件**: `fleet-views.nix`

### buildPipeFlows

构建管道流数据：

```nix
flows = diag.pipes.buildFlows fleetCapture;
# { environments: [{ name, hosts: [{ name, produces, collects }] }],
#   flowEdges: [{ from, to, pipe, environment }],
#   orphanHosts: [...] }
```

### 视图 1: toPipeFlowMermaid

管道流程图：显示环境子图中的跨主机管道数据流。

```nix
mermaidString = diag.toPipeFlowMermaid fleetCapture;
```

颜色：每个管道名称分配一个强调色（跨 8 个调色板槽使用 3 步长）。
节点形状：生产者为方框，消费者为圆角，两者兼有为胶囊形。

### 视图 2: toScopeTopologyMermaid

作用域拓扑图：渲染作用域树（fleet→environment→host→user）。

```nix
mermaidString = diag.toScopeTopologyMermaid fleetCapture;
```

颜色：实体类型着色（fleet=第 5 强调色、environment=第 6 强调色、host=第 3 强调色、user=第 1 强调色）。

### 视图 3: toAspectMatrixMermaid

方面矩阵图：每个主机一个子图，列出其有意义的方面。

```nix
mermaidString = diag.toAspectMatrixMermaid fleetCapture;
```

同一方面在不同主机上用虚线连接。颜色：每个方面分配唯一的强调色。

### 视图 4: toPolicyResolutionMapMermaid

策略解析图：作用域树 + 标注驱动每个实体转移的策略。

```nix
mermaidString = diag.toPolicyResolutionMapMermaid fleetCapture;
```

边标签显示策略名（如 `host-to-users`）。

### 视图 5: toPipeSequenceMermaid

管道序列图：Mermaid 序列图，主机是参与者（按环境分组），发送是笔记，收集是箭头。

```nix
mermaidString = diag.toPipeSequenceMermaid fleetCapture;
```

### 视图 6: toFleetDagMermaid

舰队 DAG 图：所有主机的方面树合并为单一 DAG，含环境/主机子图和跨主机管道边。

```nix
mermaidString = diag.toFleetDagMermaid {
  fleetCapture = captureData;
  hostGraphs = { "igloo" = iglooGraph; "tuxbook" = tuxbookGraph; };
};
```

______________________________________________________________________

## 关联

- **`capture.nix`**: 跟踪捕获（`captureFleet` 提供舰队 IR 输入）
- **`graph.nix`**: 单主机图 IR
- **`default.nix`**: 图表库总览（挂载 `fleet.*` 和 `pipes.*` 钩子）
