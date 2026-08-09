{ den, ... }:
{
  den.homes.x86_64-linux.xiaot_evo = {
    classes = [
      "homeManager"
      "hjem"
    ];
    home-manager.enable = true;
    hjem.enable = true;
  };
  den.aspects.xiaot_evo = {
    includes =
      (with den.batteries; [
        define-user
        primary-user
        inputs'
        (user-shell "fish")
        (unfree [
          "bilibili"
          "warp-terminal"
          "ventoy"
        ])
        (insecure [
          "ventoy-1.1.12"
        ])
      ])
      ++ (with den.aspects; [
        services.dae
        services.ddns-updater
        services.ly
        services.udiskie
        services.printing
        services.kdeconnect
        (services.flathub {
          # Wayland 原生
          packages = [
            "com.qq.QQ"
            "com.usebottles.bottles"
            # 浏览器（flatpak 版；zen-browser-flake 的上游资源不稳定，改用官方 flatpak）
            "app.zen_browser.zen"
            # 通讯（flatpak 版）
            "org.telegram.desktop"
            # 游戏启动器（flatpak 版，沙箱内置 Java 运行时管理）
            "com.modrinth.ModrinthApp"
          ];
          # 不支持/不完整支持 Wayland，启用 X11 fallback
          "packages-x11" = [
            "com.dingtalk.DingTalk"
            "com.tencent.WeChat"
            "cn.wps.wps_365"
          ];
        })
        system.fonts
        desktop.wm.niri
        desktop.shell.dms-shell
        desktop.input-method.fcitx5
        preference.theme
        dev.shell.fish
        dev.shell.starship
        dev.tools.git
        dev.tools.yazi
        dev.tools.distrobox
        dev.ai.claude-code
        dev.ai.pi-coding-agent
        dev.editors.zed-editor
        dev.editors.helix
        apps.terminals.ghostty
        apps.notes.obsidian
        apps.gaming.steam
        apps.gaming.prismlauncher
      ]);

    homeManager =
      { pkgs, inputs', ... }:
      {
        home.packages =
          (with pkgs; [
            ## cmd
            android-tools

            ## GUI
            bilibili
            mission-center
            obs-studio
            gopeed
            ventoy
          ])
          ++ [ inputs'.llm-agents-nix.packages.reasonix ];
      };

    provides.to-hosts.nixos = {
      home-manager.backupFileExtension = "bak";
      nix.settings.trusted-users = [
        "xiaot_evo"
      ];
      users.users.xiaot_evo.extraGroups = [
        "dialout"
        "podman"
      ];
    };
  };
}
