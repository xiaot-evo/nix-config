# nil 迁移 + treefmt-nix 集成实现计划

> **面向 AI 代理的工作者：** 必需子技能：使用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 逐任务实现此计划。步骤使用复选框（`- [ ]`）语法来跟踪进度。

**目标：** 将 Nix 语言服务器从 nixd 迁移到 nil（Zed + Helix + devenv），并集成 treefmt-nix 实现统一格式化。

**架构：**

- LSP 迁移：在 Zed 和 Helix 的 Nix 语言配置中将 `nixd` 替换为 `nil`，并更新 nil 的简洁配置（formatter、diagnostics、flake 评估）
- treefmt-nix：通过 flake-parts flakeModule 注入，在 `modules/treefmt.nix` 中配置 nixfmt 作为统一格式化器
- 两个任务共享 nixfmt 作为 formatter，保持一致

**技术栈：** nil (oxalica/nil), treefmt-nix (numtide/treefmt-nix), nixfmt, flake-parts

---

### 任务 1：修改 Zed 的 `_languages.nix` — 替换 nixd 为 nil

**文件：** `modules/features/dev/editors/zed-editor/_languages.nix`

- [ ] **步骤 1：替换语言服务器列表**

将 `language_servers = [ "nixd" "!nil" ]` 改为 `[ "nil" ]`

- [ ] **步骤 2：移除 nixd 配置块，添加 nil 配置块**

移除整个 `lsp.nixd = { ... }` 块，添加 `lsp.nil = { ... }` 配置：

```nix
{ pkgs, ... }:
{
  languages = {
    Nix = {
      language_servers = [
        "nil"
      ];
    };
  };
  lsp = {
    nil = {
      settings = {
        formatting = {
          command = [ "nixfmt" ];
        };
        diagnostics = {
          ignored = [ "unused_binding" ];
        };
        nix = {
          flake = {
            autoEvalInputs = true;
            nixpkgsInputName = "nixpkgs";
          };
        };
      };
    };
  };
}
```

- [ ] **步骤 3：Commit**

```bash
git add modules/features/dev/editors/zed-editor/_languages.nix
git commit -m "feat(zed): switch Nix LSP from nixd to nil"
```

---

### 任务 2：修改 Zed 的 `zed-editor.nix` — 替换 extraPackages

**文件：** `modules/features/dev/editors/zed-editor/zed-editor.nix`

- [ ] **步骤 1：将 `extraPackages` 中的 `nixd` 替换为 `nil`**

```nix
extraPackages = with pkgs; [
  nil
  nixfmt
  package-version-server
  yaml-language-server
];
```

- [ ] **步骤 2：Commit**

```bash
git add modules/features/dev/editors/zed-editor/zed-editor.nix
git commit -m "feat(zed): replace nixd package with nil"
```

---

### 任务 3：修改 Helix 的 `_languages.nix` — 替换 nixd 为 nil

**文件：** `modules/features/dev/editors/helix/_languages.nix`

- [ ] **步骤 1：将 Nix 语言的语言服务器从 `nixd` 改为 `nil`**

```nix
{
  name = "nix";
  auto-format = true;
  formatter.command = "${pkgs.nixfmt}/bin/nixfmt";
  language-servers = [ "nil" ];
}
```

- [ ] **步骤 2：将 `language-server.nixd` 配置块替换为 `language-server.nil`**

移除整个 `nixd` 配置块，添加：

```nix
language-server = {
  nil = {
    command = "${pkgs.nil}/bin/nil";
    config = {
      nil = {
        formatting = {
          command = [ "nixfmt" ];
        };
        diagnostics = {
          ignored = [ "unused_binding" ];
        };
        nix = {
          flake = {
            autoEvalInputs = true;
            nixpkgsInputName = "nixpkgs";
          };
        };
      };
    };
  };
  gopls = {
    command = "${pkgs.gopls}/bin/gopls";
    config.gofumpt = true;
  };
};
```

- [ ] **步骤 3：Commit**

```bash
git add modules/features/dev/editors/helix/_languages.nix
git commit -m "feat(helix): switch Nix LSP from nixd to nil"
```

---

### 任务 4：修改 Helix 的 `helix.nix` — 替换 extraPackages

**文件：** `modules/features/dev/editors/helix/helix.nix`

- [ ] **步骤 1：将 `extraPackages` 中的 `nixd` 替换为 `nil`**

```nix
extraPackages = with pkgs; [
  nil
  nixfmt
  # go
  gopls
  delve
];
```

- [ ] **步骤 2：Commit**

```bash
git add modules/features/dev/editors/helix/helix.nix
git commit -m "feat(helix): replace nixd package with nil"
```

---

### 任务 5：修改 `devenv.nix` — 替换 nixd 为 nil

**文件：** `devenv.nix`

- [ ] **步骤 1：将 `languages.nix.lsp.package` 从 `pkgs.nixd` 改为 `pkgs.nil`**

```nix
languages.nix = {
  enable = true;
  lsp = {
    enable = true;
    package = pkgs.nil;
  };
};
```

- [ ] **步骤 2：Commit**

```bash
git add devenv.nix
git commit -m "feat(devenv): switch Nix LSP from nixd to nil"
```

---

### 任务 6：添加 treefmt-nix 输入到 `dendritic.nix`

**文件：** `modules/dendritic.nix`

- [ ] **步骤 1：在 `imports` 中添加 treefmt-nix flakeModule**

```nix
imports = [
  (inputs.flake-file.flakeModules.dendritic or { })
  (inputs.den.flakeModules.dendritic or { })
  (inputs.treefmt-nix.flakeModule or { })
];
```

- [ ] **步骤 2：在 `flake-file.inputs` 中添加 treefmt-nix 声明**

```nix
treefmt-nix = {
  url = "github:numtide/treefmt-nix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

- [ ] **步骤 3：Commit**

```bash
git add modules/dendritic.nix
git commit -m "feat: add treefmt-nix input and flakeModule"
```

---

### 任务 7：创建 `modules/treefmt.nix`

**文件：** 新建 `modules/treefmt.nix`

- [ ] **步骤 1：编写 treefmt 配置**

```nix
{ ... }:
{
  treefmt = {
    projectRootFile = "flake.nix";
    programs.nixfmt.enable = true;
  };
}
```

- [ ] **步骤 2：git add 新文件**

```bash
git add modules/treefmt.nix
```

- [ ] **步骤 3：Commit**

```bash
git commit -m "feat: add treefmt-nix configuration with nixfmt"
```

---

### 任务 8：重新生成 flake.nix 并验证

- [ ] **步骤 1：运行 write-flake 重新生成 flake.nix**

运行：`nix run .#write-flake`
预期：flake.nix 自动更新，包含 treefmt-nix 输入

- [ ] **步骤 2：git add flake.nix**

```bash
git add flake.nix
```

- [ ] **步骤 3：运行 nix flake check 验证整体配置**

运行：`nix flake check`
预期：所有检查通过，包括 formatting 检查

- [ ] **步骤 4：如果 flake check 成功，完成 commit**

```bash
git commit -m "chore: regenerate flake.nix with treefmt-nix input"
```
