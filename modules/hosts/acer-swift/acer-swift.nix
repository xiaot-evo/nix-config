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
        system.sound
      ]

      );
    nixos =
      { pkgs, lib, ... }:
      {
      };

    provides.to-users.homeManager =
      { pkgs, ... }:
      {
      };
  };
}
