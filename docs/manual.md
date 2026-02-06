# Flake FHS 使用手册

Flake FHS 是一个 Nix Flake 框架，旨在通过标准化的目录结构自动生成 flake outputs，减少配置文件的维护成本。

## 1. 快速概览

框架的核心机制是将文件系统的目录结构直接映射为 Nix flake outputs。

**目录映射表**

| 目录 | 生成 Output | 对应的 Nix 命令 | 详细文档 |
| :--- | :--- | :--- | :--- |
| [`hosts`](#guide-hosts) | `nixosConfigurations.<name>` | `nixos-rebuild switch --flake .#<name>` | [系统配置 (hosts)](./manual-hosts.md) |
| [`modules`](#guide-modules) | `nixosModules.<name>` | - | [NixOS 模块 (modules)](./manual-modules.md) |
| [`pkgs`](#guide-pkgs) | `packages.<system>.<name>` | `nix build .#<name>` | [软件包 (pkgs)](./manual-pkgs.md) |
| [`apps`](#guide-apps) | `apps.<system>.<name>` | `nix run .#<name>` | [应用程序 (apps)](./manual-apps.md) |
| [`checks`](#guide-checks) | `checks.<system>.<name>` | `nix flake check .#<name>` | [测试与检查 (checks)](./manual-checks.md) |
| [`shells`](#guide-shells) | `devShells.<system>.<name>` | `nix develop .#<name>` | [开发环境 (shells)](./manual-shells.md) |
| [`lib`](#guide-lib) | `lib.<name>` | `nix eval .#lib.<name>` | [函数库 (lib)](./manual-lib.md) |
| [`templates`](#guide-templates) | `templates.<name>` | `nix flake init --template .#<name>` | [模板 (templates)](./manual-templates.md) |

## 2. 详细指南

**新手提示**：你**不需要**一次性读完所有文档。Flake outputs 是按需生成的，只有当你创建了对应的目录时，相关功能才会生效。你可以先从 `hosts` 开始配置你的系统，根据需要再逐步探索其他功能。

本手册按推荐学习顺序排列：

### <span id="guide-hosts">🖥️ 系统配置 (Hosts)</span>

定义具体的机器配置（Entrypoints）。

*   **📖 [阅读详细手册 (manual-hosts.md)](./manual-hosts.md)**
*   **核心内容**：
    *   如何定义 `nixosConfigurations`。
    *   共享配置的导入方式。

### <span id="guide-modules">🧩 NixOS 模块系统 (Modules)</span>

用于组织可复用的 NixOS 模块。

*   **📖 [阅读详细手册 (manual-modules.md)](./manual-modules.md)**
*   **核心内容**：
    *   **自动发现**：目录结构如何映射为模块。
    *   **Guarded Modules**：包含 `options.nix` 的模块加载机制。
    *   **Unguarded Modules**：普通目录的递归加载机制。

### <span id="guide-pkgs">📦 软件包 (Packages) & Scoped Package Tree</span>

用于定义项目特有的软件包。

*   **📖 [阅读详细手册 (manual-pkgs.md)](./manual-pkgs.md)**
*   **核心内容**：
    *   **Scope (作用域)** 系统：如何管理依赖。
    *   **callPackage** 机制：如何构建包。
    *   **参数注入**：如何将全局 inputs 传入包中。
*   **注意**：`apps`, `shells`, `checks` 都复用了此核心机制，建议在阅读这些章节前先了解本章。

### <span id="guide-apps">🚀 应用程序 (Applications)</span>

定义可通过 `nix run` 直接运行的目标。

*   **📖 [阅读详细手册 (manual-apps.md)](./manual-apps.md)**
*   **核心内容**：
    *   如何定义 App。
    *   自动推断程序入口 (`meta.mainProgram`) 的规则。

### <span id="guide-checks">✅ 测试与检查 (Checks)</span>

用于 CI/CD 的测试与检查 (`nix flake check`)。

*   **📖 [阅读详细手册 (manual-checks.md)](./manual-checks.md)**
*   **核心内容**：
    *   如何编写测试用例。
    *   如何使用 `callPackage` 构建测试。

### <span id="guide-shells">🛠️ 开发环境 (Development Shells)</span>

定义开发环境 (`nix develop`)。

*   **📖 [阅读详细手册 (manual-shells.md)](./manual-shells.md)**
*   **核心内容**：
    *   如何编写 `devShells`。
    *   如何从 `packages` 继承环境。

### <span id="guide-lib">📚 函数库 (Library)</span>

自定义 Nix 函数库。

*   **📖 [阅读详细手册 (manual-lib.md)](./manual-lib.md)**
*   **核心内容**：
    *   如何定义及在 Flake 中使用自定义函数。

### <span id="guide-templates">📋 模板 (Templates)</span>

用于初始化新项目的模板。

*   **📖 [阅读详细手册 (manual-templates.md)](./manual-templates.md)**
*   **核心内容**：
    *   目录结构与模板映射。
    *   如何使用 `nix flake init`。

### <span id="guide-config">⚙️ 全局配置 (Global Configuration)</span>

`flake.nix` 全局配置。

*   **📖 [阅读详细手册 (manual-config.md)](./manual-config.md)**
*   **核心内容**：
    *   `mkFlake` 选项说明 (`systems`, `nixpkgs.config` 等)。
    *   代码格式化工具 (`nix fmt`) 的设置。

## 3. 最佳实践

### 项目组织

*   **遵循约定**：尽量使用框架默认的目录结构，减少自定义配置。
*   **模块化**：将复杂的系统配置拆分为小的、可复用的模块 (`modules/`)。
*   **利用封装**：如果一个包需要多个辅助文件，请使用目录模式（即创建 `pkgs/<name>/package.nix`）。该目录下的其他 `.nix` 文件（如 `helper.nix`）不会被自动扫描为独立包，从而保持对外接口的整洁。

### 开发流程

*   **快速开始**：总是使用模板 (`nix flake init --template ...`) 来初始化新项目或组件。
*   **持续检查**：养成运行 `nix flake check` 的习惯，配合 `checks/` 目录下的测试用例。
*   **格式化**：使用 `nix fmt` 保持代码风格统一。

### 性能优化

*   **模块化管理**：对于拥有大量 NixOS 模块的项目，Flake FHS 的模块加载机制（Guarded Modules）可以帮助你更好地组织代码。确保将独立的模块放入带有 `options.nix` 的子目录中，这样只有在 `enable = true` 时才会激活其配置逻辑。
