{ den, ... }:
{
  den.aspects.services.printing = {
    nixos =
      { pkgs, ... }:
      {
        # Enable CUPS to print documents.
        # services.printing.enable = true;
        services.printing = {
          enable = true;
          openFirewall = true;
          drivers = [ pkgs.hplip ];
        };
        services.avahi = {
          enable = true;
          nssmdns4 = true;
          openFirewall = true;
        };
      };
  };
}
