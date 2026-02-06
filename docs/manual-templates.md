# 模板 (Templates)

模板用于快速初始化新项目或组件。映射为 `templates.<name>`。

## 目录结构

`templates/` 目录下的每个**子目录**都被视为一个独立的模板。

```
templates/
├── basic/
│   ├── flake.nix
│   └── README.md
├── rust/
│   ├── flake.nix
│   └── cargo.toml
└── python/
    └── ...
```

*   **扁平结构**: 不支持嵌套或分类，直接映射一级子目录。
*   **内容**: 子目录中的所有文件都会作为模板内容。

## 使用方法

### 初始化项目

使用 `nix flake init` 命令：

```bash
# 使用名为 "basic" 的模板初始化当前目录
nix flake init --template <flake-url>#basic

# 示例 (如果 flake-fhs 是本地输入)
nix flake init --template .#basic
```

### 查看可用模板

使用 `nix flake show` 查看当前 Flake 提供的所有模板：

```bash
nix flake show
```

或者查看特定模板的描述（如果有 `description` 字段）：

```bash
nix flake show --json | jq '.templates'
```
