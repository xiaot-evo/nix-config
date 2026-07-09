# 方面子功能模块（Aspect）

**源文件**: `nix/lib/aspects/fx/aspect/*.nix`（4 个文件）

## 概述

`aspect/` 目录提供了方面管道的核心递归逻辑：子节点遍历、约束注册、策略创建和子节点规范化。这些函数被 `handlers/compile-static.nix`、`handlers/resolve-children.nix` 等处理程序调用，是管道编译流程的"业务逻辑"层。

与处理程序（handler）不同，这里的函数是纯数据变换——它们不直接操作管道状态，而是返回效果序列供处理程序发送。

______________________________________________________________________

## 文件一览

| 文件 | 行数 | 导出函数 | 用途 |
|------|------|----------|------|
| `default.nix` | 14 | `emitIncludes`, `registerConstraints`, `emitAspectPolicies` | 重新导出入口 |
| `children.nix` | 162 | `emitIncludes`, `registerConstraints` | 子节点遍历与约束注册 |
| `provide.nix` | 154 | `emitAspectPolicies` | 策略创建与自提供 |
| `normalize.nix` | 116 | `wrapChild`, `isMeaningfulName` | 子节点规范化 |

______________________________________________________________________

## `default.nix`

### 签名

```nix
{ lib, den }:
{ ctxFromHandlers }:
{
  emitIncludes     = /* children.nix 导出 */;
  registerConstraints = /* children.nix 导出 */;
  emitAspectPolicies  = /* provide.nix 导出 */;
}
```

### 用途

重新导出 `children.nix` 和 `provide.nix` 的公开函数。接收 `ctxFromHandlers` —— 一个从 `__scopeHandlers` attrset 构建上下文记录的函数，用于为 `emitAspectPolicies` 提供作用域上下文。

### 使用示例

```nix
# 在 compile-static.nix 中使用
inherit (import ../aspect { inherit lib den; } { inherit ctxFromHandlers; })
  registerConstraints
  ;
```

______________________________________________________________________

## `children.nix`

### 概述

`emitIncludes` 遍历一个方面的 `includes` 列表，将每个子节点发送到 `resolve` 效果链中。`registerConstraints` 处理 `excludes` 和 `meta.handleWith`，向约束注册表注册约束。

### `emitIncludes`

#### 签名

```nix
emitIncludes : {
  __parentScopeHandlers? :: AttrSet,
  __parentCtxId? :: StringOrNull,
  __skipNameAnon? :: Bool
} -> [Aspect] -> Effects
```

#### 参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `__parentScopeHandlers` | AttrSet | `null` | 父方面的作用域处理程序，传播给子节点 |
| `__parentCtxId` | String | `null` | 父方面的上下文 ID，传播给子节点 |
| `__skipNameAnon` | Bool | `false` | 跳过匿名命名（用于单元素包含） |

#### 内部函数

**`processInclude`**：处理单个包含项，路由策略值到 `register-aspect-policy`，列表递归分解，其他值通过 `wrapChild` 规范化后分派：

```nix
processInclude = { parentScopeHandlers, parentCtxId, skipNameAnon }: idx: rawChild:
  if isPolicy rawChild then registerPolicy rawChild
  else if builtins.isList rawChild then
    # 分解列表：策略注册 + 非策略递归
    ...
  else
    # 包装 + 作用域传播 → 去重分派
    let
      withScope = propagateScope ... (wrapChild rawChild);
      child = if !skipNameAnon && !isMeaningfulName ... then
        withScope // { name = nameAnon ...; }
      else withScope;
    in dedupAndDispatch child
```

**`propagateScope`**：将父方面的 `__scopeHandlers` 和 `__ctxId` 传播到子节点（除非子节点已有自己的值）。

**`nameAnon`**：为匿名方面生成名字：`"${parentChain}/<anon>:${idx}[${ctxId}]"`。

**`dedupAndDispatch`**：发送 `resolve` 效果：

```nix
dedupAndDispatch = child:
  fx.send "resolve" {
    aspect = child;
    identity = identity.key child;
    ctx = { };
  };
```

#### 示例

```nix
# 使用方式（来自 resolve-children.nix 或 emit-include handler）
emitIncludes {
  __parentScopeHandlers = aspect.__scopeHandlers or null;
  __parentCtxId = aspect.__ctxId or null;
} (aspect.includes or [ ])
```

