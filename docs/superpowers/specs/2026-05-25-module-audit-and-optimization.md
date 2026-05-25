# 模块审计与优化方案

> 基于 Nix flake 配置的全面审计，仅提方案，不应用更改。

---

## 1. Git 提交审计

### 当前状态

`dev` 分支领先 `origin/dev` 4 个提交，工作区干净，未推送。

### 提交列表（按时间倒序）

| Commit | 类型 | 内容 |
|--------|------|------|
| `7e5bd38` | `refactor` | acer-swift: hostname battery 加入 includes |
| `0b77121` | `feat` | zed: 添加 nil LSP，从 nixd 切换为主 LSP |
| `5a76e92` | — | **混合提交**: 添加 debug.nix + 更新编辑器 LSP flake exprs + ly.nix 删除 + fish.nix 修改 |
| `9c81fd2` | `normalize` | Plymouth 主题和内核参数规范化 |

### 问题

- **`5a76e92` 混合了 4 类无关更改**：新增模块 (debug.nix)、编辑器 LSP 配置重构、ly 服务清理、fish 包调整。应拆分为：
  - `feat(debug): add debug module`
  - `refactor(editors): update LSP flake expressions for helix/zed`
  - `chore(ly): remove unused import`
  - `chore(fish): fix config file syntax`

---

## 2. 模块分类问题

### 2.1 空目录（应删除或填充）

| 路径 | 状态 |
|------|------|
| `modules/features/preference/` | 空 |
| `modules/features/security/` | 空 |
| `modules/features/dev/languages/` | 空 |
| `modules/features/dev/shell/` | 空 |
| `modules/features/dev/tools/` | 空 |
| `modules/features/desktop/wallpaper/` | 仅含 `.gitkeep` |

**建议**：删除空目录（保留 git 历史干净），待有实际内容时再创建。

### 2.2 `modules/packages/` 分类模糊

`packages/` 包含了两种不同性质的包定义：

- **`wrappers` 封装的包**：`fish.nix`、`git.nix`、`starship.nix`、`opencode.nix` — 均使用 `inputs.wrappers` 生成 `perSystem` packages
- **基础设施**：`nh.nix` — 使用 `den.lib.nh` 为所有 host/home 生成 nh 构建入口，与 wrappers 无关

**建议**：
- 拆出 `modules/packages/wrappers/` 子目录统一管理 wrappers 包，或
- 将 `nh.nix` 移至 `modules/features/system/nh.nix` 作为系统功能

### 2.3 `features/README.md` 与实际结构不匹配

| README 声明 | 实际路径 | 差异 |
|-------------|----------|------|
| `apps/terminals/ghostty.nix` | `apps/ghostty.nix` | 无 `terminals/` 子目录 |
| `shell/fish.nix` | `packages/fish.nix` | 不存在于 `features/shell/` |
| `dev/editors/neovim.nix` | 不存在 | neovim 不存在 |
| `desktop/wallpaper/`, `lockscreen/`, `polkit/` | 不存在或空 | 仅 `wallpaper/` 存在且空 |
| `services/` 中示例包含 nbfc-linux | `system/hardware/nbfc-linux.nix` | 实际在 `system/hardware/` 下 |
| 无 `security/`, `themes/`, `shell/` 目录 | 存在空 `security/` | README 超前于实现 |

**建议**：更新 README.md 以反映实际结构，或完成空目录的理想结构后再更新。

### 2.4 `debug.nix` 位置孤立

`modules/debug.nix` 是唯一一个直接在 `modules/` 根目录的 `.nix` 文件（不含 `defaults.nix`、`dendritic.nix`）。

**建议**：移至 `modules/features/system/debug.nix`。

### 2.5 `apps/gaming/steam.nix` 与其他 app 层级不一致

- `apps/gaming/steam.nix` — 二级子目录
- `apps/ghostty.nix` — 直接一级
- `apps/zen-browser.nix` — 直接一级
- `apps/input-method/fcitx5.nix` — 二级子目录

**建议**：
- 统一为一级（`apps/steam.nix`），或
- 所有 app 按类别放入子目录（`apps/terminals/ghostty.nix`、`apps/browsers/zen-browser.nix`、`apps/gaming/steam.nix`）

