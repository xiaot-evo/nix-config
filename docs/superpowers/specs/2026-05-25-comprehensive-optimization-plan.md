# Comprehensive Optimization Plan

> 全面清扫：清理、代码质量、架构重构三阶段方案

## Summary

全面审计 Nix flake 配置仓库，清理遗留文件、消除重复配置、解耦耦合模块、添加代码质量基础设施。分 3 个 Phase 实施，每个 Phase 可独立验证 `nix flake check`。

---

## Phase 1 — 清理与文档同步

### 1.1 删除空目录

| 路径 | 原因 |
|------|------|
| `modules/features/desktop/wallpaper/` | 仅含 `.gitkeep`，无实际内容 |
| `modules/features/dev/languages/` | 空目录，无文件 |
| `modules/features/dev/shell/` | 空目录，无文件 |
| `modules/features/dev/tools/` | 空目录，无文件 |

清理方式：删除目录及 `.gitkeep`。有实际内容时再创建。

### 1.2 清理未使用的 devenv 文件

删除 `devenv.nix` / `devenv.yaml` / `devenv.lock`。项目使用 `nix run .#<host>` 构建/部署，不使用 `devenv shell`。

### 1.3 移除隐式依赖

`modules/features/desktop/shell/dms-shell.nix` 中移除 `includes = [ den.aspects.services.powermanagement ]`。电源管理是正交关注点，不应由桌面外壳隐式引入。

同时将 `services.powermanagement` 添加到 `acer-swift.nix` 的 host includes 中，确保功能不被丢失。

### 1.4 删除空的配置块

`modules/hosts/acer-swift/acer-swift.nix` 中的空代码块：

```nix
nixos = { pkgs, lib, ... }: { };
provides.to-users.homeManager = { pkgs, ... }: { };
```

删除这两块。

### 1.5 更新文档

**README.md**：
- `preference/` 和 `security/` 标记为"已实现"（cursor-theme, icon-theme, gnome-keyring 已存在）
- `nh.nix` 更正路径：`modules/features/system/nh.nix`（非 `modules/packages/`）
- 反映当前实际目录结构

**AGENTS_PROJECT.md**：
- acer-swift 的 used aspects 补上 `system.nh`

---

## Phase 2 — 代码质量基础设施

### 2.1 配置 formatter + pre-commit

Nix formatter：`nixfmt`（已在 helix 中作为默认 formatter 使用，需在 flake 中配置）

在 `flake.nix` / `dendritic.nix` 中配置 `formatter = nixfmt`，使 `nix fmt` 可用。

pre-commit hooks（可选，可配置在 `flake.nix` 中用 `pre-commit-hooks.nix`）：
- nixfmt 格式化检查
- 基本检查（空白字符、EOF 换行）

### 2.2 starship 预设本地化

`modules/packages/starship.nix` 使用 `builtins.fetchurl` 在 eval 时下载预设 TOML：

```nix
builtins.fromTOML (builtins.readFile (builtins.fetchurl { ... }))
```

改为使用同目录下的本地 `plain-text-symbols.toml` 文件，用 `builtins.readFile ./plain-text-symbols.toml` 读取。

### 2.3 fish.nix 字符串优化

当前双引号内插：

```nix
configFile.content = "
  set fish_greeting
  ${self'.packages.starship}/bin/starship init fish | source
";
```

保留双引号风格（功能正确），仅确认可读性。

### 2.4 实现 network.nix 空桩

`modules/features/system/network.nix`：
- 从 `system/nix.nix` 移入 `networking.networkmanager.enable = true`
- 添加基本的防火墙配置（可选）

---

## Phase 3 — 架构重构

### 3.1 system/nix.nix 拆分

当前 `system/nix.nix` 承担 5 个职责：

| 配置项 | 目标模块 |
|--------|---------|
| `networking.networkmanager.enable` | `system/network.nix`（已有空桩，Phase 2 实现） |
| `hardware.bluetooth.enable` | `system/bluetooth.nix`（新建） |
| `hardware.display.edid` | 保留在 `system/nix.nix` |
| `time.timeZone` + `i18n.defaultLocale` | `system/locale.nix`（新建） |
| `nix.settings.experimental-features` | `system/nix.nix`（保留） |

