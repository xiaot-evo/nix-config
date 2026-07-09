# Den 框架中文文档

> Den 是一个面向方面的、上下文驱动的 Dendritic Nix 配置框架。
> 本文档面向普通 NixOS 用户，从入门到高级，涵盖所有概念和用法。

______________________________________________________________________

## 使用指南

由浅入深，从概念到实践。

| # | 文件 | 内容 |
|---|------|------|
| 00 | [Den 框架简介](./00-%E7%AE%80%E4%BB%8B.md) | 什么是 Den、与传统 NixOS 的区别、核心哲学、使用场景 |
| 01 | [快速开始](./01-%E5%BF%AB%E9%80%9F%E5%BC%80%E5%A7%8B.md) | 从零搭建 Den 项目，分步指南 + 完整示例 |
| 02 | [核心概念详解](./02-%E6%A0%B8%E5%BF%83%E6%A6%82%E5%BF%B5.md) | 实体、方面、策略、管道、类、电池、命名空间 |
| 03 | [声明主机和用户](./03-%E5%A3%B0%E6%98%8E%E4%B8%BB%E6%9C%BA%E5%92%8C%E7%94%A8%E6%88%B7.md) | hosts/homes/users 声明方式及选项详解 |
| 04 | [方面配置指南](./04-%E6%96%B9%E9%9D%A2%E9%85%8D%E7%BD%AE%E6%8C%87%E5%8D%97.md) | 方面结构、includes、provides、四种形态 |
| 05 | [内置电池](./05-%E5%86%85%E7%BD%AE%E7%94%B5%E6%B1%A0.md) | 所有 den.batteries 详解及代码示例 |
| 06 | [Home Manager 集成](./06-home-manager%E9%9B%86%E6%88%90.md) | HM/Hjem/Maid 集成、独立 vs 主机管理 |
| 07 | [策略系统](./07-%E7%AD%96%E7%95%A5%E7%B3%BB%E7%BB%9F.md) | 7 种策略效果、内置策略、激活机制 |
| 08 | [管道与 Quirks](./08-%E7%AE%A1%E9%81%93%E4%B8%8Equirks.md) | 结构化数据流、生产者消费者模式 |
| 09 | [命名空间](./09-%E5%91%BD%E5%90%8D%E7%A9%BA%E9%97%B4.md) | den.ful、角度括号语法、外部导入 |
| 10 | [自定义类](./10-%E8%87%AA%E5%AE%9A%E4%B9%89%E7%B1%BB.md) | 转发方面、守卫、适配器、碰撞策略 |
| 11 | [高级主题](./11-%E9%AB%98%E7%BA%A7%E4%B8%BB%E9%A2%98.md) | Fleet、作用域划分、调试、代数效应、图库 |
| 12 | [从其他框架迁移](./12-%E4%BB%8E%E5%85%B6%E4%BB%96%E6%A1%86%E6%9E%B6%E8%BF%81%E7%A7%BB.md) | 从 NixOS/flake-parts 迁移到 Den |
| 13 | [常见问题与排错](./13-%E5%B8%B8%E8%A7%81%E9%97%AE%E9%A2%98.md) | FAQ、调试方法、社区资源 |
| **14** | **[实用模式汇总](./14-%E5%AE%9E%E7%94%A8%E6%A8%A1%E5%BC%8F.md)** | **17 个实战模式 —— 跨类路由、角色组合、Pipe 数据流、转发类等** |

______________________________________________________________________

## 模板指南

| 文件 | 内容 |
|------|------|
| [README](./examples/README.md) | **总览**：13 个模板的用途、复杂度评级、选择指南 |
| [minimal](./examples/minimal.md) | 最小 NixOS 配置（3 输入，无 flake-parts/HM） |
| [default](./examples/default.md) | **推荐起点**：flake-parts + HM + VM 工作流 |
| [noflake](./examples/noflake.md) | 无 flake 使用 Den（npins + nix-maid/hjem） |
| [bogus](./examples/bogus.md) | Bug 复现和报告模板 |
| [scoped-import-tree](./examples/scoped-import-tree.md) | 作用域导入树 + 库自动注入 |
| [example](./examples/example.md) | 跨平台（NixOS + nix-darwin）完整示例 |
| [flake-parts-modules](./examples/flake-parts-modules.md) | 转发类与 perSystem 工具集成 |
| [diagram-demo](./examples/diagram-demo.md) | 管道捕捉 + 可视化诊断 |
| [fleet-demo](./examples/fleet-demo.md) | Fleet 多主机编排与 Pipe 数据流 |
| [microvm](./examples/microvm.md) | MicroVM 集成（独立 + 托管） |
| [nvf-standalone](./examples/nvf-standalone.md) | 独立 Neovim 应用配置 |
| [terranix-demo](./examples/terranix-demo.md) | Terraform/OpenTofu 集成 |
| [ci](./examples/ci.md) | 测试套件（133+ 用例） |

______________________________________________________________________

## 函数参考

按模块分组的函数级分析文档，每个函数包含签名、用途、参数、示例和实现简析。

### lib 核心库

| 文件 | 函数 |
|------|------|
| [aspects](./functions/lib/aspects.md) | resolve / resolveImports / resolveWithState / normalizeRoot / hasAspectIn / collectPathSet / mkEntityHasAspect |
| [aspects/types](./functions/lib/aspects/types.md) | aspectType / providerType / aspectContentType / \_\_isPolicy |
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
| [options](./functions/modules/options.md) | den.\* 选项完整参考 |
| [aspects-definition](./functions/modules/aspects-definition.md) | 方面定义基础设施 |
| [policies](./functions/modules/policies.md) | 内置策略 |
| [outputs](./functions/modules/outputs.md) | 输出生成 |

______________________________________________________________________

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
