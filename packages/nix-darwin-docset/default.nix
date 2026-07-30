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
in
  myLib.buildDashDocset {
    inherit version dashingConfig;

    pname = "nix-darwin";
    src = "${manual}/share/doc/darwin";
    checkExpectations = {
      "networking.computerName" = "Option";
    };
    checkAbsences = [];

    nativeBuildInputs = [
      (myLib.renderDocsForDash {
        arguments = [
          "--stylesheet"
          "style.css"
          "--stylesheet"
          "highlightjs/mono-blue.css"
          "--script"
          "./highlightjs/highlight.pack.js"
          "--script"
          "./highlightjs/loader.js"
        ];
      })
    ];
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
