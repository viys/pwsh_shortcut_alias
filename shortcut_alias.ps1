param (
    [Parameter(
        Position = 0,
        Mandatory
    )]
    [ValidateSet("add", "remove", "list", "switch", "search", "update")]
    [string]$Action,

    [Parameter(Position = 1)]
    [string]$AliasName,

    [Parameter(Position = 2)]
    [string]$ShortcutPath
)

. .\AliasYaml.ps1

$YamlCfgPath = ".\shortcout_aliases.yaml"

Initialize-AliasYaml -Path $YamlCfgPath

# function Use-ShortcutAlias {
# }

function Add-ShortcutAlias {
    param (
        [Parameter(Mandatory)]
        $AliasName,

        [Parameter(Mandatory)]
        $ShortcutPath
    )

    Write-Verbose -Message "Attempting to add alias $AliasName with shortcut path $ShortcutPath"

    if (Test-Path -Path $ShortcutPath) {
        $ShortcutPath = Resolve-Path $ShortcutPath
        Add-AliasPath -Path $YamlCfgPath -AliasName $AliasName -ShortcutPath $ShortcutPath
    } else {
        Write-Host -Message "$ShortcutPath does not exist" -ForegroundColor Red
    }

}

function Remove-ShortcutAlias {
    param (
        [Parameter(Mandatory)]
        $AliasName
    )
}

function Search-ShortcutAlias {
    param (
        [Parameter(Mandatory)]
        $AliasName
    )
}

function Show-ShortcutAlias {
    param (
        [Parameter(Mandatory)]
        $AliasName
    )
}

function Update-ShortcutAlias {
    # 没有参数时，重新加载 pwsh 的 profile 文件
    param (
        $AliasName,
        $ShortcutPath
    )

    $aliases = Read-AliasYaml -Path $YamlCfgPath

    foreach ($name in $aliases.Keys) {
        $target = $aliases[$name]
        if (-not (Test-Path $target)) {
            Write-Warning "Target not found: $target"
            continue
        }
        $fullPath = (Resolve-Path $target).Path
        Write-Host -Message "$name -> $fullPath"

        Set-Alias -Name $name -Value $fullPath
    }
}

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
    "switch" {
        Switch-ShortcutAlias -AliasName $AliasName
    }
    "search" {
        Search-ShortcutAlias -AliasName $AliasName
    }
    "update" {
        Update-ShortcutAlias
    }
    Default {}
}

Update-ShortcutAlias -Path $YamlCfgPath
