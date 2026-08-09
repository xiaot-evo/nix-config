{ den, inputs, ... }: {
  den.aspects.desktop.wm.niri =
    { user, ... }:
    {
      nixos = {
        imports = [ inputs.niri-nix.nixosModules.default ]; # For NixOS
        programs.niri = {
          enable = true;
          withXDG = true;
          useNautilus = true;
        };
        services.gnome.gnome-keyring.enable = true;
      };
      homeManager =
        { pkgs, lib, ... }:
        let
          # 窗口规则辅助函数：为应用添加毛玻璃效果
          blurredApp = appId: {
            match._props.app-id = appId;
            opacity = 0.75;
            background-effect = {
              xray = true;
              blur = true;
            };
          };
          maximizedBlurredApp = appId: blurredApp appId // { open-maximized = true; };
        in
        {
          imports = [ inputs.niri-nix.homeModules.default ];
          home.packages = with pkgs; [
            nautilus
          ];
          wayland.windowManager.niri = {
            enable = true;
            settings = {
              output = [
                {
                  _args = [ "eDP-1" ];
                  mode = "1920x1080@80";
                  position._props = {
                    x = 0;
                    y = 0;
                  };
                  scale = 1.0;
                }
              ];
              input = {
                keyboard.xkb = {
                  layout = "us";
                };
                touchpad = {
                  tap = [ ];
                  dwt = [ ];
                  natural-scroll = [ ];
                };
              };
              debug = {
                # 允许面板切换和窗口激活，DMS/Noctalia 等 Shell 需要
                honor-xdg-activation-with-invalid-serial = true;
              };

              layout = {
                background-color = "transparent";
                preset-column-widths._children = [
                  { proportion = 0.33333; }
                  { proportion = 0.5; }
                  { proportion = 0.66667; }
                  { proportion = 1.0; }
                ];
              };

              hotkey-overlay = {
                skip-at-startup = true;
              };

              screenshot-path = "/home/${user.userName}/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";
              window-rule = [
                {
                }
                (maximizedBlurredApp "zen-beta")
                (blurredApp "com.mitchellh.ghostty")
                (blurredApp "tabby")
                (blurredApp "com.danklinux.dms")
                (maximizedBlurredApp "dev.zed.Zed")
                (maximizedBlurredApp "obsidian")
                {
                  # match = { };
                  # block-out-from = "screen-capture";
                  draw-border-with-background = false;
                  default-column-width = {
                    proportion = 0.75;
                  };
                  clip-to-geometry = true;
                  # 所有窗口启用模糊背景
                  background-effect = {
                    blur = true;
                    xray = false;
                  };
                }
                {
                  match._props.title = "^float$";
                  open-floating = true;
                }
                {
                  match = {
                    _props = {
                      is-active = false;
                    };
                  };
                  opacity = 0.75;
                  background-effect = {
                    xray = true;
                    blur = true;
                  };
                }
                {
                  opacity = 0.75;
                  match._props.is-floating = true;
                  background-effect = {
                    xray = false;
                    blur = true;
                  };
                }
              ];

              binds = {
                "Mod+T" = {
                  _props = {
                    hotkey-overlay-title = "Open a Terminal: ghostty";
                  };
                  spawn = "ghostty";
                };
                "Mod+Shift+T" = {
                  _props = {
                    hotkey-overlay-title = "Open a Floating Terminal: ghostty";
                  };
                  spawn = [
                    "ghostty"
                    "--title=float"
                  ];
                };
                "Mod+Shift+Slash".show-hotkey-overlay = [ ];
                "Mod+Q" = {
                  _props = {
                    repeat = false;
                  };
                  close-window = [ ];
                };
                "Mod+E" = {
                  _props = {
                    hotkey-overlay-title = "Open a File Explorer: Nautilus";
                  };
                  spawn = "nautilus";
                };
                "Mod+Shift+E".quit._props.skip-confirmation = true;

                "Mod+H".focus-column-left = [ ];
                "Mod+L".focus-column-right = [ ];
                "Mod+J".focus-window-or-workspace-down = [ ];
                "Mod+K".focus-window-or-workspace-up = [ ];

                "Mod+Ctrl+H".move-column-left = [ ];
                "Mod+Ctrl+L".move-column-right = [ ];
                "Mod+Ctrl+K".move-column-to-workspace-up = [ ];
                "Mod+Ctrl+J".move-column-to-workspace-down = [ ];

                "Mod+Page_Down".focus-workspace-down = [ ];
                "Mod+Page_Up".focus-workspace-up = [ ];
                "Mod+U".focus-workspace-down = [ ];
                "Mod+I".focus-workspace-up = [ ];
                "Mod+Ctrl+Page_Down".move-column-to-workspace-down = [ ];
                "Mod+Ctrl+Page_Up".move-column-to-workspace-up = [ ];
                "Mod+Ctrl+U".move-column-to-workspace-down = [ ];
                "Mod+Ctrl+I".move-column-to-workspace-up = [ ];

                "Mod+1".focus-workspace = 1;
                "Mod+2".focus-workspace = 2;
                "Mod+3".focus-workspace = 3;
                "Mod+4".focus-workspace = 4;
                "Mod+5".focus-workspace = 5;
                "Mod+6".focus-workspace = 6;
                "Mod+7".focus-workspace = 7;
                "Mod+8".focus-workspace = 8;
                "Mod+9".focus-workspace = 9;
                "Mod+Ctrl+1".move-column-to-workspace = 1;
                "Mod+Ctrl+2".move-column-to-workspace = 2;
                "Mod+Ctrl+3".move-column-to-workspace = 3;
                "Mod+Ctrl+4".move-column-to-workspace = 4;
                "Mod+Ctrl+5".move-column-to-workspace = 5;
                "Mod+Ctrl+6".move-column-to-workspace = 6;
                "Mod+Ctrl+7".move-column-to-workspace = 7;
                "Mod+Ctrl+8".move-column-to-workspace = 8;
                "Mod+Ctrl+9".move-column-to-workspace = 9;

                "Mod+Comma".consume-window-into-column = [ ];
                "Mod+Period".expel-window-from-column = [ ];

                "Mod+R".switch-preset-column-width = [ ];
                "Mod+F".maximize-column = [ ];
                "Mod+Shift+F".fullscreen-window = [ ];
                "Mod+C".center-column = [ ];

                "Mod+Minus".set-column-width = "-10%";
                "Mod+Equal".set-column-width = "+10%";

                # Finer height adjustments when in column with other windows.
                "Mod+Shift+Minus".set-window-height = "-10%";
                "Mod+Shift+Equal".set-window-height = "+10%";

                "Mod+Tab".focus-window-down-or-column-right = [ ];
                "Mod+Shift+Tab".focus-window-up-or-column-left = [ ];

                "Mod+Alt+V".switch-focus-between-floating-and-tiling = [ ];
                "Mod+Shift+V".toggle-window-floating = [ ];

                # 方向键导航（HJKL 备用）
                "Mod+Left".focus-column-left = [ ];
                "Mod+Right".focus-column-right = [ ];
                "Mod+Up".focus-window-or-workspace-up = [ ];
                "Mod+Down".focus-window-or-workspace-down = [ ];

                # 跨显示器导航
                "Mod+Shift+H".focus-monitor-left = [ ];
                "Mod+Shift+L".focus-monitor-right = [ ];
                "Mod+Shift+K".focus-monitor-up = [ ];
                "Mod+Shift+J".focus-monitor-down = [ ];

                # 跨显示器移动列
                "Mod+Shift+Ctrl+H".move-column-to-monitor-left = [ ];
                "Mod+Shift+Ctrl+L".move-column-to-monitor-right = [ ];
                "Mod+Shift+Ctrl+K".move-column-to-monitor-up = [ ];
                "Mod+Shift+Ctrl+J".move-column-to-monitor-down = [ ];

                # 工作区移动
                "Mod+Shift+Page_Down".move-workspace-down = [ ];
                "Mod+Shift+Page_Up".move-workspace-up = [ ];

                # 列首/列尾导航
                "Mod+Home".focus-column-first = [ ];
                "Mod+End".focus-column-last = [ ];

                # 窗口操作增强
                "Mod+BracketLeft".consume-or-expel-window-left = [ ];
                "Mod+BracketRight".consume-or-expel-window-right = [ ];
                "Mod+Shift+R".switch-preset-column-width-back = [ ];
                "Mod+Ctrl+R".reset-window-height = [ ];
                "Mod+Ctrl+Shift+R".switch-preset-window-height = [ ];
                "Mod+Ctrl+F".expand-column-to-available-width = [ ];
                "Mod+Ctrl+C".center-visible-columns = [ ];
                "Mod+W".toggle-column-tabbed-display = [ ];

                # 系统功能
                "Mod+O".toggle-overview = [ ];
                "Mod+Escape".toggle-keyboard-shortcuts-inhibit = [ ];
                "Ctrl+Alt+Delete".quit._props.skip-confirmation = true;
                "Mod+Shift+P".power-off-monitors = [ ];

                # 滚轮快捷键
                "Mod+WheelScrollDown".focus-workspace-down = [ ];
                "Mod+WheelScrollUp".focus-workspace-up = [ ];
                "Mod+Ctrl+WheelScrollDown".move-column-to-workspace-down = [ ];
                "Mod+Ctrl+WheelScrollUp".move-column-to-workspace-up = [ ];

                "Print".screenshot._props.show-pointer = false;
                "Ctrl+Print".screenshot-screen._props.show-pointer = false;
                "Alt+Print".screenshot-window = [ ];
              };
              environment = {
                NIXOS_OZONE_WL = "1";
                ELECTRON_OZONE_PLATFORM_HINT = "auto";
                EDITOR = "hx";
                QT_IM_MODULE = "fcitx5";
                XMODIFIERS = "@im=fcitx5";
                SDL_IM_MODULE = "fcitx5";
                GLFW_IM_MODULE = "fcitx5";
              };
              spawn-sh-at-startup = [
                [ "${pkgs.fcitx5}/usr/bin/fcitx5 -d" ]
              ];
              xwayland-satellite.path = "${lib.getExe pkgs.xwayland-satellite}";
            };
          };
        };
    };
}
