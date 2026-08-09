{
  den,
  inputs,
  ...
}:
{
  # Parametric aspect:
  #   (services.flathub { packages = [ ... ]; "packages-x11" = [ ... ]; })
  den.aspects.services.flathub =
    {
      packages,
      ...
    }@args:
    let
      packages-x11 = args."packages-x11" or [ ];
      # 默认随 aspect 固定安装的包（调用方 packages 之外的附加）
      defaultPackages = [
        # flatpak 沙箱看不到 /nix/store 里的主机主题，需装 flatpak 版 adw-gtk3（与 theme.nix 一致）
        "org.gtk.Gtk3theme.adw-gtk3"
        # flatpak 应用管理
        "io.github.flattool.Warehouse"
        # flatpak 权限管理
        "com.github.tchx84.Flatseal"
      ];
    in
    {
      nixos = { pkgs, ... }: {
        services.flatpak.enable = true;
      };
      homeManager =
        {
          pkgs,
          config,
          themePrefs,
          ...
        }:
        let
          # 从 theme.nix 的 quirk 获取统一主题配置（与 dms-shell 消费方式一致）
          tp = if themePrefs != [ ] then builtins.head themePrefs else { };
          # 主题名/大小/包全部跟随 theme.nix（home.pointerCursor / gtk.iconTheme 已配置值），
          # 缺失时回退 quirk 默认 —— 全局换主题只需改 theme.nix 一处
          cursorTheme = config.home.pointerCursor.name or tp.cursorTheme or "Bibata-Modern-Classic";
          cursorSize = toString (config.home.pointerCursor.size or tp.cursorSize or 24);
          cursorPkg =
            if (config.home.pointerCursor.package or null) != null then
              config.home.pointerCursor.package
            else
              pkgs.bibata-cursors;
          iconPkg =
            if (config.gtk.iconTheme.package or null) != null then
              config.gtk.iconTheme.package
            else
              pkgs.whitesur-icon-theme;
        in
        {
          imports = [ inputs.nix-flatpak.homeManagerModules.nix-flatpak ];
          home = {
            sessionVariables = {
              # /usr/share 在 NixOS 上不存在，改用真实路径；flatpak exports 目录供主机读取
              XDG_DATA_DIRS = "$XDG_DATA_DIRS:/run/current-system/sw/share:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share";
            };
          };
          services.flatpak = {
            enable = true;
            update = {
              # onActivation = true;
              auto = {
                enable = true;
              };
            };
            remotes = [
              {
                name = "flathub";
                location = "https://mirror.sjtu.edu.cn/flathub/flathub.flatpakrepo";
                # location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
              }
            ];
            packages = builtins.map (appId: {
              # 必须与 remotes 中的 name 完全一致（flatpak remote 名大小写敏感）
              origin = "flathub";
              inherit appId;
            }) (packages ++ packages-x11 ++ defaultPackages);
            overrides.settings = {
              global = {
                # Force Wayland by default
                Context = {
                  sockets = [
                    "wayland"
                    "!x11"
                    "!fallback-x11"
                  ];
                  # 暴露宿主 ~/.local/share/icons（沙箱内即 /run/host/user-share/icons）供光标主题加载。
                  # flatpak 默认无 xdg-data 权限，XCURSOR_PATH 指向的目录在沙箱内不可见
                  filesystems = [
                    "xdg-data/icons:ro"
                    # home-manager 的 ~/.icons、~/.local/share/icons 主题链接指向 /nix/store
                    # 内的包（中间层 home-manager-files），而 flatpak 沙箱不挂载宿主 /nix/store
                    # → 链接在沙箱内断链 → 光标/图标回退默认样式。
                    # 直接挂载主题包本体（不引用 config.home-files——它与
                    # flatpak-managed-install.service 互相依赖会求值循环），
                    # 再分别把包内目录加进 XCURSOR_PATH / XDG_DATA_DIRS（见下），
                    # 沙箱内即可直接解析主题。包与主题名均来自 theme.nix（见 homeManager 顶部）
                    "${cursorPkg}:ro"
                    "${iconPkg}:ro"
                  ];
                };

                Environment = {
                  # --- 图标主题 ---
                  # 沙箱内 GTK/Qt 只按 XDG_DATA_DIRS 搜索图标（默认 /app/share:/usr/share），
                  # 不包含宿主 ~/.local/share/icons。挂载 whitesur 主题包（见上）后，
                  # 追加其 share 目录即可直接找到 WhiteSur-light。
                  # 注意：此键为覆盖语义，必须显式保留 flatpak 默认值
                  XDG_DATA_DIRS = "/app/share:/usr/share:${iconPkg}/share";
                  # --- 光标主题 ---
                  # flatpak 沙箱不继承宿主环境变量，必须显式指定主题名和大小。
                  # 末尾追加主题包内 share/icons：主题包已挂载（见 Context.filesystems），
                  # 沙箱内直接按此路径加载主题，不依赖宿主 ~/.icons 链接（那些链接指向 /nix/store，沙箱内断链）
                  XCURSOR_PATH = "/run/host/user-share/icons:/run/host/share/icons:${cursorPkg}/share/icons";
                  XCURSOR_THEME = cursorTheme;
                  XCURSOR_SIZE = cursorSize;
                  # 不设 GTK_THEME：主题经 xdg-desktop-portal 跟随主机 gsettings（adw-gtk3），
                  # 强制 GTK_THEME 会压过 portal 跟随导致主题异常
                };
              };
              # Warehouse 安装/管理应用需写宿主用户 flatpak 安装目录（~/.local/share/flatpak），
              # 但其 manifest 只请求了该目录的只读访问（:ro）→ 授予 home 读写权限。
              # nix-flatpak 会写入 overrides/io.github.flattool.Warehouse，每次 activation 保证存在
              "io.github.flattool.Warehouse" = {
                Context = {
                  sockets = [
                    "wayland"
                    "!x11"
                    "!fallback-x11"
                  ];
                  filesystems = [ "home" ];
                };
              };
            }
            # Apps that don't fully support Wayland — enable X11 fallback
            // (builtins.listToAttrs (
              map (appId: {
                name = appId;
                value = {
                  Context = {
                    sockets = [
                      "wayland"
                      "x11"
                      "!fallback-x11"
                    ];
                    # 输入法：暴露 Fcitx5 配置目录供 x11 应用读取
                    filesystems = [
                      "xdg-config/fcitx5:ro"
                    ];
                  };
                  Environment =
                    # Qt 应用（微信/WPS）强制 X11 后端以兼容 fcitx5（参考 Debian 论坛配置）
                    (
                      if (appId == "com.tencent.WeChat" || appId == "cn.wps.wps_365") then
                        {
                          QT_QPA_PLATFORM = "xcb";
                        }
                      else
                        { }
                    )
                    // {
                      GTK_IM_MODULE = "fcitx";
                      QT_IM_MODULE = "fcitx";
                      XMODIFIERS = "@im=fcitx";
                    };
                };
              }) packages-x11
            ));
          };
        };
    };
}
