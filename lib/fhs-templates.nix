# © Copyright 2025 罗宸 (luochen1990@gmail.com, https://lambda.lc)
#
# Flake FHS templates implementation
#
flakeFhsLib:
let
  inherit (builtins)
    pathExists
    listToAttrs
    concatLists
    map
    ;

  inherit (flakeFhsLib)
    for
    lsDirs
    ;
in
{
  mkTemplatesOutput =
    args:
    { roots }:
    let
      readTemplatesFromRoot =
        root:
        let
          templatePath = root + "/templates";
        in
        if pathExists templatePath then
          for (lsDirs templatePath) (
            name:
            let
              fullPath = templatePath + "/${name}";
              flakePath = fullPath + "/flake.nix";
              hasFlake = pathExists flakePath;
              description =
                if hasFlake then (import flakePath).description or "Template: ${name}" else "Template: ${name}";
            in
            {
              inherit name;
              value = {
                path = fullPath;
                inherit description;
              };
            }
          )
        else
          [ ];

      allTemplateLists = map readTemplatesFromRoot roots;
      allTemplates = concatLists allTemplateLists;
    in
    {
      templates = listToAttrs allTemplates;
    };
}
