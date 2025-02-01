# Dash / Zeal Docsets for nix/nixpkgs/NixOS/nix-darwin

[Dash on macOS](https://kapeli.com/dash) and [Zeal on linux/windows](https://zealdocs.org/) are two highly excellent offline documentation browser/navigation tools. They have very quick keyword search and ... they work offline!

However, they lack docsets for the nix cinematic universe, which this repo aims to mitigate.

The flake in this repo contains a package per docset for:

* nix, the commandline tool and language
* nixpkgs, the package collection and standard environment for building more packages
* NixOS, the linux system based on nixpkgs
* nix-darwin, the darwin configuration manager based on nixpkgs

All of them (except for NixOS, which requires linux platforms) are portable and can be built anywhere. I would suggest deploying them on a linux machine with a static file server serving the .tgz and .xml files.

## Incomplete

This flake is by far not complete yet. Things I'd like to do (that work in my personal system config flake, which is of no benefit to you):

* Generate a feed .xml that dash can subscribe to, with a "version" per aspect of the documentation
* Add a `nixosModules.default` and `darwinModules.default` that allows configuring where the output packages go
* Configure github actions to publish a static page of the generated docsets, with auto-updates.
