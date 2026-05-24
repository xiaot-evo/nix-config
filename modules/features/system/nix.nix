# Nix 守护进程与系统引导配置
# 包含 bootloader、内核参数、plymouth、网络、蓝牙、显示 EDID、时区、语言和 nix 自身设置
{ den, ... }:
{
  den.aspects.system.nix = {
    nixos =
      {
        lib,
        pkgs,
        inputs,
        ...
      }:
      {

        # 网络：使用 NetworkManager
        networking.networkmanager.enable = true;

        # 蓝牙
        hardware.bluetooth.enable = true;

        # 显示 EDID —— 自定义 1080p@80Hz 模型线
        hardware.display.edid = {
          enable = true;
          modelines."1080p80" = "186.71 1920 1968 2000 2080 1080 1083 1088 1122 +hsync -vsync";
        };

        # 时区与语言
        time.timeZone = "Asia/Shanghai";
        i18n.defaultLocale = "zh_CN.UTF-8";

        # Nix 自身配置
        # nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
        nix.settings.experimental-features = [
          "nix-command"
          "flakes"
        ];
      };
  };
}
