{
  description = "Simple project using NFHS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    NFHS.url = "github:luochen1990/NFHS";
  };

  outputs =
    {
      self,
      nixpkgs,
      NFHS,
      ...
    }:
    NFHS.lib.mkFlake {
      inherit self nixpkgs;
      lib = nixpkgs.lib;
      roots = [ ./. ];
      nixpkgsConfig = {
        allowUnfree = true;
      };
    };
}
