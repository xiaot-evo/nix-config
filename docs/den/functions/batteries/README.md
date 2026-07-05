# 内置电池模块（Built-in Batteries）

> 所有电池的独立分析文件，按分类列出。

______________________________________________________________________

## 系统电池

| 电池 | 源文件 | 说明 |
|------|--------|------|
| [hostname](./hostname.md) | `hostname.nix` | 自动设置网络主机名 |
| [define-user](./define-user.md) | `define-user.nix` | 创建完整的 OS + HM 用户 |
| [primary-user](./primary-user.md) | `primary-user.nix` | 设为超级用户（wheel/管理员） |
| [user-shell](./user-shell.md) | `user-shell.nix` | 设置用户默认 Shell |
| [os-class](./os-class.md) | `os-class.nix` | `os` 便利类（nixos + darwin 双转发） |
| [os-user](./os-user.md) | `os-user.nix` | `user` 轻量用户类（users.users 转发） |
| [wsl](./wsl.md) | `wsl.nix` | WSL 支持 |
| [forward](./forward.md) | `forward.nix` | 创建自定义类转发 |
| [import-tree](./import-tree.md) | `import-tree.nix` | 按 `_class` 目录递归导入 |
| [host-aspects](./host-aspects.md) | `host-aspects.nix` | 主机方面投射到用户 |
| [flake-scope](./flake-scope.md) | `flake-scope.nix` | 向管道暴露 `lib`/`inputs`/`den` |

## 家庭环境电池

| 电池 | 源文件 | 说明 |
|------|--------|------|
| [home-manager](./home-manager.md) | `home-manager.nix` | Home Manager 集成 |
| [hjem](./hjem.md) | `hjem.nix` | Hjem（Rust HM）集成 |
| [maid](./maid.md) | `maid.nix` | nix-maid 家政服务集成 |

## 包管理电池

| 电池 | 源文件 | 说明 |
|------|--------|------|
| [unfree](./unfree.md) | `unfree/unfree.nix` | 允许不自由包 |
| [insecure](./insecure.md) | `insecure/insecure.nix` | 允许不安全包 |

## Flake-Parts 电池

| 电池 | 源文件 | 说明 |
|------|--------|------|
| [self'](./self'.md) | `flake-parts/self.nix` | 提供 `self'` 模块参数 |
| [inputs'](./inputs'.md) | `flake-parts/inputs.nix` | 提供 `inputs'` 模块参数 |

## 便利电池

| 电池 | 源文件 | 说明 |
|------|--------|------|
| [vm-autologin](./vm-autologin.md) | `vm-autologin.nix` | VM 自动 TTY 登录 |
| [tty-autologin](./tty-autologin.md) | `tty-autologin.nix` | 物理 TTY 自动登录 |

______________________________________________________________________

## 关联

- **`modules/aspects/batteries.nix`**: `den.batteries` 选项的类型声明（freeformType）
- **`modules/aspects/batteries/`**: 电池实现代码目录
- **`den.lib.home-env`**: `makeHomeEnv` 工厂函数（HM/hjem/maid 共用）
- **`den.lib.forward`**: `forwardEach` 转发引擎（forward 电池使用）
