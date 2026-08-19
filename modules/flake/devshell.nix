{ self, inputs, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    let
      hostname = "acer-swift";
    in
    {
      devShells.default = pkgs.mkShell {
        # ── 基础工具 ─────────────────────────────────
        packages = with pkgs; [
          git
          gh
          nh
          nixfmt
          fish
        ];

        # ── 快捷脚本（通过 shellHook 注册为 shell 函数） ─
        shellHook = ''
          # ── 快捷脚本 ─────────────────────────────────
          flake-write() { nix run .#write-flake; }
          fmt() { nix fmt; }
          fmt-check() { nix fmt -- --fail-on-change; }
          check() { nix flake check; }
          build() { nix run .#${hostname} --impure; }
          build-switch() { nix run .#${hostname} -- switch --impure; }
          build-boot() { nix run .#${hostname} -- boot --impure; }
        '';
      };
    };
}
