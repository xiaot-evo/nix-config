{ den, inputs, ... }:
{
  den.aspects.services.dae = {
    nixos =
      # nixos configuration module
      {
        imports = [
          inputs.daeuniverse.nixosModules.dae
          inputs.daeuniverse.nixosModules.daed
        ];
        # daed - dae with a web dashboard
        services.daed = {
          enable = true;

          openFirewall = {
            enable = true;
            port = 11122;
          };

          # default options

          # package = inputs.daeuniverse.packages.x86_64-linux.daed;
          # configDir = "/etc/daed";
          listen = "127.0.0.1:22233";
        };
      };
  };
}
