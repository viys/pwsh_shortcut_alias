<#
.SYNOPSIS
    Build script for pwsh_shortcut_alias module - Install/Uninstall

.DESCRIPTION
    Manages installation and uninstallation of the pwsh_shortcut_alias module,
    including dependency installation, profile injection, and cleanup.
#>

param (
    [Parameter(Position = 0, Mandatory)]
    [ValidateSet("install", "uninstall")]
    [string]$Action
)

# --------------------------
# Constant Definitions
# --------------------------
$ModuleName = "pwsh_shortcut_alias"
$RequiredModules = @('powershell-yaml')
$ProfileMarkerStart = "### pwsh_shortcut_alias_start"
$ProfileMarkerEnd   = "### pwsh_shortcut_alias_end"

$ProfileContent = @'
### pwsh_shortcut_alias_start
if (-not (Get-Command Use-ShortcutAlias -ErrorAction SilentlyContinue)) {
    Import-Module pwsh_shortcut_alias -ErrorAction Stop
}

Use-ShortcutAlias update 6> $null
### pwsh_shortcut_alias_end
'@.Trim()

# --------------------------
# Helper Functions
# --------------------------
function Test-PSRepositoryTrusted {
    [CmdletBinding()]
    param ([string]$RepositoryName = "PSGallery")

    $repo = Get-PSRepository -Name $RepositoryName -ErrorAction SilentlyContinue
    if (-not $repo) {
        Write-Warning "Repository $RepositoryName not found, registering..."
        Register-PSRepository `
            -Name $RepositoryName `
            -SourceLocation "https://www.powershellgallery.com/api/v2/" `
            -InstallationPolicy Trusted
        return $true
    }

    return $repo.InstallationPolicy -eq "Trusted"
}

function Install-RequiredModule {
    [CmdletBinding()]
    param ([string]$ModuleName)

    if (Get-Module -Name $ModuleName -ListAvailable) {
        Write-Host "✅ Module $ModuleName is already installed" -ForegroundColor Green
        Import-Module -Name $ModuleName -Force -ErrorAction SilentlyContinue
        return $true
    }

    if (-not (Test-PSRepositoryTrusted)) {
        Write-Host "🔒 Setting PSGallery as trusted repository" -ForegroundColor Cyan
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction Stop
    }

    try {
        Write-Host "📦 Installing required module: $ModuleName" -ForegroundColor Cyan
        Install-Module `
            -Name $ModuleName `
            -Scope CurrentUser `
            -Repository PSGallery `
            -Force `
            -ErrorAction Stop

        Import-Module -Name $ModuleName -Force -ErrorAction Stop
        Write-Host "✅ Successfully installed $ModuleName" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "❌ Failed to install $ModuleName : $($_.Exception.Message)"
        return $false
    }
}

function Update-ProfileContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateSet("add", "remove")]
        [string]$Operation,

        [string]$Content,
        [string]$StartMarker,
        [string]$EndMarker
    )

    # Profile directory must exist (created earlier in install)
    $profileDir = Split-Path $PROFILE -Parent
    if (-not (Test-Path $profileDir)) {
        Write-Error "❌ Invalid profile directory: $profileDir"
        return $false
    }

    if (-not (Test-Path $PROFILE)) {
        Write-Host "📄 Creating PowerShell profile at $PROFILE" -ForegroundColor Cyan
        New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    }

    $profileContent = Get-Content -Path $PROFILE -Raw -Encoding UTF8 -ErrorAction Stop

    switch ($Operation) {
        "add" {
            if ($profileContent -match [regex]::Escape($StartMarker) -and
                $profileContent -match [regex]::Escape($EndMarker)) {

                Write-Warning "⚠️ $ModuleName already exists in profile, updating"
                $profileContent = $profileContent -replace `
                    "(?ms)$([regex]::Escape($StartMarker)).*?$([regex]::Escape($EndMarker))",
                    $Content
            }
            else {
                $profileContent += "`n$Content"
            }
        }

        "remove" {
            if (-not ($profileContent -match [regex]::Escape($StartMarker))) {
                Write-Warning "⚠️ $ModuleName not found in profile, nothing to remove"
                return $true
            }

            $profileContent = $profileContent -replace `
                "(?ms)$([regex]::Escape($StartMarker)).*?$([regex]::Escape($EndMarker))",
                ""

            $profileContent = $profileContent -replace "`n+", "`n" -replace "`n$", ""
        }
    }

    try {
        Set-Content -Path $PROFILE -Value $profileContent -Encoding UTF8NoBOM -Force
        Write-Host "✅ Profile updated successfully" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "❌ Failed to update profile: $($_.Exception.Message)"
        return $false
    }
}

