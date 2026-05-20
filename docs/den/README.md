# Den 框架中文文档

> Den 是一个面向方面的、上下文驱动的 Dendritic Nix 配置框架。
> 本文档面向普通 NixOS 用户，从入门到高级，涵盖所有概念和用法。

---

## 使用指南

由浅入深，从概念到实践。

| # | 文件 | 内容 |
|---|------|------|
| 00 | [Den 框架简介](./00-简介.md) | 什么是 Den、与传统 NixOS 的区别、核心哲学、使用场景 |
| 01 | [快速开始](./01-快速开始.md) | 从零搭建 Den 项目，分步指南 + 完整示例 |
| 02 | [核心概念详解](./02-核心概念.md) | 实体、方面、策略、管道、类、电池、命名空间 |
| 03 | [声明主机和用户](./03-声明主机和用户.md) | hosts/homes/users 声明方式及选项详解 |
| 04 | [方面配置指南](./04-方面配置指南.md) | 方面结构、includes、provides、四种形态 |
| 05 | [内置电池](./05-内置电池.md) | 所有 den.batteries 详解及代码示例 |
| 06 | [Home Manager 集成](./06-home-manager集成.md) | HM/Hjem/Maid 集成、独立 vs 主机管理 |
| 07 | [策略系统](./07-策略系统.md) | 7 种策略效果、内置策略、激活机制 |
| 08 | [管道与 Quirks](./08-管道与quirks.md) | 结构化数据流、生产者消费者模式 |
| 09 | [命名空间](./09-命名空间.md) | den.ful、角度括号语法、外部导入 |
| 10 | [自定义类](./10-自定义类.md) | 转发方面、守卫、适配器、碰撞策略 |
| 11 | [高级主题](./11-高级主题.md) | Fleet、作用域划分、调试、代数效应、图库 |
| 12 | [从其他框架迁移](./12-从其他框架迁移.md) | 从 NixOS/flake-parts 迁移到 Den |
| 13 | [常见问题与排错](./13-常见问题.md) | FAQ、调试方法、社区资源 |

---

## 函数参考

按模块分组的函数级分析文档，每个函数包含签名、用途、参数、示例和实现简析。

### lib 核心库

| 文件 | 函数 |
|------|------|
| [aspects](./functions/lib/aspects.md) | resolve / resolveImports / resolveWithState / normalizeRoot / hasAspectIn / collectPathSet / mkEntityHasAspect |
| [aspects/types](./functions/lib/aspects/types.md) | aspectType / providerType / aspectContentType / __isPolicy |
| [aspects/has-aspect](./functions/lib/aspects/has-aspect.md) | hasAspectIn / collectPathSet / mkEntityHasAspect |
| [can-take](./functions/lib/can-take.md) | atLeast / exactly / upTo |
| [forward](./functions/lib/forward.md) | forwardItem / forwardEach |
| [resolve-entity](./functions/lib/resolve-entity.md) | resolveEntity |
| [synthesize-policies](./functions/lib/synthesize-policies.md) | resolveArgsSatisfied |
| [home-env](./functions/lib/home-env.md) | makeHomeEnv |
| [nh](./functions/lib/nh.md) | denPackages / denShell / hostApps / homeApps |
| [namespace](./functions/lib/namespace.md) | namespace |
| [policy-effects](./functions/lib/policy-effects.md) | resolve / include / exclude / route / instantiate / provide / pipe / for / when / mkPolicy |
| [policy-inspect](./functions/lib/policy-inspect.md) | inspect |
| [strict](./functions/lib/strict.md) | strict 模块 |
| [den-brackets](./functions/lib/den-brackets.md) | 角度括号语法解析 |
| [schema-util](./functions/lib/schema-util.md) | schemaEntityKinds |
| [types](./functions/lib/types.md) | 库类型导出 |
| [nsTypes](./functions/lib/nsTypes.md) | namespaceType（`den.ful` 选项类型） |
| [fx](./functions/lib/fx.md) | `den.lib.fx` — nix-effects 代数效果库重导出 |

### FX 管道

| 文件 | 函数 |
|------|------|
| [pipeline](./functions/lib/aspects/fx/pipeline.md) | mkPipeline / fxFullResolve / mkScopeId |
| [identity](./functions/lib/aspects/fx/identity.md) | aspectPath / pathKey / key |
| [key-classification](./functions/lib/aspects/fx/key-classification.md) | classifyKeys / classKeys / nestedKeys / pipeKeys |
| [constraints](./functions/lib/aspects/fx/constraints.md) | exclude / substitute / filterBy |
| [includes](./functions/lib/aspects/fx/includes.md) | includeIf |
| [class-module](./functions/lib/aspects/fx/class-module.md) | wrapClassModule |
| [resolve](./functions/lib/aspects/fx/resolve.md) | wrap / provide / route / instantiate |
| [wrap-classes](./functions/lib/aspects/fx/wrap-classes.md) | 类封装传递 |
| [assemble-pipes](./functions/lib/aspects/fx/assemble-pipes.md) | 管道数据组装 |
| [trace](./functions/lib/aspects/fx/trace.md) | 结构化跟踪处理程序 |
| [content-util](./functions/lib/aspects/fx/content-util.md) | 内容展开工具（`unwrapContentValuesList` 等） |
| [handlers/README](./functions/lib/aspects/fx/handlers/README.md) | 全部 37 个管道处理程序总览 |
| [aspect/README](./functions/lib/aspects/fx/aspect/README.md) | 子方面操作（emitIncludes、emitAspectPolicies） |

### 实体类型

| 文件 | 内容 |
|------|------|
| [host](./functions/lib/entities/host.md) | 主机实体类型选项 |
| [home](./functions/lib/entities/home.md) | 家庭实体类型选项 |
| [types](./functions/lib/entities/types.md) | 共享类型辅助 |

### 图库 (diag)

| 文件 | 内容 |
|------|------|
| [overview](./functions/lib/diag/overview.md) | 图库总览 |
| [capture](./functions/lib/diag/capture.md) | 跟踪捕获 |
| [graph](./functions/lib/diag/graph.md) | 图 IR 构建 |
| [mermaid](./functions/lib/diag/mermaid.md) | Mermaid 渲染 |
| [dot](./functions/lib/diag/dot.md) | Graphviz DOT 渲染 |
| [plantuml](./functions/lib/diag/plantuml.md) | PlantUML 渲染 |
| [c4](./functions/lib/diag/c4.md) | C4 模型渲染 |
| [filters](./functions/lib/diag/filters.md) | 7 种过滤器 |
| [fleet](./functions/lib/diag/fleet.md) | 舰队图 |

### 电池

| 文件 | 内容 |
|------|------|
| [README](./functions/batteries/README.md) | 所有电池索引 |

### NixOS 模块选项

| 文件 | 内容 |
|------|------|
| [options](./functions/modules/options.md) | den.* 选项完整参考 |
| [aspects-definition](./functions/modules/aspects-definition.md) | 方面定义基础设施 |
| [policies](./functions/modules/policies.md) | 内置策略 |
| [outputs](./functions/modules/outputs.md) | 输出生成 |

---

## 快速导航

如果你是 Den **新手**，建议按顺序阅读：
00 → 01 → 02 → 03 → 04 → 05 → 06

如果你已基本了解，想深入某个主题：
- 策略 → 07
- 管道 → 08
- 命名空间 → 09
- 自定义类 → 10
- 高级 → 11
- 迁移 → 12

如果你在找某个函数的具体用法，请直接查看函数参考目录（functions/）。
