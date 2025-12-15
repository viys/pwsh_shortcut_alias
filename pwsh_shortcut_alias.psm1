$ModuleRoot = $PSScriptRoot

# 加载私有实现
. "$ModuleRoot\Private\alias_yaml.ps1"

# 模块级配置（绝对路径）
$YamlCfgPath = Join-Path $ModuleRoot 'shortcout_aliases.yaml'

function Use-ShortcutAlias {
    param (
        [Parameter(
            Position = 0,
            Mandatory
        )]
        [ValidateSet("add", "remove", "search", "update")]
        [string]$Action,

        [Parameter(Position = 1)]
        [string]$AliasName,

        [Parameter(Position = 2)]
        [string]$ShortcutPath
    )

    Initialize-AliasYaml -Path $YamlCfgPath

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
            Update-ShortcutAlias -Path $YamlCfgPath
        }
        Default {}
    }
}

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
    # 必须严格按照存储的 AliasName 删除，如果没有查询到则提示错误
    param (
        [Parameter(Mandatory)]
        [string]$AliasName
    )

    $aliases = Read-AliasYaml -Path $YamlCfgPath

    if (-not $aliases.ContainsKey($AliasName)) {
        Write-Host "Alias '$AliasName' not found" -ForegroundColor Red
        return
    }

    Remove-AliasPath -Path $YamlCfgPath -AliasName $AliasName
    # 同步移除全局函数
    if (Get-Command $AliasName -ErrorAction SilentlyContinue) {
        Remove-Item -Path "Function:\Global:$AliasName"
    }

    Write-Host "Alias '$AliasName' removed successfully" -ForegroundColor Green
}

function Search-ShortcutAlias {
    # 当 AliasName 为空时，列出所有别名，支持模糊搜索
    param (
        [string]$AliasName
    )

    $aliases = Read-AliasYaml -Path $YamlCfgPath

    if (-not $AliasName) {
        # 不带参数，列出全部
        foreach ($key in $aliases.Keys) {
            Write-Host "$key -> $($aliases[$key])"
        }
        return
    }

    # 支持模糊搜索
    $found = $false
    foreach ($key in $aliases.Keys) {
        if ($key -like "*$AliasName*") {
            Write-Host "$key -> $($aliases[$key])"
            $found = $true
        }
    }

    if (-not $found) {
        Write-Host "No alias matching '$AliasName' found" -ForegroundColor Yellow
    }
}

function Update-ShortcutAlias {
    $aliases = Read-AliasYaml -Path $YamlCfgPath

    foreach ($name in $aliases.Keys) {
        $target = $aliases[$name]
        if (-not (Test-Path $target)) {
            Write-Warning "Target not found: $target"
            continue
        }
        $fullPath = (Resolve-Path $target).Path
        Write-Verbose -Message "$name -> $fullPath"

        $path = $fullPath  # 冻结当前循环的值

        $sb = {
            param($args)
            Start-Process $path -ArgumentList $args
        }.GetNewClosure()

        Set-Item -Path "Function:\Global:$name" -Value $sb
    }
}

Export-ModuleMember -Function Use-ShortcutAlias