### 2.6 `apps/input-method/fcitx5.nix` 分类不当

输入法作为系统级配置（全局 `i18n.inputMethod`）放在 `apps/` 下有误导性。它与桌面环境强相关，与普通"应用"不同。

**建议**：移至 `desktop/input-method/fcitx5.nix` 或 `services/input-method/fcitx5.nix`。

---

## 3. 内联配置拆分问题

### 3.1 `niri.nix` 中的 `services.gnome.gnome-keyring.enable`

**位置**：`modules/features/desktop/wm/niri.nix:11`

**问题**：在非 GNOME 的 WM (niri) 配置中启用 GNOME Keyring，属于隐式依赖混入。

**建议**：拆分为独立模块：
- `modules/features/desktop/services/gnome-keyring.nix`，或
- `modules/features/services/gnome-keyring.nix`

然后在需要使用 keyring 的 host/user 级 `includes` 中显式引入。

### 3.2 `dms-shell.nix` 包含 `den.aspects.services.powermanagement`

**位置**：`modules/features/desktop/shell/dms-shell.nix:5`

**问题**：DMS Shell (桌面外壳) 不应隐式依赖电源管理服务。shell 和电源管理是正交的。

**建议**：将 `den.aspects.services.powermanagement` 从 DMS shell 的 `includes` 中移除，改为在 host 或 user 配置中显式添加。

### 3.3 `system/nix.nix` 耦合过多职责

**位置**：`modules/features/system/nix.nix`

**当前包含**：
- NetworkManager（网络）
- Bluetooth（蓝牙）
- Display EDID（显示）
- Timezone/locale（时区/语言）
- Nix daemon settings（Nix 自身配置）

**建议**：拆分为：
- `system/network.nix` — NetworkManager + 防火墙
- `system/bluetooth.nix` — 蓝牙

显示 EDID 可保留在 `system/nix.nix` 或由硬件模块管理。Timezone/locale 可拆为 `system/locale.nix`。

### 3.4 `boot.nix` 的 scope 问题

**位置**：`modules/features/system/boot.nix`

当前包含 bootloader (systemd-boot)、plymouth、内核参数。**合理性评估**：这三者紧密相关，拆分意义不大，可保留。但注意它使用了函数参数 `efipath`，其 `den.aspects` 声明格式与其他模块不一致。

---

## 4. 重复 / 可共享代码

### 4.1 nixd LSP 配置在 helix 和 zed 中重复

- `modules/features/dev/editors/helix/_languages.nix:26-74` — 完整的 nixd 配置（nixpkgs expr、options、diagnostics）
- `modules/features/dev/editors/zed-editor/_languages.nix:74-108` — 几乎相同的 nixd 配置

**差异很小**（zed 的 nixd 多了 formatting 块）。大多数配置块完全重复。

**建议**：提取为共享模块：
- `modules/features/dev/languages/nixd-config.nix`，或
- `modules/features/dev/lsp/nixd.nix`

两个编辑器从共享模块 import。

### 4.2 `dendritic.nix` 与 `flake.nix` 的 input 重复

`flake.nix` (auto-generated) 和 `dendritic.nix` 都声明了：
- `daeuniverse`
- `den`
- `dms` / `dms-plugin-registry`
- `flake-file`
- `flake-parts`
- `home-manager`
- `import-tree`
- `niri-nix`
- `nixpkgs`
- `wrappers`
- `zen-browser`

以及完全重复的 `nixConfig` 块（substituters + public keys）。

**建议**：
- 标记部分 input 定义可移至使用模块（如 `daeuniverse` → `features/services/dae.nix`、`niri-nix` → `desktop/wm/niri.nix`、`zen-browser` → `apps/zen-browser.nix`），使用 `flake-file.inputs.<name>.url` 就近声明
- 但要注意 `dendritic.nix` 是 flake-file 系统的 source of truth，`flake.nix` 是从它生成的。检查 `nix run .#write-flake` 是否会将 dendritic 中的 inputs 同步到 flake.nix。

### 4.3 `dendritic.nix` 和 `flake.nix` 的 `nixConfig` 重复

同 4.2，`nixConfig` 块也在两处出现。确认 `write-flake` 是否负责同步。

---

## 5. 主机配置结构

