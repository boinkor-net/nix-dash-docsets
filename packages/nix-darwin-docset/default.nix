{
  flake-inputs,
  lib,
  stdenv,
  writeShellApplication,
  writeText,
  myPkgs,
  myLib,
}: let
  manual = flake-inputs.nix-darwin.packages.${stdenv.targetPlatform.system}.manualHTML;
  options = flake-inputs.nix-darwin.packages.${stdenv.targetPlatform.system}.optionsJSON;
  version = "1.0.${flake-inputs.nix-darwin.lastModifiedDate}-${flake-inputs.nix-darwin.shortRev}";

  dashingConfig = {
    name = "nix-darwin ${version} manual";
    package = "nix-darwin";
    index = "index.html";
    externalURL = "https://daiderd.com/nix-darwin/manual/index.html";
    # NOTE: Do not use the `ignore` parameter, as that messes up
    # dashing's autolinking. You'll have to play with regexes (see
    # below for the "Note" exclusion one) instead.

    selectors = {
      ".book:has(#book-darwin-manual) dt" = "Option";
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

    pname = "nix-darwin";
    src = "${manual}/share/doc/darwin";
    checkExpectations = {
      "networking.computerName" = "Option";
    };
    checkAbsences = [];

    nativeBuildInputs = [wrapped-render-docs];
    # TODO: might have to patch out the "unresolved xref" error from nixos-generate-docs if it gets annoying.
    patchPhase = ''
      mkdir -p ./options/options
      ${lib.getExe myPkgs.nixos-options-split} \
         --options-file ${options}/share/doc/darwin/options.json \
         --output-dir ./options \
         --book-name "nix-darwin options" \
         --root-id book-darwin-manual \
         users launchd nix services system \
         programs system.defaults
      rm index.html
    '';
  }
