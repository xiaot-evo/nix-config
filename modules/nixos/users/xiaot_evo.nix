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
          "qq"
          "wechat"
          "bilibili"
          "wpsoffice-cn"
          "warp-terminal"
          "ventoy"
          "modrinth-app"
          "modrinth-app-unwrapped"
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
        # dev.ai.ollama
        dev.ai.claude-code
        dev.ai.pi-coding-agent
        dev.editors.zed-editor
        dev.editors.helix
        apps.terminals.ghostty
        apps.browsers.zen-browser
        apps.notes.obsidian
        apps.gaming.steam
        # apps.gaming.opengamepadui
        # apps.gaming.lutris
        apps.gaming.prismlauncher
      ]);

    homeManager =
      { pkgs, inputs', ... }:
      {
        home.packages =
          (with pkgs; [
            ## cmd
            devenv
            android-tools

            ## GUI
            qq
            wechat
            bilibili
            (modrinth-app.override {
              jdks = with graalvmPackages; [
                graalvm-ce # JDK 25 + Graal JIT — Minecraft 1.17+
                zulu25
                zulu21
                zulu17 # fallback for older modpacks
                zulu8 # pre-1.17 Minecraft
              ];
            })
            mission-center
            wpsoffice-cn
            (bottles.override {
              removeWarningPopup = true;
              extraPkgs =
                pkgs: with pkgs; [
                  wineWow64Packages.stagingFull
                ];
              # extraLibraries = pkgs: with pkgs; [ dxvk ];
            })
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
