{ den, ... }:
{
  den.aspects.acer-swift = {
    includes = [
      den.aspects.acer-hardware
      den.aspects.acer-nvidia
      den.aspects.acer-nbfc
    ];

    nixos =
      { pkgs, lib, ... }:
      {
        nixpkgs.config.allowUnfree = true;

        boot.kernelPackages = pkgs.linuxKernel.packages.linux_zen;

        # Boot loader
        boot.loader = {
          systemd-boot.enable = true;
          efi = {
            canTouchEfiVariables = true;
            efiSysMountPoint = "/boot/efi";
          };
          timeout = 0;
        };

        # Plymouth silent boot
        boot.plymouth = {
          enable = true;
          theme = lib.mkForce "bgrt";
        };
        boot.consoleLogLevel = 3;
        boot.initrd.enable = true;
        boot.initrd.verbose = false;
        boot.kernelParams = [
          "quiet"
          "splash"
          "boot.shell_on_fail"
          "udev.log_priority=3"
          "rd.systemd.show_status=auto"
          "drm.edid_firmware=eDP-1:edid/1080p80.bin"
        ];

        # Network
        networking.hostName = "nixos";
        networking.networkmanager.enable = true;

        # Bluetooth
        hardware.bluetooth.enable = true;

        # Time & locale
        time.timeZone = "Asia/Shanghai";
        i18n.defaultLocale = "zh_CN.UTF-8";

        # Sound
        services.pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
        };

        # Nix
        nix.settings = {
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          substituters = [
            "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
            "https://nix-community.cachix.org"
            "https://cache.nixos.org/"
            "https://cache.nixos-cuda.org"
          ];
          trusted-public-keys = [
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
          ];
          trusted-users = [
            "root"
            "xiaot_evo"
          ];
        };
      };

    provides.to-users.homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          fastfetch
          neovim
        ];
      };
  };
}
