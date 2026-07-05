# 方面类型系统

**源文件**: `nix/lib/aspects/types.nix`

## 概述

类型系统定义了方面（aspect）的结构约束、合并行为和身份管理。它是 Den FX 管道的类型基础——所有方面内容在进入管道前都必须通过这些类型进行合并和验证。

______________________________________________________________________

## `aspectType`

### 签名

```nix
aspectType : TypeConfig -> SubmoduleType
```

### 用途

构造一个方面子模块类型。这是方面定义的中心类型——它将任意 attrset 转换为具有结构化选项（name、meta、includes、provides、policies、classes、excludes）和自由形式键（按运行时注册表分类）的方面。

### 参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `typeCfg` | attrset | 类型配置，包含 `providerPrefix`（用于跟踪提供者链） |

### 返回

NixOS 子模块类型，具有：

- **结构化选项**：`name`、`description`、`meta`、`includes`、`excludes`、`provides`、`policies`、`classes`
- **自由形式类型**：剩余键被自动创建为 `aspectKeyType`（根据注册表分派为类模块或嵌套方面）

### 合并行为

`mergeWithAspectMeta` 增强了标准子模块合并：

1. **身份注入**：从定义位置（`loc`）自动派生 `name` 和 `meta.file`
1. **`__functor` 救援**：保留显式的 `__functor`（如 `den.batteries.forward`），防止被自由形式合并破坏
1. **provides 转发**：将 `provides` 的子键提升到方面顶层，使 `aspect.docker` 解析为 `aspect.provides.docker`
1. **合成 `_` 别名**：`_` 属性别名为 `provides`（通过 `lib.mkAliasOptionModule`），同时合成一个 `__functor` 包装的合成方面，暴露自由形式子键为 includes

```nix
den.aspects.myAspect = {
  nixos = { ... };        # → 类键（如果 nixos 在 den.classes 中注册）
  docker = { ... };        # → 提供子键（通过 provides.docker 转发）
  # _ 是 provides 的别名
};
```

### 函数合并策略

| 定义组合 | 行为 |
|----------|------|
| 所有定义都是 attrset | 标准子模块合并 |
| 纯参量函数（单一定义） | 返回原始包装器（避免完整的子模块评估以节省内存） |
| 纯参量函数（多个定义） | 每个函数被强制转换为 `{ includes = [fn]; }`，然后通过 aspectType 合并 |
| 混合函数 + attrset | 参量函数被强制转换为 includes |
| 包含子模块函数（lib/config/options） | 通过 aspectType 合并，**不被**强制转换为 includes |

______________________________________________________________________

## `providerType`

### 签名

```nix
providerType : TypeConfig -> OptionType
```

### 用途

用于 `includes` 列表和 `provides` 自由形式的类型。它是 `aspectType` 的包装器，增加了函数接受能力——provides 条目可以是方面 attrset、函数或参量包装器。

### 合并分派逻辑

```
defs →
  内容包装器（__contentValues）?
    → 提取内部函数，进入正常分派
  __isPolicy 列表?
    → 作为策略传递（通过列表原样）
  参量包装器（__fn/__args）?
    → 单一定义：返回原始包装器（OOM 保护）
    → 多个或混合：解包 __fn 为 includes
  混合函数 + attrset?
    → 参量函数强制转换为 includes
  纯函数（包含子模块函数）?
    → 通过 aspectType 合并
  纯函数（纯参量，单一定义）?
    → 返回原始包装器
  纯函数（纯参量，多个定义）?
    → 每个强制转换为 includes
  多个 __functor?
    → 抛出错误：合并不明确
  纯 attrset?
    → 标准子模块合并
```

______________________________________________________________________

## `aspectContentType`

### 签名

```nix
aspectContentType : TypeConfig -> OptionType
```

### 用途

方面自由形式键（类模块、弯曲发射、嵌套方面）的通用内容包装器。每个值都带有出处元数据（`__contentValues`、`__provider`）。

### 包装语义

```
输入值 → 是否已包装（有 __contentValues）?
  → 展开 __contentValues，扁平化嵌套
多站点定义 → 每个源文件保留，合并到 __contentValues 列表
单值 attrset → 直接转发（性能优化路径，跳过逐键合并）
多值 attrset → 逐键合并：
  - 单定义键：直接转发
  - 多定义键：包装在 __contentValues 中
  - 列表值键：连接
__functor 包装（单函数）:
  允许调用内容包装器：den.aspects.wm.gnome-autologin "benjamin"
_ 合成:
  像方面根一样，内容包装器也获得合成 _. 暴露子键
```

