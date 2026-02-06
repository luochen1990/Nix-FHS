# 函数库 (Library)

`lib/` 目录下的 Nix 文件被设计为函数库。

## 机制

定义在 `lib/` (以及 `tools/`, `utils/`) 下的 `.nix` 文件会被自动加载，其返回的 attribute set 会被**合并**，并具有双重用途：

1.  **对外导出**：作为 Flake Output 的 `lib` 导出。可以通过 `<this-flake>.lib` 访问。
2.  **内部调用**：
    *   **其他库文件 (Level 1/2)**：通过参数 `lib` (Level 1) 或 `pkgs.lib` (Level 2) 调用。
    *   **NixOS Modules**：通过参数 `lib` 或 `self.lib` 调用。

> **注意**：
> *   **优先级规则**：合并时 `nixpkgs.lib` 具有最高优先级。如果你的函数名与标准库冲突（例如 `lib.foldl'`），你的实现将被**覆盖**。请务必检查命名冲突，建议使用独特的命名空间或前缀。如果必须访问被覆盖的自定义函数，请通过 `self.lib` 访问。
> *   框架**不会**根据文件名自动创建命名空间。所有文件的返回值都会被直接合并到顶层 `lib` 中。
> *   **在 `packages/` 中**：默认情况下 `pkgs.lib` 仍然是原生的 Nixpkgs lib，**不包含**自定义函数。如果在 Package 中需要使用自定义库，需要在 `scope.nix` 中显式引入（见下文）。

## 加载分层 (Loading Levels)

框架根据文件返回值的类型和位置，支持三种类型的库文件定义：

### Level 0: 无依赖库 (No Dependency)
如果文件直接返回一个 Attribute Set，它会被直接合并。

**适用场景**：不依赖 `lib` 和 `pkgs`, 仅依赖 `builtins` 的库。

```nix
# lib/basic.nix
{
  # 纯逻辑函数
  add = a: b: a + b;

  # 依赖 builtins 的函数
  for = xs: f: builtins.map f xs;
}
```

### Level 1: 依赖 lib 的库 (Lib Dependent)
如果文件返回一个函数，该函数接收 `lib` 作为参数。
这里的 `lib` 包含了 Nixpkgs 的标准库以及本项目中定义的所有 Level 0 和 Level 1 的自定义函数。

**适用场景**：需要使用标准库函数（如 `lib.foldl'`）或项目内其他工具函数的情况。

```nix
# lib/math-list.nix
lib: {
  # 使用标准库函数
  sum = lib.foldl' (a: b: a + b) 0;
    
  # 假设 lib.add 是在另一个文件中定义的
  inc = x: lib.add x 1;
}
```

### Level 2: 依赖 pkgs 的库 (Pkgs Dependent)
**仅限 `lib/more/` 目录下的文件**。
这些文件返回一个函数，该函数接收 `pkgs` 作为参数。
`pkgs` 中包含 `lib` (已包含所有自定义函数) 和所有软件包。

**适用场景**：需要访问软件包（如 `pkgs.jq`, `pkgs.hello`）或特定于系统的配置。

```nix
# lib/more/yaml.nix
pkgs: {
  # yaml.generate :: Path -> AttrSet -> Drv
  yaml.generate = (pkgs.formats.yaml {}).generate;

  # 定义一个工具函数来读取 YAML 文件并将其转换为 Nix 数据结构
  # yaml.readFile :: Path -> AttrSet
  yaml.readFile = yaml-filename: let
    yj = pkgs.yj;
    json-file = pkgs.runCommand "yaml-to-json" {buildInputs = [yj];} ''
      yj -yj < ${yaml-filename} > $out
    '';
  in
    builtins.fromJSON (builtins.readFile json-file);
}
```

## 代码示例

### 1. 在 NixOS Module 中使用

在 Module 中，自定义 `lib` 可以直接通过参数使用。

```nix
# modules/my-service/default.nix
{ lib, config, ... }:
{
  # 使用自定义函数
  config.value = lib.add 1 2;
}
```

### 2. 在 Packages 中使用

默认情况下，`packages/` 下的文件拿到的 `lib` 是原生的。如需使用自定义函数，需要通过 `scope.nix` 引入。

**第一步：在目录中创建 `scope.nix`**
```nix
# packages/scope.nix
{ lib, ... }: # 这里的 lib 是包含自定义函数的 lib
{
  # 将 lib 传入 args 中，这样 package.nix 的参数就能接收到它
  args = { inherit lib; };
}
```

**第二步：在 `package.nix` 中使用**
```nix
# packages/my-pkg.nix
{ stdenv, lib, ... }: # 这里的 lib 是由 scope.nix 传入的
{
  buildPhase = ''
    echo ${toString (lib.add 1 2)} > $out
  '';
}
```

## 调试

你可以使用 `nix eval` 来测试库函数。

```bash
# 测试 lib.add
nix eval .#lib.add --apply 'f: f 1 2'
```
