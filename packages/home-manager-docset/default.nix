{
  flake-inputs,
  lib,
  stdenv,
  writeShellApplication,
  writeText,
  myPkgs,
  myLib,
}: let
  manual = flake-inputs.home-manager.packages.${stdenv.targetPlatform.system}.docs-html;
  options = flake-inputs.home-manager.packages.${stdenv.targetPlatform.system}.docs-json;
  version = "1.0.${flake-inputs.home-manager.lastModifiedDate}-${flake-inputs.home-manager.shortRev}";

  dashingConfig = {
    name = "home-manager ${version} manual";
    package = "home-manager";
    index = "index.html";
    externalURL = "https://nix-community.github.io/home-manager/";
    # NOTE: Do not use the `ignore` parameter, as that messes up
    # dashing's autolinking. You'll have to play with regexes (see
    # below for the "Note" exclusion one) instead.

    selectors = {
      ".part>.titlepage .title" = "Section";
      ".book:has(#ch-options) dt" = {
        type = "Option";
      };
      ".part:has(#ch-usage) .section>.titlepage .title" = "Guide";

      ".appendix:has(#ch-nixos-options) dt" = {
        type = "Option";
        regexp = "$";
        replacement = " (NixOS option)";
      };
      ".appendix:has(#ch-nix-darwin-options) dt" = {
        type = "Option";
        regexp = "$";
        replacement = " (nix-darwin option)";
      };
    };
    # icon32x32 = "favicon.png";
    allowJS = true;
  };

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
           --toc-depth 1 \
           --chunk-toc-depth 1 \
           "$1" \
           "$(basename "$1" .md)".html
    '';
  };
in
  myLib.buildDashDocset {
    inherit version dashingConfig;

    pname = "home-manager";
    src = "${manual}/share/doc/home-manager";
    checkExpectations = {
      "programs.zsh.enable" = "Option";
      "Rollbacks" = "Guide";
      "Installing Home Manager" = "Section";
    };
    checkAbsences = [];

    nativeBuildInputs = [wrapped-render-docs];
    # TODO: might have to patch out the "unresolved xref" error from nixos-generate-docs if it gets annoying.
    patchPhase = ''
      rm release-notes.xhtml

      mkdir -p ./options/options
      ${lib.getExe myPkgs.nixos-options-split} \
         --options-file ${options}/share/doc/home-manager/options.json \
         --output-dir ./options \
         --book-name "home-manager options" \
         --root-id ch-options \
         accounts programs services targets wayland xdg xsession
      rm options.xhtml
    '';
  }
