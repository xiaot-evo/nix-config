# FX 管道编排器

**源文件**: `nix/lib/aspects/fx/pipeline.nix`

## 概述

管道编排器是 Den 方面引擎的核心——一个代数效果弹跳床（trampoline）。每个状态变化都是一个效果；纯数据变换保持为函数。管道组合了 37 个处理程序，通过效果分派处理方面解析、编译、分类、发射和子节点解析。

______________________________________________________________________

## `mkPipeline`

### 签名

```nix
mkPipeline : {
  extraHandlers? :: AttrSet Handler,
  extraState? :: AttrSet,
  class :: String
} -> { self :: Aspect, ctx :: Context } -> { value :: Any, state :: State }
```

### 用途

创建管道实例。这是主入口——引导解析并通过效果处理程序运行方面树。

### 参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `class` | String | — | 目标类（如 `"nixos"`） |
| `extraHandlers` | AttrSet Handler | `{}` | 要组合的额外处理程序（用于测试、跟踪） |
| `extraState` | AttrSet | `{}` | 要合并的初始额外状态 |

### 引导流程

1. **发送 `"resolve"` 效果**：使用 `fx.send "resolve"` 开始解析根方面
1. **组合处理程序**：`composeHandlers rootHandlers extraHandlers`
1. **初始化状态**：rootScopeId、scopeContexts 等
1. **运行效果处理**：`fx.handle { handlers; state; } bootstrapAndResolve`

```nix
# 参数传递给 resolve 效果：
{
  aspect = self;           # 规范化的根方面
  identity = identity.key self;  # 身份键
  ctx = ctx;               # 作用域上下文（如 { host = ...; user = ...; }）
  gated = true;            # 根总是通过门控
}
```

______________________________________________________________________

## `fxFullResolve`

### 签名

```nix
fxFullResolve : {
  class :: String,
  self :: Aspect,
  ctx :: Context,
  extraState? :: AttrSet
} -> { value :: Any, state :: State }
```

### 用途

对树执行完整管道解析，返回原始结果（包括完整状态）。用于 `collectPathSet` 和其他需要访问管道状态（pathSet、scopeContexts 等）的场景。

### 示例

```nix
fxFullResolve {
  class = "nixos";
  self = normalizedAspect;
  ctx = { host = igloo; };
}
```

______________________________________________________________________

## `mkScopeId`

### 签名

```nix
mkScopeId : Context -> String
```

### 用途

从上下文 attrset 创建规范的作用域身份字符串。产生一个按 key 排序的逗号分隔的 `"key=value"` 字符串。

### 示例

```nix
mkScopeId { host = { name = "igloo"; ... }; user = { name = "tux"; ... }; }
# → "host=igloo,user=tux"
```

### 值序列化

| 类型 | 格式 |
|------|------|
| Attrs（有 name） | `key=name` |
| String | `key=value` |
| Int/Float | `key=toString(value)` |
| 其他 | `key=<type:key>` |

______________________________________________________________________

## `defaultHandlers`

### 签名

```nix
defaultHandlers : { class :: String, ctx :: Context } -> AttrSet Handler
```

### 用途

返回默认的 37 个处理程序集合，组合了常量和所有标准子处理程序。

### 处理程序总览

