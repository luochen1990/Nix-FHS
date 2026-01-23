{ pkgs, ... }:
pkgs.mkShell {
  packages = with pkgs; [
    git
    nodejs
  ];
}
