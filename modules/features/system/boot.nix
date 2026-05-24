{ den, ... }:
{
  den.aspects.system.boot = efipath: {
    nixos =
      { pkgs, lib, ... }:
      {
        # 引导与内核
        boot = {
          # systemd-boot EFI 引导
          loader = {
            systemd-boot.enable = true;
            efi = {
              canTouchEfiVariables = true;
              efiSysMountPoint = efipath;
            };
            timeout = 0; # 跳过启动菜单
          };

          # Plymouth 开机画面
          plymouth = {
            enable = true;
            theme = "bgrt";
          };

          consoleLogLevel = 3;
          initrd.enable = true;
          initrd.verbose = false;
          kernelParams = [
            "quiet"
            "splash"
            "boot.shell_on_fail"
            "udev.log_priority=3"
            "rd.systemd.show_status=auto"
            "drm.edid_firmware=eDP-1:edid/1080p80.bin"
            "zswap.enabled=1" # enables zswap
            "zswap.compressor=lz4" # compression algorithm
            "zswap.max_pool_percent=20" # maximum percentage of RAM that zswap is allowed to use
            "zswap.shrinker_enabled=1" # whether to shrink the pool proactively on high memory pressure
          ];
          kernelPackages = pkgs.linuxKernel.packages.linux_zen;
        };
      };
  };
}
