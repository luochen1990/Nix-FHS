# © Copyright 2025 罗宸 (luochen1990@gmail.com, https://lambda.lc)
#
# Flake FHS configurations output implementation
#
flakeFhsLib:
let
  inherit (builtins)
    listToAttrs
    map
    ;
in
{
  mkConfigurationsOutput =
    args:
    {
      validHosts,
      sharedModules,
      mkSysContext,
    }:
    let
      inherit (args) lib;
    in
    {
      nixosConfigurations = listToAttrs (
        map (
          host:
          let
            sysContext = mkSysContext host.info.system;
            modules = sharedModules ++ [
              (host.path + "/configuration.nix")
            ];
          in
          {
            name = host.name;
            value = lib.nixosSystem {
              inherit (sysContext)
                system
                lib
                ;
              specialArgs = sysContext.specialArgs // {
                hostname = host.name;
              };
              modules = modules ++ [
                { nixpkgs.pkgs = sysContext.pkgs; }
              ];
            };
          }
        ) validHosts
      );
    };
}
