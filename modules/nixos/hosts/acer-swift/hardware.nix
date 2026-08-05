{ ... }:

{
  den.aspects.acer-swift.hardware = {
    nixos =
      {
        config,
        lib,
        modulesPath,
        ...
      }:
      {
        imports = [
          (modulesPath + "/installer/scan/not-detected.nix")
        ];

        boot.initrd.availableKernelModules = [
          "nvme"
          "xhci_pci"
          "ahci"
        ];
        boot.initrd.kernelModules = [ ];
        boot.kernelModules = [ "kvm-amd" ];
        boot.extraModulePackages = [ ];

        fileSystems."/" = {
          device = "/dev/disk/by-uuid/b6f4d613-c06d-4de2-a366-b2673e9fff2a";
          fsType = "btrfs";
          options = [ "subvol=root" ];
        };

        fileSystems."/nix" = {
          device = "/dev/disk/by-uuid/b6f4d613-c06d-4de2-a366-b2673e9fff2a";
          fsType = "btrfs";
          options = [ "subvol=nix" ];
        };

        fileSystems."/home" = {
          device = "/dev/disk/by-uuid/b6f4d613-c06d-4de2-a366-b2673e9fff2a";
          fsType = "btrfs";
          options = [ "subvol=home" ];
        };

        fileSystems."/boot/efi" = {
          device = "/dev/disk/by-uuid/7556-B936";
          fsType = "vfat";
          options = [
            "fmask=0022"
            "dmask=0022"
          ];
        };

        swapDevices = [
          { device = "/dev/disk/by-uuid/02c045d1-239d-411b-a7c8-7545b32673d1"; }
        ];

        nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
        hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
        networking.useDHCP = lib.mkDefault true;
      };
  };
}
