# 方面定义基础设施（Aspect Definition Infrastructure）

**源文件**: `nix/nixModule/aspects.nix`、`nix/lib/aspects/types.nix`、`nix/nixModule/default.nix`

## 概述

Den 的方面定义基础设施自动管理 `den.aspects`、`den.default` 和 `den.batteries` 选项的类型和注入。本页涵盖框架如何自动创建方面条目、注入默认方面以及定义电池选项类型。

______________________________________________________________________

## aspectsType — 方面选项类型

**源文件**: `lib/aspects/types.nix`

**签名**: `aspectsType` → `optionType`

### 用途

定义 `den.aspects` 选项的类型。类型较为宽松以支持方面树的各种形式（静态 attrset、参数化函数、functor）。

### 使用示例

```nix
# nix/nixModule/aspects.nix
options.den.aspects = lib.mkOption {
  description = "Den Aspects";
  default = { };
  type = aspectsType;
};
```

### 类型行为

- 顶层：`lazyAttrsOf` 方面类型
- 每个方面是含 `freeformType = attrsOf anything` 的子模块
- `.provides`（`.` 的同义词）：子方面命名空间
- 在 `deploy` 环境下使用避免重复

______________________________________________________________________

## 自动创建 den.aspects 条目

当用户在 `den.hosts`、`den.homes` 中声明实体时，框架通过 `lookupAspect` 自动查找 `den.aspects.<name>`：

```nix
# 在 host.nix 中：
aspect = lib.mkOption {
  default = lookupAspect den config;
  # 如果 den.aspects.igloo 不存在，发出警告并使用 {}
};
```

### 隐式创建

如果用户定义了：

```nix
den.hosts."x86_64-linux".igloo = {
  nixos.services.ssh.enable = true;
};
```

但没有定义 `den.aspects.igloo`，实体得到一个空方面（发出警告）。方面定义是显式的。

### 方面名称解析

`den.aspects.<name>` 中的 `name` 与实体名匹配。支持的分辨率：

- 主机名匹配：`den.aspects.igloo` → `den.hosts.<system>.igloo`
- 用户名匹配：`den.aspects.tux` → `host.users.tux`
- 家庭名匹配：`den.aspects.myHome` → `den.homes.<system>.myHome`

______________________________________________________________________

## den.default 注入

**源文件**: `nix/nixModule/default.nix`

### 用途

定义全局默认方面，自动包含到所有实体中。

### 声明

```nix
options.den.default = lib.mkOption {
  description = "Default aspect";
  type = den.lib.aspects.types.aspectType;
};
```

### 注入机制

`den.default` 在每个实体的模式（schema）中被包含。在实体自身的方面之前合并：

```
实体解析顺序：
  den.schema.<entity> (系统默认)
  → den.default (全局默认，用户可配置)
  → den.aspects.<name> (实体本身的方面)
```

### 使用示例

```nix
# 对所有主机/用户/家庭启用
den.default.includes = [
  den.batteries.hostname
  den.batteries.define-user
  den.batteries.self'
];
```

______________________________________________________________________

## den.batteries 选项类型

**源文件**: `modules/aspects/batteries.nix`、`nix/lib/aspects/types.nix`

### 用途

注册预构建的可复用电池方面。

### 声明

```nix
options.den.batteries = lib.mkOption {
  description = "Den batteries";
  default = { };
  type = lib.types.attrsOf lib.types.raw;
};
```

### 电池注册

每个电池文件向 `den.batteries` 添加一个条目：

```nix
# batteries/hostname.nix
{ ... }: {
  den.batteries.hostname = {
    name = "hostname";
    description = "Sets the system hostname...";
    includes = [ setHostname ];
  };
}
```

### 电池类型

电池可以是：

1. **简单的 attrset**：`{ name, description, includes }`
1. **参数化函数**：`{ __functor = _self: (arg: { ... }); }`（如 `den.batteries.unfree ["pkg"]`）
1. **方面注入**：直接方面值（如 `den.batteries.primary-user`）

______________________________________________________________________

## 完整流程

```
用户声明实体 → 类型系统创建选项
  → den.default 注入 → 每个实体获得默认方面
  → lookupAspect 解析 den.aspects.<name>
     → 如果存在：使用该方面
     → 如果不存在：警告 + 空方面
  → 方面管道执行 resolves includes/provides
  → 类模块输出
```

______________________________________________________________________

## 关联

- **`options.nix`**: 主模块选项声明
- **`lib/entities/host.nix`**: 主机实体中的 `lookupAspect` 用法
- **`lib/entities/home.nix`**: 家庭实体中的 `lookupAspect` 用法
- **`lib/aspects/types.nix`**: `aspectsType` 的完整实现
- **`batteries/README.md`**: 电池文档
