# 全局配置 (Global Configuration)

本章节介绍 `flake.nix` 中的 `mkFlake` 全局配置以及其他工具（如 Formatter）的设置。

## mkFlake 配置

`mkFlake` 函数接受两个参数：上下文 (`inputs`, `self` 等) 和 配置模块。

```nix
flake-fhs.lib.mkFlake { inherit inputs; } {
  # 配置项
}
```

### 常用配置项

| 选项 | 类型 | 默认值 | 说明 |
| :--- | :--- | :--- | :--- |
| `systems` | list | standard systems | 支持的系统架构列表 (x86_64-linux, aarch64-darwin 等) |
| `nixpkgs.config` | attrs | `{ allowUnfree = true; }` | 传递给 nixpkgs 的配置 |
| `layout.roots` | list | `["" "/nix"]` | 项目根目录列表。支持从多个目录聚合内容。 |
| `systemContext` | lambda | `_: {}` | 系统上下文生成器 (`system -> attrs`)。返回的 attrset 中的 `specialArgs` 将被传递给 `nixosSystem`。支持自动合并。 |
| `flake` | attrs | `{}` | 合并到生成的 flake outputs 中。用于手动扩展或覆盖 FHS 生成的内容。 |

### 布局配置 (Layout)

你可以通过 `layout` 选项自定义各类型 output 的源目录。例如：

```nix
layout.packages.subdirs = [ "pkgs" "my-packages" ];
```

这意味着框架将同时扫描 `pkgs/` 和 `my-packages/` 目录来寻找包定义。

---

## Formatter - 代码格式化

Flake FHS 默认配置了 `formatter` 输出，支持 `nix fmt` 命令。

### 自动检测

Flake FHS 集成了 `treefmt`。它会自动检测根目录下的配置文件，优先级如下：

1.  **`treefmt.nix`**: 优先使用。若 `inputs` 中包含 `treefmt-nix`，则通过该库集成；否则直接加载 Nix 配置。
2.  **`treefmt.toml`**: 使用该 TOML 文件作为配置。
3.  **无配置文件**: 直接使用默认的 `pkgs.treefmt`。

### 使用方法

```bash
# 格式化项目中的所有文件
nix fmt
```
