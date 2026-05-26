# Packages to Aspects Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate wrapper package configs from `modules/packages/` into existing aspect files in `modules/features/`, then delete `modules/packages/`.

**Architecture:** Replace `inputs.wrappers.wrappers.<name>.wrap { ... }` (baked-into-binary config) with native home-manager modules (`programs.<name>`) that declaratively manage both installation and configuration.

**Tech Stack:** Nix, Den framework, home-manager

---

### Task 1: Migrate git wrapper to aspect

**Files:**
- Modify: `modules/features/dev/tools/git.nix`
- Delete: `modules/packages/git.nix`

```nix
# modules/features/dev/tools/git.nix
{ den, ... }:
{
  den.aspects.dev.tools.git = {
    homeManager = {
      programs.git = {
        enable = true;
        userName = "xiaot-evo";
        userEmail = "3258412091@qq.com";
      };
    };
  };
}
```

- [ ] **Write the aspect file** with the content above
- [ ] **Delete `modules/packages/git.nix`**

---

### Task 2: Migrate starship wrapper to aspect

**Files:**
- Modify: `modules/features/dev/shell/starship.nix`
- Delete: `modules/packages/starship.nix`

```nix
# modules/features/dev/shell/starship.nix
{ den, ... }:
{
  den.aspects.dev.shell.starship = {
    homeManager = {
      programs.starship = {
        enable = true;
        settings = builtins.fromTOML (builtins.readFile (builtins.fetchurl {
          url = "https://starship.rs/presets/toml/plain-text-symbols.toml";
          sha256 = "sha256-BPGFwSS0jw1DIK3u0PdHGt0RD82mWUs1LtRk65W/HtM=";
        }));
      };
    };
  };
}
```

- [ ] **Write the aspect file** with the content above
- [ ] **Delete `modules/packages/starship.nix`**

---

### Task 3: Migrate opencode wrapper to aspect

**Files:**
- Modify: `modules/features/dev/editors/opencode.nix`
- Delete: `modules/packages/opencode.nix`

```nix
# modules/features/dev/editors/opencode.nix
{ den, ... }:
{
  den.aspects.dev.editors.opencode = {
    homeManager = {
      programs.opencode = {
        enable = true;
        settings = {
          theme = "opencode";
          plugin = [
            "opencode-antigravity-auth@latest"
            "@tarquinen/opencode-dcp@latest"
            "superpowers@git+https://github.com/obra/superpowers.git"
          ];
          mcp.nixos = {
            enabled = true;
            type = "local";
            command = [
              "nix"
              "run"
              "github:utensils/mcp-nixos"
              "--"
            ];
          };
        };
      };
    };
  };
}
```

- [ ] **Write the aspect file** with the content above
- [ ] **Delete `modules/packages/opencode.nix`**

---

### Task 4: Update fish aspect (remove self'- reference)

**Files:**
- Modify: `modules/features/dev/shell/fish.nix`
- Delete: `modules/packages/fish.nix`

```nix
# modules/features/dev/shell/fish.nix
{ den, ... }:
{
  den.aspects.dev.shell.fish = {
    homeManager =
      { pkgs, ... }:
      {
        programs.fish = {
          enable = true;
          interactiveShellInit = ''
            set fish_greeting # Disable greeting
            ${pkgs.starship}/bin/starship init fish | source
            ${pkgs.devenv}/bin/devenv hook fish | source
          '';
        };
      };
  };
}
```

Note: Changed `self',` removed from function args, `self'.packages.starship` → `pkgs.starship`.

- [ ] **Write the aspect file** with the content above
- [ ] **Delete `modules/packages/fish.nix`**

---

### Task 5: Update xiaot_evo.nix — add aspect includes, remove self'- packages

**Files:**
- Modify: `modules/hosts/acer-swift/xiaot_evo.nix`

Changes:
1. Add `dev.shell.starship`, `dev.tools.git`, `dev.editors.opencode` to `includes`
2. Remove `self'.packages.{opencode, starship, git}` from `home.packages`

```diff
 includes =
   (with den.batteries; [
     ...
   ])
   ++ (with den.aspects; [
     ...
     dev.shell.fish
+    dev.shell.starship
+    dev.tools.git
+    dev.editors.opencode
     ...
   ]);
```

```diff
 homeManager =
-  { self', pkgs, ... }:
+  { pkgs, ... }:
   {
     home.packages =
-      (with self'.packages; [
-        opencode
-        starship
-        git
-      ])
-      ++ (with pkgs; [
+      (with pkgs; [
         ...
       ]);
   };
```

- [ ] **Edit xiaot_evo.nix** with the changes above

---

### Task 6: Delete packages directory and verify

**Files:**
- Delete: `modules/packages/` (directory)

- [ ] **Remove `modules/packages/` directory**: `git rm -r modules/packages/`
- [ ] **Run `nix flake check`** to verify everything compiles
- [ ] **Commit all changes**

---

## Self-Review Checklist

- [ ] **Spec coverage**: Every wrapper (git, starship, opencode, fish) mapped to HM equivalent. Consumer file (xiaot_evo.nix) updated. ✓
- [ ] **Placeholder scan**: No TODOs, TBDs, or vague instructions. All code blocks contain complete implementations. ✓
- [ ] **Type consistency**: `self'.packages.starship` → `pkgs.starship` is consistent across all files. `self'` removed from function args where no longer needed. ✓
