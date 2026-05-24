{ den, inputs, ... }:
{
  den.aspects.apps.zen-browser = {
    homeManager = {
      imports = [ inputs.zen-browser.homeModules.beta ];
      programs.zen-browser = {
        enable = true;
        setAsDefaultBrowser = true;
        policies =
          let
            mkExtensionSettings = builtins.mapAttrs (
              _: pluginId: {
                install_url = "https://addons.mozilla.org/firefox/downloads/latest/${pluginId}/latest.xpi";
                installation_mode = "force_installed";
              }
            );
          in
          {
            ExtensionSettings = mkExtensionSettings {
              "uBlock0@raymondhill.net" = "ublock-origin";
              "firefox@tampermonkey.net" = "tampermonkey";
              "{5efceaa7-f3a2-4e59-a54b-85319448e305}" = "immersive-translate";
              "addon@darkreader.org" = "darkreader";
            };
          };
      };
    };
  };
}
