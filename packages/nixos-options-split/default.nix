{
  rustPlatform,
  nix-gitignore,
  lib,
}:
rustPlatform.buildRustPackage (let
  src = lib.cleanSource (nix-gitignore.gitignoreSourcePure ["target"] ./.);
in {
  pname = "options-split";
  version = "0.0.0";

  inherit src;
  cargoLock.lockFile = ./Cargo.lock;
  meta.mainProgram = "options-split";
})
