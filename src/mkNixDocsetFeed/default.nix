{
  runCommand,
  myPkgs,
  lib,
  stdenv,
  writeTextDir,
  symlinkJoin,
}: let
  docsets = with myPkgs;
    [home-manager-docset nix-docset nix-darwin-docset nixpkgs-docset]
    ++ (
      if stdenv.isLinux
      then [nixos-docset]
      else []
    );
in
  {
    baseURL,
    zealCompat ? false,
  }: let
    feeds = builtins.map (drv: drv.updateFeed {inherit baseURL drv;}) docsets;
  in
    symlinkJoin {
      name = "nix-docset-feeds";
      paths =
        feeds
        ++ (
          if zealCompat
          then builtins.map (drv: drv.zeal) docsets
          else docsets
        );
    }
