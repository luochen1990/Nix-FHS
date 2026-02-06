# 开发环境 (Development Shells)

定义开发环境 (`devShells`)。映射为 `devShells.<system>.<name>`。

## 核心机制

`shells/` 目录完全复用 **Scoped Package Tree** 的结构与逻辑：
*   支持 `package.nix` 目录模式
*   支持 `<name>.nix` 文件模式
*   支持 `scope.nix` 依赖注入

详情请参考 [软件包与作用域文档 (manual-pkgs.md)](./manual-pkgs.md)。

## 代码示例

### `shells/rust.nix`

映射为 `devShells.<system>.rust`。

```nix
{ pkgs }:
pkgs.mkShell {
  name = "rust-dev";
  buildInputs = with pkgs; [ cargo rustc ];
}
```

### `shells/default.nix`

映射为默认的 `nix develop` 环境。

```nix
{ pkgs }:
pkgs.mkShell {
  inputsFrom = [ (import ../pkgs/my-app/package.nix { inherit pkgs; }) ];
}
```

## 使用命令

```bash
# 进入默认环境
nix develop

# 进入指定环境
nix develop .#rust
```