# --------------------------
# Main Execution
# --------------------------
try {
    switch ($Action) {

        "install" {
            Write-Host "`n🚀 Starting $ModuleName installation`n" -ForegroundColor Cyan

            # Ensure profile directory and file exist
            $profileDir = Split-Path $PROFILE -Parent
            if (-not (Test-Path $profileDir)) {
                New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
            }

            if (-not (Test-Path $PROFILE)) {
                New-Item -ItemType File -Path $PROFILE -Force | Out-Null
            }

            # Install dependencies
            foreach ($module in $RequiredModules) {
                if (-not (Install-RequiredModule -ModuleName $module)) {
                    throw "Required module install failed: $module"
                }
            }

            # Module destination
            $moduleRoot = Join-Path $profileDir "Modules"
            $moduleDest = Join-Path $moduleRoot $ModuleName

            New-Item -ItemType Directory -Path $moduleDest -Force | Out-Null
            Write-Host "📂 Module destination: $moduleDest" -ForegroundColor Gray

            # Copy files
            Write-Host "📤 Copying module files..." -ForegroundColor Cyan
            $excludeItems = @('.git', '.gitignore', 'shortcut_aliases.yaml', 'build.ps1', 'LICENSE', 'README.md')
            Copy-Item -Path ".\*" -Destination $moduleDest -Recurse -Force -Exclude $excludeItems

            # Reload module
            if (Get-Module $ModuleName -ErrorAction SilentlyContinue) {
                Remove-Module $ModuleName -Force -ErrorAction SilentlyContinue
            }

            $moduleManifest = Join-Path $moduleDest "$ModuleName.psd1"
            if (-not (Test-Path $moduleManifest)) {
                throw "Module manifest not found: $moduleManifest"
            }

            Import-Module $moduleManifest -Force -ErrorAction Stop

            # Update profile
            Write-Host "📝 Updating PowerShell profile" -ForegroundColor Cyan
            if (-not (Update-ProfileContent -Operation add `
                    -Content $ProfileContent `
                    -StartMarker $ProfileMarkerStart `
                    -EndMarker $ProfileMarkerEnd)) {
                throw "Profile update failed"
            }

            if (-not (Get-Command Use-ShortcutAlias -ErrorAction SilentlyContinue)) {
                throw "Command Use-ShortcutAlias not found after install"
            }

            Write-Host "`n🎉 $ModuleName installed successfully!" -ForegroundColor Green
            Write-Host "💡 Restart PowerShell or run: . `"$PROFILE`"`n" -ForegroundColor Yellow
        }

        "uninstall" {
            Write-Host "`n🗑️ Starting $ModuleName uninstallation`n" -ForegroundColor Cyan

            Update-ProfileContent `
                -Operation remove `
                -Content $ProfileContent `
                -StartMarker $ProfileMarkerStart `
                -EndMarker $ProfileMarkerEnd | Out-Null

            if (Get-Module $ModuleName -ErrorAction SilentlyContinue) {
                Remove-Module $ModuleName -Force -ErrorAction SilentlyContinue
            }

            $moduleDir = Join-Path (Join-Path (Split-Path $PROFILE -Parent) "Modules") $ModuleName
            if (Test-Path $moduleDir) {
                Remove-Item -Path $moduleDir -Recurse -Force -ErrorAction SilentlyContinue
            }

            Write-Host "`n✅ $ModuleName uninstalled successfully!" -ForegroundColor Green
            Write-Host "💡 Restart PowerShell to apply changes`n" -ForegroundColor Yellow
        }
    }
}
catch {
    Write-Error "`n❌ $Action failed: $($_.Exception.Message)`n"
    exit 1
}
