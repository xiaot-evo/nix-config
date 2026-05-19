# types 模块

**源文件**: `nix/lib/types.nix`

## 概述

类型兼容层。实体类型已拆分为 `nix/lib/entities/` 下的单独文件。此文件是向后兼容的重新导出垫片（shim），为任何外部消费者提供统一的入口点。

## 签名

`(args: attrset) → { hostsOption, homesOption }`

## 参数说明

- `args: attrset` — 标准模块参数（`lib`、`config`、`inputs` 等），传递给实体子模块

## 返回值说明

当前导出的类型：
- `hostsOption` — 来自 `entities/host.nix`，包含 `den.hosts` 选项的类型定义
- `homesOption` — 来自 `entities/home.nix`，包含 `den.homes` 选项的类型定义

## 使用示例

```nix
# 直接使用类型
let
  types = den.lib.types { inherit lib config inputs; };
in
{
  options.myHosts = lib.mkOption {
    type = types.hostsOption;
  };
}
```

## 实体类型文件

实体类型已按类型拆分：

### entities/host.nix

定义 `hostsOption`——`den.hosts` 的类型定义。包含主机实体 schema。

### entities/home.nix

定义 `homesOption`——`den.homes` 的类型定义。包含家庭实体 schema。

### entities/_types.nix

共享类型定义。

---

## 关联函数

- `den.lib.nsTypes` — 命名空间类型
- `modules/aspect-schema.nix` — 方面 schema 的类型系统
