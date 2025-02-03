{
  runCommand,
  myPkgs,
  lib,
  stdenv,
  writeTextDir,
  symlinkJoin,
}: let
  docsets = with myPkgs;
    [home-manager nix-docset nix-darwin-docset nixpkgs-docset]
    ++ (
      if stdenv.isLinux
      then [nixos-docset]
      else []
    );
in
  {baseURL}: let
    feeds = builtins.map (drv:
      writeTextDir "${drv.pname}.xml" ''
        <entry>
            <name>${drv.pname}</name>
            <url>${baseURL}/${drv.pname}.tgz</url>
            <version>${drv.version}</version>
          </entry>
      '')
    docsets;
  in
    symlinkJoin {
      name = "nix-docset-feeds";
      paths = docsets ++ feeds;
    }
