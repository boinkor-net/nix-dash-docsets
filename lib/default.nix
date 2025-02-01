{
  pkgs,
  lib,
  myPkgs,
  ...
}: let
  callPackage = lib.callPackageWith (pkgs // {inherit myLib myPkgs;});
  myLib = pkgs.lib.filterAttrs (_: v: v != null) (builtins.mapAttrs (name: type:
    if type == "directory"
    then callPackage ./${name} {}
    else null) (builtins.readDir ./.));
in
  myLib
