{ pkgs, system, ... }:

pkgs.mkShell {
  name = "flake-fhs-dev";

  buildInputs = with pkgs; [
    git
    curl
    hello
  ];

  shellHook = ''
    echo "🚀 Welcome to Flake FHS development environment!"
    echo "Available commands: git, curl, hello"
    echo "Try: nix build .#hello-custom"
    echo "System: ${system}"
  '';
}
