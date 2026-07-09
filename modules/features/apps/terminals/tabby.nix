{
  lib,
  den,
  ...
}:
let
  pname = "tabby-terminal-bin";
  version = "1.0.234";

  # package function for pkgs.callPackage
  package =
    {
      stdenv,
      appimageTools,
      fetchurl,
      asar,
      extraPkgs ? (pkgs: [ pkgs.hidapi ]),
    }:
    let
      src =
        {
          x86_64-linux = fetchurl {
            url = "https://github.com/Eugeny/tabby/releases/download/v${version}/tabby-${version}-linux-x64.AppImage";
            hash = "sha256-jMEtv3rzAblapzjaAkhWrvSSgOmChF9CSRmT7w1JqX0=";
          };
          aarch64-linux = fetchurl {
            url = "https://github.com/Eugeny/tabby/releases/download/v${version}/tabby-${version}-linux-arm64.AppImage";
            hash = "sha256-HIgOZO3aOj9bLqMOCAtWqdjblYZwErTLTftuhnp8fCU=";
          };
        }
        .${stdenv.hostPlatform.system}
          or (throw "${pname}-${version}: ${stdenv.hostPlatform.system} is unsupported.");

      appimageContents = appimageTools.extract {
        inherit pname version src;
        postExtract = ''
          # Get rid of the autoupdater
          ${asar}/bin/asar extract $out/resources/app.asar app
          sed -i 's/async isUpdateAvailable.*/async isUpdateAvailable(updateInfo) { return false;/g' app/node_modules/electron-updater/out/AppUpdater.js
          ${asar}/bin/asar pack app $out/resources/app.asar
        '';
      };
    in
    appimageTools.wrapAppImage {
      inherit pname version;
      src = appimageContents;

      extraPkgs = extraPkgs;

      extraInstallCommands = ''
        # Add desktop convenience stuff
        install -Dm444 ${appimageContents}/tabby.desktop -t $out/share/applications
        install -Dm444 ${appimageContents}/tabby.png -t $out/share/pixmaps
        mv $out/bin/${pname} $out/bin/tabby
        substituteInPlace $out/share/applications/tabby.desktop \
          --replace-fail 'Exec=AppRun' 'Exec=tabby'
      '';

      meta = {
        homepage = "https://tabby.sh";
        description = "Terminal for the modern age";
        platforms = [
          "x86_64-linux"
          "aarch64-linux"
        ];
        sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
        license = lib.licenses.mit;
        maintainers = with lib.maintainers; [ pokon548 ];
        mainProgram = "tabby";
      };
    };
in
{

  # Parametric aspect: (den.aspects.apps.terminals.tabby (p: [ p.hidapi p.maple-mono.NF-CN ]))
  den.aspects.apps.terminals.tabby = extraPkgs: {
    homeManager = { pkgs, ... }: {
      home.packages = [
        (pkgs.callPackage package { inherit extraPkgs; })
      ];
    };
  };
}
