@{
    # 核心模块配置
    RootModule        = 'pwsh_shortcut_alias.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'e3b6c7c0-4b7e-4f1c-9e91-4b7e4f1c9e91'

    # 作者/版权信息
    Author            = 'viys'
    CompanyName       = 'Community'
    Copyright         = '(c) 2025 viys. All rights reserved.'

    # 描述
    Description       = @'
A PowerShell module for managing global shortcut aliases backed by a YAML file.
Features:
- Create/delete/search/update aliases for programs/scripts
- Persist alias data in YAML format (cross-session persistence)
- Auto-generate global PowerShell functions for quick access
- Support fuzzy search and formatted output for aliases
'@

    # 兼容版本
    PowerShellVersion = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')

    # 导出配置
    FunctionsToExport = @('Use-ShortcutAlias')
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @('usa')

    # 模块依赖
    RequiredModules = @(
        @{
            ModuleName = 'powershell-yaml'
            ModuleVersion = '0.4.1'
        }
    )
}
