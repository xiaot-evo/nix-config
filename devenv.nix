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
    check.exec = ''
      nix flake check
    '';
    build.exec = ''
      nix run .#${hostname} --impure
    '';
    build-switch.exec = ''
      nix run .#${hostname} -- switch --impure
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
