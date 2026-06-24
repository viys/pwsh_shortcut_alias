# pwsh_shortcut_alias

**Read this in other languages: [English](README.md), [中文](README_zh.md).**

`pwsh_shortcut_alias` 是一个基于 YAML 存储的 PowerShell 快捷方式别名模块。它可以为本地程序、`.lnk` 快捷方式、脚本和 URL 注册短命令，并在刷新后从任意 PowerShell 会话里直接启动对应目标。

项目地址：[pwsh_shortcut_alias](https://github.com/viys/pwsh_shortcut_alias)

## 为什么使用它

- 为常用程序或脚本创建快捷方式别名
- 支持别名添加、删除、模糊搜索和刷新
- 搜索返回结构化 PowerShell 对象，便于管道和脚本消费
- 别名数据持久化到 YAML，跨会话可复用
- 通过一次刷新命令把别名注册为全局函数
- 同时支持 Windows PowerShell 5.1 和 PowerShell 7+

## 安装

### 从 PowerShell Gallery 安装

```powershell
Install-PSResource -Name pwsh_shortcut_alias
```

或者使用 PowerShellGet：

```powershell
Install-Module -Name pwsh_shortcut_alias
```

如果本机还没有注册 `PSGallery`：

```powershell
Register-PSRepository -Default
```

### 从源码本地安装

1. 将模块文件夹 `pwsh_short_alias` 复制到 PowerShell 模块目录，例如：

```powershell
Copy-Item -Path .\pwsh_short_alias -Destination "$HOME\Documents\PowerShell\Modules\" -Recurse -Force
```

2. 导入模块：

```powershell
Import-Module pwsh_shortcut_alias -Force
```

3. 在 PowerShell profile 添加如下内容：

```powershell
### pwsh_shortcut_alias_start
if (-not (Get-Command Use-ShortcutAlias -ErrorAction SilentlyContinue)) {
    Import-Module pwsh_shortcut_alias -ErrorAction Stop
}

Use-ShortcutAlias update 6> $null
### pwsh_shortcut_alias_end
```

## 快速开始

> `Use-ShortcutAlias` 的别名是 `usa`。

添加本地快捷方式：

```powershell
Use-ShortcutAlias add edge "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk"
```

添加 URL 快捷方式：

```powershell
Use-ShortcutAlias add chatgpt "https://chatgpt.com/"
```

刷新导出的全局函数：

```powershell
Use-ShortcutAlias update
```

通过别名启动：

```powershell
edge
chatgpt
```

## 命令示例

### 添加别名

```powershell
Use-ShortcutAlias add typora "C:\Program Files\Typora\Typora.exe"
Use-ShortcutAlias add vscode "C:\Program Files\Microsoft VS Code\Code.exe"
```

### 删除别名

```powershell
Use-ShortcutAlias remove typora
```

### 搜索别名

```powershell
Use-ShortcutAlias search code
```

### 在脚本里消费搜索结果

```powershell
Use-ShortcutAlias search code | Select-Object Name, Path, IsUrl
```

### 刷新所有别名

```powershell
Use-ShortcutAlias update
```

## 配置文件

模块首次使用时会自动生成 `shortcout_aliases.yaml`，并把别名定义保存进去：

```yaml
aliases:
  edge:
    path: "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk"
  chatgpt:
    path: "https://chatgpt.com/"
```

## 注意事项

- 别名名称必须唯一
- 添加或删除别名后，需要执行 `Use-ShortcutAlias update`，再把它们当命令直接使用
- `Use-ShortcutAlias search` 返回包含 `Name`、`Path`、`IsUrl` 的对象
- 使用 PSGallery 安装时，`powershell-yaml` 依赖会自动安装

## 故障排除

### 找不到 PSGallery 仓库

如果安装时出现 `WARNING: Repository PSGallery not found`，执行：

```powershell
Register-PSRepository -Default
```

### 别名命令不可用

如果 YAML 里已经有别名，但当前会话中命令不可用，执行：

```powershell
Use-ShortcutAlias update
```

## 示例

```powershell
# 为桌面应用添加别名
Use-ShortcutAlias add wechat "C:\Program Files\Tencent\WeChat\WeChat.exe"

# 为网页应用添加别名
Use-ShortcutAlias add yuque "https://www.yuque.com/"

# 重建导出的函数
Use-ShortcutAlias update

# 启动目标
wechat
yuque

# 以脚本友好的方式搜索
Use-ShortcutAlias search we | Select-Object Name, Path, IsUrl
```

## 开发辅助

从当前工作树安装：

```powershell
./build.ps1 install
```

卸载：

```powershell
./build.ps1 uninstall
```

生成用于 PSGallery 发布的干净目录：

```powershell
./build.ps1 stage
```

## 许可证

MIT License
