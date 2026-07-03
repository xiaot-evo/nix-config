{ pkgs, ... }:
let
  # 本地扩展 — 从 GitHub raw 拉取，无本地拷贝
  notifySrc = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/examples/extensions/notify.ts";
    hash = "sha256-Gg9kJAK+x3d7Le3v1ZJicAayh3wKCB7+ykcqYWWx4nE=";
  };

in
{
  home.file = {
    ".pi/agent/mcp.json".text = builtins.toJSON {
      mcpServers.nixos = {
        command = "nix";
        args = [
          "run"
          "github:jsiegel-supplyframe/mcp-nixos/nix-taco-sprint/den-source"
          "--"
        ];
      };
    };
    ".pi/agent/extensions/notify.ts".source = "${notifySrc}";
  };
}
