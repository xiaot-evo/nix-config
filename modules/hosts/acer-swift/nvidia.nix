{ ... }:

{
  den.aspects.acer-nvidia = {
    nixos = { config, ... }: {
      hardware.graphics = {
        enable = true;
      };

      services.xserver.videoDrivers = [
        "amdgpu"
        "nvidia"
      ];

      hardware.nvidia = {
        modesetting.enable = true;
        powerManagement.enable = false;
        powerManagement.finegrained = true;
        open = true;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
      };

      hardware.nvidia.prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        nvidiaBusId = "PCI:1@0:0:0";
        amdgpuBusId = "PCI:4@0:0:0";
      };
    };
  };
}
