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
        # 将本地所有文件移动到 $pwshPath\Modules\pwsh_shortcut_alias
        Copy-Item -Path .\* -Destination $pwshPath\Modules\pwsh_shortcut_alias -Force
        # 如果 pwsh_shortcut_alias 已存在，则先卸载
        if (Get-Module pwsh_shortcut_alias -ErrorAction SilentlyContinue) {
            Remove-Module pwsh_shortcut_alias -Force
        }
        Import-Module "$pwshPath\Modules\pwsh_shortcut_alias\pwsh_shortcut_alias.psd1" -Force
        # 检查是否已存在 pwsh_shortcut_alias_start 和 pwsh_shortcut_alias_end 是否同时存在
        $profileContent = Get-Content -Path $PROFILE -Raw
        if ($profileContent -match "### pwsh_shortcut_alias_start" -and $profileContent -match "### pwsh_shortcut_alias_end") {
            throw "pwsh_shortcut_alias already exists in your profile"
        } else {
            $profileContent = Get-Content $PROFILE -Raw
            $profileContent += "`n" + $content  # 用单个换行连接
            Set-Content -Path $PROFILE -Value $profileContent -Encoding UTF8
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

Get-Command Use-ShortcutAlias
