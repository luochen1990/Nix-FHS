# NixOS 模块系统 (Module System)

`modules/` 目录用于组织可复用的 NixOS 模块。系统将根据目录特征自动分类加载，无需手动维护 `module-list.nix`。

## 目录结构与加载逻辑

框架将目录分为两类：**Guarded** (含 `options.nix`) 和 **Unguarded** (普通目录)。

```
modules/
├── base/                 # Unguarded: 纯组织容器，会递归扫描
│   ├── shell.nix         # -> 自动导入
│   └── users.nix         # -> 自动导入
├── services/
│   └── web-server/       # Guarded: 包含 options.nix
│       ├── options.nix   # -> 总是导入
│       ├── config.nix    # -> 仅当 config.services.web-server.enable = true 时生效
│       └── sub-helper/   # -> 递归扫描并自动导入
└── personal/
    └── config.nix        # -> 自动导入
```

### 加载规则

1.  **Unguarded 目录**:
    *   如果包含 `default.nix`，则仅导入 `default.nix`（停止递归）。
    *   否则，导入目录下所有 `.nix` 文件，并递归扫描子目录。
2.  **Guarded 目录** (`options.nix` 存在):
    *   **options.nix**: 总是被导入，用于定义选项接口。
    *   **其他文件** (如 `config.nix`, `default.nix` 等): 只有当该模块被**启用**时才会生效。
        *   这通过内部生成的 `config = lib.mkIf cfg.enable { ... }` 包装器实现。

## 使用方法

### 定义一个 Guarded 模块

以 `modules/services/web-server` 为例：

**1. `options.nix`: 定义接口**

*   **严格模式 (Strict Mode)**：默认情况下，`optionsMode` 为 `strict`。你需要显式定义完整的选项路径（例如 `options.services.web-server`），框架会检查其是否匹配目录结构。
*   **自动 Enable**：框架会自动在模块路径下生成 `enable` 选项（如果未手动定义）。

```nix
{ lib, ... }:
{
  options.services.web-server = {
    # 需完整写出 options.services.web-server
    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
    };
  };
}
```

**2. `config.nix`: 实现逻辑**

默认会被包裹在 `mkIf cfg.enable { ... }` 中。

```nix
{ config, pkgs, ... }:
{
  # 无需手动写 config = lib.mkIf config.services.web-server.enable ...
  systemd.services.web-server = {
    script = "${pkgs.python3}/bin/python -m http.server ${toString config.services.web-server.port}";
  };
}
```

### 使用模块

在 `hosts/my-machine/configuration.nix` 中：

```nix
{
  # modules/ 下的模块已被自动发现并导入
  services.web-server.enable = true;
  services.web-server.port = 9000;
}
```