______________________________________________________________________

### `registerConstraints`

#### 签名

```nix
registerConstraints : Aspect -> Effects
```

#### 用途

处理 `aspect.meta.handleWith`（解析处理程序列表）和 `aspect.excludes`（便捷排除），归一化为标准约束记录，发送 `register-constraint` 效果。

#### 约束归一化流程

```
meta.handleWith = [ (exclude ref), (substitute ref rep), (filterBy pred) ]
  → 归一化为 { type, scope, identity/getReplacement/predicate, owner }
  
excludes = [ aspect1, aspect2, ... ]
  → 归一化为 { type = "exclude", scope = "subtree", identity = identity.key ref }
```

#### 身份计算（`excludeIdentity`）

```nix
excludeIdentity = ref:
  if ref.__isPolicy then ref.name
  else if ref?__provider && !(ref?name) then
    identity.key { name = last prov; meta.provider = init prov; }
  else identity.key ref;
```

#### 示例

```nix
# 来自 compile-static.nix
registerConstraints tagged
```

______________________________________________________________________

## `provide.nix`

### 概述

`emitAspectPolicies` 从一个方面创建跨实体策略和自提供包含。将 `aspect.provides` 条目转换为 `register-aspect-policy` 效果（跨实体）或 `emit-include` 效果（自提供）。

### `emitAspectPolicies`

#### 签名

```nix
emitAspectPolicies : Aspect -> Effects
```

#### 用途

1. 遍历 `aspect.provides` 中的键
1. 对于非方面名称键 → 创建跨实体策略（`to-hosts`、`to-users` 或按实体名称匹配）
1. 对于方面名称键 → 创建自提供包含

#### 内部函数

**`mkCrossPolicy`**：为每个 provides 键创建策略：

```nix
mkCrossPolicy = aspectName: nodeIdentity: provides: key:
  let
    value = provides.${key};
    policyFn = if key == "to-hosts" || key == "to-users" then
      ({ host, user, ... }:
        [ (policy.include (applyProvide value { inherit host user; })) ]
      )
    else
      ({ host, user, ... }:
        lib.optionals (host.name == key || user.name == key)
          [ (policy.include (applyProvide value { inherit host user; })) ]
      );
  in fx.send "register-aspect-policy" {
    name = "${aspectName}/${key}";
    fn = policyFn;
    ownerIdentity = nodeIdentity;
  };
```

**`resolveProviderFn`**：提取提供者的内部函数和参数——处理 `__fn`、`__functor`、裸函数、参数化包装。

**`mkSelfProvideInclude`**：为 `aspect.provides.${aspectName}` 创建自提供包含：

```nix
# 零参函数：立即解析
if isPositionalFn then
  let resolved = innerFn ctx; in
  if lib.isFunction resolved && !builtins.isAttrs resolved then
    { name = aspectName; meta = providerMeta; __fn = resolved; __args = ...; }
  else
    resolved // { name = aspectName; meta = providerMeta; ... }
# 多参函数：创建参数化方面
else
  { name = aspectName; meta = ...; __fn = innerFn; __args = args; ... }
```

#### 示例

```nix
# 方面定义
den.aspects.example = {
  nixos = { ... };
  provides = {
    # 跨实体：为所有主机注入模块
    to-hosts = { host, user }: { nixos = { ... }; };
    # 按名匹配：只为 pingu 提供
    pingu = { host, user }: { nixos = { ... }; };
    # 自提供：example 自身的选择器
    example = { host, user }: { nixos = { ... }; };
  };
};

# emitAspectPolicies 会创建：
# - register-aspect-policy "example/to-hosts"（跨所有主机触发）
# - register-aspect-policy "example/pingu"（仅 pingu 触发）
# - emit-include example/example（自提供包含）
```

______________________________________________________________________

## `normalize.nix`

### 概述

`wrapChild` 将原始包含输入强制转换为规范方面 attrset。处理多种输入格式：模块函数、`__functor` 子节点、裸函数、`__contentValues` 包装器。

### `wrapChild`

#### 签名

```nix
wrapChild : Any -> Aspect
```

#### 规范化规则

