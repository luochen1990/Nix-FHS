# Flake FHS core implementation
# mkFlake function that auto-generates flake outputs from directory structure

{
  lib,
  nixpkgs,
  inputs ? {}
}:

let
  # Built-in utils loading logic based on directory hierarchy
  # Level 1: utils/ - builtins only
  basicUtils = {
    dict = import ./dict.nix;
    list = import ./list.nix;
  };

  # Level 2: utils/more/ - lib dependent
  libUtils = lib: {
    file = import ./more/file.nix;
  };

  # Level 3: utils/more/more/ - lib and pkgs dependent (reserved for future)
  pkgsUtils = lib: pkgs: {
    # Future pkgs-dependent utilities can go here
  };

  # Merge all utils with proper dependency injection
  useLib = lib: (libUtils lib) // {
    usePkgs = pkgs: (pkgsUtils lib pkgs);
  };

  allUtils = basicUtils // {
    inherit useLib;
  };

  # System context helper with lib parameter for file operations
  getFileUtils = lib: let
    fileModule = import ./more/file.nix;
  in {
    inherit (fileModule)
      findFilesRec
      hasPostfix
      subDirsRec
      isNotHidden
      lsDirs
      lsFiles;
  };

  inherit (basicUtils.dict)
    unionFor
    dict
    ;

  inherit (basicUtils.list)
    for
    concatMap
    ;

  # System context helper
  systemContext = selfArg: system: rec {
    inherit system;
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    fileUtils = getFileUtils pkgs.lib;
    tools = allUtils // (allUtils.useLib pkgs.lib) // fileUtils;
    specialArgs = {
      self = selfArg;
      inherit
        system
        pkgs
        inputs
        tools
        fileUtils
        ;
    };
  };

  # Helper to process multiple root directories
  eachSystem' = supportedSystems: selfArg: f: dict supportedSystems (system: f (systemContext selfArg system));
  eachSystem = eachSystem' (lib.systems.flakeExposed or [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ]);

  # Discover components from multiple root directories
  discoverComponents = fileUtils: roots: componentType:
    unionFor roots (root:
      let
        componentPath = root + "/${componentType}";
      in
      if builtins.pathExists componentPath then
        for (fileUtils.lsDirs componentPath) (name: {
          inherit name root;
          path = componentPath + "/${name}";
        })
      else
        []
    );

in
rec {
  # Main mkFlake function
  mkFlake = args:
    let
      roots = args.root or [ ./. ];
      supportedSystems = args.supportedSystems or (lib.systems.flakeExposed or [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ]);
      nixpkgsConfig = args.nixpkgsConfig or { allowUnfree = true; };

      # Override systemContext with custom config
      systemContext' = selfArg: system: rec {
        inherit system;
        pkgs = import nixpkgs {
          inherit system;
          config = nixpkgsConfig;
        };
        fileUtils = getFileUtils pkgs.lib;
        tools = allUtils // (allUtils.useLib pkgs.lib) // fileUtils;
        specialArgs = {
          self = selfArg;
          inherit
            system
            pkgs
            inputs
            tools
            fileUtils
            roots
            ;
        };
      };

      eachSystem' = supportedSystems: selfArg: f: dict supportedSystems (system: f (systemContext' selfArg system));
      eachSystem = eachSystem' supportedSystems args.self;

      # Updated component discovery that respects multiple roots
      discoverComponents' = componentType:
        let
          fileUtils = getFileUtils lib;
          # Collect components from all roots as a flat list
          allComponents =
            concatMap (root:
              let
                componentPath = root + "/${componentType}";
              in
              if builtins.pathExists componentPath then
                for (fileUtils.lsDirs componentPath) (name: {
                  inherit name root;
                  path = componentPath + "/${name}";
                })
              else
              []
            ) roots;
        in
        allComponents;

      # Package discovery with optional default.nix control
      buildPackages' = context:
        let
          components = discoverComponents' "pkgs";
          # Check if any pkgs/default.nix exists in roots
          hasDefault = builtins.any (root: builtins.pathExists (root + "/pkgs/default.nix")) roots;
        in
        if hasDefault then
          # Use default.nix to control package visibility
          let
            defaultPkgs = concatMap (root:
              let
                defaultPath = root + "/pkgs/default.nix";
              in
              if builtins.pathExists defaultPath then
                let result = import defaultPath context;
                in if builtins.isAttrs result then [result] else []
              else []
            ) roots;
          in
          # Merge all package sets from default.nix files
          builtins.foldl' (acc: pkgs: acc // pkgs) {} defaultPkgs
        else
          # Auto-discover all packages
          dict components (name:
            { path, ... }:
            {
              "${name}" = context.pkgs.callPackage (path + "/package.nix") { };
            }
          );

    in
    {
      # Generate all flake outputs
      packages = eachSystem (
        context:
        buildPackages' context
      );

      devShells = eachSystem (
        context:
        let
          components = discoverComponents' "shells";
        in
        unionFor components (
          { name, path, ... }:
          {
            "${name}" = import path context;
          }
        )
      );

      apps = eachSystem (
        context:
        let
          components = discoverComponents' "apps";
        in
        unionFor components (
          { name, path, ... }:
          {
            "${name}" = import path context;
          }
        )
      );

      nixosModules =
        let
          components = discoverComponents' "modules";
        in
        unionFor components (
          { name, path, ... }:
          {
            "${name}" = import path;
          }
        )
        // {
          default =
            let
              context = systemContext' args.self "x86_64-linux";
            in
            unionFor components (
              { name, path, ... }:
              import path
            );
        };

      nixosConfigurations =
        let
          components = discoverComponents' "profiles";
          context = systemContext' args.self "x86_64-linux";
          modulesList = unionFor (discoverComponents' "modules") (
            { name, path, ... }:
            import path
          );
        in
        unionFor components (
          { name, path, ... }:
          {
            "${name}" = nixpkgs.lib.nixosSystem {
              system = "x86_64-linux";
              specialArgs = context.specialArgs // { inherit name; };
              modules = [ (path + "/configuration.nix") ] ++ modulesList;
            };
          }
        );

      checks = eachSystem (
        context:
        let
          components = discoverComponents' "checks";
        in
        unionFor components (
          { name, path, ... }:
          {
            "${name}" = import path context;
          }
        )
      );

      lib =
        let
          context = systemContext' args.self "x86_64-linux";
        in
        unionFor (discoverComponents' "utils") (
          { name, path, ... }:
          {
            "${name}" = import path context;
          }
        );

      templates =
        unionFor (discoverComponents' "templates") (
          { name, path, ... }:
          {
            "${name}" = {
              path = path;
              description = "Template: ${name}";
            };
          }
        );

      # Auto-generated overlay for packages
      overlays.default = final: prev:
        let
          fileUtils = getFileUtils final.lib;
          tools = allUtils // (allUtils.useLib final.lib) // fileUtils;
          context = { pkgs = final; inherit (final) lib; inherit tools; };
        in
        buildPackages' context;

      # Formatter
      formatter = eachSystem (
        { system, pkgs, ... }:
        pkgs.nixfmt-tree or pkgs.nixfmt
      );
    };

  # Helper functions
  inherit discoverComponents systemContext eachSystem;
}