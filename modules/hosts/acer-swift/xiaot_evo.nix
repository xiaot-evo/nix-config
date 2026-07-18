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
            resources
            marktext
            qq
            wechat
            telegram-desktop
            # modrinth-app
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
