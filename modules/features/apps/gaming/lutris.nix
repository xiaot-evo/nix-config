{ den, ... }: {
  den.aspects.apps.gaming.lutris = {
    homeManager = { pkgs, ... }: {
      programs.lutris = {
        enable = true;
        defaultWinePackage = pkgs.proton-ge-bin;
        winePackages = with pkgs; [
          (wineWow64Packages.staging.override { waylandSupport = true; })
        ];
        protonPackages = with pkgs; [
          proton-ge-bin
          dwproton-bin
        ];
        extraPackages = with pkgs; [
          mangohud
          winetricks
          gamescope
          gamemode
          umu-launcher
        ];
        steamPackage = pkgs.steam;
      };
    };
    nixos = {
      hardware.graphics.enable32Bit = true;
    };
  };
}
