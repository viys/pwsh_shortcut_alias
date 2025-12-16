<#
.SYNOPSIS
    管理快捷方式别名：添加、删除、搜索或更新别名。

.DESCRIPTION
    Use-ShortcutAlias 允许你为常用程序或脚本创建别名，并通过别名快速启动对应程序。
    支持添加(add)、删除(remove)、搜索(search)以及更新(update)别名。
    别名信息存储在模块目录下的 YAML 文件中。

.PARAMETER Action
    指定操作类型：
        add    - 添加一个新的别名
        remove - 删除指定别名
        search - 查询别名（支持模糊匹配）
        update - 根据 YAML 文件更新所有别名函数

.PARAMETER AliasName
    别名名称。对于 add/remove/search 操作必填。update 可不填。

.PARAMETER ShortcutPath
    程序或脚本的完整路径，仅在 add 操作时必填。

.EXAMPLE
    # 添加别名
    Use-ShortcutAlias add edge "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk"

.EXAMPLE
    # 删除别名
    Use-ShortcutAlias remove edge

.EXAMPLE
    # 搜索别名
    Use-ShortcutAlias search ed

.EXAMPLE
    # 更新所有别名（从 YAML 文件重新加载）
    Use-ShortcutAlias update

.NOTES
    YAML 文件路径：<模块目录>\shortcout_aliases.yaml
    模块版本：0.1.0
#>
function Use-ShortcutAlias {
    param (
        [Parameter(
            Position = 0,
            Mandatory
        )]
        [ValidateSet("add", "remove", "search", "update")]
        [string]$Action,

        [Parameter(Position = 1)]
        [string]$AliasName,

        [Parameter(Position = 2)]
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
        Default {}
    }
}
