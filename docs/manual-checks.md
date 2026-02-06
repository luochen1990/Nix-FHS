# 测试与检查 (Checks)

用于 `nix flake check`。映射为 `checks.<system>.<name>`。

## 核心机制

`checks/` 目录完全复用 **Scoped Package Tree** 的结构与逻辑：
*   支持 `package.nix` 目录模式
*   支持 `<name>.nix` 文件模式
*   支持 `scope.nix` 依赖注入

详情请参考 [软件包与作用域文档 (manual-pkgs.md)](./manual-pkgs.md)。

## 编写规范

Checks 采用标准的 `callPackage` 机制构建，因此应编写为标准的包定义函数 `{ pkgs, ... }`。

如果需要访问 `system`、`self` 或其他 inputs，请通过 `scope.nix` 显式注入它们（参见 [manual-pkgs.md](./manual-pkgs.md#pkgs)）。

## 代码示例

假设你已在 `checks/scope.nix` 中注入了 `self` 和 `inputs`。

### 1. 文件模式 (`checks/fmt.nix`)

```nix
{ pkgs, self }: # 需在 scope.nix 中注入 self
pkgs.runCommand "check-fmt" {
  buildInputs = [ pkgs.nixfmt ];
} ''
  nixfmt --check ${self}
  touch $out
''
```

### 2. 目录模式 (`checks/integration/package.nix`)

```nix
{ pkgs, inputs }: # 需在 scope.nix 中注入 inputs
pkgs.runCommand "integration-test" {} ''
  echo "Running tests against ${inputs.nixpkgs.rev}..."
  touch $out
''
```

## 运行命令

```bash
# 运行所有检查
nix flake check

# 构建特定检查
nix build .#checks.x86_64-linux.fmt
```
