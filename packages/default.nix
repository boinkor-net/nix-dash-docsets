{
  pkgs,
  flake-inputs,
  myLib,
}: let
  callPackage = pkgs.lib.callPackageWith (pkgs // {inherit myPkgs myLib flake-inputs;});
  myPkgs = pkgs.lib.filterAttrs (_: v: v != null) (builtins.mapAttrs (name: type:
    if type == "directory"
    then callPackage ./${name} {}
    else null) (builtins.readDir ./.));
in
  myPkgs
