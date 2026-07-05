# nvf-standalone 模板

**独立应用配置** — 展示如何使用 Den 的方面系统配置 Neovim（通过 nvf），完全脱离 NixOS/home-manager，仅产生可运行的应用包。

## 用途

- 理解 Den 的**通用性**——不仅限 NixOS/macOS/HM，可配置任意 Nix 工具
- 学习自定义类（`vim` 类 → `nvf` 类）和 `den.lib.aspects.resolve`
- 作为使用 den 配置非系统工具的参考实现

## 目录结构

```
templates/nvf-standalone/
├── flake.nix              # 入口（evalModules + import-tree，4 输入）
├── flake.lock
├── README.md
├── modules/
│   ├── den.nix             # 方面定义 + 包暴露
│   ├── nvf-integration.nix # 转发类 + resolve 助手
│   └── header.txt          # ASCII art 头部
```

## Flake 输入

| 输入 | 来源 | 用途 |
|------|------|------|
| `nixpkgs` | nixpkgs-unstable (tarball) | 包集合 |
| `den` | github:denful/den | Den 框架 |
| `import-tree` | github:vic/import-tree | 递归导入 |
| `nvf` | github:notashelf/nvf | Neovim 配置框架 |

## 实体结构

**无** `den.hosts`、`den.homes` 声明——本模板不使用实体概念。

## 关键模式

### 自定义 vim 类

```nix
den.aspects.my-neovim = {
  # 这些键被转发到 nvf.vim.*
  vim.globals.mapleader = " ";
  vim.keymaps = [ ... ];
  vim.lazy.plugins = [ ... ];
};
```

### 转发机制

`nvf-integration.nix` 定义了 `den.lib.nvf.package`，使用 `den.batteries.forward` 转发类：

```nix
vimClass = den.batteries.forward {
  each = lib.singleton true;
  fromClass = _: "vim";         # Den 方面中写的类键
  intoClass = _: "nvf";         # nvf 框架期望的类
  intoPath = _: [ "vim" ];      # nvf.vim.*
};
```

### 手工解析

```nix
# 不使用管道自动解析，而是手工编译
module = den.lib.aspects.resolve "nvf" aspect;
```

`den.lib.aspects.resolve` 将方面树编译为单个 NixOS 风格的模块，供 `nvf.lib.neovimConfiguration` 消费。

### 参数化变体

```nix
den.aspects.my-neovim = { mine, ... }: { ... };  # 参数化方面

den.aspects.flake.packages = { pkgs, ... }:
  let nvf = den.lib.nvf.package pkgs; in {
    my-neovim   = nvf den.aspects.my-neovim { mine = true; };
    your-neovim = nvf den.aspects.my-neovim { mine = false; };
  };
```

产生两个 Neovim 包：`my-neovim` 和 `your-neovim`。

### 数据流

```
den.aspects.my-neovim (parametric, { mine })
  └── includes: den.aspects.nvf
        ├── provides.leader → vim.globals
        ├── provides.keys → vim.keymaps
        ├── provides.which-key → vim.binds.whichKey
        ├── provides.snacks (parametric)
        └── provides.lazy → vim.lazy.plugins

den.lib.nvf.package
  │  den.batteries.forward: vim → nvf.vim
  │  den.lib.aspects.resolve "nvf" → 模块
  ▼
nvf.lib.neovimConfiguration → 纯 Neovim 包
  ▼
nix run .#my-neovim
```

## 与其他模板对比

| 特性 | nvf-standalone | microvm |
|------|---------------|---------|
| 输出类型 | **Neovim 包** | QEMU VM 配置 |
| 使用实体 | ❌ | ✅ host |
| `den.lib.aspects.resolve` | ✅ 直接使用 | ✅ 隔离映射 |
| 转发类 | ✅ vim → nvf | ✅ nixos → microvm |
| flake-parts | ❌ | ❌ |
| 自定义类 | `vim`、`nvf` | `microvm` |

## 核心启示

**Den 是通用方面组合引擎，不限 NixOS/达尔文/HM**。本模板展示了：

1. 不声明实体，直接使用 `den.aspects.*`
1. `den.batteries.forward` 将自定义类映射到外部 schema
1. `den.lib.aspects.resolve` 直接编译方面为模块
1. 产生纯应用包（非系统配置）