### 5.1 当前结构

```
modules/hosts/
└── acer-swift/
    ├── acer-swift.nix     # host 定义 + includes + nixos + provides.to-users
    ├── hardware.nix       # 纯硬件定义
    └── xiaot_evo.nix      # user 定义 + includes + homeManager
```

### 5.2 建议

- `acer-swift/acer-swift.nix` 中 `den.aspects.acer-swift` 的 `includes` 混合了系统级（`system.boot`、`system.nix`、`system.sound`、`system.hardware.nvidia`）和 user 级引用。虽然架构上 host includes 可以包含系统级 aspect，但应考虑将用户可见的 aspect 分离到 user 配置中。
- 当前所有 hosts (acer-swift) 下只有一个 user (xiaot_evo)，结构尚可。随 hosts 增加应保持清晰。

---

## 6. 其他优化建议

### 6.1 `modules/debug.nix` 中的 `debug = true;`

一个全局属性，用于给 LSP 提供 debug 选项。当前实现很简单。如果未来需要更多 debug 功能，可扩展为 attribute set。

### 6.2 `defaults.nix` 的 TODO

根据 `AGENTS.md`：
> `defaults.nix` 有一个为 `tux` 准备的假 grub/filesystem 桩 — 真实部署前应删除

当前代码中未发现假桩（可能已被清理），但应在真实部署前确认。

### 6.3 `hosts/hosts.nix` 引用但不存在

`AGENTS.md` 提到 `modules/hosts/hosts.nix` 是"所有 hosts + users + homes 的唯一真实来源"，但当前该文件不存在。当前直接在 `acer-swift/acer-swift.nix` 中用 `den.hosts.x86_64-linux.acer-swift.users.xiaot_evo = { };` 声明 host。

**建议**：按 Den 框架惯例，创建 `modules/hosts/hosts.nix` 作为集中声明，或更新 `AGENTS.md` 以匹配当前模式。

### 6.4 `dms-shell.nix` 中硬编码的 `acer-swift`

在 `dms-shell.nix` 中并未硬编码 host，但在 `helix/_languages.nix:56-57` 和 `zed-editor/_languages.nix:87-88` 的 nixd options 中写死了 `acer-swift`：

```nix
nixos = {
  expr = "(builtins.getFlake (builtins.toString ./.)).nixosConfigurations.acer-swift.options";
};
```

**建议**：使用 `builtins.currentSystem` 或从 flake 中动态推导当前 hostname，或在不同 host 间通过参数化实现。提取到共享 nixd 配置模块时可一并解决。

### 6.5 `packages/fish.nix` configFile 语法问题

```nix
configFile.content = "
  set fish_greeting # Disable greeting
  ${self'.packages.starship}/bin/starship init fish | source
";
```

双引号字符串中 `${self'...}` 被内插展开。当前也许有意为之（在 build 时展开路径），但阅读时容易与普通 Nix 字符串混淆。无功能问题，但可考虑用单引号 + 显式拼接。

---

## 7. 优化优先级汇总

| 优先级 | 项目 | 影响 |
|--------|------|------|
| P0 | gnome-keyring 从 niri 拆分 | 架构清晰度、可维护性 |
| P0 | `dendritic.nix` / `flake.nix` 重复消除 | 减少混淆、避免漂移 |
| P0 | `system/nix.nix` 拆分 | 关注点分离 |
| P1 | 空目录清理 | 整洁性 |
| P1 | `features/README.md` 与实际同步 | 文档正确性 |
| P1 | nixd LSP 配置共享 | 消除重复 |
| P1 | `debug.nix` 移入 features/ | 一致性 |
| P1 | `apps/input-method/` 重分类 | 领域正确性 |
| P1 | `dms-shell.nix` 移除 power management 依赖 | 解耦 |
| P2 | `apps/gaming/` 层级一致性 | 统一性 |
| P2 | 主机名硬编码参数化 | 可移植性 |
| P2 | `packages/` 分类细化 | 可维护性 |
| P3 | Git 历史整理 (5a76e92 拆分) | 仅本地 |
| P3 | `hosts/hosts.nix` 与文档对齐 | 文档对齐 |
| P3 | `fish.nix` 字符串风格 | 代码风格 |
