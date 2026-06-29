{ inputs, den, ... }:
{
  den.aspects.desktop.shell.dms-shell = {
    homeManager =
      { lib, config, ... }:
      {
        imports = [
          inputs.dms.homeModules.dank-material-shell
          inputs.dms-plugin-registry.homeModules.dms-plugin-registry
        ];
        systemd.user.services.dms.Install = lib.mkForce {
          WantedBy = [ "niri.service" ];
        };
        programs.dank-material-shell =
          let
            readjson = path: remove: lib.removeAttrs (builtins.fromJSON (lib.readFile path)) remove;
          in
          {
            enable = true;
            # quickshell.package = inputs.quickshell.packages.${pkgs.hostPlatform.system}.default;

            systemd = {
              enable = true;
              restartIfChanged = true;
            };

            # Core features
            enableSystemMonitoring = true; # System monitoring widgets (dgop)
            enableVPN = true; # VPN management widget
            enableDynamicTheming = true; # Wallpaper-based theming (matugen)
            enableAudioWavelength = true; # Audio visualizer (cava)
            enableCalendarEvents = true; # Calendar integration (khal)
            enableClipboardPaste = true; # Pasting items from the clipboard (wtype)

            settings = readjson ./settings.json [
              # "currentThemeName"
              # "customThemeFile"
              # "dockTransparency"
              # "fontFamily"
              # "popupTransparency"
              # "theme"
            ];
            session = readjson ./session.json [
              # "wallpaperPath"
              # "wallpaperPathDark"
              # "wallpaperPathLight"
            ];
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
        wayland.windowManager.niri.settings = {
          include = [
            { _args = [ "dms/alttab.kdl" ]; }
            { _args = [ "dms/binds.kdl" ]; }
            { _args = [ "dms/colors.kdl" ]; }
            { _args = [ "dms/cursor.kdl" ]; }
            { _args = [ "dms/layout.kdl" ]; }
            { _args = [ "dms/outputs.kdl" ]; }
            { _args = [ "dms/windowrules.kdl" ]; }
            { _args = [ "dms/wpblur.kdl" ]; }
          ]; # Includes are excluded from niri config validation
          binds =
            let
              cfg = config.programs.dank-material-shell;
              dms-ipc =
                args:
                [
                  "dms"
                  "ipc"
                ]
                ++ args;
            in
            {
              "Mod+Space" = {
                _props.hotkey-overlay-title = "Toggle Application Launcher";
                spawn._args = dms-ipc [
                  "spotlight"
                  "toggle"
                ];
              };
              "Mod+N" = {
                _props.hotkey-overlay-title = "Toggle Notification Center";
                spawn._args = dms-ipc [
                  "notifications"
                  "toggle"
                ];
              };
              "Mod+Slash" = {
                _props.hotkey-overlay-title = "Toggle Settings";
                spawn._args = dms-ipc [
                  "settings"
                  "toggle"
                ];
              };
              "Mod+P" = {
                _props.hotkey-overlay-title = "Toggle Notepad";
                spawn._args = dms-ipc [
                  "notepad"
                  "toggle"
                ];
              };
              "Super+Alt+L" = {
                _props.hotkey-overlay-title = "Toggle Lock Screen";
                spawn._args = dms-ipc [
                  "lock"
                  "lock"
                ];
              };
              "Mod+X" = {
                _props.hotkey-overlay-title = "Toggle Power Menu";
                spawn._args = dms-ipc [
                  "powermenu"
                  "toggle"
                ];
              };
              "XF86AudioRaiseVolume" = {
                _props.allow-when-locked = true;
                spawn._args = dms-ipc [
                  "audio"
                  "increment"
                  "3"
                ];
              };
              "XF86AudioLowerVolume" = {
                _props.allow-when-locked = true;
                spawn._args = dms-ipc [
                  "audio"
                  "decrement"
                  "3"
                ];
              };
              "XF86AudioMute" = {
                _props.allow-when-locked = true;
                spawn._args = dms-ipc [
                  "audio"
                  "mute"
                ];
              };
              "XF86AudioMicMute" = {
                _props.allow-when-locked = true;
                spawn._args = dms-ipc [
                  "audio"
                  "micmute"
                ];
              };
              "XF86MonBrightnessUp" = {
                _props.allow-when-locked = true;
                spawn._args = dms-ipc [
                  "brightness"
                  "increment"
                  "5"
                  ""
                ];
              };
              "XF86MonBrightnessDown" = {
                _props.allow-when-locked = true;
                spawn._args = dms-ipc [
                  "brightness"
                  "decrement"
                  "5"
                  ""
                ];
              };
              "Mod+Alt+N" = {
                _props = {
                  allow-when-locked = true;
                  hotkey-overlay-title = "Toggle Night Mode";
                };
                spawn._args = dms-ipc [
                  "night"
                  "toggle"
                ];
              };
              "Mod+V" = {
                _props.hotkey-overlay-title = "Toggle Clipboard Manager";
                spawn._args = dms-ipc [
                  "clipboard"
                  "toggle"
                ];
              };
            }
            // lib.attrsets.optionalAttrs cfg.enableSystemMonitoring {
              "Mod+M" = {
                _props.hotkey-overlay-title = "Toggle Process List";
                spawn._args = dms-ipc [
                  "processlist"
                  "toggle"
                ];
              };
            };
        };
      };
  };
}
