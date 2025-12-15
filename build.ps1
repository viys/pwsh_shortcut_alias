param (
    [Parameter(
        Position = 0,
        Mandatory
    )]
    [ValidateSet("install", "uninstall")]
    [string]$Action
)

$pwshPath = Split-Path -Path $PROFILE
$content = @'
### pwsh_shortcut_alias_start
if (-not (Get-Command Use-ShortcutAlias -ErrorAction SilentlyContinue)) {
    Import-Module pwsh_shortcut_alias -ErrorAction Stop
}

Use-ShortcutAlias update
### pwsh_shortcut_alias_end
'@.Trim()

switch ($Action) {
    "install" {
        try {
            $dest = Join-Path $pwshPath 'Modules\pwsh_shortcut_alias'

            # 1. 复制模块文件（失败就直接退出）
            if (Test-Path $dest) {
                Remove-Item $dest -Recurse -Force -ErrorAction Stop
            }

            New-Item -ItemType Directory -Path $dest -Force -ErrorAction Stop | Out-Null

            Copy-Item .\* `
                -Destination $dest `
                -Recurse `
                -Force `
                -Exclude .git `
                -ErrorAction Stop

            # 2. 卸载已加载的模块（非致命，但也要可控）
            if (Get-Module pwsh_shortcut_alias -ErrorAction SilentlyContinue) {
                Remove-Module pwsh_shortcut_alias -Force -ErrorAction Stop
            }

            # 3. 导入模块（关键步骤）
            Import-Module "$dest\pwsh_shortcut_alias.psd1" -Force -ErrorAction Stop

            # 4. 处理 profile 注入
            if (-not (Test-Path $PROFILE)) {
                New-Item -ItemType File -Path $PROFILE -Force -ErrorAction Stop | Out-Null
            }

            $profileContent = Get-Content -Path $PROFILE -Raw -ErrorAction Stop

            if (
                $profileContent -match '### pwsh_shortcut_alias_start' -and
                $profileContent -match '### pwsh_shortcut_alias_end'
            ) {
                Write-Warning "pwsh_shortcut_alias already exists in your profile"
            } else {
                $profileContent += "`n$content"
                Set-Content -Path $PROFILE -Value $profileContent -Encoding UTF8 -ErrorAction Stop
            }

            # 5. 最终验证
            Get-Command Use-ShortcutAlias -ErrorAction Stop
        } catch {
                Write-Error "Install failed: $($_.Exception.Message)"
                return
        }
    }
    "uninstall" {
        # 从 $PROFILE 中删除 pwsh_shortcut_alias_start 和 pwsh_shortcut_alias_end 之间的内容
        $profileContent = Get-Content -Path $PROFILE -Raw
        $profileContent = $profileContent -replace "(?ms)### pwsh_shortcut_alias_start.*?### pwsh_shortcut_alias_end", ""
        $profileContent | Set-Content -Path $PROFILE -Encoding UTF8

    }
    Default {}
}
