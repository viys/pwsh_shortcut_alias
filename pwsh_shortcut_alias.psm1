$ModuleRoot = $PSScriptRoot
$YamlCfgPath = Join-Path $ModuleRoot 'shortcout_aliases.yaml'

# Load private implementation helpers
. "$ModuleRoot\Private\alias_yaml.ps1"

# Module-scope launch entry point. Tests can temporarily replace this script block.
$script:ShortcutAliasLaunchInvoker = {
    param (
        [Parameter(Mandatory)]
        [string]$Target
    )

    Invoke-ShortcutAliasLaunch -Target $Target
}

# Private helper: check whether a key exists in either OrderedDictionary or Hashtable
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

# Private helper: resolve alias targets and centralize URL and local path normalization
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

# Private helper: convert YAML alias data into the shared runtime entry shape
function Get-ShortcutAliasRegistryEntries {
    [CmdletBinding()]
    param ()

    $aliases = Read-AliasYaml -Path $YamlCfgPath
    $entries = foreach ($name in $aliases.Keys) {
        Resolve-ShortcutAliasTarget -AliasName $name -ShortcutPath $aliases[$name] -AllowUnresolvedLocalPath
    }

    return @($entries)
}

# Private helper: isolate the actual alias launch behavior from registration logic
function Invoke-ShortcutAliasLaunch {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Target
    )

    Start-Process explorer.exe $Target
}

# Private helper: build search results separately from any console presentation concerns
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
    [Alias("usa")] # Short alias for interactive use
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
        })] # Validate the target early
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

        # Remove the corresponding global function as well
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
        [string]$AliasName = "*" # Fuzzy match everything by default
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

        # Only validate local path existence for non-URL targets
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
