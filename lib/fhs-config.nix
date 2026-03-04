# © Copyright 2025 罗宸 (luochen1990@gmail.com, https://lambda.lc)
#
# Flake FHS configuration schemas
#
lib:
let
  # ================================================================
  # Configuration Schema
  # ================================================================
  defaultLayout = {
    roots = {
      subdirs = [
        ""
        "/nix"
      ];
    };
    packages = {
      subdirs = [
        "pkgs"
        "packages"
      ];
    };
    nixosModules = {
      subdirs = [
        "modules"
        "nixosModules"
      ];
    };
    nixosConfigurations = {
      subdirs = [
        "hosts"
        "profiles"
        "nixosConfigurations"
      ];
    };
    devShells = {
      subdirs = [
        "shells"
        "devShells"
      ];
    };
    apps = {
      subdirs = [ "apps" ];
    };
    lib = {
      subdirs = [
        "lib"
        "tools"
        "utils"
      ];
    };
    checks = {
      subdirs = [ "checks" ];
    };
    templates = {
      subdirs = [ "templates" ];
    };
  };

  # Configuration Module Schema
  flakeFhsOptions =
    { lib, ... }:
    let
      # mkLayoutEntry :: String -> AttrSet -> AttrSet -> Option
      # Create a layout entry option with optional extra options
      mkLayoutEntry =
        description: default: extraOptions:
        lib.mkOption {
          inherit description;
          inherit default;
          type =
            lib.types.coercedTo (lib.types.listOf (lib.types.either lib.types.str lib.types.path))
              (l: { subdirs = l; })
              (
                lib.types.submodule {
                  options = {
                    subdirs = lib.mkOption {
                      type = lib.types.listOf (lib.types.either lib.types.str lib.types.path);
                      description = "List of subdirectories or paths";
                      default = [ ];
                    };
                  }
                  // extraOptions;
                }
              );
        };

      # No extra options for most layout entries
      noExtraOptions = { };

      # Extra options for nixosModules layout
      nixosModulesExtraOptions = {
        suffix = lib.mkOption {
          type = lib.types.str;
          default = ".nix";
          description = "File suffix for modules to auto-discover and import";
          example = ".mod.nix";
        };
      };
    in
    {
      options = {
        systems = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = lib.systems.flakeExposed;
          description = "List of supported systems";
        };

        nixpkgs.config = lib.mkOption {
          type = lib.types.attrs;
          default = {
            allowUnfree = true;
          };
          description = "Nixpkgs configuration";
        };

        layout = lib.mkOption {
          type = lib.types.submodule {
            freeformType = lib.types.attrs;
            options = {
              roots = mkLayoutEntry "Roots directories" defaultLayout.roots noExtraOptions;
              packages = mkLayoutEntry "Packages directories" defaultLayout.packages noExtraOptions;
              nixosModules =
                mkLayoutEntry "NixOS modules directories" defaultLayout.nixosModules
                  nixosModulesExtraOptions;
              nixosConfigurations =
                mkLayoutEntry "NixOS configurations directories" defaultLayout.nixosConfigurations
                  noExtraOptions;
              devShells = mkLayoutEntry "DevShells directories" defaultLayout.devShells noExtraOptions;
              apps = mkLayoutEntry "Apps directories" defaultLayout.apps noExtraOptions;
              lib = mkLayoutEntry "Lib directories" defaultLayout.lib noExtraOptions;
              checks = mkLayoutEntry "Checks directories" defaultLayout.checks noExtraOptions;
              templates = mkLayoutEntry "Templates directories" defaultLayout.templates noExtraOptions;
            };
          };
          default = { };
          description = "Directory layout configuration";
        };

        colmena = lib.mkOption {
          type = lib.types.submodule {
            options = {
              enable = lib.mkEnableOption "colmena integration";
            };
          };
          default = { };
          description = "Colmena configuration";
        };

        flake = lib.mkOption {
          type = lib.types.attrs;
          default = { };
          description = "Extra flake outputs to merge with FHS outputs";
        };

        systemContext = lib.mkOption {
          description = "Context generator dependent on system";
          default = _: { };
          type = lib.mkOptionType {
            name = "systemContext";
            description = "function system -> attrs";
            check = lib.isFunction;
            merge =
              loc: defs: system:
              lib.foldl' (acc: def: lib.recursiveUpdate acc (def.value system)) { } defs;
          };
        };
      };
    };
in
{
  inherit defaultLayout flakeFhsOptions;
}