| 类别 | 处理程序 | 效果键 | 说明 |
|------|----------|--------|------|
| **状态初始化** | `constantHandler` | — | 设置类、aspect-chain 等常量状态 |
| **收集** | `classCollectorHandler` | `emit-class` | 收集发射的类模块条目 |
| **约束** | `constraintRegistryHandler` | `register-constraint`, `check-constraint` | 注册和检查约束（排除、替换、过滤） |
| **链追踪** | `chainHandler` | `chain-push`, `chain-pop` | 追踪包括祖先链 |
| **包含** | `includeHandler` | `emit-include` | 发射子包含项 |
| **去重** | `checkDedupHandler` | `check-dedup` | 通过身份键检测重复 |
| **上下文** | `ctxSeenHandler` | — | 追踪已见的上下文 |
| **路径集** | `pathSetHandler` | `get-path-set` | 提供路径集查询 |
| **路径收集** | `collectPathsHandler` | `resolve-complete` | 在路径集中记录已解析的方面 |
| **策略** | `registerAspectPolicyHandler` | `register-aspect-policy` | 注册方面策略 |
| **路由** | `registerRouteHandler` | `register-route` | 注册路由效果 |
| **实例化** | `registerInstantiateHandler` | `register-instantiate` | 注册实例化效果 |
| **提供** | `provideHandler` | — | 处理方面 provides |
| **管道效果** | `registerPipeEffectHandler` | `register-pipe-effect` | 注册弯曲管道效果 |
| **实体解析** | `resolveEntityHandler` | `resolve-entity` | 通过类型解析实体 |
| **作用域** | `pushScopeHandler` | `push-scope` | 推入新作用域 |
| **作用域** | `restoreScopeHandler` | `restore-scope` | 恢复先前的作用域 |
| **路由传播** | `propagateRoutesHandler` | `propagate-routes` | 将路由传播到子作用域 |
| **触发追踪** | `recordFiredHandler` | `record-fired` | 记录已触发的策略 |
| **上下文扩展** | `widenContextHandler` | `widen-context` | 用新参数扩展上下文 |
| **模式实体** | `resolveSchemaEntityHandler` | `resolve-schema-entity` | 解析模式实体 |
| **门控** | `gateHandler` | `gate` | 去重 + 约束检查复合 |
| **解析** | `resolveHandler` | `resolve` | 主要解析分派 |
| **编译** | `compileHandler` | `compile` | 形状路由器（检测方面形状） |
| **转发编译** | `compileForwardHandler` | `compile-forward` | 编译转发方面 |
| **条件编译** | `compileConditionalHandler` | `compile-conditional` | 编译条件方面 |
| **条件延迟** | `deferConditionalHandler` | `defer-conditional` | 延迟条件方面 |
| **条件排空** | `drainConditionalsHandler` | `drain-conditionals` | 排空延迟的条件 |
| **参量编译** | `compileParametricHandler` | `compile-parametric` | 编译参量方面 |
| **静态编译** | `compileStaticHandler` | `compile-static` | 编译静态方面 |
| **绑定** | `bindHandler` | `bind` | 绑定参量函数参数 |
| **延迟** | `deferHandler` | `defer` | 延迟包含（等待可用参数） |
| **排空** | `drainHandler` | `drain` | 排空延迟的包含 |
| **作用域扩展** | `scopeWidenHandler` | `scope-widen` | 扩展作用域的上下文 |
| **分类** | `classifyHandler` | `classify` | 对方面键进行分类 |
| **类发射** | `emitClassesHandler` | `emit-classes` | 发射类模块条目 |
| **子节点解析** | `resolveChildrenHandler` | `resolve-children` | 递归解析子方面 |
| **策略分派** | `dispatchPoliciesHandler` | `dispatch-policies` | 分派已触发的策略 |
| **策略效果发射** | `emitPolicyEffectsHandler` | `emit-policy-effects` | 发射策略产生的效果 |

______________________________________________________________________

## `defaultState`

### 签名

```nix
defaultState : State
```

### 状态结构

**扁平状态（全局，不按作用域分割）**：

```nix
seen = _: { };          # 已见的方面
pathSet = _: { };       # 已收集的身份路径
```

**按作用域分割的输出状态**：

```nix
scopedClassImports = _: { };          # 每个作用域：{ class → [entries] }
scopedAspectPolicies = _: { };        # 每个作用域：{ name → policyFn }
flatAspectPolicies = { };             # 预合并的扁平视图
scopedDeferredIncludes = _: { };      # 每个作用域的延迟包含
scopedDeferredConditionals = _: { };  # 每个作用域的延迟条件
scopedIncludesChain = _: { };         # 每个作用域的包括祖先链
scopedConstraintRegistry = _: { };    # 每个作用域的约束注册表
scopedConstraintFilters = _: { };     # 每个作用域的约束过滤器
flatConstraintRegistry = { };         # 预合并的扁平约束
flatConstraintFilters = [ ];          # 预合并的扁平过滤器
scopedRoutes = _: { };                # 每个作用域的路由
scopedInstantiates = _: { };          # 每个作用域的实例化
scopedProvides = _: { };              # 每个作用域的 provides
scopedPipeEffects = _: { };           # 每个作用域的管道效果
scopedEmittedLocs = _: { };           # 每个作用域已发射的位置
```

**作用域树追踪**：

```nix
rootScopeId = "__unscoped";       # 根作用域 ID
currentScope = "__unscoped";      # 当前作用域 ID
scopeContexts = _: { };           # 作用域 ID → 上下文
scopeParent = _: { };             # 作用域 ID → 父作用域 ID
```

**策略分派追踪**：

```nix
firedPolicyNames = _: { };        # 已触发的策略名称
dispatchedPolicies = _: { };      # 已分派的策略
registeredRouteKeys = _: { };     # 已注册的路由键
inLateDispatch = false;           # 是否在延迟分派中
includeSeen = _: { };             # 已见的包含项
```

______________________________________________________________________

## `composeHandlers`

### 签名

