{ den, ... }:
{
  # 声明 quirk：供其他 aspect 消费的主题偏好
  den.quirks.themePrefs = {
    description = "主题偏好：图标、光标、字体等共享配置";
  };

  den.aspects.preference.theme = {
    # 发射 quirk 数据 — 供 dms-shell 等消费者引用，实现单一配置源
    themePrefs = {
      iconTheme = "WhiteSur-light";
      cursorTheme = "Bibata-Modern-Classic";
      cursorSize = 24;
      fontFamily = "LXGW WenKai";
      monoFontFamily = "Maple Mono NF CN";
    };

    homeManager =
      { pkgs, ... }:
      {
        # --- 光标主题 ---
        home.pointerCursor = {
          enable = true;
          name = "Bibata-Modern-Classic";
          package = pkgs.bibata-cursors;
          size = 24;
          x11 = {
            enable = true;
            defaultCursor = "Bibata-Modern-Classic";
          };
        };

        # --- GTK 主题 ---
        gtk = {
          enable = true;
          theme = {
            name = "adw-gtk3";
            package = pkgs.adw-gtk3;
          };
          iconTheme = {
            name = "WhiteSur-light";
            package = pkgs.whitesur-icon-theme;
          };
          cursorTheme = {
            name = "Bibata-Modern-Classic";
            package = pkgs.bibata-cursors;
            size = 24;
          };
          font = {
            name = "LXGW WenKai";
            size = 11;
          };
          gtk3.extraConfig = {
            gtk-application-prefer-dark-theme = 0;
          };
        };

        # --- Qt 主题（Qt5 用 qt5ct，Qt6 自动回退 Fusion） ---
        qt = {
          enable = true;
          platformTheme.name = "qt5ct";
        };

        # 主题相关包
        home.packages = with pkgs; [
          adw-gtk3
          kdePackages.breeze-icons  # WhiteSur 图标主题的继承依赖
          libsForQt5.qt5ct
          qt6Packages.qt6ct
          libsForQt5.qtstyleplugin-kvantum
          qt6Packages.qtstyleplugin-kvantum
        ];
      };
  };
}
