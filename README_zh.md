# pwsh_shortcut_alias

**Read this in other languages: [English](README.md), [中文](README_zh.md).**

`pwsh_shortcut_alias` 是一个 PowerShell 模块，用于管理快捷方式别名。通过该模块，你可以轻松为常用程序或脚本创建别名，通过别名快速启动对应程序，并支持添加、删除、搜索和更新操作。

项目地址：[pwsh_shortcut_alias](https://github.com/viys/pwsh_shortcut_alias)

## 功能特点

* 为常用程序或脚本创建快捷方式别名
* 支持别名添加、删除、搜索（模糊搜索）和更新
* 别名信息存储在 YAML 文件中，模块可跨会话使用
* 一键更新所有别名，自动注册为全局函数
* 支持 PowerShell 7+，依赖 `powershell-yaml` 模块解析 YAML 文件

## 安装

### 自动化

- 安装

```powershell
./build.ps1 install
```

- 卸载

```powershell
./build.ps1 uninstall
```

### 手动安装

1. 将模块文件夹 `pwsh_shortcut_alias` 复制到 PowerShell 模块目录，例如：

```powershell
Copy-Item -Path .\pwsh_shortcut_alias -Destination "$HOME\Documents\PowerShell\Modules\" -Recurse -Force
```

2. 导入模块：

```powershell
Import-Module pwsh_shortcut_alias -Force
```

3. 可选：将模块自动加载到 PowerShell profile，方便每次启动时使用：

```powershell
# 使用 notepad $PROFILE 快速编辑
if (-not (Get-Command Use-ShortcutAlias -ErrorAction SilentlyContinue)) {
    Import-Module pwsh_shortcut_alias -ErrorAction Stop
}
Use-ShortcutAlias update
```

## 使用方法

### 添加别名

```powershell
Use-ShortcutAlias add edge "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk"
Use-ShortcutAlias add typora "C:\Program Files\Typora\Typora.exe"
```

### 删除别名

```powershell
Use-ShortcutAlias remove edge
```

### 搜索别名（模糊搜索）

```powershell
Use-ShortcutAlias search ed
```

### 更新所有别名

```powershell
Use-ShortcutAlias update
```

### 使用别名启动程序

```powershell
edge
typora
```

## 配置文件

* 模块在第一次使用时会自动生成 `shortcout_aliases.yaml` 文件，用于存储别名信息：

```yaml
aliases:
  edge:
    path: "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk"
  typora:
    path: "C:\Program Files\Typora\Typora.exe"
```

## 依赖

* PowerShell 7+ 或 Windows PowerShell
* `powershell-yaml` 模块：

```powershell
Install-Module powershell-yaml -Scope CurrentUser
```

## 注意事项

* 别名名称必须唯一
* `Use-ShortcutAlias update` 会将 YAML 文件中所有别名注册为全局函数
* 使用别名前确保 `Use-ShortcutAlias update` 已执行，否则函数可能未注册

## 示例

```powershell
# 添加别名
Use-ShortcutAlias add vscode "C:\Program Files\Microsoft VS Code\Code.exe"

# 使用别名启动程序
vscode

# 删除别名
Use-ShortcutAlias remove vscode

# 搜索别名
Use-ShortcutAlias search co
```

## 许可证

MIT License
