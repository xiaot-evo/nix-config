{ den, ... }:
{
  den.aspects.xiaot_evo = {
    includes =
      (with den.batteries; [
        define-user
        primary-user
        (user-shell "fish")
        (unfree [
          "qq"
          "wechat"
          "bilibili"
          "wpsoffice-cn"
          "warp-terminal"
          "ventoy"
          "modrinth-app"
          "modrinth-app-unwrapped"
        ])
      ])
      ++ (with den.aspects; [
        # services.dae
        services.ddns-updater
        services.ly
        services.udiskie
        services.printing
        # services.kdeconnect
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
        dev.ai.ollama
        dev.ai.claude-code
        dev.ai.pi-coding-agent
        dev.editors.zed-editor
        dev.editors.helix
        apps.terminals.ghostty
        (apps.terminals.tabby (
          p: with p; [
            hidapi
            maple-mono.NF-CN
          ]
        ))
        apps.browsers.zen-browser
        apps.notes.obsidian
        apps.gaming.steam
        # apps.gaming.prismlauncher
      ]);

    homeManager =
      { pkgs, ... }:
      {
        home.packages = (
          with pkgs;
          [
            ## cmd
            fastfetch
            devenv
            android-tools

            ## gui
            bilibili
            qq
            wechat
            telegram-desktop
            # workaround: 新版 wrap-gapps-hook 按 output 追踪运行状态,
            # 而 symlinkJoin 的 postBuild 手动调用 wrapGAppsHook 时 $output 未定义,
            # 导致 "bad array subscript"。上游修复后可还原为 modrinth-app。
            (modrinth-app.overrideAttrs (old: {
              buildCommand = "output=out\n" + old.buildCommand;
            }))
            # (modrinth-app.override {
            #   jdks =
            #     let
            #       t = javaPackages.compiler.temurin-bin;
            #     in
            #     [
            #       t."jdk-8"
            #       t."jdk-17"
            #       t."jdk-21"
            #       t."jdk-25"
            #     ];
            # })
            readest
            wpsoffice-cn
            obs-studio
            remmina
            # freecad
            # ventoy
          ]
        );
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
