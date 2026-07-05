# Home Manager 集成

Den 框架深度集成了 Home Manager（以及替代方案 Hjem 和 Nix-Maid），提供声明式、模块化的用户环境管理。本文介绍三种家庭环境的使用方式及高级配置模式。

## 三种家庭环境

Den 支持三种用户级家庭环境：

| 环境 | 类名 | 说明 |
|------|------|------|
| **Home Manager** | `homeManager` | Nix 生态标准方案，最成熟 |
| **Hjem** | `hjem` | Rust 实现的快速替代品 |
| **Nix-Maid** | `maid` | 声明式家政/文件整理工具 |

可以同时启用多种环境，同一用户可同时使用 HM + Hjem。

## 启用家庭环境

Home Manager、Hjem 和 Nix-Maid 集成由 Den 框架通过模块自动激活——无需手动 `den.schema.host.includes` 引入。

### 使用前提

需要 flake 中有对应的输入：

```nix
{
  inputs = {
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hjem = { url = "github:feel-co/hjem"; };
    nix-maid = { url = "github:maid-nix/maid"; };
  };
}
```

然后在主机上为用户声明对应的 class：

```nix
{
  den.hosts.x86_64-linux.igloo.users.tux = {
    classes = [ "homeManager" ];     # 启用 Home Manager
    # classes = [ "hjem" ];          # 启用 Hjem
    # classes = [ "maid" ];          # 启用 Nix-Maid
    # classes = [ "homeManager" "hjem" ];  # 同时启用 HM + Hjem
  };
}
```

主机管理模式下，若同时使用 `den.batteries.host-aspects` 电池，该电池会为用户自动回退到 `homeManager` class。

## 主机管理的家庭配置 vs 独立家庭配置

### 主机管理（推荐）

用户通过主机声明，家庭配置由主机统一管理：

```nix
{
  # 在主机上声明用户
  den.hosts.x86_64-linux.igloo.users.tux = { };

  # 用户方面包含家庭配置
  den.aspects.tux = {
    homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.neovim ];
    };
  };
}
```

### 独立家庭配置

用户不通过主机管理，而是独立声明：

```nix
{
  # 独立家庭：绑定了主机
  den.homes.x86_64-linux."tux@igloo" = {
    # home 可以访问绑定的 host 和 user
  };

  # 独立家庭：无绑定
  den.homes.x86_64-linux."remote-user" = { };
}
```

独立家庭在 `den.homes` 中声明，使用 `"user@host"` 命名约定。

## 在方面中编写 Home Manager 配置

### 基本配置

```nix
{
  den.aspects.alice = {
    includes = [
      den.batteries.define-user
    ];

    homeManager = { pkgs, ... }: {
      # Home Manager 标准选项
      home.username = "alice";
      home.homeDirectory = "/home/alice";
      home.stateVersion = "25.05";

      home.packages = with pkgs; [
        neovim
        htop
        ripgrep
      ];

      programs.git = {
        enable = true;
        userName = "Alice";
        userEmail = "alice@example.com";
      };

      programs.fish.enable = true;

      services.nextcloud-client.enable = true;
    };
  };
}
```

### 带参数的配置

```nix
{
  den.aspects.alice = { host, ... }: {
    homeManager = { pkgs, ... }: {
      home.username = host.name;  # 从主机上下文读取
    };
  };
}
```

### 使用主机提供的默认配置

主机可以通过 `provides.to-users.homeManager` 为用户提供基础家庭配置：

```nix
{
  den.aspects.igloo = {
    nixos = { ... };

    # 主机为所有用户提供默认包
    provides.to-users.homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.vim ];
    };
  };

  den.aspects.tux = {
    includes = [ den.batteries.host-aspects ];

    homeManager = { pkgs, ... }: {
      # 自动获得主机提供的 vim
      # 再添加自己的包
      home.packages = [ pkgs.neovim ];
    };
  };
}
```

## 独立 HM：den.homes 声明

### 绑定主机的独立 HM

```nix
{
  # 声明
  den.homes.x86_64-linux."tux@igloo" = { };

  # 配置独立家庭的方面
  den.aspects."tux@igloo" = { host, ... }: {
    homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.htop ];
    };
  };
}
```

绑定后可以通过 `host` 和 `user` 上下文访问相关信息。

### 无绑定独立 HM

```nix
{
  den.homes.x86_64-linux."remote" = { };

  den.aspects.remote = {
    homeManager = { pkgs, ... }: {
      home.username = "remote";
      home.homeDirectory = "/home/remote";
      home.packages = [ pkgs.htop ];
    };
  };
}
```

无绑定的 HM 无法访问 `host` 上下文。

## 多个家庭环境同时使用

同一用户可以同时使用 Home Manager 和 Hjem：

