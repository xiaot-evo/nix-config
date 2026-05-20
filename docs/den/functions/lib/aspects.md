# aspects 模块

**源文件**: `nix/lib/aspects/default.nix`

## 概述

方面（Aspect）引擎是 Den 的核心。方面是可组合、可复用的配置单元，通过管道（pipeline）解析为类模块（class modules）。

本模块提供了将方面树解析为模块的核心函数，以及身份路径查询工具。

---

## den.lib.aspects.resolve

**签名**: `(class: string, resolved: aspect) → { imports = [modules] }`

### 用途

将方面树解析为类模块列表。这是最常用的解析入口——获取最终结果，跳过内部状态。

### 参数说明

- `class: string` — 目标类名（如 `"nixos"`、`"homeManager"`）
- `resolved: aspect` — 已解析的方面值（可直接是 attrset、函数或 functor）

### 返回值说明

返回类模块列表，可直接合并到对应类的 `imports` 中。

### 使用示例

```nix
let
  myAspect = {
    nixos.services.ssh.enable = true;
    homeManager.programs.git.enable = true;
  };
in
den.lib.aspects.resolve "nixos" myAspect
# → { imports = [ { services.ssh.enable = true; } ]; }
```

### 实现简析

内部调用 `normalizeRoot` 统一不同形式的输入（纯函数、functor、attrset），然后通过 `fx.pipeline.fxResolve` 执行完整的管道流程。

---

## den.lib.aspects.resolveImports

**签名**: `(class: string, resolved: aspect) → { imports = [imports] }`

### 用途

跳过实体实例化（entity instantiation），只解析 `includes` 链。适用于嵌套解析场景，例如从主机树中提取 homeManager 模块而不触发完整的主机实例化。

### 参数说明

与 `resolve` 相同。

### 返回值说明

仅返回 `includes` 中解析出的内容，不包含实体的类模块输出。

### 使用示例

```nix
let
  hostTree = {
    nixos = { };
    provides.users.user1 = {
      homeManager.programs.git.enable = true;
    };
  };
in
den.lib.aspects.resolveImports "homeManager" hostTree
# → { imports = [ ... ]; } 只解析 user1 的 includes，不实例化主机
```

### 实现简析

与 `resolve` 共享相同的规范化逻辑，但使用 `fx.pipeline.fxResolveImports`，在管道中跳过实体实例化步骤。

---

## den.lib.aspects.resolveWithState

**签名**: `(class: string, resolved: aspect) → { value, state, ... }`

### 用途

完整解析包括管道状态。在需要检查管道状态（如 `pathSet`、去重信息）时使用，主要用于测试和调试。

### 参数说明

与 `resolve` 相同。

### 返回值说明

返回包含完整管道结果和状态的 attrset：
- `value` — 管道最终解析结果
- `state` — 管道内部状态（pathSet 等）

### 使用示例

```nix
let
  result = den.lib.aspects.resolveWithState "nixos" myAspect;
in
{
  modules = result.value;
  pathSet = result.state.pathSet null;
}
```

### 实现简析

使用 `fx.pipeline.fxFullResolve`，返回 `{ value, state }` 结构（原始管道处理结果），不丢弃状态信息。

---

## den.lib.aspects.normalizeRoot

**签名**: `(resolved: any) → aspect`

### 用途

将各种形式的输入（裸函数、functor attrset、模块函数、普通 attrset）统一规范化为标准的方面 attrset，供管道后续处理。

### 参数说明

- `resolved: any` — 任意格式的方面输入

### 返回值说明

返回规范化的方面 attrset：
- 纯函数 → `{ __fn, __args, name, meta }`
- 模块函数（带 `lib`/`config`/`options` 参数）→ 通过类型合并转为标准方面
- Functor attrset → 提取 `__functor`，保留 `includes`、`__scopeHandlers`
- 普通 attrset → 原样返回

### 使用示例

```nix
# 裸函数
den.lib.aspects.normalizeRoot ({ host, ... }: { nixos.hostName = host.name; })
# → { __fn = ...; __args = { host = false; }; name = "<bare-fn>"; meta = {}; }

# 普通 attrset
den.lib.aspects.normalizeRoot { nixos.hostName = "myhost"; }
# → { nixos.hostName = "myhost"; }
```

### 实现简析

通过鸭子类型检测输入形状：检查 `isFunction`、`__functor`、`isSubmoduleFn`，然后路由到不同的规范化路径。

---

## den.lib.aspects.hasAspectIn

**签名**: `({ tree, class, ref }) → bool`

### 用途

检查方面树中是否包含某指定方面。用于条件化配置，例如"如果启用了桌面环境，则配置 X 服务"。

### 参数说明

- `tree: aspect` — 方面树
- `class: string` — 类名
- `ref: aspect` — 要检查的方面引用（必须有 `name` 和 `meta`）

### 返回值说明

布尔值：`true` 表示方面树包含该引用。

### 使用示例

```nix
den.lib.aspects.hasAspectIn {
  tree = den.aspects.igloo;
  class = "nixos";
  ref = den.batteries.hostname;
}
# → true 或 false
```

### 实现简析

通过 `collectPathSet` 解析管道状态获取 `pathSet`，然后检查指定引用的身份键是否在集合中。

---

## den.lib.aspects.collectPathSet

**签名**: `({ tree, class }) → attrset`

### 用途

收集方面树中所有身份路径（identity paths）。返回一个 attrset，键为身份路径，值为 `true`。

### 参数说明

- `tree: aspect` — 方面树
- `class: string` — 类名

### 返回值说明

`{ <pathKey> = true; ... }` 格式的 attrset。

### 使用示例

```nix
den.lib.aspects.collectPathSet {
  tree = den.aspects.igloo;
  class = "nixos";
}
```

### 实现简析

执行完整管道解析（`fxFullResolve`），从返回的 `state.pathSet` 中提取身份路径。

---

## den.lib.aspects.mkEntityHasAspect

**签名**: `({ tree, primaryClass, classes }) → function`

### 用途

为实体创建 `hasAspect` 查询函数，支持按类查询和跨类查询。

### 参数说明

- `tree: aspect` — 方面树
- `primaryClass: string` — 主类名
- `classes: [string]` — 附加类列表

### 返回值说明

返回一个带 `__functor` 的函数对象，具有以下方法：
- `__functor`: `(ref) → bool` — 在主类上查询
- `forClass`: `(class, ref) → bool` — 在指定类上查询
- `forAnyClass`: `(ref) → bool` — 在任意注册类上查询

### 使用示例

```nix
let
  has = den.lib.aspects.mkEntityHasAspect {
    tree = den.aspects.igloo;
    primaryClass = "nixos";
    classes = [ "homeManager" ];
  };
in
{
  hasHostname = has den.batteries.hostname;
  hasInHome = has.forClass "homeManager" den.batteries.hostname;
  hasAnywhere = has.forAnyClass den.batteries.hostname;
}
```

### 实现简析

为每个类预计算 `pathSet`，然后生成带有闭包的查询函数。

---

## 关联函数

- `den.lib.aspects.normalizeRoot` 是所有解析函数的基础
- `den.lib.aspects.types` 提供方面类型系统
- `den.lib.aspects.fx` 提供管道效果处理
- `den.lib.aspects.policyTypes` 提供策略注册类型
