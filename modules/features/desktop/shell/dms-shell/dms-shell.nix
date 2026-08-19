{ inputs, den, ... }:
{
  den.aspects.desktop.shell.dms-shell = {
    # danklinux 生态实用工具 + niri 设置子 aspects（同目录下由 import-tree 自动发现）
    includes = [
      den.aspects.desktop.shell.dms-shell.niri-settings
      den.aspects.desktop.shell.dms-shell.danksearch
    ];
    homeManager =
      {
        lib,
        themePrefs,
        ...
      }:
      let
        # 从 theme.nix 的 quirk 获取统一主题配置
        tp = if themePrefs != [ ] then builtins.head themePrefs else { };
      in
      {
        imports = [
          inputs.dms.homeModules.dank-material-shell
          inputs.dms-plugin-registry.homeModules.dms-plugin-registry
        ];
        programs.dank-material-shell = {
          enable = true;

          systemd = {
            enable = true;
            restartIfChanged = true;
            target = "niri.service";
          };

          # Core features
          enableSystemMonitoring = true; # System monitoring widgets (dgop)
          enableVPN = true; # VPN management widget
          enableDynamicTheming = true; # Wallpaper-based theming (matugen)
          enableAudioWavelength = true; # Audio visualizer (cava)
          enableCalendarEvents = true; # Calendar integration (khal)

          settings = lib.recursiveUpdate (builtins.fromJSON (lib.readFile ./settings.json)) {
            # 全部从 theme.nix 的 quirk 引用，保持单一配置源
            iconTheme = tp.iconTheme or "WhiteSur-light";
            cursorSettings = {
              size = tp.cursorSize or 24;
              theme = tp.cursorTheme or "Bibata-Modern-Classic";
            };
            fontFamily = tp.fontFamily or "LXGW WenKai";
            monoFontFamily = tp.monoFontFamily or "Maple Mono NF CN";
          };
          session = builtins.fromJSON (lib.readFile ./session.json);
          clipboardSettings = {
            maxHistory = 25;
            maxEntrySize = 5242880;
            autoClearDays = 1;
            clearAtStartup = true;
            disabled = false;
            disableHistory = false;
            disablePersist = true;
          };
          # Auto-enabled when plugins have settings configured
          managePluginSettings = true;
          plugins = {
            dankKDEConnect = {
              enable = true;
            };
            dankGifSearch = {
              enable = true;
            };
            dankLauncherKeys = {
              enable = true;
            };
            dankStickerSearch = {
              enable = true;
            };
            # somePlugin = {
            #   enable = true;
            #   settings = {
            #     # Your plugin settings here
            #   };
            # };
          };
        };
      };
  };
}
