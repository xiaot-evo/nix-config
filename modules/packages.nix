# 自动发现 packages/ 目录下的所有自定义包，注入到 self'.packages
{ lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      pkgDir = ../packages;
      readDirSafe =
        dir:
        let
          raw = builtins.readDir dir;
        in
        builtins.filter (n: lib.hasSuffix ".nix" n) (builtins.attrNames raw);

      pkgFiles = readDirSafe pkgDir;

      toPackage = name: {
        name = lib.removeSuffix ".nix" name;
        value = pkgs.callPackage (pkgDir + "/${name}") { };
      };
    in
    {
      packages = builtins.listToAttrs (map toPackage pkgFiles);
    };
}
