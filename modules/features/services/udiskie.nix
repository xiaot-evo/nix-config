{ den, ... }:
{
  den.aspects.services.udiskie = {
    nixos = {
      services.udisks2 = {
        enable = true;
      };
    };
    homeManager = {
      services.udiskie = {
        enable = true;
        automount = true;
        notify = true;
        tray = "auto";
        settings = {
          icon_names.media = [ "media-optical" ];
        };
      };
    };
  };
}
