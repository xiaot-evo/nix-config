# 效果处理程序（Handlers）

**源文件**: `nix/lib/aspects/fx/handlers/*.nix`（37 个文件：36 个处理程序 + 1 个汇编文件 `default.nix`）

## 概述

处理程序是 FX 管道弹跳床（trampoline）中的所有效果处理器。每个处理程序注册一个或多个效果键，当管道发送相应效果时被调用。管道将 37 个处理程序组合成一个统一的处理程序集，通过代数效果驱动方面解析、编译、分类、发射和子节点解析。

每个处理程序文件导出一个带有效果键的处理程序值。处理程序接收 `{ param, state }`，返回 `{ resume, state }`，其中 `resume` 是下一个效果计算，`state` 是更新后的管道状态。

______________________________________________________________________

## 处理程序分组

### 管道入口与路由（3 个）

| 文件 | 效果键 | 说明 |
|------|--------|------|
| `resolve.nix` | `resolve` | 解析入口——直接将参数转发至 `compile` 效果 |
| `compile.nix` | `compile` | 形状路由器——根据方面形状分派至 `compile-*` |
| `ctx.nix` | — | `constantHandler`（从上下文构建处理程序）、`ctxSeenHandler`（去重追踪） |

`resolve` 是管道的入口效果。所有方面解析都通过 `fx.send "resolve" { aspect; identity; ctx; }` 发起。`compile` 检测方面形状：

```nix
effect =
  if meta ? __forward then "compile-forward"
  else if meta ? guard then "compile-conditional"
  else if aspect.__args or { } != { } then "compile-parametric"
  else "compile-static";
```

______________________________________________________________________

### 方面编译（4 个）

| 文件 | 效果键 | 说明 |
|------|--------|------|
| `compile-static.nix` | `compile-static` | 静态方面：门控 → 分类 → 发射 → 子节点解析 |
| `compile-parametric.nix` | `compile-parametric` | 参数化方面：门控 → 绑定 → 重新解析 |
| `compile-forward.nix` | `compile-forward` | 转发方面：提取规格 → 注册路由 |
| `compile-conditional.nix` | `compile-conditional` | 条件方面：守卫评估 → 发射/延迟 → 排空 |

**compile-static** 处理最常见的情况。经过门控检查后，调用 `classify` → `emit-classes` → `registerConstraints` → `resolve-children`。

**compile-parametric** 处理带 `__args` 的方面。调用 `bind` 探测作用域处理程序，如果所有参数可用则编译并重新解析，否则延迟。

**compile-forward** 处理 `meta.__forward` 方面。提取转发规格，分类为简单/复杂路由，注册到 `scopedRoutes`。

**compile-conditional** 处理 `meta.guard` 方面。评估守卫函数，如果通过则发射子方面，否则通过 `defer-conditional` 延迟。

______________________________________________________________________

### 门控与去重（3 个）

| 文件 | 效果键 | 说明 |
|------|--------|------|
| `gate.nix` | `gate` | 复合门控：去重检查 + 约束检查（排除、替换、过滤） |
| `gate-tag.nix` | — | `gateAndTag` 共享逻辑——执行门控检查，将约束所有者标记到方面 |
| `check-dedup.nix` | `check-dedup` | 按身份键去重检查——生成 `scopeId/identityKey` 复合键 |

`gate` 是复合效果：先通过 `check-dedup` 检查重复，再通过 `check-constraint` 检查约束。根据结果返回 `{ blocked, result }` 或 `{ passed }`。

```nix
fx.bind (fx.send "check-dedup" aspect) ({ isDuplicate, dedupKey }:
  if isDuplicate then fx.pure { blocked = true; result = [ ]; }
  else fx.bind (fx.send "check-constraint" { identity; aspect; }) (decision: ...)
)
```

`gateAndTag` 被 `compile-static` 和 `compile-parametric` 共用。如果 `param.gated` 为 `true`（如参数化重新进入时）则跳过门控。

______________________________________________________________________

### 键分类与发射（3 个）

| 文件 | 效果键 | 说明 |
|------|--------|------|
| `classify.nix` | `classify` | 键分类→ 将方面键分为 classKeys/nestedKeys/pipeKeys |
| `emit-classes.nix` | `emit-classes` | 发射类/管道模块→ 遍历键值并发送 `emit-class` |
| `class-collector.nix` | `emit-class` | 收集发射的类模块到带作用域的状态中 |

