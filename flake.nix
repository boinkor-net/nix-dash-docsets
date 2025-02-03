{
  description = "Description for the project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
      ];
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];
      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: let
        inherit (pkgs) lib;
        source = with lib.fileset;
          toSource {
            root = ./.;
            fileset = union (gitTracked ./lib) (gitTracked ./packages);
          };
        myLib = pkgs.callPackage "${source}/lib" {inherit myLib myPkgs;};
        myPkgs = pkgs.lib.filterAttrs matchesSystem (pkgs.callPackage "${source}/packages" {
          inherit myLib;
          flake-inputs = inputs;
        });
        matchesSystem = n: pkg: (n
          != "override"
          && n != "overrideDerivation"
          && builtins.elem system
          (pkgs.lib.recursiveUpdate
            {meta = {platforms = pkgs.lib.platforms.all;};}
            pkg)
          .meta
          .platforms);
      in {
        packages = myPkgs;

        legacyPackages.mkNixDocsetFeed = pkgs.callPackage ./src/mkNixDocsetFeed {inherit myPkgs;};

        formatter = pkgs.alejandra;
      };
    };
}
