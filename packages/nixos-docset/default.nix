{
  flake-inputs,
  callPackage,
  lib,
  myLib,
  myPkgs,
  writeShellApplication,
  writeText,
}: let
  nixos = callPackage "${flake-inputs.nixpkgs}/nixos/release.nix" {};
  manual = nixos.manual."x86_64-linux";
  options = nixos.options;
  version = "1.0.${flake-inputs.nixpkgs.lastModifiedDate}-${flake-inputs.nixpkgs.shortRev}";

  wrapped-render-docs = writeShellApplication {
    name = "nixos-render-docs";
    runtimeInputs = [myPkgs.nixos-render-docs-without-xref];
    text = ''
      exec nixos-render-docs -j "$NIX_BUILD_CORES" manual html \
           --manpage-urls ${writeText "manpage-urls.json" "{}"} \
           --revision ${lib.escapeShellArg "0"} \
           --generator "nixos-render-docs ${lib.version}" \
           --stylesheet style.css \
           --stylesheet highlightjs/mono-blue.css \
           --script ./highlightjs/highlight.pack.js \
           --script ./highlightjs/loader.js \
           --script ./anchor.min.js \
           --script ./anchor-use.js \
           --toc-depth 1 \
           --chunk-toc-depth 1 \
           "$1" \
           "$(basename "$1" .md)".html
    '';
  };

  dashingConfig = {
    name = "NixOS ${version} manual";
    package = "nixos";
    index = "index.html";
    externalURL = "https://nixos.org/manual/nixos/stable/";
    # NOTE: Do not use the `ignore` parameter, as that messes up
    # dashing's autolinking. You'll have to play with regexes (see
    # below for the "Note" exclusion one) instead.

    selectors = {
      ".part>.titlepage .title" = "Section";
      ".part:has(#ch-configuration,#ch-running) .chapter>.titlepage .title" = "Guide";
      ".variablelist dt" = "Option";
    };
    # icon32x32 = "favicon.png";
    allowJS = true;
  };
in
  myLib.buildDashDocset {
    inherit version dashingConfig;

    pname = "nixos";
    src = "${manual}/share/doc/nixos";
    checkExpectations = {
      "Installation" = "Section";
      "Subversion" = "Guide";
      "Logging" = "Guide";
      "networking.hostName" = "Option";
    };
    checkAbsences = [];

    nativeBuildInputs = [wrapped-render-docs];
    patchPhase = ''
      mkdir -p ./options/options
      ${lib.getExe myPkgs.nixos-options-split} \
         --options-file ${options}/share/doc/nixos/options.json \
         --output-dir ./options \
         --book-name "NixOS Options" \
         --root-id ch-options \
         users nix services system \
         programs
      rm options.html
    '';

    meta.platforms = lib.platforms.linux;
  }