`classify` 委托给 `keyClassification.classifyKeys`，将方面 attrset 中的键分类。未注册的类键被当作类键处理（向后兼容）。

`emit-classes` 遍历 classKeys 和 pipeKeys，使用 `unwrapContentValuesList` 提取模块，逐条发送 `emit-class`。支持上下文相关检测和碰撞策略。

`class-collector` 通过 `scopedClassImports` 和 `scopedEmittedLocs` 将类模块条目收集到按作用域分区的状态中。通过 `loc`（`${class}@${baseIdentity}`）去重。

______________________________________________________________________

### 包含与子节点（2 个）

| 文件 | 效果键 | 说明 |
|------|--------|------|
| `include.nix` | `include-unseen`, `emit-include` | 取消去重注册、发射包含项 |
| `resolve-children.nix` | `resolve-children` | 完整子节点解析：链追踪 → 策略 → 包含 → 排空 → 完成 |

`emit-include` 是 `emitIncludes` 的薄包装，将原始子节点作为单元素列表转发。

`resolve-children` 是核心递归驱动：

```nix
chainWrap chainIdentity (resolveChildSequence aspect)
  → emitAspectPolicies (self-provide + cross policies)
  → emitIncludes (walk aspect.includes)
  → installPolicies (entity-level policy effects)
  → drain-conditionals (re-evaluate deferred guards)
  → resolve-complete (record path)
```

______________________________________________________________________

### 延迟执行（3 个）

| 文件 | 效果键 | 说明 |
|------|--------|------|
| `defer.nix` | `defer` | 延迟包含→ 发送墓碑，将延迟项入队到 `scopedDeferredIncludes` |
| `drain.nix` | `drain` | 排空延迟包含→ 按上下文可满足性分区 |
| `scope-widen.nix` | `scope-widened` | 作用域扩展→ 排空可满足的延迟项并重新解析 |

当参数化方面的所需参数在作用域中不可用时，`bind` 发送 `defer` 效果。`scope-widened` 在上下文丰富后重新检查。

______________________________________________________________________

### 约束与策略（5 个）

| 文件 | 效果键 | 说明 |
|------|--------|------|
| `constraint.nix` | `register-constraint`, `check-constraint` | 约束注册与检查（排除/替换/过滤） |
| `policy.nix` | `register-aspect-policy` | 方面策略注册 |
| `dispatch-policies.nix` | `dispatch-policies` | 策略分派（包装 `mkDispatch`） |
| `emit-policy-effects.nix` | `emit-policy-effects` | 发射策略效果（排除/路由/提供/实例化/包含） |
| `record-fired.nix` | `record-fired` | 记录已触发的策略名称 |

`constraint.nix` 管理作用域感知的约束注册表：

```nix
# 约束注册：按作用域 + 身份键存储
register-constraint → scopedConstraintRegistry + flatConstraintRegistry

# 约束检查：前缀匹配 + 作用域过滤
lookupEntries: 精确匹配 + 路径前缀匹配
filterByScope: 全局约束或包含祖先链中的子树约束
```

______________________________________________________________________

### 路由与提供（3 个）

| 文件 | 效果键 | 说明 |
|------|--------|------|
| `route.nix` | `register-route` | 路由注册（带作用域去重） |
| `propagate-routes.nix` | `propagate-routes` | 将复杂路由从根作用域传播到子作用域 |
| `provide.nix` | `register-provide` | 提供注册 |

`route.nix` 按 `routeKey`（`fromClass>intoClass@sourceScopeId/path`）去重。

`propagate-routes.nix` 在实体解析后将根作用域的复杂路由复制到子作用域（仅复制子作用域有对应 class 的路由）。

______________________________________________________________________

### 实例化（1 个）

| 文件 | 效果键 | 说明 |
|------|--------|------|
| `instantiate.nix` | `register-instantiate` | 实例化规格注册（后处理中的实体创建） |

______________________________________________________________________

### 管道效果（1 个）

| 文件 | 效果键 | 说明 |
|------|--------|------|
| `register-pipe-effect.nix` | `register-pipe-effect` | 管道效果注册（弯曲/quirks 条目收集） |

______________________________________________________________________

### 作用域管理（4 个）

| 文件 | 效果键 | 说明 |
|------|--------|------|
| `push-scope.nix` | `push-scope` | 推入新作用域（设置 currentScope、继承延迟项、记录源策略） |
| `restore-scope.nix` | `restore-scope` | 恢复父作用域（重置 currentScope、恢复 inLateDispatch） |
| `resolve-schema-entity.nix` | `resolve-schema-entity` | 实体解析：推作用域 → 解析实体 → 遍历 → 排空 → 传播路由 → 恢复 |
| `widen-context.nix` | `widen-context` | 上下文扩展（更新 scopeContexts） |

