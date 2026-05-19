# 后处理组装阶段

**源文件**: `nix/lib/aspects/fx/resolve.nix`

## 概述

后处理组装是管道执行后的阶段，将原始管道状态转换为最终的 `{ imports = [...]; }` 结果。这包括四个连续阶段：包装（wrap）、提供（provide）、路由（route）和实例化（instantiate）。

---

## 后处理阶段的组合顺序

```
管道执行（pipeline.nix）
     │
     ▼
assemblePipes（组装管道数据到作用域上下文中）
     │
     ▼
drain DeferredIncludes（排空延迟的包含项）
     │
     ▼
阶段1: wrapPerScope（逐作用域包装类模块）
     ├── 每个作用域调用 wrapCollectedClasses
     └── 跨作用域去重（第一个匹配项胜出）
     │
     ▼
阶段2: applyProvides（注入 provides 模块）
     │
     ▼
阶段3: applyRoutes（路由模块）
     ├── 简单路由：路径嵌套 + 守卫 + adaptArgs
     └── 复杂路由：转发方面解析
     │
     ▼
阶段4: applyInstantiates（实例化实体输出）
     │
     ▼
{ imports = [ ... ] }
```

---

## `fxResolve`

### 签名
```nix
fxResolve : mkPipeline -> {
  class :: String,
  self :: Aspect,
  ctx :: Context
} -> { imports :: [Module] }
```

### 用途
主解析入口。运行完整管道，然后执行四个后处理阶段以产生最终类导入。

### 示例
```nix
fxResolve mkPipeline {
  class = "nixos";
  self = den.aspects.igloo;
  ctx = { host = iglooHost; };
}
# → { imports = [ ... ]; }
```

### 实现概览

```nix
fxResolve = mkPipeline: { class, self, ctx }:
  let
    result = mkPipeline { inherit class; } { inherit self ctx; };
    # 提取管道状态
    scopeContexts = result.state.scopeContexts null;
    scopedClassImportsRaw = result.state.scopedClassImports null;
    scopeParent = result.state.scopeParent null;
    scopedProvides = result.state.scopedProvides null;
    scopedRoutes = result.state.scopedRoutes null;

    # 组装管道数据（弯曲值）
    augmentedScopeContexts = assemblePipes { ... };

    # 排空延迟的包含
    drainedClassImportsRaw = ...;

    # 阶段 1-4
    phase1 = wrapPerScope ctx augmentedScopeContexts drainedClassImportsRaw;
    phase2 = applyProvides ctx augmentedScopeContexts scopedProvides phase1;
    phase3 = applyRoutes ... phase2;
    phase4 = applyInstantiates { ... } phase3.classImports;
  in
  { imports = phase4.${class} or [ ]; };
```

---

## 阶段 1: `wrapPerScope`（包装）

### 签名
```nix
wrapPerScope : Context -> ScopeContexts -> ScopedClassImports -> {
  classImports :: ClassImports,
  perScope :: PerScopeWrapped
}
```

### 用途
为每个作用域包装原始类导入。包装涉及：

1. 通过 `wrapCollectedClasses` 将每个原始条目通过 `wrapClassModule`
2. 跨作用域去重：相同键的模块只保留第一个

### 去重策略
- 有 `key` 的命名模块：跨作用域去重（第一个匹配项胜出）
- 没有 `key` 的匿名模块：总是追加（包括警告、日志等）

### 返回结构
```nix
{
  classImports = { nixos = [ mod1, mod2, ... ]; ... };  # 跨作用域合并
  perScope = {                                         # 逐作用域视图
    "host=igloo" = { nixos = [ ... ]; };
    "host=igloo,user=tux" = { nixos = [ ... ]; };
  };
}
```

---

## 阶段 2: `applyProvides`（提供）

### 签名
```nix
applyProvides : Context -> ScopeContexts -> ScopedProvides -> Phase1Result -> Phase2Result
```

### 用途
应用策略 `provide` 效果——将模块注入到目标类中。provides 是跨实体分派机制：一个方面可以为不同实体（主机、用户）提供模块。

### 提供去重

`dedupProvides` 按组合键 `policyName/class/path` 去重 provides：

```nix
dedupProvides = raw:
  let
    go = seen: specs:
      if specs == [ ] then [ ]
      else
        let s = builtins.head specs; in
        let key = "${s.__providePolicyName}/${s.class}/${lib.concatStringsSep "/" (s.path or [ ])}"; in
        if key != null && seen ? ${key} then go seen rest
        else [ s ] ++ go (if key != null then seen // { ${key} = true; } else seen) rest;
  in go { } raw;
```

这种去重防止当策略为多个实体类触发时产生重复模块。

---

## 阶段 3: `applyRoutes`（路由）

