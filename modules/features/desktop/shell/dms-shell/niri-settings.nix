{ den, ... }:
{
  # DMS 相关 niri 设置：kdl includes + IPC 键绑定
  den.aspects.desktop.shell.dms-shell.niri-settings = {
    homeManager =
      { lib, config, ... }:
      {
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
