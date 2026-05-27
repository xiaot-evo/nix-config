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
        ])
        self'
      ])
      ++ (with den.aspects; [
        services.dae
        services.ly
        services.udiskie
        services.printing
        services.kdeconnect
        system.fonts
        desktop.wm.niri
        desktop.shell.dms-shell
        desktop.input-method.fcitx5
        preference.cursor-theme
        preference.icon-theme
        dev.shell.fish
        dev.shell.starship
        dev.tools.git
        dev.editors.opencode
        dev.editors.zed-editor
        dev.editors.helix
        apps.terminals.ghostty
        apps.browsers.zen-browser
        apps.notes.obsidian
        apps.gaming.steam
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
            yazi
            android-tools

            ## gui
            bilibili
            resources
            splayer
            # typora
            marktext
            # hmcl
            prismlauncher
            qq
            wechat
            telegram-desktop
            readest
            wpsoffice-cn
            obs-studio
          ]
        );
      };

    provides.to-hosts.nixos = {
      nix.settings.trusted-users = [
        "xiaot_evo"
      ];
    };
  };
}
