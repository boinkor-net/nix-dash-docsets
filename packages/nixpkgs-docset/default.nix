{
  flake-inputs,
  lib,
  callPackage,
  myLib,
  ...
}: let
  nixpkgsDocs = callPackage "${flake-inputs.nixpkgs}/doc" {};
  dashingConfig = {
    name = "nixpkgs ${flake-inputs.nixpkgs.shortRev} manual";
    package = "nixpkgs";
    index = "index.html";
    externalURL = "https://nixos.org/manual/nixpkgs/unstable/";
    # NOTE: Do not use the `ignore` parameter, as that messes up
    # dashing's autolinking. You'll have to play with regexes (see
    # below for the "Note" exclusion one) instead.

    selectors = let
      # The build helpers chapter is a jumble. There are some things
      # that need to be indexed as functions, and some that should
      # be guides.
      #
      # Also, dashing has a long-standing bug where it doesn't
      # recognize :has(>.titlepage), but it does recognize
      # :haschild(.titlepage), which isn't supported by chrome
      # devtools' $$ function. Gotta love this ecosystem.
      buildHelperFunctions = lib.genAttrs (map (sec: "div:haschild(.titlepage:has(${sec})) div.titlepage code.literal")
        [
          "#chap-pkgs-fetchers"
          "#chap-trivial-builders"
          "#chap-testers"
          "#chap-devShellTools"
          "#sec-vm-tools"
        ]) (n: "Function");
    in
      {
        "div.section:has(#sec-functions-library) h4.title" = {
          type = "Function";
          requiretext = "^lib.";
        };
        "div.section:has(#sec-pkgs-dockerTools) div.titlepage h3.title" = "Function";
        "#ssec-language-go" = {
          type = "Function";
          regexp = "^.*$";
          replacement = "buildGoModule";
        };

        "div.section:has(#sec-stdenv-phases) h5.title>code.literal" = "Attribute";
        "div.section:has(#variables-specifying-dependencies) h5.title>code.literal" = "Attribute";

        "div.section:has(#ssec-setup-hooks) h3.title" = {
          type = "Hook";
          requiretext = "^(.{1,3}|[^N].*|N[^o].*|No[^t].*|Not[^e].*|[^N].*)$";
        };
        "div.chapter:has(#chap-hooks) h2.title" = "Hook";

        "div.part>.titlepage h1.title" = "Section";

        "div.chapter:has(#chap-packages) div.section>div.titlepage h2.title" = "Guide";
        "div.chapter:has(#chap-language-support) div.section>div.titlepage h2.title" = "Guide";
      }
      // buildHelperFunctions;
    icon32x32 = ./icon32x32.png;
    allowJS = true;
  };
in
  myLib.buildDashDocset {
    inherit dashingConfig;
    pname = "nixpkgs";
    version = "1.0.${flake-inputs.nixpkgs.lastModifiedDate}-${flake-inputs.nixpkgs.shortRev}";
    src = "${nixpkgsDocs}/share/doc/nixpkgs";
    checkExpectations = {
      "vmTools.extractFs" = "Function";
      "lib.versions.major" = "Function";
      "streamNixShellImage" = "Function";
      "lib.fileset.fromSource" = "Function";
      "buildGoModule" = "Function";
      "Autoconf" = "Hook";
      "Emacs" = "Guide";
      "Javascript" = "Guide";
      "Build helpers" = "Section";
      "move-docs.sh" = "Hook";
    };
    checkAbsences = ["Note"];

    patchPhase = ''
      mv manual.html index.html
      cp ${./icon32x32.png} ./icon32x32.png
    '';
  }
