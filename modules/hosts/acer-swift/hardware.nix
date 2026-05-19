{ ... }:

{
  den.aspects.acer-hardware = {
    nixos = { config, lib, ... }: {
      boot.initrd.availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usb_storage"
        "sd_mod"
      ];
      boot.kernelModules = [ "kvm-amd" ];

      fileSystems."/" = {
        device = "/dev/disk/by-uuid/b6f4d613-c06d-4de2-a366-b2673e9fff2a";
        fsType = "btrfs";
        options = [
          "subvol=root"
          "compress=zstd"
        ];
      };

      fileSystems."/home" = {
        device = "/dev/disk/by-uuid/b6f4d613-c06d-4de2-a366-b2673e9fff2a";
        fsType = "btrfs";
        options = [
          "subvol=home"
          "compress=zstd"
        ];
      };

      fileSystems."/nix" = {
        device = "/dev/disk/by-uuid/b6f4d613-c06d-4de2-a366-b2673e9fff2a";
        fsType = "btrfs";
        options = [
          "subvol=nix"
          "noatime"
          "compress=zstd"
        ];
      };

      fileSystems."/boot/efi" = {
        device = "/dev/disk/by-uuid/7556-B936";
        fsType = "vfat";
        options = [
          "fmask=0022"
          "dmask=0022"
        ];
      };

      networking.useDHCP = lib.mkDefault true;

      nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
      powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
  };
}
