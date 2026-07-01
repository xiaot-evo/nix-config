# ci 模板

**测试套件** — Den 框架的 133+ 测试用例集合。不是供用户复制的模板，而是 Den 自身的 CI 门禁和回归测试套件。

> **注意**：本模板不是供用户直接复制的开始模板。如果你需要最小可复现环境提交 bug，请使用 [bogus](./bogus.md) 模板。如果你想学习 Den 的 API 用法，`public-api/` 目录中的测试文件是最好的参考。

## 用途

- Den 框架的 CI 门禁（`nix flake check` / `just ci`）
- 回归测试（`deadbugs/` 目录）
- 学习 Den API 用法的用户（`public-api/` 测试）

## 目录结构

```
templates/ci/
├── flake.nix              # 入口（evalModules + import-tree，10 输入）
├── flake.lock
├── provider/              # 外部命名空间提供者（测试用子 flake）
├── non-dendritic/         # 非 dendritic 模块（裸 NixOS/Darwin 模块）
└── modules/
    ├── new-test.nix       # 可复制的测试模板（创建新测试的起点）
    ├── test-support/
    │   └── eval-den.nix   # 基础框架：导入 denTest，连接 Den
    ├── public-api/        # ～50 个高层用户 API 测试
    ├── internal-api/      # ～70 个管道内部机制测试
    ├── deadbugs/          # ～30 个回归测试（对应 GitHub issue）
    ├── deprecated/        # ～13 个已弃用 API 兼容性测试
    └── features/          # 4 个较新功能的测试
```

## Flake 输入

| 输入 | 来源 | 用途 |
|------|------|------|
| `den` | github:denful/den | Den 框架 |
| `nixpkgs` | nixpkgs-unstable | 包集合 |
| `import-tree` | github:vic/import-tree | 递归导入 |
| `home-manager` | github:nix-community/home-manager | 用户环境 |
| `darwin` | github:nix-darwin/nix-darwin | macOS 配置 |
| `nix-unit` | github:nix-community/nix-unit | 测试运行器 |
| `nix-effects` | github:denful/nix-effects | 效果测试 |
| `gen-schema` | github:sini/gen-schema | schema 生成 |
| `provider` | path:./provider | 测试用命名空间提供者 |
| `files` | github:mightyiam/files | 文件处理 |

## 测试分类

### public-api/（～50 文件）— 高层用户 API

| 文件 | 测试内容 |
|------|----------|
| `nested-aspects.nix` | 直接嵌套、多层嵌套、参数化父级 |
| `flat-hosts.nix` | 扁平主机声明语法 |
| `homes.nix` | Home 实体声明 |
| `policies.nix` | 基本策略触发和共存 |
| `pipes.nix` | Pipe 系统声明、分类、消费 |
| `namespaces.nix` | 外部命名空间提供者导入 |
| `forward-*.nix` | 各种前置模式（别名、互斥、自定义类、条件） |
| `routes.nix` | Route 机制 |
| `define-user.nix` | 用户定义电池 |
| `strict.nix` | 严格模式 |
| ... | |

### internal-api/（～70 文件）— 管道内部

涵盖 FX 管道的每个阶段：

| 领域 | 文件 |
|------|------|
| 编译阶段 | `fx-compile-static`, `fx-compile-parametric`, `fx-compile-conditional`, `fx-compile-forward`, `fx-compile-router` |
| 门控 | `fx-gate` |
| 解析 | `fx-resolve` |
| 边/拓扑排序 | `fx-edges-pi`, `fx-toposort-edges`, `fx-instantiate-edges`, `fx-materialize-unified` |
| 范围/标识 | `fx-identity`, `fx-scope-effects` |
| 约束 | `fx-constraints`, `fx-coverage` |
| 追踪/诊断 | `fx-trace`, `fx-diag-capture`, `fx-diag-context` |
| 端到端 | `fx-e2e`, `fx-full-pipeline` |
| 前置/解析 | `forward`, `forward-to`, `cross-context-forward`, `resolve` |
| 策略 | `policy-type`, `policy-combinators`, `policy-include-routing` |
| 其他 | `ctx-chain`, `stages`, `pure-eval`, `namespace`, `inheritance` |

### deadbugs/（～30 文件）— 回归测试

对应 GitHub issue 编号：

| Issue | 描述 |
|-------|------|
| #201 | forward 到多用户 |
| #216 | 重复 functor |
| #254 | HM 上下文用户 includes |
| #297 | mutual 未包含 static |
| #311 | 嵌套 includes 参数化 |
| #408 | 裸函数作为 aspect |
| #429 | 参数化 aspect 在 include 时调用 |
| #460 | 参数化去重 |
| #525 | hasAspect 在 policy-when 中 |
| #540 | 条件首 include / exclude guard |
| #580 | 自输出分类递归 |
| #588 | 命名空间 provides 别名 |
| #609 | 主机作用域 HM 泄漏 |
| #613 | exclude 兄弟隔离 |
| ... | |

### deprecated/（～13 文件）— 已弃用 API

测试已弃用 API 的向后兼容性：`parametric.nix`、`perUser-perHost.nix`、`ctx-compat.nix` 等。

### features/（4 文件）— 新功能

`entity-isolation.nix`、`projected-hasaspect-rules.nix`、`relationship-fanout.nix`、`user-scoped-host-class-fanout.nix`。

## denTest 框架

### 基本模式

```nix
{ denTest, ... }:
{
  flake.tests.my-suite = {
    test-my-thing = denTest (
      { den, igloo, tuxHm, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.aspects.igloo.nixos.networking.hostName = "test";
        expr = igloo.networking.hostName;
        expected = "test";
      }
    );
  };
}
```

### denTest 参数

| 参数 | 说明 |
|------|------|
| `den` | den 模块配置 |
| `igloo` | `nixosConfigurations.igloo.config` |
| `tuxHm` | `igloo.home-manager.users.tux` |
| `apple` | `darwinConfigurations.apple.config` |
| `funnyNames` | 从方面收集 "funny" 类值 |

### 运行测试

```bash
# 全部
just ci
# 特定套件
just ci nested-aspects
# 特定测试
just ci nested-aspects.test-direct-nesting-basic
# 直接用 nix-unit
nix-unit --override-input den . --flake ./templates/ci#.tests.<suite>
```

## 与其他模板对比

| 特性 | ci | bogus |
|------|-----|-------|
| 用途 | **完整测试套件** | Bug 复现 |
| 测试数 | 133+ | 1 |
| 测试类型 | 单元测试 + 集成测试 + 回归 | 可编辑调试 |
| 工具 | nix-unit + nix-effects | nix-unit |
| 适用者 | Den 贡献者/维护者 | Bug 报告者 |
