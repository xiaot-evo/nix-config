# 主机实体（Host Entity）

**源文件**: `nix/lib/entities/host.nix`

## 概述

主机实体定义了 Den 框架中 NixOS/darwin 主机的数据模型。通过 `den.hosts` 选项声明，每个主机包含系统信息、网络配置、用户列表及实例化策略。

______________________________________________________________________

## hostsOption — 主机选项类型

**签名**: `submodule { system → submodule { hostName → hostType } }`

### 用途

`den.hosts` 选项的类型定义。按系统架构分组（如 `x86_64-linux`、`aarch64-darwin`），每组包含一组主机定义。

### 结构

```
den.hosts = {
  <system> = {
    <hostName> = {
      # 自由格式字段 + 预定义选项
    };
  };
};
```

### 示例

```nix
{
  den.hosts."x86_64-linux" = {
    igloo = {
      hostName = "igloo";
      system = "x86_64-linux";
      nixos.services.ssh.enable = true;
    };
    tuxbook = {
      hostName = "tuxbook";
      class = "nixos";
      users.tux = { };
      aspects.tux.userShell = "fish";
    };
  };
}
```

______________________________________________________________________

## 主机选项字段

### `name`

- **类型**: `str`
- **默认值**: 主机配置名称（模块中的 `name` 参数）
- **说明**: 主机配置的唯一标识名

### `hostName`

- **类型**: `str`
- **默认值**: `config.name`
- **说明**: 网络主机名，用于设置系统 hostname

### `system`

- **类型**: `str`
- **默认值**: 所在系统架构组名（如 `"x86_64-linux"`）
- **说明**: 平台系统标识

### `class`

- **类型**: `str`
- **默认值**: 根据 `system` 自动推导：`darwin` 后缀 → `"darwin"`，否则 `"nixos"`
- **说明**: Nix 配置类。支持 `"nixos"`、`"darwin"`、`"systemManager"`

### `aspect`

- **类型**: `raw`（不合并）
- **默认值**: `lookupAspect den config`（查找 `den.aspects.<name>`）
- **说明**: 配置该主机的方面。缺失时发出警告并使用空方面

### `description`

- **类型**: `str`
- **默认值**: `"${config.class}.${config.hostName}@${config.system}"`
- **说明**: 主机描述

### `users`

- **类型**: `attrsOf userType`
- **默认值**: `{}`
- **说明**: 用户账号声明。每个用户是一个子模块

### `instantiate`

- **类型**: `raw`
- **默认值**: 按类自动选择：
  - `nixos` → `inputs.nixpkgs.lib.nixosSystem`
  - `darwin` → `inputs.darwin.lib.darwinSystem`
  - `systemManager` → `inputs.system-manager.lib.makeSystemConfig`
- **说明**: 实例化 OS 配置的函数。需要自定义时（如使用 `nixos-unstable`）可覆盖

### `intoAttr`

- **类型**: `listOf str`
- **默认值**: 按类：
  - `nixos` → `["nixosConfigurations" name]`
  - `darwin` → `["darwinConfigurations" name]`
  - `systemManager` → `["systemConfigs" name]`
- **说明**: Flake 输出属性路径。`flake.<intoAttr>.<name>` 指向生成的配置

### `mainModule`

- **类型**: `deferredModule`（只读）
- **默认值**: `den.lib.aspects.resolve config.class config.resolved`
- **说明**: 通过方面管道解析生成的主模块。用于 flake 输出构建

______________________________________________________________________

## 用户子实体选项（`host.users.<name>`）

### `name`

- **类型**: `str`
- **默认值**: 用户名（模块中的 `name` 参数）

### `userName`

- **类型**: `str`
- **默认值**: 用户名
- **说明**: OS 用户账号名

### `classes`

- **类型**: `listOf str`
- **默认值**: `["user"]`
- **说明**: 家庭管理 Nix 类。可扩展以支持多个用户环境

### `aspect`

- **类型**: `raw`
- **默认值**: `lookupAspect den config`（查找 `den.aspects.<name>`）
- **说明**: 配置该用户的方面

### `host`

- **类型**: 主机模块的引用
- **默认值**: `host`（父主机实体）
- **说明**: 子实体对父主机的反向引用，用于上下文感知

______________________________________________________________________

## 模式定义

主机实体使用 `freeformType = lib.types.attrsOf lib.types.anything`，并导入 `den.schema.host` 模式模块。这意味着：

1. 预定义选项优先匹配
1. 未知属性（如 `nixos.services.ssh`）作为自由格式通过
1. 模式可通过 `den.schema.host.includes` 扩展

## 关联

- **`_types.nix`**: 共享的 `strOpt`、`lookupAspect`、`mainModuleOption` 助手
- **`home.nix`**: 家庭实体，共享相同的类型助手
- **`options.nix`**: `den.hosts` 选项声明
- **`policies/core.nix`**: `host-to-users` 策略，将主机方面扇出到用户
