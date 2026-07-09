# 实体共享类型（Shared Entity Types）

**源文件**: `nix/lib/entities/_types.nix`

## 概述

本模块提取了所有实体类型定义共享的辅助函数。位于 `nix/lib/types.nix` 中实体的内部实现——在分离为 `host.nix` 和 `home.nix` 时提取。

______________________________________________________________________

## strOpt — 可选字符串

**签名**: `(description: string, default: string) → option`

### 用途

创建预定义类型为 `str` 的选项，简化重复的 `lib.mkOption` 调用。

### 参数说明

| 参数 | 类型 | 说明 |
|------|------|------|
| `description` | `string` | 选项的描述文本 |
| `default` | `string` | 选项的默认值 |

### 返回值

一个 NixOS 模块选项，类型为 `lib.types.str`。

### 实现

```nix
strOpt = description: default:
lib.mkOption {
  type = lib.types.str;
  inherit description default;
};
```

### 使用示例

```nix
# 在实体选项中使用
options = {
  name = strOpt "host configuration name" name;
  system = strOpt "platform system" system;
  description = strOpt "host description"
    "${config.class}.${config.hostName}@${config.system}";
};
```

______________________________________________________________________

## lookupAspect — 查找方面

**签名**: `(den: attrset, config: attrset) → aspect`

### 用途

根据实体名称在 `den.aspects` 中查找对应的方面。如果未定义，发出警告并使用空方面。

### 参数说明

| 参数 | 类型 | 说明 |
|------|------|------|
| `den` | `attrset` | Den 配置（包含 `den.aspects`） |
| `config` | `attrset` | 当前实体的配置（须有 `name` 字段） |

### 返回值

`den.aspects.${config.name}` 的值，或空 `{}`。

### 实现

```nix
lookupAspect = den: config:
if den.aspects ? ${config.name} then
  den.aspects.${config.name}
else
  lib.warn "den.aspects.${config.name} not defined — entity gets empty aspect" { };
```

### 使用示例

```nix
# 在主机实体中
aspect = lib.mkOption {
  default = lookupAspect den config;
};
```

### 行为说明

- 如果 `den.aspects.igloo` 存在，主机 `igloo` 获得该方面
- 如果不存在，发出警告并使用空方面，使主机仍然可以工作

______________________________________________________________________

## mainModuleOption — 主模块选项

**签名**: `(den: attrset, config: attrset) → option`

### 用途

创建内部只读选项，存储通过方面管道解析生成的主模块。主机和家庭实体共享完全相同的实现。

### 参数说明

| 参数 | 类型 | 说明 |
|------|------|------|
| `den` | `attrset` | Den 配置（提供 `den.lib.aspects.resolve`） |
| `config` | `attrset` | 实体配置（须有 `class` 和 `resolved` 字段） |

### 返回值

一个 `deferredModule` 类型的 NixOS 模块选项。

### 实现

```nix
mainModuleOption = den: config:
lib.mkOption {
  internal = true;
  visible = false;
  readOnly = true;
  type = lib.types.deferredModule;
  defaultText = "den.lib.aspects.resolve config.class config.resolved";
  default = den.lib.aspects.resolve config.class config.resolved;
};
```

### 使用示例

```nix
# 在主机和家庭实体中
hostType = lib.types.submodule ({ name, config, ... }: {
  options.mainModule = mainModuleOption den config;
});
```

### 说明

- `internal = true`：对用户不可见
- `readOnly = true`：只读，不可由用户设置
- `type = deferredModule`：延迟评估，避免无限递归
- 值通过 `den.lib.aspects.resolve` 在评估时计算

______________________________________________________________________

## 关联

- **`host.nix`**: 主机实体，使用所有三个助手
- **`home.nix`**: 家庭实体，使用所有三个助手
- **`types.nix`**: 旧版类型定义（`_types.nix` 从中提取）
