# 方面查询系统

**源文件**: `nix/lib/aspects/has-aspect.nix`

## 概述

提供在方面树中查询特定方面是否存在的工具。这允许实体配置根据某个方面是否在其树中而被有条件地包含。

______________________________________________________________________

## `hasAspectIn`

### 签名

```nix
hasAspectIn : { tree :: Aspect, class :: String, ref :: Aspect } -> Bool
```

### 用途

在给定的方面树中查询是否存在指定 ref 的方面。

### 参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `tree` | Aspect | 要搜索的方面树（如 `den.aspects.igloo`） |
| `class` | String | 解析时使用的目标类（如 `"nixos"`） |
| `ref` | Aspect | 要查找的方面引用（必须同时有 `name` 和 `meta`） |

### 示例

```nix
hasAspectIn {
  tree = den.aspects.igloo;
  class = "nixos";
  ref = den.batteries.home-manager;
}
# → true 如果 igloo 方面树中包含 home-manager
```

### 实现

1. 使用 `refKey` 从 ref 计算规范路径键：`pathKey (aspectPath ref)`
1. 调用 `collectPathSet` 解析树并收集所有身份路径
1. 检查 ref 的键是否存在于收集到的路径集中

```nix
hasAspectIn = { tree, class, ref }:
  (collectPathSet { inherit tree class; }) ? ${refKey ref};
```

______________________________________________________________________

## `collectPathSet`

### 签名

```nix
collectPathSet : { tree :: Aspect, class :: String } -> AttrSet String Bool
```

### 用途

对方面树进行全面管道解析，并从结果状态中提取 `pathSet`——这是树中所有已解析方面身份的集合。

### 示例

```nix
collectPathSet {
  tree = den.aspects.igloo;
  class = "nixos";
}
# → { "igloo" = true; "igloo/networkd" = true; ... }
```

### 实现细节

1. 使用 `normalizeRoot` 规范化根方面（处理裸 lambda、functor attrset）
1. 从 `__scopeHandlers` 提取上下文
1. 通过 `fxFullResolve` 运行完整管道解析
1. 从 `result.state.pathSet` 获取路径集

______________________________________________________________________

## `mkEntityHasAspect`

### 签名

```nix
mkEntityHasAspect : {
  tree :: Aspect,
  primaryClass :: String,
  classes :: [String]
} -> {
  __functor :: (ref -> Bool),
  forClass :: String -> Aspect -> Bool,
  forAnyClass :: Aspect -> Bool
}
```

### 用途

为实体创建一个可调用的查询工具，用于针对一个或多个类测试方面的存在。结果的 `__functor` 使其可以直接作为函数调用（默认使用 `primaryClass`）。

### 参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `tree` | Aspect | 要搜索的方面树 |
| `primaryClass` | String | 默认查询的类（如 `"nixos"`） |
| `classes` | [String] | 所有可用的类列表，用于 `forAnyClass` |

### 返回

```nix
{
  __functor = _: bareFn;          # default: primaryClass
  forClass = class: ref -> Bool;  # 在指定类中查询
  forAnyClass = ref -> Bool;      # 在任意类中查询
}
```

### 示例

```nix
# 在实体配置中使用
let
  hasAspect = mkEntityHasAspect {
    tree = den.aspects.igloo;
    primaryClass = "nixos";
    classes = [ "nixos" "homeManager" ];
  };
in
{
  # 直接使用（默认 primaryClass）
  services.nginx.enable = hasAspect den.features.nginx;

  # 指定类
  services.nginx.enable = hasAspect.forClass "nixos" den.features.nginx;

  # 查询任意类
  someOption = if hasAspect.forAnyClass den.features.nginx then ... else ...;
}
```

### 实现

1. 对主类和所有附加类运行 `collectPathSet`（每个类一次完整管道解析）
1. 为 `forClass` 和 `forAnyClass` 创建闭包函数
1. `forAnyClass` 使用 `lib.any` 检查所有类中是否有匹配

______________________________________________________________________

## 身份键计算

### `refKey`

```nix
refKey = ref:
  if (ref ? name) && (ref ? meta) then
    pathKey (aspectPath ref)
  else
    throw "hasAspect: ref must have both `name` and `meta` (got ${builtins.typeOf ref}).";
```

确保 ref 具有完整的身份信息（通过 `mergeWithAspectMeta` 注入的 `name` 和 `meta`）。否则抛出一个明确的错误。

______________________________________________________________________

## 关联函数

- `den.lib.aspects` — 方面引擎主模块，hasAspectIn/collectPathSet/mkEntityHasAspect 的所在模块
- `den.lib.aspects.types` — 方面类型系统，提供身份元数据（name、meta）的类型定义
- `den.lib.aspects.fx.identity` — 身份路径计算（aspectPath/pathKey），是 hasAspect 中 refKey 计算的基础
- `den.lib.aspects.fx.pipeline` — 管道编排器，collectPathSet 通过 fxFullResolve 获取 pathSet
- `den.lib.aspects.normalizeRoot` — 方面规范化，collectPathSet 内部调用

## 关联文档

- [方面配置指南](../../04-%E6%96%B9%E9%9D%A2%E9%85%8D%E7%BD%AE%E6%8C%87%E5%8D%97.md) — 方面查询和条件化配置的使用场景
- [高级主题](../../11-%E9%AB%98%E7%BA%A7%E4%B8%BB%E9%A2%98.md) — hasAspect 在调试和条件配置中的应用
