{
  den,
  inputs,
  ...
}:
{
  # Parametric aspect:
  #   (services.flathub { packages = [ ... ]; "packages-x11" = [ ... ]; })
  den.aspects.services.flathub =
    {
      packages,
      ...
    }@args:
    let
      packages-x11 = args."packages-x11" or [ ];
    in
    {
      nixos = { pkgs, ... }: {
        services.flatpak.enable = true;
      };
      homeManager = { pkgs, ... }: {
        imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];
        home = {
          sessionVariables = {
            XDG_DATA_DIRS = "$XDG_DATA_DIRS:/usr/share:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share";
          };
        };
        services.flatpak = {
          enable = true;
          update = {
            # onActivation = true;
            auto = {
              enable = true;
            };
          };
          remotes = [
            {
              name = "flathub";
              location = "https://mirrors.ustc.edu.cn/flathub";
              # location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
            }
          ];
          packages = builtins.map (appId: {
            origin = "flathub";
            inherit appId;
          }) (packages ++ packages-x11);
          overrides.settings = {
            global = {
              # Force Wayland by default
              Context = {
                sockets = [
                  "wayland"
                  "!x11"
                  "!fallback-x11"
                ];
                filesystem = [

                ];
              };

              Environment = {
                # Fix un-themed cursor in some Wayland apps
                XCURSOR_PATH = "/run/host/user-share/icons:/run/host/share/icons";

                # Force correct theme for some GTK apps
                GTK_THEME = "Adwaita:light";
              };
            };
          }
          # Apps that don't fully support Wayland — enable X11 fallback
          // (builtins.listToAttrs (
            map (appId: {
              name = appId;
              value = {
                Context.sockets = [
                  "wayland"
                  "x11"
                  "!fallback-x11"
                ];
              };
            }) packages-x11
          ));
        };
      };
    };
}
