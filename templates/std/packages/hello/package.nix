{
  lib,
  writeShellScriptBin,
}:

writeShellScriptBin "hello-fhs" ''
  echo "Hello from Flake FHS package hello-fhs-1.0.0!"
''
