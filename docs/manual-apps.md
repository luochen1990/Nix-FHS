# 应用程序 (Applications)

定义可通过 `nix run` 直接运行的目标。映射为 `apps.<system>.<name>`。

## 核心机制

`apps/` 目录完全复用 **Scoped Package Tree** 的结构与逻辑：
*   支持 `package.nix` 目录模式
*   支持 `<name>.nix` 文件模式
*   支持 `scope.nix` 依赖注入

详情请参考 [软件包与作用域文档 (manual-pkgs.md)](./manual-pkgs.md)。

区别在于：Flake FHS 会自动将构建出的软件包包装为 App 结构 `{ type = "app"; program = "..."; }`。

## 自动推断机制

框架会尝试自动推断程序的入口点。当然，你也可以通过设置 `meta.mainProgram` 来手动指定。推断优先级如下：
1.  `meta.mainProgram` (显式指定)
2.  `pname`
3.  `name` (去除版本号后缀)

## 代码示例

**1. 目录模式 (`apps/deploy/package.nix`)**

```nix
{ writeShellScriptBin }:
writeShellScriptBin "deploy" ''
  echo "Deploying..."
''
```

**2. 文件模式 (`apps/hello.nix`)**

```nix
{ pkgs }:
pkgs.hello
```

## 运行命令

```bash
nix run .#deploy
nix run .#hello
```
