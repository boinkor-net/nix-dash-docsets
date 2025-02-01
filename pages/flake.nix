{
  description = "GitHub pages build for the dash docsets supported on linux";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    docsets.url = "path:../";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];
      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: {
        packages.default = inputs'.docsets.legacyPackages.mkNixDocsetFeed {baseURL = "https://boinkor-net.github.io/nix-dash-docsets";};
      };
      flake = {};
    };
}
