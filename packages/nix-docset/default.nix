{
  lix,
  myLib,
  fetchurl,
  ...
}: let
  nixDocs = lix.doc;
  dashingConfig = {
    name = "${lix.pname} ${lix.version} manual";
    package = "nix";
    index = "index.html";
    externalURL = "https://docs.lix.systems/manual/lix/stable/";
    # NOTE: Do not use the `ignore` parameter, as that messes up
    # dashing's autolinking. You'll have to play with regexes (see
    # below for the "Note" exclusion one) instead.

    selectors = {
      "main>h1:first-child" = {
        type = "Section";
        matchpath = "^([^r][^e][^l]).*/.*";
      };
      "main:has(h1#name)>h1#name+p:has(code)" = {
        type = "Command";
        matchpath = "command-ref/";
      };
      "#primitives +ul>li>p:first-child>a:first-child" = {
        type = "Type";
        matchpath = "language/values.html";
      };
      "#list,#attribute-set" = {
        type = "Type";
        matchpath = "language/values.html";
      };
      "main:has(#operators) h2" = {
        type = "Operator";
        matchpath = "language/operators.html";
      };
      "main:has(#language-constructs) h2" = {
        type = "Keyword";
        matchpath = "language/constructs.html";
      };
      "main:has(#string-interpolation) h1" = {
        type = "Keyword";
        matchpath = "language/string-interpolation.html";
      };
      "main:has(#derivations) h1" = {
        type = "Function";
        regexp = "^.*$";
        replacement = "derivation";
        matchpath = "language/derivations.html";
      };
      "main:has(#built-in-constants) dt" = {
        type = "Constant";
        matchpath = "language/builtin-constants.html";
      };
      "main:has(#built-in-functions) dt" = {
        type = "Function";
      };
    };
    icon32x32 = "favicon.png";
    allowJS = true;
  };
in
  myLib.buildDashDocset {
    inherit dashingConfig;
    pname = "nix";
    version = lix.version;
    src = "${nixDocs}/share/doc/nix/manual";
    patchPhase = ''
      cp "${fetchurl {
        url = "https://lix.systems/favicon-32.png";
        hash = "sha256-cfz6TSNaJ6IFLsy1p5AtrlwryMzGleBCcVytbh4VKOs=";
      }}" ./favicon.png
      rm print.html
    '';

    checkExpectations = {
      "attrValues set" = "Function";
      "Comparison" = "Operator";
      "null (null)" = "Constant";
    };
    checkAbsences = [];
  }
