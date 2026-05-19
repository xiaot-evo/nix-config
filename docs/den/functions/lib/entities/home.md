# 家庭实体（Home Entity）

**源文件**: `nix/lib/entities/home.nix`

## 概述

家庭实体定义 Den 框架中独立 Home Manager 配置的数据模型。通过 `den.homes` 选项声明，支持绑定到特定主机（`user@host` 语法）或独立运行。

---

## homesOption — 家庭选项类型

**签名**: `submodule { system → submodule { name → homeType } }`

### 用途

`den.homes` 选项的类型定义。按系统架构分组，每组包含独立家庭配置。

### 结构

```
den.homes = {
  <system> = {
    <name> = {
      # 支持 "user@host" 命名约定
      # 自由格式字段 + 预定义选项
    };
  };
};
```

### 示例

```nix
{
  den.homes."x86_64-linux" = {
    # 绑定到主机的家庭（user@host 语法）
    "alice@igloo" = {
      homeManager.programs.git.enable = true;
    };
    # 独立家庭（不绑定主机）
    "bob" = {
      homeManager.programs.git.enable = true;
    };
  };
}
```

---

## 命名约定：`user@host`

家庭配置名支持 `user@host` 格式：

- **`alice@igloo`**：alice 用户在 igloo 主机上的家庭配置
- **`bob`**：独立的 Bob 用户家庭配置（不绑定主机）

使用 `user@host` 格式时，Den 会自动绑定：
- `hostByName` = `den.hosts.${system}.${hostName}`
- `userByName` = `hostByName.users.${userName}`
- `instantiate` 会自动传递 `osConfig`（`osConfig = flake.<host.intoAttr>.config`）

---

## 家庭选项字段

### `name`

- **类型**: `str`
- **默认值**: 解析后的用户名（`user@host` 格式中的用户名部分）
- **说明**: 家庭配置的名称

### `userName`

- **类型**: `str`
- **默认值**: 解析后的用户名
- **说明**: 用户账号名

### `hostName`

- **类型**: `nullOr str`
- **默认值**: 从 `user@host` 格式解析；若无则为 `null`
- **说明**: 关联主机名。`null` 表示独立家庭

### `user`

- **类型**: 用户实体引用
- **默认值**: 从 `den.hosts` 查找的用户子实体
- **说明**: 对关联用户实体的反向引用

### `host`

- **类型**: 主机实体引用
- **默认值**: 从 `den.hosts` 查找的主机实体
- **说明**: 对关联主机实体的反向引用

### `system`

- **类型**: `str`
- **默认值**: 所在系统架构组名
- **说明**: 平台系统标识

### `class`

- **类型**: `str`
- **默认值**: `"homeManager"`
- **说明**: 家庭管理 Nix 类

### `aspect`

- **类型**: `raw`（不合并）
- **默认值**: `lookupAspect den config`
- **说明**: 配置该家庭的方面

### `description`

- **类型**: `str`
- **默认值**: `"home.${config.name}@${config.system}"`
- **说明**: 家庭配置描述

### `pkgs`

- **类型**: `raw`
- **默认值**: `inputs.nixpkgs.legacyPackages.${config.system}`
- **说明**: 构建家庭配置使用的 nixpkgs 实例

### `instantiate`

- **类型**: `raw`
- **默认值**: `inputs.home-manager.lib.homeManagerConfiguration`
- **说明**: 实例化家庭配置的函数。绑定到主机的版本会自动传入 `extraSpecialArgs.osConfig`

### `intoAttr`

- **类型**: `listOf str`
- **默认值**: `["homeConfigurations" name]`
- **说明**: Flake 输出属性路径

### `mainModule`

- **类型**: `deferredModule`（只读）
- **默认值**: `den.lib.aspects.resolve config.class config.resolved`
- **说明**: 通过方面管道解析的主模块

---

## 绑定主机的实例化

当家庭绑定到主机时（`user@host` 格式），`instantiate` 的行为不同：

```nix
# 绑定主机的实例化会自动传递 osConfig
{ pkgs, modules }:
inputs.home-manager.lib.homeManagerConfiguration {
  inherit pkgs modules;
  extraSpecialArgs.osConfig = lib.attrByPath
    (["flake"] ++ hostByName.intoAttr ++ ["config"])
    null
    top.config;
}
```

这使得家庭配置可以直接访问 OS 级配置。

---

## 关联

- **`_types.nix`**: 共享的 `strOpt`、`lookupAspect`、`mainModuleOption` 助手
- **`host.nix`**: 主机实体，家庭可以绑定到主机
- **`options.nix`**: `den.homes` 选项声明
