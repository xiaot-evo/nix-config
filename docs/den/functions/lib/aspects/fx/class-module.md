# 类模块封装

**源文件**: `nix/lib/aspects/fx/class-module.nix`

## 概述

类模块封装备是 Den 方面引擎与 NixOS 模块系统之间的关键桥梁。它将 Den 上下文参数（如 `pkgs`、`lib`、`inputs`）注入到类模块中，同时处理与模块系统参数的碰撞。

______________________________________________________________________

## `wrapClassModule`

### 签名

```nix
wrapClassModule : {
  module :: AspectModule,
  ctx :: Context,
  aspectPolicy :: StringOrNull,
  globalPolicy :: String
} -> {
  module :: AspectModule,
  wrapped :: Bool,
  validator? :: Function,
  validatorAdvertisedArgs? :: AttrSet,
  advertisedArgs? :: AttrSet,
  unsatisfied? :: Bool,
  missingArgs? :: [String]
}
```

### 用途

用 Den 上下文参数封装类模块（函数或 attrset-with-imports）。这是后处理包装阶段的主要入口。

### 参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `module` | AspectModule | 函数模块或 attrset-with-imports |
| `ctx` | Context | Den 上下文参数（{ host, user, pkgs, lib, inputs, ... }） |
| `aspectPolicy` | StringOrNull | 方面级碰撞策略（来自 aspect.meta.collisionPolicy） |
| `globalPolicy` | String | 全局碰撞策略（来自 den.config.classModuleCollisionPolicy） |

### 分派

```nix
wrapClassModule = args:
  if builtins.isAttrs args.module && args.module ? imports then
    wrapImportsModule args    # attrset-with-imports 路径
  else if !builtins.isFunction args.module then
    { module = args.module; wrapped = false; }  # 纯值传递
  else
    wrapFunctionModule args   # 函数模块路径
```

______________________________________________________________________

## `wrapFunctionModule`

### 签名

```nix
wrapFunctionModule : {
  module :: Function,
  ctx :: Context,
  aspectPolicy :: StringOrNull,
  globalPolicy :: String
} -> WrappedModule
```

### 流程

1. **检测 Den 参数**：列出函数请求且上下文存在的参数
1. **检测缺失参数**：检查标准模式参数（host、user、pkgs 等）是否存在——如果缺失，发出警告
1. **未满足的参数**：如果任何模式参数缺失且没有默认值，标记为 `unsatisfied = true`
1. **没有 Den 参数**：如果函数不请求任何 Den 参数，传递 `wrapped: false`
1. **部分应用**：如果函数只请求可立即满足的 Den 参数，调用函数并传递 `wrapped: true`
1. **碰撞路径**：如果函数既有 Den 参数又有模块系统参数，创建一个包装器，在模块评估时用冲突解决策略注入 Den 参数

______________________________________________________________________

## 碰撞处理策略

### 策略层次

```
1. aspect.meta.collisionPolicy (方面级)
2. ctx.{host,user,...}.collisionPolicy (实体级)
3. ctx.__collisionPolicies.{name} (来自模式条目的预计算策略)
4. den.config.classModuleCollisionPolicy (全局，默认 "error")
```

### 选项

| 策略 | 说明 |
|------|------|
| `"error"`（默认） | 检测到碰撞时抛出错误 |
| `"class-wins"` | 模块系统值优先——Den 注入值被丢弃 |
| `"den-wins"` | Den 注入值优先——模块系统值被覆盖 |

### 碰撞检测

`mkCollisionValidator` 检查 `config._module.args` 中每个 Den 参数名称的存在性：

```nix
mkCollisionValidator = policy: denArgNames: moduleArgs:
  let
    collisionChecks = lib.concatMap (name:
      let
        mArgs = moduleArgs.config._module.args or { };
        hasReal = (builtins.tryEval (builtins.seq (mArgs.${name} or null) (mArgs ? ${name}))).value or false;
        p = policy name;
      in
      if !hasReal then [ ]
      else if p == "error" then
        throw "den: class module arg '${name}' collides with module-system arg — set collisionPolicy to resolve"
      else if p == "class-wins" then
        [ "den: class module arg '${name}' collision — class-wins, den value dropped" ]
      else
        [ "den: class module arg '${name}' collision — den-wins, module-system value shadowed" ]
    ) denArgNames;
  in { warnings = collisionChecks; };
```

______________________________________________________________________

## 上下文参数注入

`wrapFunctionModule` 中的包装器构建：

