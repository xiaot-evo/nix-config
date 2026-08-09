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
          font = {
            name = "LXGW WenKai";
            size = 11;
          };
          gtk3.extraConfig = {
            gtk-application-prefer-dark-theme = 0;
          };
        };

        # --- Qt 主题（Qt5 用 qt5ct，Qt6 用 qt6ct） ---
        qt = {
          enable = true;
          platformTheme.name = "qt5ct";
        };

        # Qt5ct/Qt6ct 图标主题配置（确保 Qt 应用托盘图标正常）
        xdg.configFile = {
          "qt5ct/qt5ct.conf".text = ''
            [Appearance]
            icon_theme=WhiteSur-light
          '';
          "qt6ct/qt6ct.conf".text = ''
            [Appearance]
            icon_theme=WhiteSur-light
          '';
        };

        # 环境变量：Qt 平台主题 + 图标主题
        home.sessionVariables = {
          QT_QPA_PLATFORMTHEME = "qt5ct";
          QT_STYLE_OVERRIDE = "kvantum";
        };

        # 主题相关包
        home.packages = with pkgs; [
          adw-gtk3
          adwaita-icon-theme # GNOME 应用及系统托盘图标回退依赖
          kdePackages.breeze-icons # WhiteSur 图标主题的继承依赖（Inherits=breeze）
          hicolor-icon-theme # XDG 标准最终回退主题（Inherits=hicolor）
          libsForQt5.qt5ct
          qt6Packages.qt6ct
          libsForQt5.qtstyleplugin-kvantum
          qt6Packages.qtstyleplugin-kvantum
        ];
      };
  };
}
