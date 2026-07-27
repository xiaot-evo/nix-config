# 自动发现 packages/ 目录下的所有自定义包，注入到 flake packages 输出
{
  lib,
  ...
}:
let
  pkgDir = ../../packages;

  readDirSafe =
    dir:
    if builtins.pathExists dir then
      let
        raw = builtins.readDir dir;
      in
      builtins.filter (n: lib.hasSuffix ".nix" n) (builtins.attrNames raw)
    else
      [ ];

  pkgFiles = readDirSafe pkgDir;

  toPackage = callPackage: name: {
    name = lib.removeSuffix ".nix" name;
    value = callPackage (pkgDir + "/${name}") { };
  };

  mkPackages = callPackage: builtins.listToAttrs (map (toPackage callPackage) pkgFiles);
in
{
  perSystem = { pkgs, ... }: {
    # flake 输出，使 nix build .#<name> 可用
    packages = mkPackages pkgs.callPackage;
  };
}
