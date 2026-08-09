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
          # 自动 git add 所有未跟踪的 .nix 文件（packages/ 等）
          pkg-sync() {
            echo "同步 packages..."
            git ls-files --others --exclude-standard -- "packages/*.nix" | while read -r f; do
              echo "  + git add $f"
              git add "$f"
            done
            echo "完成。"
          }
          check() {
            git ls-files --others --exclude-standard -- "packages/*.nix" | xargs -r git add
            nix flake check
          }
          build() {
            git ls-files --others --exclude-standard -- "packages/*.nix" | xargs -r git add
            nix run .#${hostname} --impure
          }
          build-switch() {
            git ls-files --others --exclude-standard -- "packages/*.nix" | xargs -r git add
            nix run .#${hostname} -- switch --impure
          }
          build-boot() {
            git ls-files --others --exclude-standard -- "packages/*.nix" | xargs -r git add
            nix run .#${hostname} -- boot --impure
          }
        '';
      };
    };
}
