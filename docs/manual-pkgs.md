# 软件包 (Packages) & Scoped Package Tree

Flake FHS 采用统一的 **"Scoped Package Tree"** 模型来处理软件包 (`pkgs`)、应用程序 (`apps`)、开发环境 (`shells`) 和检查 (`checks`)。

本文档详细介绍这一核心模型，它是理解整个框架构建逻辑的基础。

## <span id="pkgs">pkgs/ - 软件包</span>

`pkgs/` 目录用于定义项目特有的软件包，映射为 `packages.<system>.<name>`。它是 Scoped Package Tree 模型的标准实现。

### 目录结构

遵循类似 `nixpkgs` 的 `by-name` 结构，同时支持单文件定义：

```
pkgs/
├── hello.nix            # 简单包 (文件模式)
├── complex-app/         # 复杂包 (目录模式)
│   ├── package.nix      # -> 必须包含此文件，被识别为包定义
│   └── src/             # 其他辅助文件不会被识别为独立包
└── group/               # 包组 (普通目录)
    ├── scope.nix        # -> 定义局部作用域
    ├── utils.nix        # 辅助文件，非包定义
    └── core/
        └── package.nix  # 子目录中的包
```

### Scope 与 callPackage

Flake FHS 使用 Nix 的 `callPackage` 机制来构建软件包。所有包定义（无论是 `.nix` 文件还是 `package.nix`）都通过 `callPackage` 构建，因此你可以直接声明所需的依赖。

#### Scope (作用域)

`scope.nix` 文件用于配置 `callPackage` 所使用的 **Scope (上下文包集)**。

*   **作用范围**: `scope.nix` 会影响**同级目录**中的所有包以及**所有子目录**。
*   **约定格式**: `{ pkgs, inputs, ... }: { scope = ...; args = ...; }`

#### 参数说明

*   **scope**: 指定用于执行 `callPackage` 的基础包集 (Base Scope)。
    *   例如：`pkgs.python3Packages`。
    *   如果指定了 `scope`，则会**替换**父级的 scope（切断继承）。
    *   如果未指定，则默认**继承**父级的 scope。
*   **args**: 注入到 `callPackage` 的额外参数。
    *   这些参数会作为 **第二个参数** 传递给 `callPackage`。
    *   最终，它们可以作为参数直接传递给包定义函数。

#### 参数注入

默认情况下，`callPackage` 的作用域仅包含 `pkgs`。如果你的包需要访问全局参数（如 `self`, `inputs`, `lib`），你需要通过 `scope.nix` 显式注入它们。

例如，注入 `self` 和 `inputs`：

`pkgs/scope.nix`:
```nix
{ pkgs, self, inputs, lib, ... }:
{
  scope = lib.mkScope (pkgs // { inherit self inputs lib; });
}
```

然后你就可以在包定义中使用它们：
```nix
{ stdenv, inputs, ... }: 
stdenv.mkDerivation {
  # ... 使用 inputs.nixpkgs ...
}
```

#### 继承规则

*   **只提供 `args`**: **合并**。继承父级 args，并与当前 args 合并。适合注入公共依赖或配置。
*   **提供 `scope`**: **替换**。使用提供的 `scope` 作为新基础。适合切换语言生态（如切换到 Python 环境）。注意：即使替换了 Scope，父级目录定义的 `args` 依然会被继承（除非被同名参数覆盖）。

### 示例

#### 示例 1：集成 Python 包 (目录级)

```
pkgs/
└── python/
    ├── scope.nix      # 定义作用域
    ├── pandas/
    │   └── package.nix
    └── numpy.nix      # 文件模式
```

`pkgs/python/scope.nix`:
```nix
{ pkgs, ... }:
{
  # 替换模式：切换到 Python 包集
  scope = pkgs.python311Packages;
  
  # 可选：同时对该 scope 进行 override
  # args = { ... }; 
}
```

`pkgs/python/numpy.nix`:
```nix
# 这里可以直接请求 buildPythonPackage, pytest 等 Python 生态的包
{ buildPythonPackage, pytest, ... }:

buildPythonPackage {
  pname = "numpy";
  # ...
}
```

#### 示例 2：Per-Package 注入参数

你可以在 `package.nix` 旁边放一个 `scope.nix` 来为该特定包注入参数：

`pkgs/my-app/scope.nix`:
```nix
{ ... }: {
  args = {
    enableFeatureX = true;
    customVersion = "1.0.0";
  };
}
```

`pkgs/my-app/package.nix`:
```nix
{ stdenv, enableFeatureX, customVersion }: # 这里可以直接接收注入的参数

stdenv.mkDerivation {
  # ... 使用 enableFeatureX 和 customVersion
}
```
