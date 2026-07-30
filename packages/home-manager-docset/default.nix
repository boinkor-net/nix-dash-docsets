{
  flake-inputs,
  lib,
  stdenv,
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
      "main > h1" = "Section";

      # These three entries all are different and match the same path, but they are all needed
      # because there's no other way to discern the option kinds from each other. Thanks, mdbook.
      "main > h2" = {
        type = "Option";
        matchpath = "options/home-manager/.*\\.html";
      };
      "#mdbook-content > main > h2" = {
        type = "Option";
        regexp = "$";
        replacement = " (NixOS option)";
        matchpath = "options/nixos/.*\\.html";
      };
      ".content > main > h2" = {
        type = "Option";
        regexp = "$";
        replacement = " (nix-darwin option)";
        matchpath = "options/nix-darwin/.*\\.html";
      };
    };
    # icon32x32 = "favicon.png";
    allowJS = true;
  };
in
  myLib.buildDashDocset {
    inherit version dashingConfig;

    pname = "home-manager";
    src = "${manual}/share/doc/home-manager";
    checkExpectations = {
      "programs.zsh.enable" = "Option";
      "home-manager.startAsUserService (NixOS option)" = "Option";
      "home-manager.backupCommand (nix-darwin option)" = "Option";
      "Rollbacks" = "Section";
      "Installing Home Manager" = "Section";
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
    # TODO: might have to patch out the "unresolved xref" error from nixos-generate-docs if it gets annoying.
    patchPhase = ''
      rm release-notes.xhtml
      rm print.html

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
