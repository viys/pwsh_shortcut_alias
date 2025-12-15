# aliases:
#   typora:
#     path: "C:\Program Files\Typora\Typora.exe"
#   wechat:
#     path: "C:\Program Files (x86)\Tencent\WeChat\WeChat.exe"

Install-Module powershell-yaml -Scope CurrentUser
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

        @{
            aliases = @{}
        } | ConvertTo-Yaml | Set-Content -Path $Path -Encoding UTF8
    }
}

function Read-AliasYaml {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        return @{}
    }

    if (-not (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue)) {
        throw "ConvertFrom-Yaml not found. Use PowerShell 7+ or install powershell-yaml."
    }

    $data = Get-Content $Path -Raw | ConvertFrom-Yaml

    if (-not $data -or -not $data.aliases) {
        return @{}
    }

    $result = @{}

    foreach ($name in $data.aliases.Keys) {
        $entry = $data.aliases[$name]

        if ($entry.path) {
            $result[$name] = $entry.path
        }
    }

    return $result
}

function Write-AliasYaml {
    param (
        [Parameter(Mandatory)]
        [hashtable]$Data,

        [Parameter(Mandatory)]
        [string]$Path
    )

    $Data | ConvertTo-Yaml | Set-Content -Path $Path -Encoding UTF8
}

function Add-AliasPath {
    param (
        [Parameter(Mandatory)]
        [string]$Path,          # aliaspath.yaml

        [Parameter(Mandatory)]
        [string]$AliasName,     # build / flash / monitor

        [Parameter(Mandatory)]
        [string]$ShortcutPath  # ./scripts/build.ps1
    )

    Initialize-AliasYaml -Path $Path

    $data = Get-Content $Path -Raw | ConvertFrom-Yaml

    if (-not $data.aliases) {
        $data.aliases = @{}
    }

    # 核心语义：alias → path
    $data.aliases[$AliasName] = @{
        path = $ShortcutPath
    }

    Write-AliasYaml -Data $data -Path $Path
}

function Remove-AliasPath {
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$AliasName
    )

    if (-not (Test-Path $Path)) {
        return
    }

    if (-not (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue)) {
        throw "ConvertFrom-Yaml not found. Use PowerShell 7+ or install powershell-yaml."
    }

    $data = Get-Content $Path -Raw | ConvertFrom-Yaml

    if (-not $data -or -not $data.aliases) {
        return
    }

    if (-not $data.aliases.ContainsKey($AliasName)) {
        return
    }

    $data.aliases.Remove($AliasName) | Out-Null

    Write-AliasYaml -Data $data -Path $Path
}

Import-Module powershell-yaml -ErrorAction Stop