`push-scope.nix` 创建新作用域 ID（通过 `mkScopeId`），设置 `scopeContexts`、`scopeParent`，继承父作用域的延迟包含项，记录 `scopeEntityClass`、`scopeEntityKind`、`scopeSourcePolicy`。

`resolve-schema-entity.nix` 编排完整的实体解析流程：

```nix
push-scope → resolve-entity → merge includes → resolve entity aspect
  → drain deferred → walkDeferred → propagate-routes → restore-scope
```

______________________________________________________________________

### 绑定与链追踪（3 个）

| 文件 | 效果键 | 说明 |
|------|--------|------|
| `bind.nix` | `bind` | 探测作用域处理程序→ 找到所有参数则编译，否则延迟 |
| `chain.nix` | `chain-push`, `chain-pop` | 包含祖先链追踪（用于约束作用域判断） |
| `forward.nix` | — | `buildForwardAspect`——构建适配器/直接转发方面 |

`bind.nix` 探测作用域中所需的参数键。先检查 `__scopeHandlers`，再回退到管道状态的 `scopeContexts`。检测管道键引用并有条件地延迟。

`chain.nix` 管理 `scopedIncludesChain`——包含祖先链，用于约束中的作用域判断（`subtree` 范围）。

______________________________________________________________________

### 状态工具（1 个）

| 文件 | 说明 |
|------|------|
| `state-util.nix` | 共享状态变更辅助函数：`scopedAppend`、`scopedAppendMany`、`scopedMerge` |

______________________________________________________________________

## 处理程序组装

**源文件**: `handlers/default.nix`

```nix
args:
(import ./state-util.nix)
// (import ./ctx.nix args)
// (import ./constraint.nix args)
// ... 所有 37 个处理程序按依赖顺序合并
```

通过 Nix 的 `//` 操作符合并所有处理程序集。`default.nix` 的返回即为 `defaultHandlers`，在 `pipeline.nix` 中被 `mkPipeline` 使用：

```nix
defaultHandlers = { class, ctx, ... }:
  # 组装 constantHandler（从 ctx 构建）
  # 合并所有标准子处理程序
  constantHandler ... // ... // constraintRegistryHandler // ...
```

______________________________________________________________________

## 管道流程与处理程序交互

```
resolve
  → compile（形状路由器）
    → compile-static
      → gate（check-dedup + check-constraint）
        → classify → classKeys/nestedKeys/pipeKeys
        → emit-classes → emit-class（class-collector 收集）
        → registerConstraints（约束注册）
        → resolve-children
          → chain-push（链追踪）
          → emitAspectPolicies（策略注册）
          → emitIncludes（子节点 → resolve 递归）
          → installPolicies（实体策略安装）
          → drain-conditionals（重新评估延迟守卫）
          → chain-pop
          → resolve-complete（路径记录）
    → compile-parametric
      → gate → bind（探测 → 编译/延迟）
    → compile-forward
      → register-route（路由注册）
    → compile-conditional
      → guard 评估 → emit-include / defer-conditional
  → drain-conditionals（全局排空）
  → drain（排空延迟包含）
  → scope-widened（上下文扩展后重新触发）
  → dispatch-policies → emit-policy-effects
  → resolve-schema-entity（实体级解析）
  → propagate-routes（路由传播）
```

______________________________________________________________________

## 关联函数

- `fx.pipeline` — 管道编排器，组合处理程序、驱动效果弹跳床
- `fx.aspect.children` — `emitIncludes`、`registerConstraints` 的源实现
- `fx.aspect.provide` — `emitAspectPolicies` 的源实现
- `fx.identity` — 身份路径系统，门控去重和约束匹配使用
- `fx.key-classification` — 键分类系统，`classify` 效果的核心逻辑
- `fx.constraints` — 约束系统构造函数（`exclude`、`substitute`、`filterBy`）

## 关联文档

- [管道编排器](../pipeline.md) — 管道架构、状态结构、处理程序总览
- [键分类系统](../key-classification.md) — 分类算法的详细说明
- [约束系统](../constraints.md) — 约束注册与检查的详细说明
- [resolve.md](../resolve.md) — 后处理组装阶段（包装、提供、路由、实例化）
