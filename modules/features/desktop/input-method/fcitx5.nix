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
            fcitx5-tokyonight
          ];
        };
        # rime-ice patch
        home.file.".local/share/fcitx5/rime/default.custom.yaml".text = ''
          patch:
            __include: rime_ice_suggestion:/
        '';
        # fcitx5 theme：Tokyonight-Day（day 亮色）
        # 注：mellow 系列主题在 X11 下有黑框问题（kwinblur 依赖 KWin 模糊、圆角 SVG 透明像素
        # 在 xwayland-satellite 下合成失败），若未来在纯 Wayland 环境使用可改回 mellow-youlan
        xdg.configFile."fcitx5/conf/classicui.conf".text = ''
          Theme=Tokyonight-Day
        '';
      };
  };
}
