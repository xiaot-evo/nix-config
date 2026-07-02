# 迁移 Nix LSP 到 nil + 集成 treefmt-nix 设计规格

> 日期: 2026-07-02
> 状态: 已批准设计

---

## 目标

1. **将 Nix 语言服务器从 `nixd` 切换到 `nil`**，覆盖 Zed、Helix 和 devenv 三个环境
2. **集成 treefmt-nix**，实现 `nix fmt` 和 `nix flake check` 的统一 Nix 格式化

---

## 1. LSP 迁移：nixd → nil

### 涉及文件

| # | 文件路径 | 变更内容 |
|---|----------|----------|
| 1a | `modules/features/dev/editors/zed-editor/_languages.nix` | 移除 `language_servers = [ "nixd" "!nil" ]`，改为 `[ "nil" ]`；移除整个 `lsp.nixd` 配置块；添加 `lsp.nil` 配置块 |
| 1b | `modules/features/dev/editors/helix/_languages.nix` | 将 `language-servers` 从 `[ "nixd" ]` 改为 `[ "nil" ]`；替换 `language-server.nixd` 配置块为 `language-server.nil` |
| 1c | `modules/features/dev/editors/zed-editor/zed-editor.nix` | `extraPackages` 中 `nixd` → `nil` |
| 1d | `modules/features/dev/editors/helix/helix.nix` | `extraPackages` 中 `nixd` → `nil` |
| 1e | `devenv.nix` | `languages.nix.lsp.package = pkgs.nil` |

### nil 配置

#### Zed（`_languages.nix`）

```nix
languages.Nix = {
  language_servers = [ "nil" ];
};
lsp.nil = {
  settings = {
    formatting.command = [ "nixfmt" ];
    diagnostics.ignored = [ "unused_binding" ];
    nix.flake = {
      autoEvalInputs = false;
      nixpkgsInputName = "nixpkgs";
    };
  };
};
```

#### Helix（`_languages.nix`）

```nix
language = [
  {
    name = "nix";
    auto-format = true;
    formatter.command = "${pkgs.nixfmt}/bin/nixfmt";
    language-servers = [ "nil" ];
  }
];
language-server.nil = {
  command = "${pkgs.nil}/bin/nil";
  config.nil = {
    formatting.command = [ "nixfmt" ];
    diagnostics.ignored = [ "unused_binding" ];
    nix.flake.nixpkgsInputName = "nixpkgs";
  };
};
```

#### devenv

```nix
languages.nix = {
  enable = true;
  lsp = {
    enable = true;
    package = pkgs.nil;
  };
};
```

### 注意事项

- `nil` 使用 flake 输入自动检测来提供补全，不支持像 `nixd` 那样通过 Nix 表达式求值获取选项补全（NixOS/home-manager 选项）
- `nixfmt` 作为外部格式化器保留，nil 通过 `formatting.command` 调用它
- `nixd` 包将从 `extraPackages` 中移除，改为添加 `nil`

---

## 2. treefmt-nix 集成

### 涉及文件

| # | 文件路径 | 变更内容 |
|---|----------|----------|
| 2a | `modules/dendritic.nix` | 添加 `treefmt-nix` 输入声明；在 `imports` 中添加 `(inputs.treefmt-nix.flakeModule or { })` |
| 2b | `modules/treefmt.nix` | 新建文件，包含 treefmt 配置 |
| 2c | `flake.nix` | `nix run .#write-flake` 自动重新生成 |

### 数据流

```
dendritic.nix
  ├─ inputs.treefmt-nix 声明
  └─ imports 中注入 flakeModule
       │
       └─ perSystem.treefmt（来自 treefmt.nix）
            ├─ formatter.<system>  ← nix fmt
            └─ checks.treefmt      ← nix flake check
```

### 配置（`modules/treefmt.nix`）

```nix
{ ... }:
{
  treefmt = {
    projectRootFile = "flake.nix";
    programs.nixfmt.enable = true;
  };
}
```

### 效果

- `nix fmt` → 运行 nixfmt 格式化所有 Nix 文件
- `nix flake check` → 自动检查格式化一致性

---

## 实施步骤

1. 修改 `modules/features/dev/editors/zed-editor/_languages.nix`
2. 修改 `modules/features/dev/editors/zed-editor/zed-editor.nix`
3. 修改 `modules/features/dev/editors/helix/_languages.nix`
4. 修改 `modules/features/dev/editors/helix/helix.nix`
5. 修改 `devenv.nix`
6. 修改 `modules/dendritic.nix`（添加 treefmt-nix 输入和 flakeModule）
7. 新建 `modules/treefmt.nix`
8. 运行 `nix run .#write-flake` 重新生成 flake.nix
9. 运行 `nix flake check` 验证
