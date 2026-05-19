# 方面身份管理

**源文件**: `nix/lib/aspects/fx/identity.nix`

## 概述

方面身份系统为每个方面节点提供全局唯一的标识符。身份用于去重（通过 `check-dedup`）、约束定位（排除/替换目标）、路径集收集以及管道中的调试追踪。

---

## `aspectPath`

### 签名
```nix
aspectPath : Aspect -> [String]
```

### 用途
从方面 attrset 构造其规范路径组件列表。路径是 `meta.provider ++ [name] ++ [{ctxId}]` 的形式。

### 参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `a` | Aspect | 方面 attrset（必须有 `name` 和可选的 `meta.provider`、`__ctxId`） |

### 返回
字符串列表，表示从提供者链到方面名称再到上下文实例的路径。

### 示例
```nix
aspectPath { name = "postgres"; meta.provider = [ ]; }
# → [ "postgres" ]

aspectPath { name = "postgres"; meta.provider = [ "igloo" "services" ]; }
# → [ "igloo" "services" "postgres" ]

aspectPath { name = "postgres"; meta.provider = [ "igloo" ]; __ctxId = "host=igloo"; }
# → [ "igloo" "postgres" "{host=igloo}" ]
```

### 实现
```nix
aspectPath = a:
  (a.meta.provider or [ ])
  ++ [ (a.name or "<anon>") ]
  ++ lib.optional (a ? __ctxId) "{${a.__ctxId}}";
```

提供者链通过 `typeCfg.providerPrefix` 在 `aspectSubmodule` 中逐层累积。每个嵌套级别将当前名称附加到前缀：

```nix
providerPrefix = (typeCfg.providerPrefix or [ ]) ++ [ config.name ];
```

---

## `pathKey`

### 签名
```nix
pathKey : [String] -> String
```

### 用途
将路径组件列表转换为可用的字符串键（用 `/` 连接）。

### 示例
```nix
pathKey [ "igloo" "services" "postgres" ]
# → "igloo/services/postgres"
```

---

## `key`

### 签名
```nix
key : Aspect -> String
```

### 用途
`aspectPath` → `pathKey` 的单步组合。

```nix
key = a: pathKey (aspectPath a);
```

### 示例
```nix
key { name = "postgres"; meta.provider = [ "igloo" ]; }
# → "igloo/postgres"
```

---

## `isAnonIdentity`

### 签名
```nix
isAnonIdentity : String -> Bool
```

### 用途
检查身份字符串是否引用匿名/未解析节点。匿名节点获取 `null` 去重键，因此它们不会被去重。

### 匿名检测
- 名称本身不是有意义的（`"<anon>"`、`"<function body>"` 或以 `[definition ` 开头）
- 以 `"<root>/"` 开头
- 包含 `"/<anon>:"`（匿名包含索引标记）

```nix
isAnonIdentity = id:
  !(den.lib.aspects.isMeaningfulName id)
  || lib.hasPrefix "<root>/" id
  || lib.hasInfix "/<anon>:" id;
```

---

## `stripCtxSuffix`

### 签名
```nix
stripCtxSuffix : String -> String
```

### 用途
从身份字符串中去除 `/{ctxId}` 后缀，返回基础身份。用于 `wrap-classes.nix` 中，上下文无关的模块获取剥离后的身份。

### 示例
```nix
stripCtxSuffix "igloo/postgres/{host=igloo}"
# → "igloo/postgres"
```

---

## `toPathSet`

### 签名
```nix
toPathSet : [[String]] -> AttrSet String Bool
```

### 用途
将路径列表转换为 attrset（路径键 → true）。用于直接构造路径集，无需经过完整管道。

```nix
toPathSet = paths:
  builtins.listToAttrs (
    builtins.map (p: { name = pathKey p; value = true; }) paths
  );
```

---

## `tombstone`

### 签名
```nix
tombstone : Aspect -> AttrSet -> Aspect
```

### 用途
创建一个"墓碑"方面——标记已排除的方面，保留其原始元数据并添加排除信息。墓碑包含 `meta.excluded = true`、`meta.originalName` 和调用者提供的额外元数据，但 `includes = [ ]`。

### 参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `resolved` | Aspect | 被排除的已解析方面 |
| `extra` | AttrSet | 要合并的额外元数据 |

### 示例
```nix
tombstone aspect { excludedFrom = "some-owner"; }
# → { name = "~aspectName"; meta = { excluded = true; originalName = "..."; excludedFrom = "some-owner"; }; includes = []; }
```

---

## `collectPathsHandler`

### 签名
```nix
collectPathsHandler : Handler
```

### 效果键
`"resolve-complete"`

### 用途
在 `pathSet` 状态中记录每个方面身份（包括基础路径，无上下文 ID）。当方面被排除时跳过记录。

### 存储的内容
```nix
state.pathSet = _: state.pathSet null // {
  "igloo/postgres" = true;                    # 完整路径
  "igloo/postgres" = true;                    # 基础路径（与 ctxId 相同或不同）
};
```

如果 `baseKey != key`（即有 `{ctxId}`），基础路径也被记录，因此 `hasAspect` 可以在不需要知道特定上下文实例的情况下匹配。

---

## `pathSetHandler`

### 签名
```nix
pathSetHandler : Handler
```

### 效果键
`"get-path-set"`

### 用途
从状态中检索当前 `pathSet`。用于 `collectPathSet` 在管道完成后提取路径集。

---

## 身份在去重中的作用

在 `checkDedupHandler` 中，去重键构造为：

```nix
rawDedupKey = if isMeaningfulName name then identity.key child else null;
dedupKey = "${scope}/${rawDedupKey}";
```

这意味着：
- **有意义的名称**：`{scope}/{provider}/{name}` 格式的去重键，如 `host=igloo/igloo/postgres`
- **匿名节点**：去重键为 `null`，不会被去重
- **作用域分割**：相同方面在不同作用域中被视为不同的，允许每个实体独立包含

---

## 身份在约束中的作用

约束系统使用身份键定位目标方面：

```nix
excludeFields = ref: {
  type = "exclude";
  identity = pathKey (aspectPath ref);
};
```

约束匹配器在 `check-constraint` 效果中检查当前方面身份是否匹配注册的排除/替换身份。

---

## 关联函数

- `fx.pipeline` — 管道编排器，身份在去重、约束、路径收集中被使用
- `fx.constraints` — 约束系统，通过身份键定位排除/替换目标
- `den.lib.aspects.has-aspect` — 方面查询系统，hasAspectIn 使用 aspectPath/pathKey 计算 refKey
- `den.lib.aspects.types` — 方面类型系统，aspectType 通过 meta.provider 累积身份路径
- `den.lib.aspects` — 顶层方面引擎，collectPathSet 依赖身份路径收集

## 关联文档

- [方面配置指南](../../../04-方面配置指南.md) — 方面去重和身份识别的概念
- [核心概念](../../../02-核心概念.md) — 方面解析和去重机制
