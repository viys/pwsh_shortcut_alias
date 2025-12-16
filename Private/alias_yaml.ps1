# aliases:
#   typora:
#     path: "C:\Program Files\Typora\Typora.exe"
#   wechat:
#     path: "C:\Program Files (x86)\Tencent\WeChat\WeChat.exe"

# 全局模块导入：优化重复导入+失败处理
if (-not (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue)) {
    try {
        Import-Module powershell-yaml -ErrorAction Stop
        Write-Verbose "成功导入 powershell-yaml 模块"
    }
    catch {
        throw "导入 powershell-yaml 模块失败，请先执行：Install-Module powershell-yaml -Scope CurrentUser -Force"
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
        Write-Verbose "初始化 YAML 配置文件：$Path"
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
        throw "解析 YAML 文件失败：$Path`n错误详情：$_"
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
        Write-Verbose "成功写入 YAML 配置文件：$Path"
    }
    catch {
        throw "写入 YAML 文件失败：$Path`n错误详情：$_"
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
        throw "读取配置文件失败：$Path`n错误详情：$_"
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
        Write-Verbose "配置文件不存在：$Path，无需删除别名" -ForegroundColor Yellow
        return
    }

    try {
        # 读取YAML（有序）
        $data = Get-Content $Path -Raw | ConvertFrom-Yaml -Ordered
    }
    catch {
        throw "读取配置文件失败：$Path`n错误详情：$_"
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

    # 5. 执行删除/提示
    if ($aliasExists) {
        $data.aliases.Remove($AliasName) | Out-Null
        Write-AliasYaml -Data $data -Path $Path
        Write-Verbose "Alias '$AliasName' removed successfully"
    } else {
        Write-Verbose "Alias '$AliasName' does not exist"
    }
}