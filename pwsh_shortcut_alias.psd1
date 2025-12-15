@{
    RootModule        = 'pwsh_shortcut_alias.psm1'
    ModuleVersion     = '0.1.0'

    GUID              = 'e3b6c7c0-4b7e-4f1c-9e91-4b7e4f1c9e91'

    Author            = 'viys'
    CompanyName       = 'Community'
    Copyright         = '(c) 2025'

    Description       = 'A PowerShell module for managing shortcut aliases backed by a YAML file.'

    PowerShellVersion = '5.1'

    FunctionsToExport = @(
        'Use-ShortcutAlias'
    )

    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{
        PSData = @{
            Tags       = @('alias', 'shortcut', 'yaml', 'cli')
            ProjectUri = 'https://github.com/viys/pwsh_shortcut_alias'
        }
    }
}
