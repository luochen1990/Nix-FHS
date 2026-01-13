{
  description = "Full-featured project with modules and profiles using NFHS";

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
      roots = [ ./. ];
      supportedSystems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
      ];
      nixpkgsConfig = {
        allowUnfree = true;
      };
    };
}
