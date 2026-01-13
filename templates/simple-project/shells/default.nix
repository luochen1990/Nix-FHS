{ pkgs, system, ... }:

pkgs.mkShell {
  name = "NFHS-dev";

  buildInputs = with pkgs; [
    git
    vim
    curl
    nixfmt
    hello
  ];

  shellHook = ''
    echo "🚀 Welcome to NFHS development environment!"
    echo "Available commands: git, vim, curl, nixfmt, hello"
    echo "Try: nix build .#hello-custom"
    echo "System: ${system}"
  '';
}