```nix
{
  # 同时启用（电池已由框架自动激活）
  den.hosts.x86_64-linux.igloo.users.alice = {
    classes = [ "homeManager" "hjem" ];
  };

  den.aspects.alice = {
    includes = [
      den.batteries.define-user
    ];

    # HM 配置
    homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.neovim ];
      programs.git.enable = true;
    };

    # Hjem 配置
    hjem = { pkgs, ... }: {
      packages = [ pkgs.ripgrep ];
    };
  };
}
```

> **Mutual Provider 电池已弃用**：跨实体路由现在内置于管道中。`den.batteries.mutual-provider` 已是一个空的兼容层。直接在方面中使用 `provides.to-users` 和 `provides.to-hosts` 即可，无需包含任何电池。

## Host ↔ User 互相配置（Mutual Providing）

Den 支持主机和用户之间互相交付配置，这是其最强大的特性之一。

### 主机向用户交付配置

```nix
{
  den.aspects.igloo = {
    # 主机策略：向特定用户交付
    policies.to-tux = { host, user, ... }:
      lib.optional (user.name == "tux") (
        den.lib.policy.include {
          homeManager.home.shellAliases.g = "git";
        }
      );
    includes = [ den.aspects.igloo.policies.to-tux ];
  };
}
```

### 用户向主机交付配置

```nix
{
  den.aspects.tux = {
    # 用户策略：向主机交付 OS 配置
    policies.to-igloo = { host, user, ... }:
      lib.optional (host.name == "igloo") (
        den.lib.policy.include {
          nixos.users.users.tux.extraGroups = [ "docker" ];
        }
      );
    includes = [ den.aspects.tux.policies.to-igloo ];
  };
}
```

### 双向交付

```nix
{
  den.aspects.igloo.policies.to-tux =
    { host, user, ... }:
    lib.optional (user.name == "tux") (
      den.lib.policy.include {
        homeManager.home.keyboard.model = "denboard";
      }
    );

  den.aspects.tux.policies.to-igloo =
    { host, user, ... }:
    lib.optional (host.name == "igloo") (
      den.lib.policy.include {
        nixos.boot.kernel.randstructSeed = "denseed";
      }
    );

  den.aspects.igloo.includes = [ den.aspects.igloo.policies.to-tux ];
  den.aspects.tux.includes = [ den.aspects.tux.policies.to-igloo ];
}
```

## 用户 classes 字段

`user.classes` 控制用户使用哪些家庭环境：

```nix
{
  den.hosts.x86_64-linux.server.users = {
    # 完整家庭环境
    alice = {
      classes = [ "user" "homeManager" ];
    };

    # 只创建 OS 用户，无家庭环境
    bob = {
      classes = [ "user" ];
    };

    # 使用 Hjem 替代 HM
    charlie = {
      classes = [ "user" "hjem" ];
    };

    # 同时使用 HM + Hjem
    dave = {
      classes = [ "homeManager" "hjem" ];
    };
  };
}
```

`user` 类是一个轻量级系统用户类，将内容路由到 `users.users.<userName>`，适用于不需要完整家庭管理器的场景。

## 完整示例

### 主机管理 HM + 用户交付

```nix
{ lib, pkgs, den, ... }: {
  # ====== HM 已由框架自动激活 ======
  
  # ====== 主机声明 ======
  den.hosts.x86_64-linux.igloo = {
    hostName = "nixos-test";
    users.tux = { };
    users.pingu = {
      classes = [ "homeManager" ];
    };
  };

  # ====== 主机方面 ======
  den.aspects.igloo = {
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.hello ];
    };

    # 为所有用户提供默认家庭配置
    provides.to-users.homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.vim ];
      programs.git.enable = true;
    };

    # 针对特定用户的策略
    policies.to-tux = { host, user, ... }:
      lib.optional (user.name == "tux") (
        den.lib.policy.include {
          homeManager.home.shellAliases = {
            ll = "ls -la";
            g = "git";
          };
        }
      );
    includes = [ den.aspects.igloo.policies.to-tux ];
  };

  # ====== 用户方面 ======
  den.aspects.tux = {
    includes = [
      den.batteries.define-user
      den.batteries.primary-user
      (den.batteries.user-shell "fish")
      den.batteries.host-aspects  # 接收主机提供的 HM 配置
    ];

    homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.neovim pkgs.htop ];
      programs.starship.enable = true;
    };

    # 用户向主机交付配置
    policies.to-igloo = { host, user, ... }:
      lib.optional (host.name == "igloo") (
        den.lib.policy.include {
          nixos.users.users.tux.extraGroups = [ "wheel" "networkmanager" ];
        }
      );
    includes = [ den.aspects.tux.policies.to-igloo ];
  };

  den.aspects.pingu = {
    includes = [
      den.batteries.define-user
      den.batteries.host-aspects
    ];

    homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.firefox ];
    };
  };
}
```

### 独立 HM 示例

