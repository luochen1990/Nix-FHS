{
  description = "Flake FHS - Filesystem Hierarchy Standard for Nix flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, ... }:
    let
      # Import mkFlake directly from fhs.fun.nix
      mkFlakeModule = import ./utils/fhs.fun.nix {
        lib = nixpkgs.lib;
        inherit nixpkgs;
        inherit inputs;
      };
    in
    (mkFlakeModule.mkFlake {
      root = [ ./. ];
      inherit (inputs) self;
      lib = nixpkgs.lib;
      nixpkgs = nixpkgs;
      inherit inputs;
    }) // {
      # Export mkFlake function for external use
      mkFlake = args: mkFlakeModule.mkFlake (args // {
        lib = args.lib or nixpkgs.lib;
        nixpkgs = args.nixpkgs or nixpkgs;
        inputs = args.inputs or inputs;
      });
    };
}
