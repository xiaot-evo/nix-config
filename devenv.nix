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
  packages = [
    pkgs.git
    pkgs.gh
    pkgs.nixfmt
    pkgs.fish
  ];

  # ── Nix 语言支持 ─────────────────────────────
  languages.nix = {
    enable = true;
    lsp = {
      enable = true;
      package = pkgs.nil;
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
    mcpServers = {
      devenv = {
        type = "stdio";
        command = "devenv";
        args = [ "mcp" ];
        env = {
          DEVENV_ROOT = config.devenv.root;
        };
      };
    };
  };

  enterTest = ''
    nix flake check
  '';
}