| 输入类型 | 输出 | 说明 |
|----------|------|------|
| 模块函数（有 `name`、`includes`、`isList includes`） | 原样返回 | 已经是规范格式 |
| 带 `__functor` 的属性集 | 尝试解析零参 functor 或包装为参数化 | Synthetic provides 立即解析 |
| 裸函数 | 包装为 `{ __fn = child; __args = ...; }` | 子模块函数通过 `isSubmoduleFn` 检测 → 通过 `aspectType.merge` 规范化 |
| `__contentValues` 包装器（无 `name`） | 注入 `name`、`meta.provider`，提取参数化函数 | 从 `__provider` 推导名称，将嵌套函数移入 `includes` |

#### 内部函数

**`normalizeModuleFn`**：通过 `aspectType.merge` 将 NixOS 模块函数合并为规范方面 attrset。

**`wrapFunctorChild`**：处理 `__functor` 子节点：

- 子模块函数 → 通过 `normalizeModuleFn`
- 零参 functor 返回方面形状（有 `name` 和 `includes`） → 立即解析
- 其他 → 包装为 `{ __fn, __args, includes }`

**`wrapBareFn`**：裸函数 → `{ name, meta, __fn, __args }`

**`__contentValues` 处理**：当子节点有 `__contentValues` 但没有 `name` 时：

- 从 `__provider` 推导名称（`last provider`）
- 提取参数化函数（有非 `config`/`options` 参数的函数）移入 `includes`

### `isMeaningfulName`

#### 签名

```nix
isMeaningfulName : String -> Bool
```

#### 用途

判断一个名字是否"有意义"（不是 `<anon>`、`<includeIf>` 等自动生成的合成名称）。有意义的名称用于去重键生成，合成名称匿名总是通过。

______________________________________________________________________

## 函数间交互

```
compile-static / compile-conditional / emit-include
    │
    ├── emitIncludes (children.nix)
    │     ├── wrapChild (normalize.nix) → 规范化子节点
    │     ├── propagateScope → 传播作用域信息
    │     ├── nameAnon → 匿名命名
    │     └── dedupAndDispatch → 发送 resolve 效果
    │
    ├── registerConstraints (children.nix)
    │     └── 发送 register-constraint 效果
    │
    └── emitAspectPolicies (provide.nix)
          ├── mkCrossPolicy → 跨实体策略
          ├── mkSelfProvideInclude → 自提供
          │     └── resolveProviderFn (provide.nix)
          └── 发送 register-aspect-policy / emit-include 效果
```

______________________________________________________________________

## 关联函数

- `fx.handlers.compile-static` — 调用 `registerConstraints`，通过 `resolve-children` 调用 `emitIncludes` 和 `emitAspectPolicies`
- `fx.handlers.resolve-children` — 调用 `emitIncludes`、`emitAspectPolicies`
- `fx.handlers.include` — `emit-include` 效果委托给 `emitIncludes`
- `fx.handlers.compile-conditional` — 条件版地调用 `emitIncludes`
- `fx.identity` — 身份路径系统，由 `dedupAndDispatch`、`excludeIdentity`、`nodeIdentity` 使用
- `fx.constraints` — 约束系统，`registerConstraints` 注册的约束由此消耗
- `fx.contentUtil` — `applyProvide` 由 `mkCrossPolicy` 使用
- `den.lib.aspects` — `isSubmoduleFn`、`isParametricWrapper`、`isMeaningfulName`、`types.aspectType.merge`

## 关联文档

- [管道编排器](../pipeline.md) — 管道整体流程，了解 `aspect/` 函数在编译阶段的位置
- [键分类系统](../key-classification.md) — 分类算法，`compile-static` 在调用 `registerConstraints` 前使用
- [约束系统](../constraints.md) — 约束注册与检查的详细流程
- [resolve.md](../resolve.md) — 后处理组装阶段，`emitAspectPolicies` 创建的策略在此阶段被消费
- [includes.md](../includes.md) — 条件包含辅助，与 `emitIncludes` 的关系
- [内容工具](../class-module.md) — `contentUtil.unwrapContentValuesList` 和 `unwrapContentValuesForClassification`
- [身份系统](../identity.md) — 身份键生成，去重和约束匹配的基础
