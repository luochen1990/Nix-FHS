# © Copyright 2025 罗宸 (luochen1990@gmail.com, https://lambda.lc)
#
# Flake FHS devShells output implementation
#
flakeFhsLib:
let
  inherit (builtins)
    listToAttrs
    concatLists
    concatStringsSep
    tail
    pathExists
    ;

  inherit (flakeFhsLib)
    exploreDir
    forFilter
    lsFiles
    hasSuffix
    removeSuffix
    ;
in
{
  mkShellsOutput =
    args:
    {
      roots,
      partOf,
      eachSystem,
    }:
    {
      devShells = eachSystem (
        sysContext:
        listToAttrs (
          concatLists (
            exploreDir roots (it: rec {
              isShellsRoot = it.depth == 0 && partOf.devShells it.name;
              isShellsSubDir = it.depth >= 1;

              into = isShellsRoot || isShellsSubDir;

              out =
                if isShellsRoot then
                  # Case 1: shells/*.nix -> devShells.*
                  forFilter (lsFiles it.path) (
                    fname:
                    if hasSuffix ".nix" fname then
                      {
                        name = removeSuffix ".nix" fname;
                        value = import (it.path + "/${fname}") sysContext;
                      }
                    else
                      null
                  )
                else if isShellsSubDir && pathExists (it.path + "/default.nix") then
                  # Case 2: shells/<name>/default.nix -> devShells.<name>
                  [
                    {
                      name = concatStringsSep "/" (tail it.breadcrumbs');
                      value = import (it.path + "/default.nix") sysContext;
                    }
                  ]
                else
                  [ ];

              pick = out != [ ];
            })
          )
        )
      );
    };
}
