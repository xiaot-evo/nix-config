# nsTypes 模块

**源文件**: `nix/lib/namespace-types.nix`

## 概述

命名空间类型定义。定义了 `namespaceType`——`den.ful` 命名空间选项声明的类型。该类型创建了一个包含 `schema`（每种实体类型的自由形式延迟模块）、`classes`（导入时合并到 `den.classes` 的类声明）和自由形式方面条目的子模块结构。

---

## `namespaceType`

### 签名
```nix
namespaceType :: SubmoduleType
```

### 用途

定义 `den.ful.<name>` 选项的类型。每个命名空间是一个子模块，允许用户在特定名称下注册 schema 结构、类声明和方面条目。

### 子模块结构

```nix
{
  options.schema = {
    description = "命名空间 schema——每种实体类型的自由形式延迟模块";
    default = { };
    type = submodule {
      freeformType = lazyAttrsOf deferredModule;
    };
  };
  
  options.classes = {
    description = "导入时合并到 den.classes 的类声明";
    default = { };
    type = lazyAttrsOf raw;
  };
  
  # 自由形式：方面条目（前缀为命名空间名称的方面类型）
  freeformType = mkAspectsType { providerPrefix = [ name ]; };
}
```

### 子选项说明

| 选项 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `schema` | `submodule (freeformType = lazyAttrsOf deferredModule)` | `{}` | 每种实体类型（`host`、`user`、`home` 等）的 schema 定义。每个键是一种实体类型，值是延迟模块。 |
| `classes` | `lazyAttrsOf raw` | `{}` | 类声明。键是类名（如 `nixos`、`darwin`），值是类配置 attrset。导入时合并到全局 `den.classes` 注册表。 |

### 自由形式方面条目

除了 `schema` 和 `classes`，命名空间的自由形式部分接受任何方面条目（实体方面、电池等）。这些条目的类型由 `mkAspectsType` 生成，前缀为命名空间名称。

### 使用示例

```nix
# 在 flake 输出中声明命名空间
{
  denful.den = {
    schema.host = { ... };
    schema.user = { ... };
    classes.nixos = { ... };
    
    # 方面条目
    aspects.igloo.nixos = { ... };
    batteries.git = { ... };
  };
}
```

```nix
# namespace.nix 内部使用 namespaceType 定义 den.ful 选项
options.den.ful = lib.mkOption {
  type = lib.types.lazyAttrsOf namespaceType;
  default = { };
};
```

### 实现简析

1. 使用 `lib.types.submodule` 创建子模块类型
2. `schema` 选项使用 `freeformType = lib.types.lazyAttrsOf lib.types.deferredModule`——任何未声明的键都被视为延迟模块定义
3. `classes` 选项使用 `lib.types.lazyAttrsOf lib.types.raw`——接受任意 attrset 值
4. 自由形式类型通过 `mkAspectsType` 生成，`providerPrefix = [ name ]` 确保方面提供者路径以命名空间名称为前缀

### 为什么 schema 使用 deferredModule？

`schema` 选项存储每种实体类型的模块定义。使用 `deferredModule` 而不是 `raw` 允许 schema 条目参与模块系统的类型检查和合并，同时保持惰性（仅在需要时评估）。

---

## 关联函数

- `types.md` — 方面类型系统，`mkAspectsType` 在其中定义
- `namespace.md` — 命名空间模块，使用 `namespaceType` 定义 `den.ful` 选项
- `den.lib.types` — 实体类型定义，与命名空间 schema 类型协同工作

## 关联文档

- [den.ful 选项系统](../../modules/options.md) — den.ful 选项的整体架构
- [命名空间指南](../../namespace-guide.md) — 外部命名空间的导入和使用
