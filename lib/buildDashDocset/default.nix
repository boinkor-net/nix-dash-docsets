{
  myPkgs,
  myLib,
  writeTextFile,
  sqlite,
  lib,
  stdenv,
  writeTextDir,
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

    outputs = ["out" "zeal"];
    installPhase = ''
      mkdir -p $out/ $zeal/
      tar -zcf $out/${pname}.tgz "${pname}.docset"
      tar -zcf $zeal/${pname}.tgz -C "${pname}.docset" .
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

    passthru.updateFeed = {
      baseURL,
      drv,
    }: (
      writeTextDir "${drv.pname}.xml" ''
        <entry>
          <name>${drv.pname}</name>
          <url>${baseURL}/${drv.pname}.tgz</url>
          <version>${drv.version}</version>
        </entry>
      ''
    );
  }
