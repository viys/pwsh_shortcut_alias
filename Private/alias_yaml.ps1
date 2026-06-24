# aliases:
#   typora:
#     path: "C:\Program Files\Typora\Typora.exe"
#   wechat:
#     path: "C:\Program Files (x86)\Tencent\WeChat\WeChat.exe"

# Import the YAML module if its commands are not already available
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
        # Keep -Ordered so the read result preserves key order
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
        # Defensive guard in case an entry is missing or malformed
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

    # Build an ordered hashtable whose nested keys are sorted ascending
    $sortedOrderedData = [ordered]@{}
    foreach ($topKey in $Data.Keys) {
        $topValue = $Data[$topKey]

        if ($topValue -is [hashtable] -or $topValue -is [System.Collections.Specialized.OrderedDictionary]) {
            $sortedAlias = [ordered]@{}
            # Sort alias keys in ascending order before writing them back
            $topValue.GetEnumerator() | Sort-Object -Property Key | ForEach-Object {
                $sortedAlias[$_.Key] = $_.Value
            }
            $sortedOrderedData[$topKey] = $sortedAlias
        }
        else {
            $sortedOrderedData[$topKey] = $topValue
        }
    }

    # No -Ordered switch here; rely on the ordered hashtable to preserve output order
    try {
        $sortedOrderedData | ConvertTo-Yaml | Set-Content -Path $Path -Encoding UTF8 -Force
        Write-Verbose "Successfully wrote to YAML configuration file: $Path"
    }
    catch {
        throw "Failed to write to YAML file: $Path`nError details: $_"
    }
}

# Private helper: read a writable YAML document and ensure the aliases node always exists
function Read-AliasYamlDocument {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )

    Initialize-AliasYaml -Path $Path

    try {
        $data = Get-Content $Path -Raw | ConvertFrom-Yaml -Ordered
    }
    catch {
        throw "Failed to read configuration file: $Path`nError details: $_"
    }

    if (-not $data) {
        $data = [ordered]@{ aliases = [ordered]@{} }
    }
    if (-not $data.aliases) {
        $data.aliases = [ordered]@{}
    }

    return $data
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

    $data = Read-AliasYamlDocument -Path $Path

    # Store the alias under the aliases node using the normalized path
    $data.aliases[$AliasName] = [ordered]@{
        path = $ShortcutPath
    }

    # Persist the updated document
    Write-AliasYaml -Data $data -Path $Path
}

function Remove-AliasPath {
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$AliasName
    )

    # Exit early if the configuration file does not exist
    if (-not (Test-Path $Path)) {
        Write-Verbose "Configuration file does not exist: $Path, no need to remove alias"
        return $false
    }

    $data = Read-AliasYamlDocument -Path $Path

    # Check whether the alias exists in the current document
    $aliasExists = $false
    if ($data.aliases -is [System.Collections.Specialized.OrderedDictionary]) {
        # OrderedDictionary uses Contains
        $aliasExists = $data.aliases.Contains($AliasName)
    }
    elseif ($data.aliases -is [hashtable]) {
        # Hashtable uses ContainsKey
        $aliasExists = $data.aliases.ContainsKey($AliasName)
    }

    # Remove and persist only when the alias exists
    if ($aliasExists) {
        $data.aliases.Remove($AliasName) | Out-Null
        Write-AliasYaml -Data $data -Path $Path
        Write-Verbose "Alias '$AliasName' removed successfully"
        return $true
    } else {
        Write-Verbose "Alias '$AliasName' does not exist"
        return $false
    }
}
