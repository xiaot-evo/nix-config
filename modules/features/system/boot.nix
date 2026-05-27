{ inputs, den, ... }:
{
  den.aspects.system.boot =
    { host, ... }:
    {
      nixos =
        {
          lib,
          ...
        }:
        {
          # 引导与内核
          boot = {
            # systemd-boot EFI 引导
            loader = {
              systemd-boot.enable = true;
              efi = {
                canTouchEfiVariables = true;
                efiSysMountPoint = "/boot/efi";
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
              "udev.log_level=3"
              "systemd.show_status=auto"
              "drm.edid_firmware=eDP-1:edid/1080p80.bin"
              "zswap.enabled=1" # enables zswap
              "zswap.compressor=zstd" # compression algorithm
              "zswap.max_pool_percent=20" # maximum percentage of RAM that zswap is allowed to use
              "zswap.shrinker_enabled=1" # whether to shrink the pool proactively on high memory pressure
            ];
            kernelPackages =
              let
                pkgs = import inputs.nixpkgs {
                  inherit (host) system;
                  overlays = [
                    inputs.nix-cachyos-kernel.overlays.pinned
                  ];
                };
              in
              pkgs.cachyosKernels.linuxPackages-cachyos-bore-x86_64-v3;
          };
        };
    };
}
