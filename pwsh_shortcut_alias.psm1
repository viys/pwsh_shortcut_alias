$ModuleRoot = $PSScriptRoot
$YamlCfgPath = Join-Path $ModuleRoot 'shortcout_aliases.yaml'

# 加载私有实现
. "$ModuleRoot\Private\alias_yaml.ps1"

# 模块作用域启动入口：默认指向真实启动逻辑，测试时可在模块上下文内临时替换
$script:ShortcutAliasLaunchInvoker = {
    param (
        [Parameter(Mandatory)]
        [string]$Target
    )

    Invoke-ShortcutAliasLaunch -Target $Target
}

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

# 私有通用函数：统一解析别名目标，收敛 URL/本地路径判断和路径规范化规则
function Resolve-ShortcutAliasTarget {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$ShortcutPath,

        [Parameter()]
        [string]$AliasName = "",

        [Parameter()]
        [switch]$AllowUnresolvedLocalPath
    )

    $uri = $null
    if ([System.Uri]::TryCreate($ShortcutPath, [System.UriKind]::Absolute, [ref]$uri) -and $uri.Scheme -in 'http', 'https') {
        return [PSCustomObject]@{
            Name  = $AliasName
            Path  = $ShortcutPath
            IsUrl = $true
        }
    }

    if ($AllowUnresolvedLocalPath) {
        return [PSCustomObject]@{
            Name  = $AliasName
            Path  = $ShortcutPath
            IsUrl = $false
        }
    }

    $resolvedPath = Resolve-Path $ShortcutPath -ErrorAction Stop
    return [PSCustomObject]@{
        Name  = $AliasName
        Path  = $resolvedPath.Path
        IsUrl = $false
    }
}

# 私有通用函数：统一把 YAML 中的别名数据转换为阶段一约定的数据结构
function Get-ShortcutAliasRegistryEntries {
    [CmdletBinding()]
    param ()

    $aliases = Read-AliasYaml -Path $YamlCfgPath
    $entries = foreach ($name in $aliases.Keys) {
        Resolve-ShortcutAliasTarget -AliasName $name -ShortcutPath $aliases[$name] -AllowUnresolvedLocalPath
    }

    return @($entries)
}

# 私有通用函数：集中封装快捷别名的真实启动行为，避免系统调用散落在注册逻辑中
function Invoke-ShortcutAliasLaunch {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Target
    )

    Start-Process explorer.exe $Target
}

# 私有通用函数：统一构建搜索结果，分离搜索匹配和控制台展示职责
function Get-ShortcutAliasSearchResults {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$AliasName = "*"
    )

    $filter = "*$AliasName*"
    $entries = Get-ShortcutAliasRegistryEntries | Where-Object { $_.Name -like $filter }

    return @($entries)
}

function Use-ShortcutAlias {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [Alias("usa")] # 添加别名，方便快速调用
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
                Resolve-ShortcutAliasTarget -ShortcutPath $_ | Out-Null
                return $true
            }
            catch {
                return $false
            }
        })] # 提前验证路径存在
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
        [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9_-]*$')]
        [string]$AliasName,

        [Parameter(Mandatory)]
        [string]$ShortcutPath
    )

    Write-Verbose "Attempting to add alias '$AliasName' with path '$ShortcutPath'"

    try {
        $resolvedTarget = Resolve-ShortcutAliasTarget -AliasName $AliasName -ShortcutPath $ShortcutPath
        Add-AliasPath -Path $YamlCfgPath -AliasName $resolvedTarget.Name -ShortcutPath $resolvedTarget.Path
        Write-Host "Alias '$AliasName' added successfully -> $($resolvedTarget.Path)" -ForegroundColor Green
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

    try {
        $removed = Remove-AliasPath -Path $YamlCfgPath -AliasName $AliasName
        if (-not $removed) {
            Write-Host "Alias '$AliasName' not found" -ForegroundColor Red
            return
        }

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

    $searchResults = Get-ShortcutAliasSearchResults -AliasName $AliasName

    if (-not $searchResults) {
        Write-Host "No alias matching '$AliasName' found" -ForegroundColor Yellow
        return
    }

    return $searchResults
}

function Update-ShortcutAlias {
    [CmdletBinding()]
    param ()

    $entries = Get-ShortcutAliasRegistryEntries
    if (-not $entries) {
        Write-Verbose "No aliases found to update"
        return
    }

    $updatedCount = 0

    foreach ($entry in $entries) {
        $name = $entry.Name
        $target = $entry.Path

        # 只有非 URL 才做路径存在检查
        if (-not $entry.IsUrl -and -not (Test-Path $target)) {
            Write-Warning "Target path not found for alias '$name': $target"
            continue
        }

        try {
            $launchInvoker = $script:ShortcutAliasLaunchInvoker
            $scriptBlock = {
                & $launchInvoker -Target $target
            }.GetNewClosure()

            Set-Item -Path "Function:\Global:$name" -Value $scriptBlock -ErrorAction Stop
            Write-Verbose "Updated $name -> $target"
            $updatedCount++
        }
        catch {
            Write-Warning "Failed to update alias '$name': $($_.Exception.Message)"
        }
    }

    Write-Host "Updated $updatedCount/$($entries.Count) aliases successfully" -ForegroundColor Green
}

Export-ModuleMember -Function Use-ShortcutAlias -Alias usa