```nix
{ den, ... }: {
  # HM 已由框架自动激活

  # 独立家庭：绑定到 igloo 的 tux
  den.homes.x86_64-linux."tux@igloo" = { };

  den.aspects."tux@igloo" = { host, user, ... }: {
    homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.neovim ];
    };
  };

  # 无绑定独立家庭
  den.homes.x86_64-linux."headless" = { };

  den.aspects.headless = {
    homeManager = { pkgs, ... }: {
      home.username = "headless";
      home.homeDirectory = "/home/headless";
      home.packages = [ pkgs.screen ];
    };
  };
}
```

### Hjem + HM 混合

```nix
{ den, ... }: {
  # HM 和 Hjem 已由框架自动激活
  
  den.hosts.x86_64-linux.workstation.users.alice = {
    classes = [ "homeManager" "hjem" ];
  };

  den.aspects.alice = {
    includes = [
      den.batteries.define-user
      den.batteries.primary-user
    ];

    # HM 用于程序配置
    homeManager = { pkgs, ... }: {
      programs.git.enable = true;
      programs.fish.enable = true;
    };

    # Hjem 用于包管理
    hjem = { pkgs, ... }: {
      packages = with pkgs; [ neovim ripgrep fd ];
    };
  };
}
```

## 高级模式

### 使用 `den.lib.policy.when` 条件启用

```nix
{
  den.schema.user.includes = [
    # 仅当用户包含某个方面时才生效
    den.lib.policy.when
      ({ hasAspect, ... }: hasAspect "vim-aspect")
      (den.lib.policy.include {
        homeManager.home.keyboard.model = "vim-friendly";
      })
  ];
}
```

### 自定义类转发（使用 forward 电池）

```nix
{
  den.aspects.my-home = den.batteries.forward {
    each = lib.singleton true;
    fromClass = _: "myEnv";
    intoClass = _: "homeManager";
    intoPath = _: [ "home" ];
    fromAspect = _: sourceAspect;
  };

  den.aspects.user-config = {
    myEnv = { pkgs, ... }: {
      keyboard.model = "custom";
    };
    includes = [ den.aspects.my-home ];
  };
}
```

## 重要行为变化

### 主机作用域的参数化方面不再向用户传递 homeManager 内容

在较早版本中，主机作用域的参数化方面（如 `{ user, ... }`）中的 `homeManager` 类内容会"泄漏"到该主机的每个用户。现在这种行为已经改变——主机作用域的参数化方面虽然在每个用户上下文下重复，但它的类内容是**在主机上本地发射**的，不会传递到用户的 Home Manager 求值。

如果你的代码依赖这种泄漏行为来从主机作用域向用户推送家庭配置，请改用以下方式之一：

- 使用显式的 `provides.to-users` 跨实体路由
- 使用 `den.batteries.host-aspects` 电池
- 在用户方面中直接包含所需的配置

```nix
# ✅ 正确做法：使用 provides.to-users
den.aspects.igloo = {
  nixos = { ... };
  provides.to-users.homeManager = { pkgs, ... }: {
    home.packages = [ pkgs.vim ];
  };
};
```

## 最佳实践

1. **优先使用主机管理**：`den.hosts.<host>.users` 比 `den.homes` 更便于统一管理
1. **利用 `provides.to-users`**：主机提供的默认配置减少重复
1. **合理设置 classes**：不需要 HM 的用户用 `classes = [ "user" ]`
1. **Mutual Provider 已内置**：`provides.to-users` / `provides.to-hosts` 无需额外电池，直接在方面中使用
1. **独立 HM 用于远程/无主机场景**：如 CI 环境、容器
1. **同一实体避免多个 HM 源冲突**：通过 `den.lib.policy.for` 限定特定实体

## 关联函数

| 函数/电池 | 说明 |
|-----------|------|
| [`den.batteries.home-manager`](functions/batteries/home-manager.md) | HM 集成电池 |
| [`den.batteries.hjem`](functions/batteries/hjem.md) | Hjem 集成电池 |
| [`den.batteries.maid`](functions/batteries/maid.md) | Nix-Maid 集成电池 |
| [`den.batteries.define-user`](functions/batteries/define-user.md) | 创建 OS + HM 用户 |
| [`den.batteries.primary-user`](functions/batteries/primary-user.md) | 赋予管理员权限 |
| [`den.batteries.user-shell`](functions/batteries/user-shell.md) | 设置用户登录 Shell |
| [`den.batteries.host-aspects`](functions/batteries/host-aspects.md) | 主机方面投射到用户 |
| [`den.batteries.forward`](functions/batteries/forward.md) | 自定义类转发工厂 |
| [`den.lib.policy`](functions/lib/policy-effects.md) | 策略效果构造器 |
| [`den.lib.home-env`](functions/lib/home-env.md) | 家庭环境集成工厂 |
