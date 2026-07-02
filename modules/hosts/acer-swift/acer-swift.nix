{ den, ... }:
{
  # xiaot_evo user at nixos host
  den.hosts.x86_64-linux.acer-swift.users.xiaot_evo = { };

  den.aspects.acer-swift = {
    includes =
      (with den.batteries; [
        hostname
      ])
      ++ (with den.aspects; [
        acer-swift.hardware
        (system.hardware.nvidia {
          nvidiaBusId = "PCI:1@0:0:0";
          amdgpuBusId = "PCI:4@0:0:0";
        })
        (system.hardware.nbfc-linux "Acer Swift SFX14-41G")
        system.boot
        system.nix
        system.network
        system.sound
        services.powermanagement
      ]

      );
    nixos =
      { pkgs, lib, ... }:
      {
        # 时区与语言
        time.timeZone = "Asia/Shanghai";
        i18n.defaultLocale = "zh_CN.UTF-8";

        environment.systemPackages = with pkgs; [
          pciutils
        ];
      };
  };
}
