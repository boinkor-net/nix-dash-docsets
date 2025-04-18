# Dash / Zeal Docsets for nix/nixpkgs/NixOS/nix-darwin

[Dash on macOS](https://kapeli.com/dash) and [Zeal on linux/windows](https://zealdocs.org/) are two highly excellent offline documentation browser/navigation tools. They have very quick keyword search and ... they work offline!

However, they lack docsets for the nix cinematic universe, which this repo aims to mitigate.

The flake in this repo contains a package per docset for:

- nix, the commandline tool and language
- nixpkgs, the package collection and standard environment for building more packages
- NixOS, the linux system based on nixpkgs
- nix-darwin, the darwin configuration manager based on nixpkgs
- home-manager, the home directory manager based on nixpkgs

All of them (except for NixOS, which requires linux platforms) are portable and can be built anywhere. I would suggest deploying them on a linux machine with a static file server serving the .tgz and .xml files.

# Usage

## Doc feeds for the latest version of nixpkgs/nix-darwin/etc

The docsets get built daily and deployed to Github Pages, see the [nix dash docsets overview](https://boinkor-net.github.io/nix-dash-docsets/).

## Using it in your system configuration flake

In a nix flake, you'll generate the feeds, which are exposed as a function on this flake's `legacyPackages` attribute:

## `nix-dash-docsets.legacyPackages.${system}.mkNixDocsetFeed {baseURL, zealCompat}`

Parameters passed via attrset:

- `baseURL` - The absolute base URL (http or https) serving the generated directory. Dash can not deal with relative URLs here, and it requires a http or https URL in its docset feeds.
- `zealCompat` (default: `false`) - if set to true, generate feeds pointing to docset packages that can be imported by Zeal.

This function builds the available docsets on the platform identified by `system` and writes them to its output directory.

Once generated, you can add each of the following XML files as feeds in Dash's "Main Docsets" (under "Downloads") preferences, after clicking "+":

- `{baseURL}/nix.xml`
- `{baseURL}/nixos.xml`
- `{baseURL}/nixpkgs.xml`
- `{baseURL}/nix-darwin.xml`
- `{baseURL}/home-manager.xml`

## Status: Incomplete

This flake is by far not complete yet. Things I'd like to do (that work in my personal system config flake, which is of no benefit to you):

- Add a `nixosModules.default` and `darwinModules.default` that allows configuring where the output packages go
- Configure github actions to publish a static page of the generated docsets, with auto-updates.
