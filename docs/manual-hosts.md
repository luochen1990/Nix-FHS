# 系统配置 (System Configurations)

`hosts/` 目录用于定义具体的机器配置（Entrypoints），映射为 `nixosConfigurations.<name>`。

## 目录结构

```
hosts/
├── server-a/
│   └── configuration.nix   # -> nixosConfigurations.server-a
├── laptop/
│   ├── default.nix         # -> 定义架构元数据 (可选)
│   ├── hardware.nix
│   └── configuration.nix   # -> nixosConfigurations.laptop
└── shared/                 # (约定) 存放共享配置
    └── common.nix
```

系统会自动寻找 `<name>/configuration.nix` 作为入口文件。

## 代码示例

`hosts/laptop/configuration.nix`:

```nix
{ pkgs, ... }:
{
  imports = [
    ./hardware.nix
    ../shared/common.nix  # 手动导入共享配置
  ];

  # networking.hostName = "laptop"; # 框架已默认注入，无需手动设置
  environment.systemPackages = [ pkgs.git ];
}
```

## 设置系统架构 (System Architecture)

默认情况下，框架假定主机架构为 `x86_64-linux`。如果需要修改（例如部署到 Raspberry Pi 或 Apple Silicon），需要在主机目录下创建一个 `default.nix` 文件。

`hosts/laptop/default.nix`:

```nix
{
  system = "aarch64-linux"; # 或 "aarch64-darwin", "x86_64-darwin" 等
}
```

> **注意**：不要在 `configuration.nix` 中通过 `nixpkgs.hostPlatform` 设置架构。因为 Flake FHS 会在模块加载前预先实例化 `pkgs` 并注入到模块参数中，因此模块内部的架构设置会被忽略。必须通过 `default.nix` 在实例化前告知框架所需的架构。

## 构建与部署

### 单机部署

使用标准 NixOS 命令：

```bash
# 构建并切换
nixos-rebuild switch --flake .#laptop

# 仅构建
nixos-rebuild build --flake .#laptop
```

### 多机部署 (Colmena)

如果启用了 `colmena.enable = true`（参见全局配置），你可以使用 Colmena 进行高效的多机部署：

```bash
# 部署所有主机
colmena apply

# 部署特定主机
colmena apply --on laptop
```
