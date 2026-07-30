# Hook that makes a version of nixos-render-docs with reasonable-ish default cli args.
{
  nixos-render-docs,
  myPkgs,
  lib,
  writeShellApplication,
  writeText,
}: {arguments}:
writeShellApplication {
  name = "nixos-render-docs";
  runtimeInputs = [
    myPkgs.nixos-render-docs-without-xref
  ];
  text = ''
    nixos-render-docs  -j "$NIX_BUILD_CORES" \
         manual html \
         --manpage-urls ${writeText "manpage-urls.json" "{}"} \
         --revision ${lib.escapeShellArg "0"} \
         --generator "nixos-render-docs ${lib.version}" \
         --sidebar-depth 1 \
         ${lib.escapeShellArgs arguments} \
         "$1" \
         "$(basename "$1" .md)".html
  '';
}