新增模块需添加到 `acer-swift.nix` 的 host includes 中（除 `system/network.nix` 已在 host includes 中）。

### 3.2 nixd LSP 配置共享

提取 `modules/features/dev/lsp/nixd.nix`：

```nix
{ flakeExpr, nixosConfigName, ... }:
{
  # nixd 共享配置
  command = "...";
  config.nixd = {
    nixpkgs.expr = "...";
    options = {
      nixos.expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.${nixosConfigName}.options";
      # ...
    };
    diagnostic.suppress = [ "sema-extra-with" ];
  };
}
```

helix 和 zed 的 `_languages.nix` 分别 import 并传入各自的 `nixosConfigName`。

`nixosConfigName` 从 host 配置中动态推导，而非硬编码 `acer-swift`。

### 3.3 apps/gaming/ 层级统一

`modules/features/apps/gaming/steam.nix` → `modules/features/apps/steam.nix`

更新 `xiaot_evo.nix` 中引用路径：
- `desktop.input-method.fcitx5` ✓（已正确）
- `apps.gaming.steam` → `apps.steam`

### 3.4 nixd 主机名参数化

在共享 nixd 模块中，`nixosConfigName` 作为参数传入，由 host/user 配置决定。当前 helix 和 zed 的 `_languages.nix` 中写死了 `acer-swift`：

```nix
nixos.expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.acer-swift.options";
```

改为参数化后，不同 host 可传入不同值。

---

## 实现顺序

```
Phase 1 ──→ Phase 2 ──→ Phase 3
(无风险)     (低风险)     (需验证 nix flake check)
```

每 Phase 完成后执行 `nix flake check` 验证。

## 文件变更清单

### Phase 1
| 操作 | 文件 |
|------|------|
| 删除 | `modules/features/desktop/wallpaper/.gitkeep` |
| 删除 | `modules/features/dev/languages/` |
| 删除 | `modules/features/dev/shell/` |
| 删除 | `modules/features/dev/tools/` |
| 删除 | `devenv.nix` |
| 删除 | `devenv.yaml` |
| 删除 | `devenv.lock` |
| 编辑 | `modules/features/desktop/shell/dms-shell.nix` |
| 编辑 | `modules/hosts/acer-swift/acer-swift.nix` |
| 编辑 | `README.md` |
| 编辑 | `AGENTS_PROJECT.md` |

### Phase 2
| 操作 | 文件 |
|------|------|
| 编辑 | `dendritic.nix`（添加 formatter） |
| 编辑 | `modules/packages/starship.nix` |
| 新建 | `modules/packages/plain-text-symbols.toml` |
| 编辑 | `modules/features/system/network.nix` |
| 编辑 | `modules/features/system/nix.nix` |

### Phase 3
| 操作 | 文件 |
|------|------|
| 新建 | `modules/features/system/bluetooth.nix` |
| 新建 | `modules/features/system/locale.nix` |
| 编辑 | `modules/features/system/nix.nix`（精简） |
| 新建 | `modules/features/dev/lsp/nixd.nix` |
| 编辑 | `modules/features/dev/editors/helix/_languages.nix` |
| 编辑 | `modules/features/dev/editors/zed-editor/_languages.nix` |
| 移动 | `modules/features/apps/gaming/steam.nix` → `modules/features/apps/steam.nix` |
| 编辑 | `modules/hosts/acer-swift/xiaot_evo.nix` |
| 编辑 | `modules/hosts/acer-swift/acer-swift.nix` |

---

## Rollback 策略

每个 Phase 由独立 commit 提交。如需回滚：

```bash
git revert <phase-commit-hash>
```

Phase 1 和 Phase 2 不含功能变化，回滚无副作用。Phase 3 涉及模块拆分，回滚时需确保所有引用同步恢复。
