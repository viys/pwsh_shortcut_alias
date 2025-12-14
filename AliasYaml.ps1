# aliases:
#   build:
#     path: ./scripts/build.ps1
#   flash:
#     path: ./scripts/flash.ps1
#   monitor:
#     path: ./scripts/monitor.ps1

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

        @"
aliases:
"@ | Set-Content -Path $Path -Encoding UTF8
    }
}

function Read-AliasYaml {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )

    Initialize-AliasYaml $Path

    $content = Get-Content $Path -Raw
    if (-not $content.Trim()) {
        return @{ aliases = @{} }
    }

    ConvertFrom-Yaml $content
}

# function Write-AliasYaml {
#     param (
#         [Parameter(Mandatory)]
#         [string]$Path,

#         [Parameter(Mandatory)]
#         [string]$Alias,

#         [Parameter(Mandatory)]
#         [string]$ShortcutPath
#     )

#     $yaml = $Alias | ConvertTo-Yaml
#     Set-Content -Path $Path -Value $yaml -Encoding UTF8
# }

function Write-AliasYaml {
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [hashtable]$Config
    )

    $yaml = $Config | ConvertTo-Yaml
    Set-Content -Path $Path -Value $yaml -Encoding UTF8
}


function Set-AliasEntry {
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$TargetPath,

        [string]$Description
    )

    $cfg = Read-AliasYaml $Path

    if (-not $cfg.aliases) {
        $cfg | Add-Member -MemberType NoteProperty -Name aliases -Value @{}
    }

    $entry = @{
        path = $TargetPath
    }

    if ($Description) {
        $entry.desc = $Description
    }

    $cfg.aliases[$Name] = $entry

    Write-AliasYaml $Path $cfg
}

function Remove-AliasEntry {
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Name
    )

    $cfg = Read-AliasYaml $Path

    if ($cfg.aliases -and $cfg.aliases.ContainsKey($Name)) {
        $cfg.aliases.Remove($Name)
        Write-AliasYaml $Path $cfg
    }
}
