{ pkgs, ... }:
let
  # pi 官方範例擴展 — 直接從 GitHub raw 拉取，無本地拷貝
  src = {
    notify = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/examples/extensions/notify.ts";
      hash = "sha256-Gg9kJAK+x3d7Le3v1ZJicAayh3wKCB7+ykcqYWWx4nE=";
    };
    planModeIndex = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/examples/extensions/plan-mode/index.ts";
      hash = "sha256-kPrlPi+tqXFl90iFIL1U88v+XSx+TP070qoH7nluYeg=";
    };
    planModeUtils = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/examples/extensions/plan-mode/utils.ts";
      hash = "sha256-Euoo1XzFXmjo1SovHRbfiy5/J0nNaU1BRTAoACor2tk=";
    };
  };

  # 組裝擴展目錄
  extensionsDir = pkgs.runCommand "pi-extensions" {} ''
    mkdir -p $out/plan-mode
    cp ${src.notify} $out/notify.ts
    cp ${src.planModeIndex} $out/plan-mode/index.ts
    cp ${src.planModeUtils} $out/plan-mode/utils.ts
  '';

  # Permission system 配置 — 類似 OpenCode 的信任模式
  permissionConfig = builtins.toJSON {
    permission = {
      "*" = "allow";
      path = {
        "*" = "allow";
        "*.env" = {
          action = "deny";
          reason = "環境變數檔案包含憑證，禁止直接存取";
        };
        "*.env.*" = {
          action = "deny";
          reason = "環境變數檔案包含憑證，禁止直接存取";
        };
        ".git/*" = {
          action = "deny";
          reason = ".git 內部檔案不應直接修改";
        };
        "~/.ssh/*" = {
          action = "deny";
          reason = "SSH 金鑰檔案受保護";
        };
      };
      bash = {
        "*" = "allow";
        "rm -rf *" = "deny";
        "rm -rf /*" = "deny";
        "sudo *" = "ask";
        "chmod 777 *" = "ask";
        "chmod -R 777 *" = "ask";
        "> *" = "ask";
        ">>*" = "ask";
        "dd *" = "deny";
        "mkfs*" = "deny";
        "reboot" = "deny";
        "shutdown" = "deny";
      };
      external_directory = "ask";
    };
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
    ".pi/agent/extensions/notify.ts".source = "${extensionsDir}/notify.ts";
    ".pi/agent/extensions/plan-mode".source = "${extensionsDir}/plan-mode";
    ".pi/agent/extensions/pi-permission-system/config.json".text = permissionConfig;
  };
}
