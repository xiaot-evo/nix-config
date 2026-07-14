{ den, inputs, ... }:
{
  den.aspects.desktop.shell.noctalia = {
    includes = [ den.aspects.desktop.shell.noctalia.niri-settings ];
    nixos = {
      networking.networkmanager.enable = true;
      hardware.bluetooth.enable = true;
      services.tuned.enable = true;
      services.upower.enable = true;
    };
    homeManager = {
      imports = [ inputs.noctalia.homeModules.default ];
      programs.noctalia = {
        enable = true;
        systemd.enable = true;
        settings = builtins.fromTOML (builtins.readFile ./noctalia-config.toml);
      };
    };
  };
}
