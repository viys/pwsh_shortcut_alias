function Use-ShortcutAlias {
    param (
        [Parameter(
            Position = 0,
            Mandatory
        )]
        [ValidateSet("add", "remove", "list", "search", "update")]
        [string]$Action,

        [Parameter(Position = 1)]
        [string]$AliasName,

        [Parameter(Position = 2)]
        [string]$ShortcutPath
    )

    switch ($Action) {
        "add" {
            Add-ShortcutAlias -AliasName $AliasName -ShortcutPath $ShortcutPath
        }
        "remove" {
            Remove-ShortcutAlias -AliasName $AliasName
        }
        "list" {
            Show-ShortcutAlias -AliasName $AliasName
        }
        "search" {
            Search-ShortcutAlias -AliasName $AliasName
        }
        "update" {
            Update-ShortcutAlias -Path $YamlCfgPath
        }
        Default {}
    }
}
