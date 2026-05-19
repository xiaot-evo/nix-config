# Den 函数参考索引

**源路径**: `nix/lib/`

## 概述

Den 库 (`den.lib`) 是 Den 框架的核心函数集合，通过 `nix/lib/default.nix` 自动加载。所有函数以 `den.lib.<模块>.<函数>` 的形式暴露给用户。

库的代码在纯 Nix 中实现（无需模块系统），但部分函数通过 `config` 访问运行时注册信息（如 `den.classes`、`den.schema`）。

## 函数分类索引

| 模块 | 文件 | 功能 |
|---|---|---|
| `den.lib.aspects` | `nix/lib/aspects/` | 方面引擎：解析、规范化、查询 |
| `den.lib.canTake` | `nix/lib/can-take.nix` | 函数参数检测 |
| `den.lib.forward` | `nix/lib/forward.nix` | 转发方面构建 |
| `den.lib.resolveEntity` | `nix/lib/resolve-entity.nix` | 实体根方面创建 |
| `den.lib.synthesizePolicies` | `nix/lib/synthesize-policies.nix` | 策略参数检查 |
| `den.lib.home-env` | `nix/lib/home-env.nix` | 家庭环境集成 |
| `den.lib.nh` | `nix/lib/nh.nix` | nh 工具集成 |
| `den.lib.namespace` | `nix/lib/namespace.nix` | 外部命名空间导入 |
| `den.lib.policy` | `nix/lib/policy-effects.nix` | 策略效果构造器 |
| `den.lib.policyInspect` | `nix/lib/policy-inspect.nix` | 策略检查 |
| `den.lib.strict` | `nix/lib/strict.nix` | 严格模式 |
| `den.lib.__findFile` | `nix/lib/den-brackets.nix` | `<den/...>` 语法解析 |
| `den.lib.schemaUtil` | `nix/lib/schema-util.nix` | 模式工具函数 |
| `den.lib.types` | `nix/lib/types.nix` | 类型兼容层 |

## 快速查找指南

- **正在使用 Aspects 模式？** → `den.lib.aspects`
- **需要策略（政策）效果？** → `den.lib.policy`
- **为主机或用户创建根方面？** → `den.lib.resolveEntity`
- **跨类转发模块？** → `den.lib.forward`
- **调试策略为什么不触发？** → `den.lib.policyInspect`
- **集成 home-manager 服务？** → `den.lib.home-env`
- **创建 nh 构建/部署命令？** → `den.lib.nh`
- **导入外部 Denful 命名空间？** → `den.lib.namespace`
- **启用严格模式？** → `den.lib.strict`
- **理解 `<den/X/Y>` 语法？** → `den.lib.__findFile`（即 `den-brackets.nix`）
