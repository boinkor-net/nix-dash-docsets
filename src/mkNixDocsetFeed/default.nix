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
  {baseURL}: let
    feeds = lib.mapConcat (drv:
      [(writeTextDir "${drv.pname}.xml" ''
        <entry>
          <name>${drv.pname}</name>
          <url>${baseURL}/${drv.pname}.tgz</url>
          <version>${drv.version}</version>
        </entry>
      ''
      )
      (writeTextDir "${drv.pname}-zeal.xml" ''
        <entry>
          <name>${drv.pname}</name>
          <url>${baseURL}/${drv.pname}-zeal.tgz</url>
          <version>${drv.version}</version>
        </entry>
      ''
      )])
    docsets;
  in
    symlinkJoin {
      name = "nix-docset-feeds";
      paths = docsets ++ feeds;
    }
