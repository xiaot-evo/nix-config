{ den, ... }:
{
  den.aspects.security.gnome-keyring = {
    nixos = {
      services.gnome.gnome-keyring.enable = true;
    };
  };
}
