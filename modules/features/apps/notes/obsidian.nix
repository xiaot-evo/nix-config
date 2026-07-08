{ den, ... }:
{
  den.aspects.apps.notes.obsidian = {
    includes = [
      (den.batteries.unfree [ "obsidian" ])
    ];
    homeManager =
      { pkgs, ... }:
      let
        mkPlugin =
          {
            pname,
            version,
            files,
          }:
          pkgs.stdenv.mkDerivation {
            name = "${pname}-${version}";
            dontUnpack = true;
            installPhase = ''
              mkdir -p $out
              ${builtins.concatStringsSep "\n" (
                builtins.map (
                  f:
                  "cp ${
                    pkgs.fetchurl {
                      inherit (f) url hash;
                      name = f.name;
                    }
                  } $out/${f.name}"
                ) files
              )}
            '';
          };

        editing-toolbar = pkgs.fetchzip {
          name = "editing-toolbar-4.0.9";
          url = "https://github.com/PKM-er/obsidian-editing-toolbar/releases/download/4.0.9/editing-toolbar.zip";
          hash = "sha256-32CKMKXgyimzEMD3WrOZVG90ZRJK/ixRNYHERFNMk2E=";
        };

        obsidian-tasks = pkgs.fetchzip {
          name = "obsidian-tasks-8.2.2";
          url = "https://github.com/obsidian-tasks-group/obsidian-tasks/releases/download/8.2.2/obsidian-tasks-8.2.2.zip";
          hash = "sha256-m5MoupjOV97tIAq3KTlrgHlqSrrGWGb+kA7Q2yAbcFw=";
        };

        quickadd = mkPlugin {
          pname = "quickadd";
          version = "2.17.2";
          files = [
            {
              name = "main.js";
              url = "https://github.com/chhoumann/quickadd/releases/download/2.17.2/main.js";
              hash = "sha256-yPODyV+r+LFzyNd+BIUlCjsuCXPbYa6ZRcBlzNxuI34=";
            }
            {
              name = "manifest.json";
              url = "https://github.com/chhoumann/quickadd/releases/download/2.17.2/manifest.json";
              hash = "sha256-2eyUCo9zsO5bbG52SiiOuekZHWDcS0M+UtMeVX83Dbo=";
            }
            {
              name = "styles.css";
              url = "https://github.com/chhoumann/quickadd/releases/download/2.17.2/styles.css";
              hash = "sha256-SxnWmpiiLFx777fYQa4SzfkHYgdMfMgZNeDbjjLGBd0=";
            }
          ];
        };

        excalidraw = mkPlugin {
          pname = "obsidian-excalidraw-plugin";
          version = "2.25.1";
          files = [
            {
              name = "main.js";
              url = "https://github.com/zsviczian/obsidian-excalidraw-plugin/releases/download/2.25.1/main.js";
              hash = "sha256-P/IyxfBXy6DHZray3IxaroKc1dh5hbOqfGMxkR/Q8tc=";
            }
            {
              name = "manifest.json";
              url = "https://github.com/zsviczian/obsidian-excalidraw-plugin/releases/download/2.25.1/manifest.json";
              hash = "sha256-LF81ccKhO0HW62qz7lrgvLcGdsNSWZpU2234U4p01zE=";
            }
            {
              name = "styles.css";
              url = "https://github.com/zsviczian/obsidian-excalidraw-plugin/releases/download/2.25.1/styles.css";
              hash = "sha256-aLs/hXRVuT4JuMsLBgqWQSZg0WkuDnnA0a0rn4HFhPU=";
            }
          ];
        };
      in
      {
        programs.obsidian = {
          enable = true;
          cli.enable = true;
          # pi-agent v0.0.8 无公开仓库，在 Obsidian 内手动管理
          defaultSettings.communityPlugins = [
            editing-toolbar
            obsidian-tasks
            quickadd
            excalidraw
          ];
          vaults.notes.target = "Documents/notes";
        };
      };
  };
}
