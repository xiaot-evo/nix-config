{ den, ... }:
{
  den.aspects.xiaot_evo = {
    includes =
      (with den.batteries; [
        define-user
        primary-user
        (user-shell "bash")
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
        # services.greetd
        services.udiskie
        services.printing
        services.kdeconnect
        system.fonts
        desktop.wm.niri
        desktop.shell.dms-shell
        # desktop.budgie
        dev.editors.zed-editor
        dev.editors.helix
        apps.input-method.fcitx5
        apps.ghostty
        apps.zen-browser
      ]);

    homeManager =
      { self', pkgs, ... }:
      {
        home.packages =
          (with self'.packages; [
            opencode
            fish
            starship
            git
          ])
          ++ (with pkgs; [
            ## cmd
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
          ]);
      };

    provides.to-hosts.nixos = {
      # users.users.xiaot_evo.extraGroups = [
      #   "wheel"
      #   "networkmanager"
      # ];
    };
  };
}
