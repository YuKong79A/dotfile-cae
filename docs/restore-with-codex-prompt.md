# 使用 Codex 恢复配置的提示词

重装系统并安装 Codex 后，将下面整段提示词发送给它：

```text
我刚重装了系统，需要从这个 GitHub 仓库恢复个人配置：

https://github.com/YuKong79A/dotfile-cae.git

请帮我完成以下工作：

1. 将仓库克隆到 ~/dotfile-cae。
2. 阅读仓库中的 README.md 和 docs/backup-conversation-2026-08-09.md，了解备份内容及原来的配置关系。
3. 检查当前系统、用户名、家目录、桌面环境及已安装软件。
4. 恢复以下配置：
   - Caelestia 配置、主题模板和同步脚本
   - Hyprland Lua 配置
   - Fastfetch 和 Starship 配置
   - Fish 的 f、fn、fwatch 函数
   - ~/.local/bin 中的个人脚本
   - Yazi Caelestia 主题
   - Papirus-caelestia-dark 文件夹图标主题
   - Foot Caelestia 桌面启动项和 XDG 默认终端设置
   - ~/.face 用户头像
5. 如果目标位置已经存在文件，先备份原文件，不要直接覆盖。
6. 如果新用户名不是 yukong，请修正配置中写死的 /home/yukong 路径。
7. 检查并安装恢复配置所必需的软件包；执行安装前告诉我具体包名。
8. 恢复后运行 Caelestia 的主题同步脚本，重建图标、Fastfetch、Starship、Bat 和 Yazi 主题。
9. 更新桌面启动项和 GTK 图标缓存。
10. 验证 Fish、Foot、Fastfetch、Starship、Yazi、Caelestia 和 Hyprland 配置是否正常。
11. 不要恢复缓存、密钥、令牌或其他敏感认证文件。
12. 每一步说明结果；遇到可能覆盖数据或需要管理员权限的操作时先征求我的确认。
```

如果重装后仍使用用户名 `yukong`，通常不需要修改硬编码的家目录路径。
