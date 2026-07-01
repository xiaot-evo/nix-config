# bogus 模板

**Bug 复现模板** — 用于在隔离环境中复现和报告 Den 框架的 bug，是最小可复现问题（MRE）的标准格式。

## 用途

- 向 Den 维护者提交最小可复现的 bug 报告
- 在开发新功能前隔离测试某个特定行为
- 贡献 bug 修复（所有 PR 均欢迎）

## 目录结构

```
templates/bogus/
├── flake.nix              # 入口（flake-parts + import-tree）
├── flake.lock
├── README.md
├── .github/workflows/test.yml  # CI：nix flake check
└── modules/
    ├── test-base.nix      # 基础测试框架（DO-NOT-EDIT）
    └── bug.nix            # 可编辑的测试文件
```

## Flake 输入

| 输入 | 来源 | 用途 |
|------|------|------|
| `nixpkgs` | nixos-unstable (tarball) | 包集合 |
| `den` | github:denful/den/main | Den 框架（main 分支） |
| `import-tree` | github:vic/import-tree | 递归导入 |
| `flake-parts` | github:hercules-ci/flake-parts | perSystem |
| `nix-unit` | github:nix-community/nix-unit | 测试运行器 |
| `home-manager` | github:nix-community/home-manager | 用户环境 |

## 实体结构

```nix
den.hosts.x86_64-linux.igloo.users.tux = { };
```

- 标准测试主机 `igloo`（x86_64-linux）
- 标准测试用户 `tux`
- 主机名和用户名与 Den 的 `denTest` 框架保持一致

## 关键模式

### denTest 测试框架

`bug.nix` 中使用：

```nix
{ denTest, ... }:
{
  flake.tests.bogus = {
    test-something = denTest (
      { den, igloo, tuxHm, ... }:
      {
        # 1. 定义实体
        den.hosts.x86_64-linux.igloo.users.tux = { };

        # 2. 编写方面
        den.aspects.tux.user.description = "The Penguin";

        # 3. 断言
        expr = igloo.users.users.tux.description;
        expected = "The Penguin";
      }
    );
  };
}
```

### denTest 提供的关键参数

| 参数 | 值 |
|------|-----|
| `den` | den 模块配置 |
| `igloo` | `nixosConfigurations.igloo.config` |
| `tuxHm` | `igloo.home-manager.users.tux` |
| `apple` | `darwinConfigurations.apple.config` |

### 多版本测试

CI 工作流使用 `sed` 替换 den 输入 URL 并运行 `nix flake update den`，可在不同 Den 版本间矩阵测试。

### 运行测试

```bash
cd templates/bogus
nix flake check                     # 运行所有测试
nix-unit --override-input den .     # 使用本地 Den 代码
```

## 与其他模板对比

| 特性 | bogus | ci |
|------|-------|-----|
| 目的 | **Bug 复现** | 完整测试套件 |
| 文件数 | 5 | 200+ |
| denTest | ✅ | ✅ |
| 测试类型 | 单个测试 | 133+ 测试用例 |
| 可编辑范围 | `bug.nix` 自由修改 | 全部模板 |
