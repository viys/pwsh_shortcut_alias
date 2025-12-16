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
$ProfileMarkerEnd = "### pwsh_shortcut_alias_end"
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
        Register-PSRepository -Name $RepositoryName -SourceLocation "https://www.powershellgallery.com/api/v2/" -InstallationPolicy Trusted
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

    # Ensure PSGallery is trusted
    if (-not (Test-PSRepositoryTrusted)) {
        Write-Host "🔒 Setting PSGallery as trusted repository" -ForegroundColor Cyan
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction Stop
    }

    try {
        Write-Host "📦 Installing required module: $ModuleName" -ForegroundColor Cyan
        Install-Module -Name $ModuleName -Scope CurrentUser -Repository PSGallery -Force -ErrorAction Stop
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

    # Validate profile path
    if (-not $PROFILE -or -not (Test-Path (Split-Path $PROFILE -Parent) -ErrorAction SilentlyContinue)) {
        Write-Error "❌ Invalid profile path: $PROFILE"
        return $false
    }

    # Create profile if not exists
    if (-not (Test-Path $PROFILE)) {
        Write-Host "📄 Creating PowerShell profile at $PROFILE" -ForegroundColor Cyan
        New-Item -ItemType File -Path $PROFILE -Force -Encoding UTF8NoBOM -ErrorAction Stop | Out-Null
    }

    # Read profile content (handle encoding)
    $profileContent = Get-Content -Path $PROFILE -Raw -Encoding UTF8 -ErrorAction Stop

    switch ($Operation) {
        "add" {
            if ($profileContent -match [regex]::Escape($StartMarker) -and $profileContent -match [regex]::Escape($EndMarker)) {
                Write-Warning "⚠️ $ModuleName already exists in profile, updating to latest version"
                # Replace existing content
                $profileContent = $profileContent -replace "(?ms)$([regex]::Escape($StartMarker)).*?$([regex]::Escape($EndMarker))", $Content
            }
            else {
                # Append new content
                $profileContent += "`n$Content"
            }
        }
        "remove" {
            if (-not ($profileContent -match [regex]::Escape($StartMarker))) {
                Write-Warning "⚠️ $ModuleName not found in profile, nothing to remove"
                return $true
            }
            # Remove marked content (preserve newlines)
            $profileContent = $profileContent -replace "(?ms)$([regex]::Escape($StartMarker)).*?$([regex]::Escape($EndMarker))", ""
            # Clean up empty lines
            $profileContent = $profileContent -replace "`n+", "`n" -replace "`n$", ""
        }
    }

    # Write back to profile (UTF8 no BOM for compatibility)
    try {
        Set-Content -Path $PROFILE -Value $profileContent -Encoding UTF8NoBOM -Force -ErrorAction Stop
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

            # Step 1: Install required dependencies
            $depsInstalled = $true
            foreach ($module in $RequiredModules) {
                if (-not (Install-RequiredModule -ModuleName $module)) {
                    $depsInstalled = $false
                }
            }
            if (-not $depsInstalled) {
                throw "One or more required modules failed to install"
            }

            # Step 2: Define module destination path
            $moduleDest = Join-Path (Split-Path $PROFILE) "Modules\$ModuleName"
            Write-Host "📂 Module destination: $moduleDest" -ForegroundColor Gray

            # Step 3: Create destination directory
            New-Item -ItemType Directory -Path $moduleDest -Force -ErrorAction Stop | Out-Null

            # Step 4: Copy module files (exclude git/config files)
            Write-Host "📤 Copying module files..." -ForegroundColor Cyan
            $excludeItems = @('.git', '.gitignore', 'shortcut_aliases.yaml', 'build.ps1', 'LICENSE', 'README.md')
            Copy-Item -Path ".\*" -Destination $moduleDest -Recurse -Force -Exclude $excludeItems -ErrorAction Stop

            # Step 5: Unload existing module (non-fatal)
            if (Get-Module $ModuleName -ErrorAction SilentlyContinue) {
                Write-Host "🔄 Unloading existing $ModuleName module" -ForegroundColor Cyan
                Remove-Module $ModuleName -Force -ErrorAction SilentlyContinue
            }

            # Step 6: Import new module
            Write-Host "🔧 Importing $ModuleName module" -ForegroundColor Cyan
            $moduleManifest = Join-Path $moduleDest "$ModuleName.psd1"
            if (-not (Test-Path $moduleManifest)) {
                throw "Module manifest not found at $moduleManifest"
            }
            Import-Module $moduleManifest -Force -ErrorAction Stop

            # Step 7: Update profile content
            Write-Host "📝 Updating PowerShell profile" -ForegroundColor Cyan
            if (-not (Update-ProfileContent -Operation add -Content $ProfileContent -StartMarker $ProfileMarkerStart -EndMarker $ProfileMarkerEnd)) {
                throw "Failed to update profile content"
            }

            # Step 8: Final validation
            if (-not (Get-Command Use-ShortcutAlias -ErrorAction SilentlyContinue)) {
                throw "Module installation succeeded but command not found"
            }

            Write-Host "`n🎉 $ModuleName installed successfully!`n" -ForegroundColor Green
            Write-Host "💡 To start using: Restart PowerShell or run: . $PROFILE`n" -ForegroundColor Yellow
            break
        }

        "uninstall" {
            Write-Host "`n🗑️ Starting $ModuleName uninstallation`n" -ForegroundColor Cyan

            # Step 1: Remove profile content
            Write-Host "📝 Removing $ModuleName from profile" -ForegroundColor Cyan
            Update-ProfileContent -Operation remove -Content $ProfileContent -StartMarker $ProfileMarkerStart -EndMarker $ProfileMarkerEnd

            # Step 2: Unload module
            if (Get-Module $ModuleName -ErrorAction SilentlyContinue) {
                Write-Host "🔄 Unloading $ModuleName module" -ForegroundColor Cyan
                Remove-Module $ModuleName -Force -ErrorAction SilentlyContinue
            }

            # Step 3: Delete module files (optional - confirm before delete)
            $moduleDest = Join-Path (Split-Path $PROFILE) "Modules\$ModuleName"
            if (Test-Path $moduleDest) {
                Write-Host "🗑️ Deleting module files from $moduleDest" -ForegroundColor Cyan
                Remove-Item -Path $moduleDest -Recurse -Force -ErrorAction SilentlyContinue
            }

            Write-Host "`n✅ $ModuleName uninstalled successfully!`n" -ForegroundColor Green
            Write-Host "💡 Changes will take effect after restarting PowerShell`n" -ForegroundColor Yellow
            break
        }

        Default {
            Write-Error "❌ Invalid action: $Action. Use 'install' or 'uninstall'"
            exit 1
        }
    }
}
catch {
    Write-Error "`n❌ $Action failed: $($_.Exception.Message)`n" -ForegroundColor Red
    exit 1
}
