# 示例模板指南

Den 框架提供了 13 个示例模板，覆盖从入门到高级集成的各种场景。本文档逐一分析每个模板的用途、结构和关键模式，帮助你选择合适的起点。

## 模板总览

| 模板 | 场景 | 复杂度 | 输入数 | flake-parts | home-manager | 关键特点 |
|------|------|--------|--------|-------------|--------------|---------|
| [minimal](./minimal.md) | 最小 NixOS 配置 | ⭐ | 3 | ❌ | ❌ | 最简依赖，手工 flake.nix |
| [default](./default.md) | 标准入门模板 | ⭐⭐ | 6 | ✅ | ✅ | 推荐起点，含 VM 工作流 |
| [noflake](./noflake.md) | 无 flake 使用 Den | ⭐⭐ | — | ❌ | ❌ | npins 锁依赖，nix-maid/hjem |
| [bogus](./bogus.md) | Bug 复现/测试 | ⭐ | 5 | ✅ | ✅ | 最小可复现问题模板 |
| [scoped-import-tree](./scoped-import-tree.md) | 作用域导入树 | ⭐⭐ | 6 | ❌ | ❌ | 自动注入库，角括号语法 |
| [example](./example.md) | 跨平台示例 | ⭐⭐⭐ | 8 | ✅ | ✅ | NixOS + nix-darwin |
| [flake-parts-modules](./flake-parts-modules.md) | flake-parts 模块集成 | ⭐⭐⭐ | 9 | ✅ | ❌ | 转发类，perSystem 桥接 |
| [diagram-demo](./diagram-demo.md) | 可视化/诊断 | ⭐⭐⭐⭐ | 8 | ✅ | ✅ | 捕捉 + den-diagram 渲染 |
| [fleet-demo](./fleet-demo.md) | 多主机编排 | ⭐⭐⭐⭐⭐ | 7 | ✅ | ✅ | 自定义实体，Pipe 系统 |
| [microvm](./microvm.md) | MicroVM 集成 | ⭐⭐⭐⭐ | 4 | ❌ | ❌ | 自定义策略链，VM 路由 |
| [nvf-standalone](./nvf-standalone.md) | 独立应用配置 | ⭐⭐⭐ | 4 | ❌ | ❌ | Neovim 打包，自定义类 |
| [terranix-demo](./terranix-demo.md) | Terraform 集成 | ⭐⭐⭐ | 8 | ✅ | ✅ | 自定义类，策略实例化 |
| [ci](./ci.md) | 测试套件 | 🔬 | 10 | ❌ | ✅ | 133+ 测试用例，denTest 框架 |

## 选择指南

### 从零开始

- 我想要**最简单**的 NixOS 配置 → [minimal](./minimal.md)
- 我想要**标准**的 Den 体验（含 VM、HM、nh） → [default](./default.md)
- 我不想用 **flakes** → [noflake](./noflake.md)
- 我想要**库自动注入**和角括号语法 → [scoped-import-tree](./scoped-import-tree.md)

### 学习和演示

- 我想看**跨平台**（NixOS + macOS） → [example](./example.md)
- 我想看**多主机编排**和 Pipe 系统 → [fleet-demo](./fleet-demo.md)
- 我想看**可视化诊断**图 → [diagram-demo](./diagram-demo.md)

### 集成外部工具

- 我想在 Den 中用 **flake-parts 模块**（devshell、treefmt） → [flake-parts-modules](./flake-parts-modules.md)
- 我想在 Den 中管理 **MicroVM** → [microvm](./microvm.md)
- 我想用 Den 配置 **Neovim**（纯应用，无 NixOS） → [nvf-standalone](./nvf-standalone.md)
- 我想在 Den 中生成 **Terraform** 配置 → [terranix-demo](./terranix-demo.md)

### 开发和测试

- 我想**复现 Den 的 bug** → [bogus](./bogus.md)
- 我想**学习 Den 内部测试** → [ci](./ci.md)

## 创建入口模式

Den 的模板使用两种 flake 入口模式：

### flake-parts 模式（推荐）

```nix
outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
```

用于：`default`、`example`、`diagram-demo`、`fleet-demo`、`flake-parts-modules`、`terranix-demo`

### evalModules 模式

```nix
outputs = inputs:
  (inputs.nixpkgs.lib.evalModules {
    modules = [ (inputs.import-tree ./modules) ];
    specialArgs = { inherit inputs; };
  }).config.flake;
```

用于：`minimal`、`noflake`、`ci`、`microvm`、`nvf-standalone`、`scoped-import-tree`

两种模式最终都通过 `import-tree ./modules` 自动递归导入 `modules/` 下所有 `.nix` 文件。主要区别在于 **flake-parts** 提供 `perSystem` 支持和模块组合能力，而 **evalModules** 更简洁、依赖更少。
