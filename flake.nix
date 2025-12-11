{
  description = "Test";

  outputs =
    { self, nixpkgs, ... }:
    let
      utils = (((import ./utils/utils.nix).prepareUtils ./utils).more { lib = nixpkgs.lib; }).more {
        pkgs = nixpkgs;
      };
    in
    utils.mkFlake {
      root = [ ./. ];
      inherit (self) self;
      lib = nixpkgs.lib;
      nixpkgs = nixpkgs;
      inputs = { };
    };
}
