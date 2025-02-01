{
  myPkgs,
  myLib,
  writeTextFile,
  sqlite,
  lib,
  stdenv,
  callPackage,
}: {
  pname,
  version,
  src,
  dashingConfig,
  checkExpectations ? {},
  checkAbsences ? [],
  patchPhase,
  nativeBuildInputs ? [],
  meta ? {platforms = lib.platforms.all;},
}: let
  dashing = myPkgs.dashing;
  # TODO: Don't generate the feed xml here, do it in the nixos module!
  docsetFeedXML = writeTextFile {
    name = "${pname}.xml";
    text = ''
      <entry>
        <version>${version}</version>
        <url>https://TODO/${pname}.tgz</url>
      </entry>
    '';
  };
  config = writeTextFile {
    name = "dashing.json";
    text = builtins.toJSON (dashingConfig // {package = pname;});
  };
in
  stdenv.mkDerivation {
    inherit pname version src meta;
    nativeBuildInputs = [dashing] ++ nativeBuildInputs;

    buildPhase = ''
      dashing build
    '';

    patchPhase = ''
      cp ${config} ./dashing.json
      ${patchPhase}
    '';

    installPhase = ''
      mkdir -p $out/
      tar zcf $out/${pname}.tgz ./${pname}.docset
      cp ${docsetFeedXML} $out/${pname}.xml
    '';

    nativeCheckInputs = [sqlite];

    doCheck = true;
    checkPhase = let
      expectations = checkExpectations;
      absent = checkAbsences;
    in
      (lib.concatMapAttrsStringSep "\n" (name: type: ''
          echo "${name} should be ${type}"
              if ! [ "$(sqlite3 -batch -bail ${pname}.docset/Contents/Resources/docSet.dsidx -cmd "select count(type) from searchIndex where name = '${name}' and type='${type}'" </dev/null)" = 1 ] ; then
                echo " -- FAILED"
                sqlite3 -json -batch -bail ${pname}.docset/Contents/Resources/docSet.dsidx -cmd "select * from searchIndex where name = '${name}'" </dev/null
                exit 1
              fi
        '')
        expectations)
      + "\n"
      + (lib.concatMapStringsSep "\n" (name: ''
          echo "${name} should be absent"
            [ "$(sqlite3 -batch -bail ${pname}.docset/Contents/Resources/docSet.dsidx -cmd "select count(type) from searchIndex where name = '${name}'" </dev/null)" = 0 ]
        '')
        absent);
  }
