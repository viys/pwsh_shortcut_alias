# pwsh_shortcut_alias
**Read this in other languages: [English](README.md), [中文](README_zh.md).**

`pwsh_shortcut_alias` is a PowerShell module for managing shortcut aliases backed by a YAML file. It lets you register short commands for local programs, `.lnk` shortcuts, scripts, and URLs, then launch them from any PowerShell session after a refresh.

Project Repository: [pwsh_shortcut_alias](https://github.com/viys/pwsh_shortcut_alias)

## Why Use It
- Create shortcut aliases for frequently used programs or scripts
- Support alias add, remove, fuzzy search, and refresh operations
- Return structured PowerShell objects from search for pipeline and scripting use
- Persist alias data in YAML for cross-session usage
- Register aliases as global functions with one refresh command
- Support both Windows PowerShell 5.1 and PowerShell 7+

## Installation
### From PowerShell Gallery
```powershell
Install-PSResource -Name pwsh_shortcut_alias
```

Or with PowerShellGet:

```powershell
Install-Module -Name pwsh_shortcut_alias
```

If `PSGallery` is not registered:

```powershell
Register-PSRepository -Default
```

### Local Install From Source
1. Copy the module folder `pwsh_short_alias` to the PowerShell module directory. For example:
```powershell
Copy-Item -Path .\pwsh_short_alias -Destination "$HOME\Documents\PowerShell\Modules\" -Recurse -Force
```
2. Import the module:
```powershell
Import-Module pwsh_shortcut_alias -Force
```
3. Add the following to your PowerShell profile:
```powershell
### pwsh_shortcut_alias_start
if (-not (Get-Command Use-ShortcutAlias -ErrorAction SilentlyContinue)) {
    Import-Module pwsh_shortcut_alias -ErrorAction Stop
}

Use-ShortcutAlias update 6> $null
### pwsh_shortcut_alias_end
```

## Quick Start

> The alias for Use-ShortcutAlias is usa.

Add a local shortcut:

```powershell
Use-ShortcutAlias add edge "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk"
```

Add a URL shortcut:

```powershell
Use-ShortcutAlias add chatgpt "https://chatgpt.com/"
```

Refresh exported global functions:

```powershell
Use-ShortcutAlias update
```

Launch by alias:

```powershell
edge
chatgpt
```

## Commands

### Add aliases

```powershell
Use-ShortcutAlias add typora "C:\Program Files\Typora\Typora.exe"
Use-ShortcutAlias add vscode "C:\Program Files\Microsoft VS Code\Code.exe"
```

### Remove aliases

```powershell
Use-ShortcutAlias remove typora
```

### Search aliases

```powershell
Use-ShortcutAlias search code
```

### Search aliases in scripts

```powershell
Use-ShortcutAlias search code | Select-Object Name, Path, IsUrl
```

### Refresh all aliases

```powershell
Use-ShortcutAlias update
```

## Configuration File

The module creates `shortcout_aliases.yaml` on first use and stores alias definitions there:

```yaml
aliases:
  edge:
    path: "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk"
  chatgpt:
    path: "https://chatgpt.com/"
```

## Notes

- Alias names must be unique
- Run `Use-ShortcutAlias update` after adding or removing aliases before using them as commands
- `Use-ShortcutAlias search` returns objects with `Name`, `Path`, and `IsUrl`
- The module depends on `powershell-yaml`, which is installed automatically when using PSGallery

## Troubleshooting

### PSGallery repository not found

If installation reports `WARNING: Repository PSGallery not found`, run:

```powershell
Register-PSRepository -Default
```

### Alias command is not available

If an alias exists in YAML but its command is unavailable in the current session, run:

```powershell
Use-ShortcutAlias update
```

## Examples

```powershell
# Add an alias for a desktop app
Use-ShortcutAlias add wechat "C:\Program Files\Tencent\WeChat\WeChat.exe"

# Add an alias for a web app
Use-ShortcutAlias add yuque "https://www.yuque.com/"

# Rebuild exported functions
Use-ShortcutAlias update

# Launch targets
wechat
yuque

# Search for aliases in a script-friendly way
Use-ShortcutAlias search we | Select-Object Name, Path, IsUrl
```

## Development Helpers

Install from the working tree with the helper script:

```powershell
./build.ps1 install
```

Uninstall with:

```powershell
./build.ps1 uninstall
```

Generate a clean publish layout for PSGallery with:

```powershell
./build.ps1 stage
```

## License
MIT License
