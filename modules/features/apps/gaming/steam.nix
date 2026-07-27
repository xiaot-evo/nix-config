{ den, ... }:
{
  den.aspects.apps.gaming.steam = { user, ... }: {
    includes = [
      (den.batteries.unfree [
        "steam"
        "steam-unwrapped"
      ])
      den.aspects.apps.gaming.gamemode
    ];
    user = {
      extraGroups = [
        "seat"
      ];
    };
    nixos =
      { pkgs, ... }:
      {
        programs.gamescope = {
          enable = true;
          enableWsi = false;
          capSysNice = false;
        };
        services.seatd = {
          enable = true;
        };
        programs.steam = {
          enable = true;
          extest.enable = true;
          package = pkgs.steam.override {
            extraPkgs =
              pkgs: with pkgs; [
                libXcursor
                libXi
                libXinerama
                libXScrnSaver
                libpng
                libpulseaudio
                libvorbis
                stdenv.cc.cc.lib
                libkrb5
                keyutils
                pulseaudio
                mangohud
              ];
          };
          gamescopeSession = {
            enable = true;
            args = [
              "-W 1920"
              "-H 1080"
              "-f"
              "-e"
              "--xwayland-count 2"
              "--mangoapp"
            ];
            steamArgs = [
              "-pipewire-dmabuf"
              "-gamepadui"
              "-steamdeck"
              "-steamos3"
            ];
          };
          extraCompatPackages = with pkgs; [
            proton-ge-bin
            dwproton-bin
          ];
          remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
          dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
          localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
        };
      };
  };
}
