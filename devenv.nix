{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

{
  # https://devenv.sh/basics/
  # env.GREET = "devenv";

  # https://devenv.sh/packages/
  packages = [ pkgs.gh ];

  # https://devenv.sh/languages/
  # languages.rust.enable = true;
  languages.nix = {
    enable = true;
    lsp = {
      enable = true;
      package = pkgs.nil;
    };
  };

  # https://devenv.sh/processes/
  # processes.dev.exec = "${lib.getExe pkgs.watchexec} -n -- ls -la";

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/scripts/
  scripts = {
    flake-write.exec = ''
      nix run .#write-flake
    '';
    build.exec = ''
      nix run  .#${builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile /etc/hostname)}  --impure
    '';
    build-switch.exec = ''
      nix run  .#${
        builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile /etc/hostname)
      }  -- switch --impure
    '';
  };
  # https://devenv.sh/basics/
  enterShell = ''
    git --version # Use packages
  '';

  # https://devenv.sh/tasks/
  # tasks = {
  #   "myproj:setup".exec = "mytool build";
  #   "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/tests/
  enterTest = ''
    echo "Running tests"
    git --version | grep --color=auto "${pkgs.git.version}"
  '';

  # https://devenv.sh/git-hooks/
  # git-hooks.hooks.shellcheck.enable = true;

  # See full reference at https://devenv.sh/reference/options/
}
