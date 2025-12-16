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

        # 读取 YAML，获取顶层的 aliases 节点
        $yamlContent = Get-Content -Path $YamlCfgPath -Raw | ConvertFrom-Yaml
        $aliases = $yamlContent.aliases  # 取出 aliases 下的所有别名（哈希表）

        # 按 Key 升序排序，转为有序哈希表
        $sortedAliases = $aliases.GetEnumerator() | Sort-Object -Property Key
        $sortedHash = [ordered]@{}
        foreach ($item in $sortedAliases) {
            # 保留 path 字段
            $sortedHash[$item.Key] = $item.Value
        }

        # 重新构建 YAML 结构并写入文件
        $yamlContent.aliases = $sortedHash  # 替换为排序后的 aliases
        $yamlContent | ConvertTo-Yaml | Out-File -Path $YamlCfgPath -Encoding utf8
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

    # 不带参数，列出全部
    if (-not $AliasName) {
        # 获取所有key的最大长度（核心基准）
        $maxKeyLength = ($aliases.Keys | Measure-Object -Property Length -Maximum).Maximum

        foreach ($key in $aliases.Keys) {
            # 计算需要补充的空格数：最大长度 - 当前key长度 + 2（额外留2个空格间距）
            $spaceCount = $maxKeyLength - $key.Length + 2
            # 生成空格字符串（彻底替代Tab）
            $spaces = " " * $spaceCount

            # 输出：key + 补齐空格 + -> + 路径
            Write-Host "$key$spaces" -ForegroundColor Green -NoNewline
            Write-Host "-> " -ForegroundColor DarkGray -NoNewline
            Write-Host "$($aliases[$key])"
        }
        return
    }

    # 支持模糊搜索
    $found = $false
    $matchingKeys = $aliases.Keys | Where-Object { $_ -like "*$AliasName*" }
    if ($matchingKeys) {
        $maxKeyLength = ($matchingKeys | Measure-Object -Property Length -Maximum).Maximum

        foreach ($key in $matchingKeys) {
            $spaceCount = $maxKeyLength - $key.Length + 2
            $spaces = " " * $spaceCount

            Write-Host "$key$spaces" -ForegroundColor Green -NoNewline
            Write-Host "-> " -ForegroundColor DarkGray -NoNewline
            Write-Host "$($aliases[$key])"
            $found = $true
        }
    }

    if (-not $found) {
        Write-Host "No alias matching '$AliasName' found" -ForegroundColor Yellow
    }
}

function Update-ShortcutAlias {
    $aliases = Read-AliasYaml -Path $YamlCfgPath

    # 获取所有别名的最大长度（用于对齐）
    $maxNameLength = ($aliases.Keys | Measure-Object -Property Length -Maximum).Maximum

    foreach ($name in $aliases.Keys) {
        $target = $aliases[$name]
        if (-not (Test-Path $target)) {
            Write-Warning "Target not found: $target"
            continue
        }
        $fullPath = (Resolve-Path $target).Path

        # 计算空格并补齐并输出
        $spaces = " " * ($maxNameLength - $name.Length + 2)
        Write-Verbose -Message "$name$spaces-> $fullPath"

        $path = $fullPath  # 冻结当前循环的值

        $sb = {
            param($args)
            # Start-Process $path -ArgumentList $args
            explorer.exe $path
        }.GetNewClosure()

        Set-Item -Path "Function:\Global:$name" -Value $sb
    }
}

Export-ModuleMember -Function Use-ShortcutAlias