### 内容包装器的结构

```nix
{
  __contentValues = [ { value = <raw>; file = <source>; } ... ];
  __provider = [ "aspectName" "keyName" ];
  __providesForwarded = [ "child" ... ];
  _ = { __functor = ...; };  # 合成子方面
  # 每个子键作为直接属性转发
}
```

______________________________________________________________________

## `aspectKeyType`

### 签名

```nix
aspectKeyType : TypeConfig -> OptionType
```

### 用途

方面子模块自由形式的统一类型。目前所有键都使用 `aspectContentType` 包装。注册表查找使用 `den.classes or {}`（由电池模块和 `aspect-schema.nix` 填充——没有循环依赖，因为声明性选项访问不会触发自由形式合并）。

______________________________________________________________________

## `metaType`

### 签名

```nix
metaType : TypeConfig -> config -> SubmoduleType
```

### 方面元数据选项

| 选项 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `handleWith` | `nullOr handlerValue` | `null` | 此方面子树的解析处理程序 |
| `provider` | `listOf str` | `typeCfg.providerPrefix` | 提供者路径，跟踪方面出处（内部、不可见） |
| `collisionPolicy` | `nullOr (enum ["error" "class-wins" "den-wins"])` | `null` | 扁平形式类模块参数与模块系统参数重叠时的碰撞策略 |

______________________________________________________________________

## `__isPolicy` — 策略类型标记

**源文件**: `nix/lib/aspects/policy-type.nix`

策略函数被包装为 `{ __isPolicy = true; name = <name>; fn = <function>; }` 记录。它们通过策略注册表类型注册，并被管道路由到 `register-aspect-policy` 效果，而不是方面解析。

```nix
policyRegistryType = lib.types.lazyAttrsOf policyFnType;
```

```nix
# 策略函数签名
{ host, user, ... } -> [ effects... ]
```

______________________________________________________________________

## `isParametricWrapper` — 鸭子类型检测

```nix
isParametricWrapper = v: builtins.isAttrs v && v ? __fn && v ? __args;
```

检测一个值是否是参量包装器（`__fn` + `__args`）。用于在合并分派期间识别需要参数绑定的方面工厂。`__` 前缀约定使得假阳性不太可能但并非不可能——如果需要显式标记，添加 `_type = "den:parametric"`。

______________________________________________________________________

## `isSubmoduleFn` — 模块函数检测

```nix
isSubmoduleFn = canTake.upTo { lib = true; config = true; options = true; };
```

检测一个函数是否是 NixOS 子模块函数（接受 `lib`、`config`、`options`）。这些函数**不**被强制转换为 includes——它们由 `wrapChild` 的 `normalizeModuleFn` 处理。

______________________________________________________________________

## `isMeaningfulName` — 有意义的名称检测

```nix
isMeaningfulName =
  name: name != "<anon>" && name != "<function body>" && !(lib.hasPrefix "[definition " name);
```

用于去重：匿名节点（由管道生成）获取 `null` 去重键，因此不会被去重。

______________________________________________________________________

## 关联函数

- `den.lib.aspects` — 方面引擎主模块，types 是方面系统的类型基础
- `den.lib.aspects.fx.key-classification` — 键分类系统，依赖 aspectType 注册的类/管道注册表
- `den.lib.aspects.fx.identity` — 身份路径计算，aspectType 通过 meta.provider 累积身份
- `den.lib.aspects.fx.pipeline` — 管道编排器，使用 aspectType 构建的方面进行解析
- `den.lib.aspects.normalizeRoot` — 方面规范化，与类型的函数合并策略交互

## 关联文档

- [核心概念](../../02-%E6%A0%B8%E5%BF%83%E6%A6%82%E5%BF%B5.md) — 方面（Aspects）的四种形态和结构说明
- [方面配置指南](../../04-%E6%96%B9%E9%9D%A2%E9%85%8D%E7%BD%AE%E6%8C%87%E5%8D%97.md) — 方面类型系统的实际应用