### 签名
```nix
applyRoutes : fxResolve -> Context -> ScopeContexts -> RootScopeId -> ScopeParent -> ScopedRoutes -> Phase2Result -> Phase3Result
```

### 用途
应用注册的路由效果，在作用域和类之间移动模块。委托给 `route.applyRoutes`。

### 路由类型

**简单路由**：路径嵌套 + 守卫 + adaptArgs
- 将模块从一个类/作用域移动到另一个
- 可以嵌套在路径下、应用守卫和参数适配

**复杂路由**：转发方面解析
- 通过 `buildForwardAspect` 从转发方面收集类模块
- 用于高级跨实体路由场景

详见 `nix/lib/aspects/fx/route/apply.nix`。

---

## 阶段 4: `applyInstantiates`（实例化）

### 签名
```nix
applyInstantiates : {
  scopedInstantiates :: AttrSet,
  augmentedScopeContexts :: AttrSet,
  scopedClassImportsRaw :: AttrSet,
  scopedProvides :: AttrSet,
  scopedRoutes :: AttrSet,
  scopeParent :: AttrSet,
  scopeEntityClass :: AttrSet,
  fxResolveFn :: Function,
  ctx :: Context
} -> ClassImports -> ClassImports
```

### 用途
为每个主机子树重新组装阶段 1-3，产生完整的主机配置输出（NixOS 评估）。这是实体最终实例化的地方。

### 主机作用域发现

```nix
findHostScopeId = scopeParent: allScopeIds: spec:
  let
    sid = spec.sourceScopeId;
    entityName = spec.name;
    # 查找源作用域的子作用域中匹配实体名称的
    children = builtins.filter
      (scopeId: scopeId != sid && (scopeParent.${scopeId} or null) == sid)
      allScopeIds;
    matchByName = builtins.filter
      (scopeId: lib.hasInfix "=${entityName}" scopeId) children;
    # 首选最短作用域 ID（实体自身的作用域）
    bestMatch = if builtins.length matchByName <= 1 then matchByName
      else [ (builtins.head (builtins.sort ... matchByName)) ];
  in
  if bestMatch != [ ] then builtins.head bestMatch
  else if spec ? mainModule && builtins.length children == 1 then builtins.head children
  else null;
```

### 子树模块提取

```nix
extractSubtreeModules = perScope: scopeParent: rootScopeId: targetClass:
  let
    allScopeIds = builtins.attrNames perScope;
    # 收集所有后代作用域
    isInSubtree = sid:
      sid == rootScopeId || (
        let parent = scopeParent.${sid} or null; in
        parent != null && parent != sid && isInSubtree parent
      );
    subtreeScopes = builtins.filter isInSubtree allScopeIds;
    # 跨子树去重
    raw = lib.concatMap (sid: perScope.${sid}.${targetClass} or [ ]) subtreeScopes;
    deduped = ...; # 第一个匹配项胜出
  in
  if deduped == [ ] then null else deduped;
```

### 实例化评估

对于每个主机规格，`applyInstantiates` 调用 `spec.instantiate` 并传递收集的模块：

```nix
evaluated = spec.instantiate {
  pkgs = spec.pkgs;                  # 可选的定制 pkgs
  modules = preWalkedModules;        # 从子树收集的模块
};
```

然后将评估结果放置到 `flake.{intoAttr}` 下的输出中。

---

## `fxResolveImports`

### 签名
```nix
fxResolveImports : mkPipeline -> {
  class :: String,
  self :: Aspect,
  ctx :: Context
} -> { imports :: [Module] }
```

### 用途
类似于 `fxResolve`，但跳过阶段 4（实例化）。用于嵌套解析场景，其中只需要收集模块而不需要实体实例化（例如，从主机树中提取 homeManager 模块）。

### 阶段
```
阶段1: wrapPerScope
阶段2: applyProvides
阶段3: applyRoutes
（跳过阶段4）
→ { imports = [ ... ]; }
```

---

## 关联函数

- `fx.pipeline` — 管道编排器，fxResolve 连接管道执行和后处理
- `fx.assemble-pipes` — 管道数据组装，在 fxResolve 的阶段 0 中执行
- `fx.class-module` / `wrapClassModule` — 类模块封装，在阶段 1 中调用
- `den.lib.aspects` — 顶层方面解析入口，调用 fxResolve 获取最终模块
- `den.lib.aspects.resolveImports` — fxResolveImports 的对外暴露接口（跳过阶段 4）
- `den.lib.aspects.normalizeRoot` — 在进入 fxResolve 前规范化方面树

## 关联文档

- [核心概念](../../../02-核心概念.md) — 方面解析的概念说明
- [方面配置指南](../../../04-方面配置指南.md) — 方面解析的实际使用
- [高级主题](../../../11-高级主题.md) — `den.lib.aspects.resolve` 在调试和自定义类中的应用
