<#
.SYNOPSIS
    管理快捷方式别名：添加、删除、搜索或更新别名。

.DESCRIPTION
    Use-ShortcutAlias (别名: usa) 是一个PowerShell模块函数，用于为常用程序/脚本创建全局快捷方式别名，
    可通过别名快速启动对应程序。别名信息持久化存储在模块目录的 YAML 文件中，支持以下操作：
    1. add    - 添加新别名（自动验证路径合法性，仅支持字母/数字/下划线命名）
    2. remove - 删除指定别名（同步移除全局函数）
    3. search - 查询别名（支持模糊匹配，结果自动对齐格式化输出）
    4. update - 根据 YAML 文件重新加载所有别名到全局函数

.PARAMETER Action
    [必填] 指定要执行的操作类型，仅支持以下值：
        add    - 添加新别名（需同时指定 AliasName 和 ShortcutPath）
        remove - 删除指定别名（需指定 AliasName）
        search - 搜索别名（AliasName 可选，为空时列出所有别名）
        update - 更新所有别名（无需额外参数）

.PARAMETER AliasName
    [可选] 别名名称，规则：
    - 仅支持字母、数字、下划线（避免特殊字符导致解析错误）
    - add/remove 操作时为必填项
    - search 操作时支持模糊匹配（如输入 "ed" 会匹配 "edge"、"edit" 等）
    - update 操作时无需指定

.PARAMETER ShortcutPath
    [可选] 程序/脚本/快捷方式的完整路径，仅在 add 操作时为必填项，
    函数会自动验证路径是否存在且为文件（非目录）。

.EXAMPLE
    # 基本用法：添加别名（推荐使用别名 usa 简化输入）
    Use-ShortcutAlias add edge "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk"
    # 或简化为
    usa add edge "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk"

.EXAMPLE
    # 删除别名
    Use-ShortcutAlias remove edge
    # 或
    usa remove edge

.EXAMPLE
    # 搜索别名（模糊匹配）
    Use-ShortcutAlias search ed
    # 或列出所有别名
    Use-ShortcutAlias search

.EXAMPLE
    # 更新所有别名（从 YAML 文件重新加载）
    Use-ShortcutAlias update
    # 或
    usa update

.INPUTS
    无（此函数不接受管道输入）

.OUTPUTS
    字符串（操作结果提示，不同操作输出不同颜色的提示信息）
    - 成功：绿色文字
    - 失败/不存在：红色/黄色文字
    - 详细日志：使用 -Verbose 参数查看

.NOTES
    1. YAML 配置文件路径：<模块根目录>\shortcout_aliases.yaml
    2. 别名创建后会生成全局函数，可直接在 PowerShell 中输入别名启动程序
    3. 模块版本：0.1.0
    4. 兼容 PowerShell 5.1/7+，需提前安装 powershell-yaml 模块：
       Install-Module powershell-yaml -Scope CurrentUser -Force

.LINK
    # 可选：如果有模块文档/仓库链接，可添加
    https://github.com/你的用户名/pwsh_shortcut_alias
#>

function Use-ShortcutAlias {
    [CmdletBinding(DefaultParameterSetName = "Default")]
    [Alias("usa")]
    param (
        [Parameter(Position = 0, Mandatory)]
        [ValidateSet("add", "remove", "search", "update")]
        [string]$Action,

        [Parameter(Position = 1)]
        [ValidatePattern('^[a-zA-Z0-9_]+$')]
        [string]$AliasName,

        [Parameter(Position = 2)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
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
