# © Copyright 2025 罗宸 (luochen1990@gmail.com, https://lambda.lc)
#
# Flake FHS formatter implementation
#
flakeFhsLib:
let
  inherit (builtins)
    pathExists
    ;
in
{
  mkFormatterOutput =
    args:
    {
      eachSystem,
    }:
    let
      inherit (args) self inputs;
    in
    {
      formatter = eachSystem (
        { pkgs, ... }:
        let
          treefmtNix = self.outPath + "/treefmt.nix";
          treefmtToml = self.outPath + "/treefmt.toml";
        in
        if pathExists treefmtNix then
          if (inputs ? treefmt-nix) then
            (inputs.treefmt-nix.lib.evalModule pkgs treefmtNix).config.build.wrapper
          else
            #NOTE: the treefmt.nix format is different here
            #DOC: https://nixos.org/manual/nixpkgs/stable/#opt-treefmt-settings
            pkgs.treefmt.withConfig { settings = import treefmtNix; }
        else if pathExists treefmtToml then
          pkgs.treefmt.withConfig { configFile = treefmtToml; }
        else
          pkgs.treefmt
      );
    };
}
