{ den, ... }: {
  den.aspects.apps.gaming.opengamepadui = {
    nixos = { pkgs, ... }: {
      programs.opengamepadui = {
        enable = true;
        inputplumber.enable = true;
        powerstation.enable = true;
        fontPackages = with pkgs; [ source-han-sans ];
        gamescopeSession = {
          enable = true;
          args = [
            "--prefer-output"
            "*,eDP-1"
            "--xwayland-count"
            "2"
            "--default-touch-mode"
            "4"
            "--hide-cursor-delay"
            "3000"
            "--fade-out-duration"
            "200"
            "--steam"
          ];
        };
      };
    };
  };
}
