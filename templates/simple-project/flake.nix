{
  description = "Simple project using Flake FHS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-fhs.url = "path:/home/lc/ws/Flake-FHS";
  };

  outputs = { self, nixpkgs, flake-fhs, ... }:
    flake-fhs.lib.mkFlake {
      inherit self nixpkgs;
      lib = nixpkgs.lib;
      root = [ ./. ];
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" ];
      nixpkgsConfig = {
        allowUnfree = true;
      };
    };
}