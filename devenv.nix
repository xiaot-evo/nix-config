{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
let
  hostname = builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile /etc/hostname);
in
{
  # ── 基础工具 ─────────────────────────────────
  packages = with pkgs; [
    git
    gh
    nh
    nixfmt
    fish
  ];

  # ── Nix 语言支持 ─────────────────────────────
  languages.nix = {
    enable = true;
    lsp = {
      enable = true;
      package = pkgs.nixd;
    };
  };

  # ── 快捷脚本 ─────────────────────────────────
  scripts = {
    flake-write.exec = ''
      nix run .#write-flake
    '';
    fmt.exec = ''
      nix fmt
    '';
    fmt-check.exec = ''
      nix fmt -- --fail-on-change
    '';
    # 自动 git add 所有未跟踪的 .nix 文件（packages/ 等）
    pkg-sync.exec = ''
      echo "同步 packages..."
      git ls-files --others --exclude-standard -- "packages/*.nix" | while read -r f; do
        echo "  + git add $f"
        git add "$f"
      done
      echo "完成。"
    '';
    check.exec = ''
      git ls-files --others --exclude-standard -- "packages/*.nix" | xargs -r git add
      nix flake check
    '';
    build.exec = ''
      git ls-files --others --exclude-standard -- "packages/*.nix" | xargs -r git add
      nix run .#${hostname} --impure
    '';
    build-switch.exec = ''
      git ls-files --others --exclude-standard -- "packages/*.nix" | xargs -r git add
      nix run .#${hostname} -- switch --impure
    '';
    build-boot.exec = ''
      git ls-files --others --exclude-standard -- "packages/*.nix" | xargs -r git add
      nix run .#${hostname} -- boot --impure
    '';
  };

  # ── Claude Code 集成 ─────────────────────────
  claude.code = {
    enable = true;
    # 暂时禁用 devenv MCP 以减少内存占用
    # mcpServers = {
    #   devenv = {
    #     type = "stdio";
    #     command = "devenv";
    #     args = [ "mcp" ];
    #     env = {
    #       DEVENV_ROOT = config.devenv.root;
    #     };
    #   };
    # };
    mcpServers = { };
  };

  enterTest = ''
    nix flake check
  '';
}
