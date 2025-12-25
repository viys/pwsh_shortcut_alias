function Use-ShortcutAlias {
<#
.SYNOPSIS
    Manage shortcut aliases: add, remove, search, or update aliases.

.DESCRIPTION
    Use-ShortcutAlias (alias: usa) is a PowerShell module function used to create
    global shortcut aliases for frequently used programs or scripts.
    These aliases allow you to quickly launch the associated targets by name.

    Alias definitions are persistently stored in a YAML file located in the module
    directory. The function supports the following operations:

    1. add    - Add a new alias (automatically validates the target path; alias names
               support letters, numbers, and underscores)
    2. remove - Remove an existing alias (also removes the corresponding global function)
    3. search - Search aliases (supports fuzzy matching; results are aligned and formatted)
    4. update - Reload all aliases from the YAML file into global functions

.PARAMETER Action
    [Required] Specifies the operation to perform. Supported values:

        add    - Add a new alias (requires AliasName and ShortcutPath)
        remove - Remove an existing alias (requires AliasName)
        search - Search aliases (AliasName is optional; lists all aliases if omitted)
        update - Reload all aliases (no additional parameters required)

.PARAMETER AliasName
    [Optional] The alias name. Rules:

    - Only letters, numbers, and underscores are supported (to avoid parsing issues)
    - Required for add and remove operations
    - Supports fuzzy matching for search (e.g. "ed" matches "edge", "edit", etc.)
    - Not required for the update operation

.PARAMETER ShortcutPath
    [Optional] The full path to the program, script, or shortcut file.
    Required only for the add operation.

    The function automatically validates that the path exists and refers to a file
    (not a directory).

.EXAMPLE
    # Basic usage: add an alias (using the alias 'usa' is recommended)
    Use-ShortcutAlias add edge "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk"

    # Or simplified:
    usa add edge "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk"

.EXAMPLE
    # Remove an alias
    Use-ShortcutAlias remove edge

    # Or:
    usa remove edge

.EXAMPLE
    # Search aliases (fuzzy matching)
    Use-ShortcutAlias search ed

    # Or list all aliases:
    Use-ShortcutAlias search

.EXAMPLE
    # Reload all aliases from the YAML file
    Use-ShortcutAlias update

    # Or:
    usa update

.INPUTS
    None. This function does not accept pipeline input.

.OUTPUTS
    String. Operation result messages with colored output:

    - Success: green text
    - Failure / not found: red or yellow text
    - Detailed logs: available via the -Verbose parameter

.NOTES
    1. YAML configuration file path:
       <ModuleRoot>\shortcout_aliases.yaml
    2. Each alias is implemented as a global function and can be invoked directly
       from PowerShell.
    3. Module version: 0.1.0
    4. Compatible with PowerShell 5.1 and 7+.
       Requires the powershell-yaml module:
       Install-Module powershell-yaml -Scope CurrentUser -Force

.LINK
    https://github.com/viys/pwsh_shortcut_alias
#>

[CmdletBinding(DefaultParameterSetName = "Default")]
    [Alias("usa")]
    param (
        [Parameter(Position = 0, Mandatory)]
        [ValidateSet("add", "remove", "search", "update")]
        [string]$Action,

        [Parameter(Position = 1)]
        [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9_-]*$')]
        [string]$AliasName,

        [Parameter(Position = 2)]
        [ValidateScript({
            try {
                $uri = [Uri]$_
                if ($uri.Scheme -in 'http','https') {
                    return $true
                }
            } catch {}

            if (Test-Path $_) {
                return $true
            }

            return $false
        })]
        [string]$ShortcutPath
    )

    switch ($Action) {
        "add" {
            Add-ShortcutAlias -AliasName $AliasName -ShortcutPath $ShortcutPath
        }
        "remove" {
            Remove-ShortcutAlias -AliasName $AliasName
        }
        "search" {
            Search-ShortcutAlias -AliasName $AliasName
        }
        "update" {
            Update-ShortcutAlias
        }
    }
}