```nix
# 部分应用：没有剩余的参数时
if effectiveRemainingArgs == { } then
  { module = warnedModule denArgs; wrapped = true; }

# 包装器路径：有碰撞可能时
else
  let
    policy = resolveCollisionPolicy { inherit ctx aspectPolicy globalPolicy; };
    classWinsNames = builtins.filter (name: policy name == "class-wins") denArgNames;
    classWinsDen = lib.genAttrs classWinsNames (k: denArgs.${k});
    denWinsDen = removeAttrs denArgs classWinsNames;
    wrapper = moduleArgs:
      warnedModule (classWinsDen // moduleArgs // resolvedDen);
  in
  { module = lib.setFunctionArgs wrapper advertisedArgs; ... }
```

参数注入顺序：`class-wins` Den 参数 → 模块系统参数 → `den-wins` Den 参数

______________________________________________________________________

## `wrapImportsModule`

### 签名

```nix
wrapImportsModule : {
  module :: AttrSet,  # 必须有 imports
  ctx :: Context,
  aspectPolicy :: StringOrNull,
  globalPolicy :: String
} -> WrappedModule
```

处理具有 `imports` 列表的 attrset，递归地将 `wrapClassModule` 应用于每个导入的元素：

```nix
wrapImportsModule = args:
  let
    result = wrapDeferredImports { ... } module.imports;
    policy = resolveCollisionPolicy { ... };
    denArgNames = builtins.attrNames ctx;
    validator = mkCollisionValidator policy denArgNames;
  in
  {
    module = module // { inherit (result) imports; };
    inherit (result) wrapped;
  }
  // lib.optionalAttrs (result.wrapped && ctx != { }) {
    inherit validator;
    ...
  };
```

### `wrapDeferredImports`

递归下降到导入树中，为每个请求 Den 上下文参数的函数模块调用 `wrapClassModule`：

```nix
wrapDeferredImports = args: imports:
  let
    go = imp:
      if builtins.isFunction imp then
        wrapClassModule (args // { module = imp; })
      else if builtins.isAttrs imp && imp ? imports then
        let inner = map go imp.imports; in
        { wrapped = anyWrapped; value = imp // { imports = map (r: r.value) inner; }; }
      else
        { wrapped = false; value = imp; };
  in { ... };
```

______________________________________________________________________

## `resolveCollisionPolicy`

### 签名

```nix
resolveCollisionPolicy : {
  ctx :: Context,
  aspectPolicy :: StringOrNull,
  globalPolicy :: String
} -> String -> String
```

### 策略解析顺序

1. **方面级**（`aspectPolicy != null`）：使用 `aspect.meta.collisionPolicy`
1. **实体级**（`ctx.{name}.collisionPolicy`）：如 `host.collisionPolicy`
1. **预计算策略**（`ctx.__collisionPolicies.{name}`）：来自 `resolveEntity` 的模式条目
1. **全局策略**（`globalPolicy`）：`den.config.classModuleCollisionPolicy`

______________________________________________________________________

## 配置 thunk 解析

当管道的 `assemblePipes` 生成包含 `__configThunk` 标记的值时，`wrapFunctionModule` 在模块包装器内部惰性地解析它们：

```nix
pipeThunks = ctx.__pipeConfigThunks or { };
hasConfigThunks = denArgsWithThunks != [ ];

# 在包装器内部
resolveMarkers = config: values:
  builtins.concatMap (v:
    if v ? __configThunk then
      let
        thunkArgs = builtins.functionArgs v.__fn;
        ctxArgs = lib.genAttrs (builtins.filter (k: ctx ? ${k}) ...) (k: ctx.${k});
        result = v.__fn (ctxArgs // { inherit config lib; });
      in
      if builtins.isList result then result else [ result ]
    else [ v ]
  ) values;
```

这打破了循环依赖：管道值在模块系统内部被解析，此时 `evalModules` 的定点 `config` 可用。

______________________________________________________________________

## 关联函数

- `fx.resolve` — 后处理组装，wrapClassModule 在阶段 1（wrapPerScope）中被调用
- `fx.wrap-classes` — 类封装传递，wrapClassModule 的上层调度入口
- `fx.assemble-pipes` — 管道数据组装，为 wrapClassModule 提供上下文（含管道值）
- `fx.pipeline` — 管道编排器，wrapClassModule 处理管道输出的类模块
- `fx.key-classification` — 键分类决定哪些键被作为类模块发射

## 关联文档

- [核心概念](../../../02-%E6%A0%B8%E5%BF%83%E6%A6%82%E5%BF%B5.md) — 扁平形式的类模块参数说明（含 `host`、`user` 等 Den 参数）
- [方面配置指南](../../../04-%E6%96%B9%E9%9D%A2%E9%85%8D%E7%BD%AE%E6%8C%87%E5%8D%97.md) — 类模块编写规范
- [自定义类](../../../10-%E8%87%AA%E5%AE%9A%E4%B9%89%E7%B1%BB.md) — 碰撞策略在自定义类中的应用
