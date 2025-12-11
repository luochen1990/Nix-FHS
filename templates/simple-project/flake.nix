{
  description = "Simple project using Flake FHS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-fhs.url = "github:luochen1990/flake-fhs";
  };

  outputs = { nixpkgs, flake-fhs, ... }:
    flake-fhs.mkFlake {
      root = [ ./. ];
      nixpkgsConfig = {
        allowUnfree = true;
      };
    };
}