{ den, ... }:
{
  den.aspects.desktop.input-method.fcitx5 = {
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
            fcitx5-mellow-themes
          ];
        };
        # rime-ice patch
        home.file.".local/share/fcitx5/rime/default.custom.yaml".text = ''
          patch:
            __include: rime_ice_suggestion:/
        '';
        # fcitx5 theme
        xdg.configFile."fcitx5/conf/classicui.conf".text = ''
          Theme=kwinblur-mellow-youlan
        '';
      };
  };
}
