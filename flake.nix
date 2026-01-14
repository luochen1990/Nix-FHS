{
  description = "Test";

  outputs =
    { self, nixpkgs, ... }:
    let
      utils' =
        nixpkgs.lib // (import ./lib/list.nix) // (import ./lib/dict.nix) // (import ./lib/file.nix);
      inherit (import ./lib/prepare-lib.nix utils') prepareLib;
      inherit
        (prepareLib {
          roots = [ ./. ];
          lib = nixpkgs.lib;
        })
        mkFlake
        ;
    in
    mkFlake {
      inherit self nixpkgs;
    };
}
