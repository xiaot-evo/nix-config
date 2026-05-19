# 内置电池模块（Built-in Batteries）

**源文件**: `modules/aspects/batteries/`

## 概述

电池是 Den 附带的预定义方面，提供常用功能。"电池"（Batteries）这个名称暗示它们是即插即用的开箱即用功能。

所有电池通过 `den.batteries.<name>` 访问，可在 `den.default.includes` 全局应用，或在各个 `den.aspects.<name>.includes` 中选择性使用。

---

## 系统电池

### den.batteries.hostname

**文件**: `hostname.nix`

设置系统 hostname。从 `den.hosts.<name>.hostName` 读取值，并写入对应类的 `networking.hostName`。

```nix
den.default.includes = [ den.batteries.hostname ];
```

支持 NixOS、Darwin、WSL。

### den.batteries.define-user

**文件**: `define-user.nix`

定义 OS 和 Home 级别的用户。自动设置：
- NixOS/Darwin：`users.users.<userName>` 基础字段
- Home Manager：`home.username`、`home.homeDirectory`

```nix
den.aspects.my-user.includes = [ den.batteries.define-user ];
```

### den.batteries.primary-user

**文件**: `primary-user.nix`

将用户设为主要用户：
- NixOS：添加 `wheel` 和 `networkmanager` 组
- Darwin：设置 `system.primaryUser`
- WSL：设置 `wsl.defaultUser`

```nix
den.aspects.my-user.includes = [ den.batteries.primary-user ];
```

### den.batteries.user-shell

**文件**: `user-shell.nix`

设置用户默认 shell。在 OS 和 Home 级别启用对应程序。

```nix
den.aspects.vic.includes = [
  (den.batteries.user-shell "fish")
];
```

返回的函数接收 shell 名称，创建一个包含 OS 和 Home 配置的方面。

### den.batteries.forward

**文件**: `forward.nix`

创建一个新的 Nix 配置类，将所有内容转发到子模块。用于实现自定义类，例如 `user` 类将选项转发到 `users.users.<userName>`。

```nix
# 实际上，homeManager 类正是通过 forward 实现的
```

### den.batteries.import-tree

**文件**: `import-tree.nix`

从目录树递归导入非树状 `.nix` 文件，自动按 Nix 配置类分组。需要 `inputs.import-tree`。

```
<repo>/
  non-dendritic/
    hosts/my-laptop/
      _nixos/          # nixos 类的导入
      _darwin/         # darwin 类的导入
      _homeManager/    # homeManager 类的导入
```

```nix
den.aspects.my-laptop.includes = [
  (den.batteries.import-tree ../non-dendritic)
];
```

提供 `.provides.host`、`.provides.user`、`.provides.home` 用于带上下文的自动导入。

### den.batteries.host-aspects

**文件**: `host-aspects.nix`

将主机方面树中的 `user.classes`（如 `homeManager`）投射到选择加入的用户上。

```nix
den.aspects.tux.includes = [ den.batteries.host-aspects ];
```

用户方面可定义访问主机级配置的方面。

---

## 家庭电池

### den.batteries.home-manager

**文件**: `home-manager.nix`

Home Manager 集成的最主要电池。自动配置：
- 通过 `home-manager` 选项注册 Home Manager 类
- 将 `homeManager` 键从主机方面转发到 `home-manager.users.<userName>`
- 检测并桥接 `den.schema.hm-host` 模式包含

```nix
# 通过 den.schema 自动包含，通常不需要显式添加
```

这是唯一在 `den.schema` 层面自动包含的电池。

### den.batteries.hjem

**文件**: `hjem.nix`

Hjem 用户环境集成。需要 `inputs.hjem`。

```nix
# 通过 den.schema 自动包含
den.classes.hjem.description = "Hjem user environment";
```

### den.batteries.maid

**文件**: `maid.nix`

nix-maid 用户环境集成。仅支持 NixOS。需要 `inputs.nix-maid`。

```nix
# 通过 den.schema 自动包含
den.classes.maid.description = "nix-maid user environment";
```

---

## 包电池

### den.batteries.unfree

**文件**: `unfree/unfree.nix`

类通用的方面，启用指定名称的 unfree 包。动态为每个类提供模块。

```nix
den.aspects.my-laptop.includes = [
  (den.batteries.unfree ["vscode" "steam"])
];
```

### den.batteries.insecure

**文件**: `insecure/insecure.nix`

类通用的方面，启用指定名称和不安全版本的包。动态为每个类提供模块。

```nix
den.aspects.my-laptop.includes = [
  (den.batteries.insecure ["openssl-1.0.0"])
];
```

---

## flake-parts 电池

### den.batteries.self'

**文件**: `flake-parts/self.nix`

提供 `self'`（flakeparts 风格，预选系统），作为顶级模块参数。允许模块访问每系统的 flake 输出。

```nix
den.default.includes = [ den.batteries.self' ];
```

### den.batteries.inputs'

**文件**: `flake-parts/inputs.nix`

提供 `inputs'`（flakeparts 风格，预选系统），作为顶级模块参数。

```nix
den.default.includes = [ den.batteries.inputs' ];
```

---

## 便利电池

### den.batteries.vm-autologin

**文件**: `vm-autologin.nix`

在 `nixos-rebuild build-vm` 时启用指定用户的自动 TTY 登录。仅影响 VM 变体 `virtualisation.vmVariant`。

```nix
den.aspects.my-laptop.includes = [ (den.batteries.vm-autologin "root") ];
```

### den.batteries.tty-autologin

**文件**: `tty-autologin.nix`

永久启用指定用户的自动 TTY 登录（非 VM 专用）。

```nix
den.aspects.my-laptop.includes = [ (den.batteries.tty-autologin "root") ];
```

### den.batteries.flake-scope

**文件**: `flake-scope.nix`

将 `lib`、`inputs` 和 `den` 暴露给方面管道函数。使用 `collisionPolicy = "class-wins"`。

```nix
den.default.includes = [ den.batteries.flake-scope ];
```

---

## 关联

- **`modules/options.nix`**: `den.batteries` 选项的类型声明
- **`nix/nixModule/aspects.nix`**: 方面选项类型定义
- **`modules/aspect-schema.nix`**: 方面模式的类型定义
- 各电池实现文件用于详细信息
