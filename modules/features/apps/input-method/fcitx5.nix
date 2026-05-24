{ den, ... }:
{
  den.aspects.apps.input-method.fcitx5 = {
    homeManager =
      { config, pkgs, ... }:
      {
        i18n.inputMethod = {
          type = "fcitx5";
          enable = true;
          fcitx5.waylandFrontend = true;
          fcitx5.addons = with pkgs; [
            (fcitx5-rime.override { rimeDataPkgs = [ pkgs.rime-ice ]; })
            fcitx5-gtk
          ];
        };
        # rime-ice patch
        home.file.".local/share/fcitx5/rime/default.custom.yaml".text = ''
          patch:
            __include: rime_ice_suggestion:/
        '';
      };
  };
}
