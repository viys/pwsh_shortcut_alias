# pwsh_shortcut_alias 手工回归清单

## 基础准备

- 清理或备份现有 `shortcout_aliases.yaml`
- 在新的 PowerShell 会话中 `Import-Module .\pwsh_shortcut_alias.psm1 -Force`
- 准备一个有效文件路径、一个有效目录路径、一个有效 `https` URL

## 用例清单

1. 添加文件路径别名
   - 执行 `Use-ShortcutAlias add <name> <file-path>`
   - 确认提示成功
   - 确认 YAML 中写入的是解析后的绝对路径
2. 添加目录别名
   - 执行 `Use-ShortcutAlias add <name> <dir-path>`
   - 确认提示成功
   - 确认 YAML 中写入的是解析后的绝对路径
3. 添加 URL 别名
   - 执行 `Use-ShortcutAlias add <name> <https-url>`
   - 确认提示成功
   - 确认 YAML 中写入原始 URL 字符串
4. 添加非法路径
   - 执行 `Use-ShortcutAlias add <name> <invalid-path>`
   - 确认参数校验失败或添加失败
   - 确认 YAML 未被破坏
5. 删除存在的别名
   - 先添加一个测试别名
   - 执行 `Use-ShortcutAlias remove <name>`
   - 确认 YAML 中该别名被移除
   - 如果当前会话已注册同名函数，确认全局函数同步删除
6. 删除不存在的别名
   - 执行 `Use-ShortcutAlias remove <missing-name>`
   - 确认输出 `not found`
   - 确认 YAML 无额外变化
7. 搜索精确命中
   - 执行 `Use-ShortcutAlias search <exact-name>`
   - 确认输出正确名称和目标路径
8. 搜索模糊命中
    - 执行 `Use-ShortcutAlias search <partial-name>`
    - 确认返回所有匹配项
    - 确认可从管道拿到结构化对象
9. 搜索结果对象验证
   - 执行 `Use-ShortcutAlias search <name> | Select-Object Name, Path, IsUrl`
   - 确认输出对象包含 `Name`、`Path`、`IsUrl`
   - 确认对象中不包含 `Spaces`、`MaxLength`
10. 更新全部别名
    - 执行 `Use-ShortcutAlias update`
    - 确认输出更新计数正确
    - 确认当前会话可直接调用已注册别名
11. 更新时遇到失效本地路径
    - 手动在 YAML 中保留一个不存在的本地路径
    - 执行 `Use-ShortcutAlias update`
    - 确认只对该条目输出 warning，其他别名仍正常注册
12. YAML 首次创建
    - 删除 YAML 后重新执行一次 `add`
    - 确认文件自动创建且结构仍为 `aliases.<name>.path`
13. YAML 排序稳定性
    - 添加多个乱序名称别名
    - 确认写回后按别名名升序稳定排序
14. 旧 YAML 读取兼容性
    - 使用现有旧版 YAML 执行 `search` 和 `update`
    - 确认可以正常读取和注册
15. 更新后直接调用别名
    - 执行 `Use-ShortcutAlias update`
    - 直接输入别名名
    - 确认目标被正常启动
16. 文件路径别名启动验证
    - 为文件路径执行 `Use-ShortcutAlias update`
    - 直接输入对应别名
    - 确认文件按既有方式被正常打开
17. 目录别名启动验证
    - 为目录路径执行 `Use-ShortcutAlias update`
    - 直接输入对应别名
    - 确认目录按既有方式被正常打开
18. URL 别名启动验证
    - 为 URL 执行 `Use-ShortcutAlias update`
    - 直接输入对应别名
    - 确认 URL 按既有方式被正常打开
19. 动态函数边界验证
    - 执行 `Use-ShortcutAlias update`
    - 检查已注册别名函数定义
    - 确认函数体只调用统一启动入口，不再直接内联 `Start-Process explorer.exe`
20. 可替换启动入口验证
    - 在模块上下文内临时替换启动入口脚本块
    - 重新执行一次 `Use-ShortcutAlias update`
    - 直接输入已注册别名
    - 确认替换入口收到正确目标，且不需要真实拉起系统进程

## 重点检查项

- `add` 与 `update` 对同一目标的 URL 判定结果一致
- 本地路径写入 YAML 前已经是解析后的绝对路径
- `remove` 删除后 YAML 与全局函数状态一致
- 单个别名失败不会破坏整个 YAML 文件
- 动态函数只负责传递 `Target`，不直接承载系统启动细节
- 统一启动入口收到的目标与 YAML 中记录的目标一致
- 搜索返回对象只暴露 `Name`、`Path`、`IsUrl` 等领域字段
- 搜索展示层变化不会影响匹配结果数量和内容
