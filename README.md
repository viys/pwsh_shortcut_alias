# pwsh_shortcut_alias
**Read this in other languages: [English](README.md), [中文](README_zh.md).**

`pwsh_shortcut_alias` is a PowerShell module designed for managing shortcut aliases. With this module, you can easily create aliases for frequently used programs or scripts, launch the corresponding programs quickly via aliases, and it supports **add, delete, search, and update** operations.

Project Repository: [pwsh_shortcut_alias](https://github.com/viys/pwsh_shortcut_alias)

## Features
- Create shortcut aliases for frequently used programs or scripts
- Support alias addition, deletion, fuzzy search, and update
- Alias information is stored in a YAML file, enabling cross-session usage of the module
- One-click update of all aliases, which are automatically registered as global functions
- Compatible with PowerShell 7+, relying on the `powershell-yaml` module for YAML file parsing

## Installation
### Automatic Installation
- Install
```powershell
./build.ps1 install
```
- Uninstall
```powershell
./build.ps1 uninstall
```

### Manual Installation
1. Copy the module folder `pwsh_shortcut_alias` to the PowerShell module directory. For example:
```powershell
Copy-Item -Path .\pwsh_shortcut_alias -Destination "$HOME\Documents\PowerShell\Modules\" -Recurse -Force
```
2. Import the module:
```powershell
Import-Module pwsh_shortcut_alias -Force
```
3. Optional: Configure the module to load automatically in the PowerShell profile for convenient use on every launch:
```powershell
# Use notepad $PROFILE to edit the profile quickly
if (-not (Get-Command Use-ShortcutAlias -ErrorAction SilentlyContinue)) {
    Import-Module pwsh_shortcut_alias -ErrorAction Stop
}
Use-ShortcutAlias update
```

## Usage
### Add Aliases
```powershell
Use-ShortcutAlias add edge "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk"
Use-ShortcutAlias add typora "C:\Program Files\Typora\Typora.exe"
```

### Remove Aliases
```powershell
Use-ShortcutAlias remove edge
```

### Search Aliases (Fuzzy Search)
```powershell
Use-ShortcutAlias search ed
```

### Update All Aliases
```powershell
Use-ShortcutAlias update
```

### Launch Programs via Aliases
```powershell
edge
typora
```

## Configuration File
- The module automatically generates a `shortcut_aliases.yaml` file to store alias information upon first use:
```yaml
aliases:
  edge:
    path: "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk"
  typora:
    path: "C:\Program Files\Typora\Typora.exe"
```

## Dependencies
- PowerShell 7+ or Windows PowerShell
- `powershell-yaml` module:
```powershell
Install-Module powershell-yaml -Scope CurrentUser
```

## Notes
- Alias names must be unique
- `Use-ShortcutAlias update` registers all aliases in the YAML file as global functions
- Ensure `Use-ShortcutAlias update` is executed before using aliases, otherwise the corresponding functions may not be registered

## Examples
```powershell
# Add an alias
Use-ShortcutAlias add vscode "C:\Program Files\Microsoft VS Code\Code.exe"

# Launch the program via alias
vscode

# Remove an alias
Use-ShortcutAlias remove vscode

# Search for aliases
Use-ShortcutAlias search co
```

## License
MIT License
