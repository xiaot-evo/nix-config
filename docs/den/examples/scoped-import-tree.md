# scoped-import-tree 模板

**作用域导入树** — 将 Den 框架库和第三方库自动注入每个模块的求值作用域，无需手动传递 `specialArgs`。

## 用途

- 同时使用 Den 和多个配套库（ned、pipe、bend）的项目
- 需要角括号语法（`<igloo>`）在模块文件中工作的场景
- 偏好 evalModules 且希望减少样板代码的团队

## 目录结构

```
templates/scoped-import-tree/
├── flake.nix              # 入口（evalModules + scoped.nix）
├── flake.lock
├── README.md
├── scoped.nix             # 核心：构造作用域导入树
└── modules/
    ├── den.nix            # Den 主机/用户/方面 + flake 烟雾测试
    └── nh.nix             # nh 构建命令
```

## Flake 输入

| 输入 | 来源 | 用途 |
|------|------|------|
| `nixpkgs` | nixpkgs-unstable (tarball) | 包集合 |
| `den` | github:denful/den | Den 框架 |
| `import-tree` | github:vic/import-tree | 递归导入 |
| `ned` | github:denful/ned | 配套库 |
| `pipe` | github:denful/pipe | 配套库 |
| `bend` | github:denful/bend | 配套库 |

## 实体结构

```nix
den.hosts.x86_64-linux.igloo.users.tux = {
  classes = [ "user" ];
};
```

- 单个主机 `igloo`，用户 `tux`（user 类，无 home-manager）

## 关键模式

### scoped.nix 核心机制

```nix
let
  den-lib = inputs.den.lib { inherit inputs lib config; };
  ned = inputs.ned.lib { inherit inputs; };
  pipe = inputs.pipe.lib;
  bend = inputs.bend.lib;

  import-tree =
    inputs.import-tree
      (it: it.addScoped { inherit ned pipe bend; })     # 第一次作用域注入
      (it: it.addScoped den-lib)                         # 第二次作用域注入
    ;
in {
  imports = [ (import-tree ./modules) ];
}
```

`import-tree.addScoped` 将库注入模块求值作用域。**后续在 `modules/` 下任意 .nix 文件中**，这些库可以直接出现在函数参数中：

```nix
# 无需 specialArgs，自动可用
{ den, lib, inputs, ned, pipe, bend, policy, ... }:
{
  # 直接使用
}
```

### 角括号语法

由于 `den-lib` 包含了 `__findFile`，`<igloo>` 语法在模块中工作：

```nix
# 等价于引用 den.hosts.x86_64-linux.igloo
let igloo = <igloo>;  # 自动解析
```

### 烟雾测试

`modules/den.nix` 中包含了 `flake.did-scoped` 烟雾测试，验证 `policy`、`<igloo>`、`pipe`、`bend`、`ned` 等是否可直接在模块参数中访问。

## 与传统 import-tree 对比

| 特性 | 传统 import-tree | scoped import-tree |
|------|-----------------|-------------------|
| 额外库传递 | 手动 specialArgs | 自动 addScoped |
| 角括号语法 | ❌ | ✅ |
| 可组合性 | 单层 | 多层 addScoped 叠加 |
| 模块参数书写 | 需列出所有特殊参数 | 自动可用所有注入库 |
| 适用场景 | 简单项目 | 多库项目 |

## 与 minimal 对比

本模板与 minimal 的最大区别在于**库的准备**——minimal 需要 `inputs` 特殊参数去手动构建库值，而 scoped-import-tree 通过 `addScoped` 提前注入。对于复杂项目（多个配套库），scoped-import-tree 显著减少了每个模块的样板代码。
