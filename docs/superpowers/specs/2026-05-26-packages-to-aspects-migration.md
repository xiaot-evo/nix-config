# Packages to Aspects Migration

## Goal

Migrate wrapper package configs from `modules/packages/` into existing aspect
files in `modules/features/`, then delete `modules/packages/`.

## Strategy

Replace `inputs.wrappers.wrappers.<name>.wrap { ... }` (which bakes config
into a standalone binary) with native home-manager modules that manage both
the package installation and its configuration declaratively.

## Per-Aspect Changes

### git → `dev.tools.git`

```nix
den.aspects.dev.tools.git = {
  homeManager = {
    programs.git = {
      enable = true;
      userName = "xiaot-evo";
      userEmail = "3258412091@qq.com";
    };
  };
};
```

Replaces: `modules/packages/git.nix` (wrapper with `user.name`/`user.email`)

### starship → `dev.shell.starship`

```nix
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
```

Replaces: `modules/packages/starship.nix`

### opencode → `dev.editors.opencode`

```nix
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
```

Replaces: `modules/packages/opencode.nix`

### fish → `dev.shell.fish`

Already has `programs.fish` HM config. Only change: replace
`self'.packages.starship` with `pkgs.starship` in `interactiveShellInit`
(since the starship wrapper package is going away).

Replaces: `modules/packages/fish.nix` (unused wrapper, delete)

## Consumer Changes (`xiaot_evo.nix`)

```diff
 includes = [
   ...
   dev.shell.fish
+  dev.shell.starship
+  dev.tools.git
+  dev.editors.opencode
   ...
 ];

 homeManager = { ... }: {
   home.packages = with self'.packages; [
-    opencode
-    starship
-    git
   ] ++ with pkgs; [
     ...
   ];
 };
```

## Deletions

- `modules/packages/` — entire directory removed
- `inputs.wrappers` still used by other code? No — `modules/packages/` is the
  only consumer. The input can stay in `dendritic.nix` for now (cleanup can be
  done separately).

## Verification

- `nix flake check` passes
- opencode, starship, git, fish all functional in running system
