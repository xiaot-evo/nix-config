{ den, ... }:
{
  den.aspects.services.ly = {
    includes = [
      den.aspects.security.gnome-keyring
    ];
    nixos = {
      services.displayManager.ly = {
        enable = true;
        x11Support = true;
        settings = {
        };
      };
    };
  };
}
