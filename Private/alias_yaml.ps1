# aliases:
#   typora:
#     path: "C:\Program Files\Typora\Typora.exe"
#   wechat:
#     path: "C:\Program Files (x86)\Tencent\WeChat\WeChat.exe"

# 全局模块导入
if (-not (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue)) {
    try {
        Import-Module powershell-yaml -ErrorAction Stop
        Write-Verbose "Successfully imported powershell-yaml module"
    }
    catch {
        throw "Failed to import powershell-yaml module. Please run: Install-Module powershell-yaml -Scope CurrentUser -Force"
    }
}

function Initialize-AliasYaml {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        $dir = Split-Path $Path -Parent
        if ($dir -and -not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }

        [ordered]@{
            aliases = [ordered]@{}
        } | ConvertTo-Yaml | Set-Content -Path $Path -Encoding UTF8
        Write-Verbose "Initialized YAML configuration file: $Path"
    }
}

function Read-AliasYaml {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        return [ordered]@{}
    }

    try {
        # 保留：-Ordered 保证读取有序
        $data = Get-Content $Path -Raw | ConvertFrom-Yaml -Ordered
    }
    catch {
        throw "Failed to parse YAML file: $Path`nError details: $_"
    }

    if (-not $data -or -not $data.aliases) {
        return [ordered]@{}
    }

    $result = [ordered]@{}

    foreach ($name in $data.aliases.Keys) {
        $entry = $data.aliases[$name]
        # 防御性判断：避免 $entry 为空导致报错
        if ($entry -and $entry.path) {
            $result[$name] = $entry.path
        }
    }

    return $result
}

function Write-AliasYaml {
    param (
        [Parameter(Mandatory)]
        [object]$Data,

        [Parameter(Mandatory)]
        [string]$Path
    )

    # 构建「按 Key 升序排列」的有序哈希表
    $sortedOrderedData = [ordered]@{}
    foreach ($topKey in $Data.Keys) {
        $topValue = $Data[$topKey]

        if ($topValue -is [hashtable] -or $topValue -is [System.Collections.Specialized.OrderedDictionary]) {
            $sortedAlias = [ordered]@{}
            # 按别名 Key 升序排序
            $topValue.GetEnumerator() | Sort-Object -Property Key | ForEach-Object {
                $sortedAlias[$_.Key] = $_.Value
            }
            $sortedOrderedData[$topKey] = $sortedAlias
        }
        else {
            $sortedOrderedData[$topKey] = $topValue
        }
    }

    # 保留：无 -Ordered，依赖有序哈希表保序
    try {
        $sortedOrderedData | ConvertTo-Yaml | Set-Content -Path $Path -Encoding UTF8 -Force
        Write-Verbose "Successfully wrote to YAML configuration file: $Path"
    }
    catch {
        throw "Failed to write to YAML file: $Path`nError details: $_"
    }
}

function Add-AliasPath {
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$AliasName,

        [Parameter(Mandatory)]
        [string]$ShortcutPath
    )

    # 初始化配置文件（确保文件存在）
    Initialize-AliasYaml -Path $Path

    try {
        $data = Get-Content $Path -Raw | ConvertFrom-Yaml -Ordered
    }
    catch {
        throw "Failed to read configuration file: $Path`nError details: $_"
    }

    # 修复5：处理 $data 为空的极端情况
    if (-not $data) {
        $data = [ordered]@{ aliases = [ordered]@{} }
    }
    if (-not $data.aliases) {
        $data.aliases = [ordered]@{}
    }

    # 将 $AliasName 映射到 $ShortcutPath，存入 aliases 节点下
    $data.aliases[$AliasName] = [ordered]@{
        path = $ShortcutPath
    }

    # 写入文件
    Write-AliasYaml -Data $data -Path $Path
}

function Remove-AliasPath {
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$AliasName
    )

    # 检查文件是否存在
    if (-not (Test-Path $Path)) {
        Write-Verbose "Configuration file does not exist: $Path, no need to remove alias" -ForegroundColor Yellow
        return
    }

    try {
        # 读取YAML（有序）
        $data = Get-Content $Path -Raw | ConvertFrom-Yaml -Ordered
    }
    catch {
        throw "Failed to read configuration file: $Path`nError details: $_"
    }

    # 检查aliases节点是否存在
    if (-not $data -or -not $data.aliases) {
        Write-Verbose "Alias '$AliasName' does not exist"
        return
    }

    # 检查别名是否存在
    $aliasExists = $false
    if ($data.aliases -is [System.Collections.Specialized.OrderedDictionary]) {
        # 有序哈希表：用Contains方法
        $aliasExists = $data.aliases.Contains($AliasName)
    }
    elseif ($data.aliases -is [hashtable]) {
        # 普通哈希表：用ContainsKey方法
        $aliasExists = $data.aliases.ContainsKey($AliasName)
    }

    # 执行删除
    if ($aliasExists) {
        $data.aliases.Remove($AliasName) | Out-Null
        Write-AliasYaml -Data $data -Path $Path
        Write-Verbose "Alias '$AliasName' removed successfully"
    } else {
        Write-Verbose "Alias '$AliasName' does not exist"
    }
}