```nix
composeHandlers : a :: AttrSet Handler -> b :: AttrSet Handler -> AttrSet Handler
```

### 用途

组合两个处理程序集：`b` 的 resume 胜出，`a` 的状态胜出。用于将跟踪处理程序与默认处理程序组合。

### 组合策略

对于共享效果键：先运行 `b`（控制 resume），然后将 `b` 的状态传递给 `a`（累积路径/导入）。

______________________________________________________________________

## `composeHandlers` 中的实现细节

```nix
composeHandlers = a: b:
  let
    shared = builtins.intersectAttrs a b;
    sharedComposed = builtins.mapAttrs (name: _:
      { param, state }:
        let
          rb = b.${name} { inherit param state; };
          ra = a.${name} { inherit param; inherit (rb) state; };
        in { inherit (rb) resume; inherit (ra) state; }
    ) shared;
  in a // b // sharedComposed;
```

关键：对于共享效果键，`b` 的结果 resume 是最终输出，但 `a` 看到 `b` 修改后的状态，因此当 `b` 可能丢弃它时，`a` 仍能累积状态（如路径集）。

______________________________________________________________________

## 管道流程执行顺序

```
resolve
  → compile (形状路由器)
    → compile-static
      → gate (去重 + 约束)
        → classify
        → emit-classes
        → resolve-children (递归)
    → compile-parametric
      → bind (绑定参数)
      → resolve (重新进入管道)
    → compile-forward
      → emit-forward (外部解析)
    → compile-conditional
      → defer-conditional (等待守卫解析)
    → defer (延迟包含)
  → drain-conditionals
  → drain (排空延迟的包含)
  → dispatch-policies
  → emit-policy-effects
  → resolve-children (策略产生的子节点)
```

______________________________________________________________________

## `fxResolve` 和 `fxResolveImports`

**源文件**: `nix/lib/aspects/fx/resolve.nix`

这些函数连接管道执行和后处理组装：

- `fxResolve`：完整解析（阶段 1-4：包装、提供、路由、实例化）
- `fxResolveImports`：跳过实例化，仅返回阶段 1-3 的导入

```nix
fxResolve mkPipeline { class = "nixos"; self = tree; ctx = { }; }
# → { imports = [ ... ]; }
```

### 后处理阶段

1. **`wrapPerScope`**：包装每个作用域的类导入（`wrapClassModule` + 碰撞检测）
1. **`applyProvides`**：应用策略 provide 效果（跨实体注入模块）
1. **`applyRoutes`**：应用路由（在作用域/实体之间移动模块）
1. **`applyInstantiates`**：应用实例化（为每个主机子树重新组装）

### 完整解析流程（fxResolve）

```
1. 运行管道 → pipeline state
2. 提取 scopeContexts, scopedClassImports, scopeParent, scopedProvides, scopedRoutes
3. 组装管道数据 (assemblePipes) → augmentedScopeContexts
4. 排空延迟的包含 (drainedClassImportsRaw)
5. 阶段1: wrapPerScope (包装类模块)
6. 阶段2: applyProvides (注入 provides)
7. 阶段3: applyRoutes (路由)
8. 阶段4: applyInstantiates (实例化实体)
9. 返回: { imports = ...; }
```

______________________________________________________________________

## 关联函数

- `fx.resolve` — 后处理组装阶段，连接管道执行后的四阶段处理（包装、提供、路由、实例化）
- `fx.assemble-pipes` — 管道数据组装，从管道状态中提取并处理弯曲数据
- `fx.class-module` / `wrapClassModule` — 类模块封装，包装管道输出的类导入
- `fx.wrap-classes` — 类封装传递，wrapClassModule 的上层调度
- `fx.identity` — 身份路径系统，管道中用于去重、约束、路径收集
- `fx.key-classification` — 键分类系统，classify 效果的核心实现
- `fx.constraints` — 约束系统，gate 阶段检查排除/替换
- `fx.includes` — 条件包含辅助，compile 阶段处理 includeIf
- `den.lib.aspects` — 顶层方面引擎，mkPipeline 被 resolve/resolveImports/resolveWithState 调用

## 关联文档

- [核心概念](../../../02-%E6%A0%B8%E5%BF%83%E6%A6%82%E5%BF%B5.md) — 方面解析流程概述
- [方面配置指南](../../../04-%E6%96%B9%E9%9D%A2%E9%85%8D%E7%BD%AE%E6%8C%87%E5%8D%97.md) — 方面的四种形态和编译流程
- [高级主题](../../../11-%E9%AB%98%E7%BA%A7%E4%B8%BB%E9%A2%98.md) — 代数效应管道和调试
