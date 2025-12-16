$ModuleRoot = $PSScriptRoot
$YamlCfgPath = Join-Path $ModuleRoot 'shortcout_aliases.yaml'

# 加载私有实现
. "$ModuleRoot\Private\alias_yaml.ps1"

# 私有通用函数：判断键是否存在（兼容OrderedDictionary/Hashtable）
function Test-AliasKeyExists {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$Dictionary,

        [Parameter(Mandatory)]
        [string]$Key
    )
    process {
        if ($Dictionary -is [System.Collections.Specialized.OrderedDictionary]) {
            return $Dictionary.Contains($Key)
        }
        elseif ($Dictionary -is [hashtable]) {
            return $Dictionary.ContainsKey($Key)
        }
        return $false
    }
}

# 私有通用函数：格式化别名输出（复用逻辑）
function Format-AliasOutput {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object]$Aliases,

        [Parameter()]
        [string]$Filter = "*"
    )
    $matchingKeys = $Aliases.Keys | Where-Object { $_ -like $Filter }
    if (-not $matchingKeys) { return $null }

    $maxKeyLength = ($matchingKeys | Measure-Object -Property Length -Maximum).Maximum
    foreach ($key in $matchingKeys) {
        $spaceCount = $maxKeyLength - $key.Length + 2
        [PSCustomObject]@{
            Name    = $key
            Spaces  = " " * $spaceCount
            Path    = $Aliases[$key]
            MaxLength = $maxKeyLength
        }
    }
}

function Use-ShortcutAlias {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [Alias("usa")] # 添加别名，方便快速调用
    param (
        [Parameter(Position = 0, Mandatory)]
        [ValidateSet("add", "remove", "search", "update")]
        [string]$Action,

        [Parameter(Position = 1)]
        [ValidatePattern('^[a-zA-Z0-9_]+$')] # 限制别名仅含字母/数字/下划线
        [string]$AliasName,

        [Parameter(Position = 2)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })] # 提前验证路径存在
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

function Add-ShortcutAlias {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidatePattern('^[a-zA-Z0-9_]+$')]
        [string]$AliasName,

        [Parameter(Mandatory)]
        [string]$ShortcutPath
    )

    Write-Verbose "Attempting to add alias '$AliasName' with path '$ShortcutPath'"

    try {
        $resolvedPath = Resolve-Path $ShortcutPath -ErrorAction Stop
        Add-AliasPath -Path $YamlCfgPath -AliasName $AliasName -ShortcutPath $resolvedPath.Path
        Write-Host "Alias '$AliasName' added successfully -> $($resolvedPath.Path)" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to add alias: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Remove-ShortcutAlias {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$AliasName
    )

    $aliases = Read-AliasYaml -Path $YamlCfgPath
    if (-not (Test-AliasKeyExists -Dictionary $aliases -Key $AliasName)) {
        Write-Host "Alias '$AliasName' not found" -ForegroundColor Red
        return
    }

    try {
        Remove-AliasPath -Path $YamlCfgPath -AliasName $AliasName

        # 同步移除全局函数
        $funcPath = "Function:\Global:$AliasName"
        if (Test-Path $funcPath) {
            Remove-Item -Path $funcPath -ErrorAction Stop
            Write-Verbose "Removed global function: $AliasName"
        }

        Write-Host "Alias '$AliasName' removed successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to remove alias: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Search-ShortcutAlias {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [string]$AliasName = "*" # 默认模糊匹配所有
    )

    $aliases = Read-AliasYaml -Path $YamlCfgPath
    $formattedOutput = Format-AliasOutput -Aliases $aliases -Filter "*$AliasName*"

    if (-not $formattedOutput) {
        Write-Host "No alias matching '$AliasName' found" -ForegroundColor Yellow
        return
    }

    # 统一输出格式
    foreach ($item in $formattedOutput) {
        Write-Host "$($item.Name)$($item.Spaces)" -ForegroundColor Green -NoNewline
        Write-Host "-> " -ForegroundColor DarkGray -NoNewline
        Write-Host $item.Path
    }
}

function Update-ShortcutAlias {
    [CmdletBinding()]
    param ()

    $aliases = Read-AliasYaml -Path $YamlCfgPath
    if (-not $aliases.Keys) {
        Write-Verbose "No aliases found to update"
        return
    }

    $formattedOutput = Format-AliasOutput -Aliases $aliases
    $updatedCount = 0

    foreach ($item in $formattedOutput) {
        $name = $item.Name
        $target = $item.Path

        if (-not (Test-Path $target)) {
            Write-Warning "Target path not found for alias '$name': $target"
            continue
        }

        try {
            $fullPath = (Resolve-Path $target).Path

            $scriptBlock = {
                param($args)
                explorer.exe $args[0]
            }.GetNewClosure()

            Set-Item -Path "Function:\Global:$name" -Value $scriptBlock -ErrorAction Stop
            Write-Verbose "Updated $name -> $fullPath"
            $updatedCount++
        }
        catch {
            Write-Warning "Failed to update alias '$name': $($_.Exception.Message)"
        }
    }

    Write-Host "Updated $updatedCount/$($aliases.Keys.Count) aliases successfully" -ForegroundColor Green
}

Export-ModuleMember -Function Use-ShortcutAlias -Alias usa
