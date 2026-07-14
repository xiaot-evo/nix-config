{ ... }: {
  den.aspects.desktop.shell.noctalia.niri-settings = {
    homeManager = {
      wayland.windowManager.niri.settings = {
        include._args = [ "noctalia.kdl" ];
        # Debug: 允许 Noctalia 通知操作和窗口激活
        debug = {
          honor-xdg-activation-with-invalid-serial = true;
        };

        layout = {
          gaps = 8;
          focus-ring = {
            width = 2;
          };
        };

        # Noctalia 相关窗口规则
        window-rule = [
          # 通用窗口圆角
          {
            geometry-corner-radius = 12;
            clip-to-geometry = true;
          }
          # Noctalia 设置窗口：浮动 + 固定尺寸
          {
            match._props.app-id = "dev.noctalia.Noctalia";
            open-floating = true;
            default-column-width.fixed = 1080;
            default-window-height.fixed = 920;
          }
          # 所有窗口启用模糊（Niri ≥ 26.04）
          {
            background-effect = {
              blur = true;
              xray = false;
            };
          }
        ];

        # Noctalia IPC 键绑定
        binds =
          let
            noctalia-msg =
              args:
              [
                "noctalia"
                "msg"
              ]
              ++ args;
          in
          {
            "Mod+Space" = {
              _props.hotkey-overlay-title = "Toggle Application Launcher";
              spawn._args = noctalia-msg [
                "panel-toggle"
                "launcher"
              ];
            };
            "Mod+S" = {
              _props.hotkey-overlay-title = "Toggle Control Center";
              spawn._args = noctalia-msg [
                "panel-toggle"
                "control-center"
              ];
            };
            "Mod+Slash" = {
              _props.hotkey-overlay-title = "Toggle Settings";
              spawn._args = noctalia-msg [ "settings-toggle" ];
            };
            "XF86AudioRaiseVolume" = {
              _props.allow-when-locked = true;
              spawn._args = noctalia-msg [ "volume-up" ];
            };
            "XF86AudioLowerVolume" = {
              _props.allow-when-locked = true;
              spawn._args = noctalia-msg [ "volume-down" ];
            };
            "XF86AudioMute" = {
              _props.allow-when-locked = true;
              spawn._args = noctalia-msg [ "volume-mute" ];
            };
            "XF86MonBrightnessUp" = {
              _props.allow-when-locked = true;
              spawn._args = noctalia-msg [ "brightness-up" ];
            };
            "XF86MonBrightnessDown" = {
              _props.allow-when-locked = true;
              spawn._args = noctalia-msg [ "brightness-down" ];
            };
          };

        # Backdrop + 层表面模糊规则
        layer-rule = [
          # Option 1: 模糊 Overview 壁纸（需配合 [niri/backdrop] 启用）
          {
            match._props.namespace = "^noctalia-backdrop";
            place-within-backdrop = true;
          }
          # Noctalia 层表面：禁用 xray 以获得真实模糊效果
          {
            match._props.namespace = "^noctalia-(bar-[^\"]+|notification|dock|panel|attached-panel|osd)$";
            background-effect = {
              xray = false;
            };
          }
          # 桌面 Widget 层规则（按需取消注释）
          # 调试：运行 `niri msg layers` 查看所有层 namespace
          # {
          #   match._props.namespace = "^noctalia-desktop-widget-";
          # }
        ];
      };
    };
  };
}
