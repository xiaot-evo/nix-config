# AGENTS.md — Nix flake

## Build & deploy

```console
# build (default action)
nix run .#igloo

# deploy (switch)
nix run .#igloo -- switch

# VM for dev (no reboot needed)
nix run .#vm

# regenerate flake.nix (auto-generated, do not edit by hand)
nix run .#write-flake

# update the den framework input
nix flake update den
```

## CI

`nix flake check` is the CI gate. Run it locally before opening a PR.

CI runs on both `ubuntu-latest` and `macos-latest`. It creates `modules/ci-runtime.nix` setting `_module.args.CI = true` — you can condition on it.

## Framework & structure

- **Den framework** (`github:denful/den`): this is a Den-based flake, not raw nixos/lib. Read https://den.denful.dev
- `flake.nix` is **auto-generated** by `flake-file` (`github:vic/flake-file`). Edit module files instead, then regenerate.
- Structure under `modules/`:
  - `defaults.nix` — global stateVersion (26.05), strict schema, home-manager enabled by default
  - `dendritic.nix` — flake module imports; re-declares inputs for the dendritic system
  - `hosts/hosts.nix` — single source of truth for all hosts + users + homes
  - `hosts/<name>/` — per-host config using the **aspects** pattern
  - `features/` — reusable feature modules (nh, opencode, niri, dae, ghostty, steam, zed-editor)
- Uses `nh` under the hood for build/packages.
- `import-tree ./modules` is the module root — `flake.nix` passes `./modules` to `import-tree`, so any `.nix` file under `modules/` is auto-imported.

## Aspects pattern

Host and user config lives in `den.aspects.<name>.<type>`:

```nix
den.aspects.igloo = {
  nixos = { ... };        # host NixOS config
  provides.to-users.homeManager = { ... };  # default home for host's users
};
den.aspects.tux = {
  includes = [ den.batteries.define-user den.batteries.primary-user (den.batteries.user-shell "fish") ];
  homeManager = { ... };  # user home config
};
den.aspects.xiaot_evo = {
  includes = [ den.batteries.define-user den.batteries.primary-user (den.batteries.user-shell "fish") ];
  homeManager = { ... };
  provides.to-hosts.nixos = { ... };  # user provides NixOS config to host
};
```

## Inputs

| input | follows | purpose |
|---|---|---|
| `den` | — | framework |
| `nixpkgs` | — | nixpkgs-unstable |
| `home-manager` | nixpkgs | user envs |
| `flake-parts` | nixpkgs-lib → nixpkgs | perSystem |
| `import-tree` | — | recursive module import (`./modules` is root) |
| `flake-file` | — | flake.nix generation |
| `wrappers` | nixpkgs | binary wrapping (e.g. opencode) |
| `niri-nix` | — | niri window manager home-manager module |

## OpenCode self-config

`modules/features/opencode.nix` wraps an OpenCode package with the nixos MCP server enabled. Build with `nix run .#myopencode`.

## Stub features

`features/dae.nix`, `features/ghostty.nix`, `features/steam.nix` are empty stubs (`{...}: {}`). `features/zed-editor/` is empty. They need implementation before use.

## Known TODOs

- `defaults.nix` has a fake grub/filesystem stub for `tux` — remove it before real deployment
- `hosts/igloo/vm.nix` enables `tty-autologin` for VM use — remove for production

## No formatter / linter / pre-commit / .envrc

None configured.
