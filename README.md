# dotfile-cae

这是 YuKong 的 CachyOS/Arch Linux、Hyprland 和 Caelestia 桌面配置备份。

本文件主要写给 Codex：用户重装系统后如果只提供本仓库地址，请先完整阅读本文，检查新系统的实际状态，再执行恢复。仓库内容是配置来源，但不要假设软件包、系统服务、用户名、挂载布局或硬件与备份时完全一致。

## Codex 恢复任务

目标是把仓库中保存的用户级配置安全恢复到当前用户的 home，同时保留新系统中不属于本仓库的文件。

必须遵守：

1. 不要删除、清空或重置整个 home。
2. 不要使用 `git reset --hard`、`git clean` 或递归删除来完成恢复。
3. 先检查用户名、`$HOME`、发行版、当前桌面、仓库内容和已安装依赖。
4. 覆盖任何已有配置前，先将冲突路径备份到带时间戳的目录，并向用户报告备份位置。
5. 只恢复仓库实际跟踪的文件；不要处理仓库中不存在的其他 home 文件。
6. `/etc`、`/boot`、PAM、显示管理器、Btrfs、Snapper 和软件安装属于独立的系统级工作，必须检查后单独处理，不要从本仓库的用户配置推断其已完成。
7. 需要 root 权限、安装软件包或改变服务状态时，明确说明操作并取得用户授权。
8. 恢复后执行本文的验证，不要只根据复制命令成功就宣称桌面已经恢复。

## 当前备份范围

仓库当前包含：

- `.config/caelestia/`：Caelestia CLI、Shell、主题模板、同步脚本、显示器配置和 Hyprland 用户覆盖。
- `.config/hypr/`：Lua 形式的 Hyprland 配置、窗口规则、快捷键和当前生成的配色。
- `.config/foot/foot.ini`：默认终端 Foot，Fish shell，JetBrains Mono Nerd Font，暗色背景透明度 `0.78`。
- `.config/fish/functions/`：选定的壁纸/Fastfetch 辅助函数；不是完整 Fish 配置备份。
- `.config/fastfetch/`、`.config/starship.toml`、`.config/yazi/`：Caelestia 联动主题及配置。
- `.config/xdg-terminals.list`：XDG 终端优先级。
- `.local/bin/`：个人壁纸、终端和透明度辅助脚本。
- `.local/share/applications/foot-caelestia.desktop`：Caelestia Foot 桌面入口。
- `.local/share/icons/Papirus-caelestia-dark/`：由当前 Caelestia 配色生成的 Papirus 图标主题。
- `.face`：用户头像。

仓库当前不包含完整的软件包清单、私钥/令牌、浏览器资料、游戏数据、完整 Fish 插件目录、Kitty 配置、Google Sans Flex 字体安装器以及系统级配置。不得声称这些内容能由本仓库恢复。

## 推荐恢复流程

以下命令是流程参考。Codex 应根据实际用户名和 home 路径调整变量，逐步执行并检查结果，不要盲目整段粘贴。

### 1. 检查环境

```bash
id
printf '%s\n' "$HOME"
uname -a
command -v git
command -v caelestia
command -v hyprctl
```

确认目标用户通常为 `yukong`、home 通常为 `/home/yukong`。如果不同，必须检查仓库中的绝对路径并进行有针对性的替换，不能直接照搬 `/home/yukong`。

### 2. 临时克隆，不要直接克隆覆盖 home

```bash
restore_root=$(mktemp -d /tmp/dotfile-cae-restore.XXXXXX)
git clone https://github.com/YuKong79A/dotfile-cae.git "$restore_root/repo"
git -C "$restore_root/repo" status --short --branch
```

克隆后先阅读：

```bash
sed -n '1,260p' "$restore_root/repo/README.md"
git -C "$restore_root/repo" ls-files
```

### 3. 备份已有冲突文件

创建仅属于本次任务的备份目录，然后对仓库将要写入且目标已经存在的路径做备份。不要备份整个 home，也不要移动不相关文件。

```bash
backup_root="$HOME/dotfile-restore-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup_root"
```

Codex 应依据 `git ls-files` 生成冲突清单，保留相对路径、权限和符号链接，并在复制前向用户汇报。恢复验证完成前不要删除该备份。

### 4. 只复制仓库跟踪内容

优先按仓库清单复制，而不是复制临时仓库的 `.git`。可以从临时克隆目录执行：

```bash
git -C "$restore_root/repo" ls-files -z | \
  tar -C "$restore_root/repo" --null -T - -cf - | \
  tar -C "$HOME" -xpf -
```

复制后检查关键文件存在、所有者属于当前用户，并搜索残留的旧 home 绝对路径：

```bash
stat -c '%U:%G %a %n' \
  "$HOME/.config/caelestia/cli.json" \
  "$HOME/.config/hypr/hyprland.lua" \
  "$HOME/.config/foot/foot.ini"
rg -n '/home/yukong' \
  "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/share/applications" 2>/dev/null
```

如果恢复账号仍为 `yukong`，匹配 `/home/yukong` 不一定是错误；逐项判断。账号不同则只修改确实依赖旧 home 的路径。

### 5. 将 home 连接为本仓库工作区

只有复制和检查完成后再建立 Git 元数据。以下 `reset --mixed` 只建立远端索引基线，不应覆盖工作树文件：

```bash
git -C "$HOME" init -b main
git -C "$HOME" remote add origin https://github.com/YuKong79A/dotfile-cae.git
git -C "$HOME" fetch origin main
git -C "$HOME" reset --mixed origin/main
git -C "$HOME" branch --set-upstream-to=origin/main main
```

为了让位于 home 根目录的仓库忽略所有非仓库文件，在本地的 `$HOME/.git/info/exclude` 末尾加入：

```gitignore
# Ignore every untracked home path. Existing tracked files remain managed.
/*
```

这是本机规则，不会上传 GitHub。验证 `git status` 只能显示仓库已跟踪配置的真实差异，不能出现整个 home、游戏、密钥或个人资料。新增一个原仓库没有的配置目录时，需要显式执行 `git add -f <path>`。

## 软件和运行时依赖

先检查再安装。仓库脚本至少可能使用：

- Caelestia Shell/CLI 与兼容的 Hyprland 环境
- `fish`、`foot`、`fastfetch`、`starship`、`yazi`
- `jq`、`python`、`perl`、`bash`、`bsdtar`
- `wl-clipboard`、`cliphist`
- `papirus-icon-theme`、Bibata 光标主题、JetBrains Mono Nerd Font
- 可选：LibreOffice、Fcitx5、Cava、Bat、Codex CLI、`arch-update`

在 Arch/CachyOS 上应先用 `pacman -Si`、`paru -Si` 或已安装包查询确认正确包名。不要未经检查就安装 README 中推测出的包，也不要假设 AUR 助手必然存在。

Caelestia 的主题同步依赖 `~/.local/state/caelestia/scheme.json`。状态文件通常由 Caelestia 生成，不在本仓库中。先正常启动/生成配色，再运行同步脚本；不要伪造状态文件。

`cli.json` 的主题和壁纸 post-hook 当前会调用：

```bash
sudo -n caelestia-greeter --sync
```

如果新系统没有安装或授权 Caelestia Greeter，该步骤可能失败。先检查 Greeter、sudoers 和显示管理器的真实状态，不要为了消除错误盲目扩大 sudo 权限。

## 当前桌面行为提示

- Caelestia 使用 12 小时制，天气位置为 `Tangshan, China`。
- Foot 是首选终端，使用 Fish；暗色背景透明度为 `0.78`。
- `user-config.fish` 不应重新添加 `GTK_IM_MODULE=fcitx`；Wayland 下保留 Qt、XMODIFIERS 和 SDL 的 Fcitx 设置。
- `hypr-user.lua` 启动 `arch-update --tray` 和剪贴板历史脚本。
- 剪贴板历史可能包含敏感数据，必要时使用 `cliphist wipe`。
- Hyprland 特殊工作区、窗口规则和快捷键以仓库中的 Lua 文件为准；恢复后必须用实际 Hyprland 版本验证。
- Papirus、Fastfetch、Starship、Yazi 和 Hyprland scheme 中的颜色可能在重新生成 Caelestia 配色后发生大量正常变化。

## 恢复后验证

先做静态检查：

```bash
jq empty \
  "$HOME/.config/caelestia/cli.json" \
  "$HOME/.config/caelestia/shell.json"
luac -p "$HOME/.config/caelestia/hypr-user.lua"
bash -n "$HOME/.config/caelestia/scripts/copy.sh"
bash -n "$HOME/.config/caelestia/posthooks/cursor.sh"
bash -n "$HOME/.config/caelestia/scripts/sync-libreoffice-theme.sh"
fish -n "$HOME/.config/caelestia/user-config.fish"
```

然后在真实图形会话中验证：

```bash
hyprctl reload
hyprctl configerrors
```

还应重新打开 Foot、Caelestia、Yazi 和需要的应用，检查字体、图标、透明度、输入法、特殊工作区和主题同步。持久化文件检查不能替代真实登录/重启后的视觉及会话验证。

最后检查 Git 范围：

```bash
git -C "$HOME" status --short --branch
git -C "$HOME" check-ignore -v .config/fish/functions/fisher.fish 2>/dev/null || true
```

如果验证失败，保留冲突备份，说明失败层级和具体错误；不要通过删除用户现有配置来强行得到干净状态。

## 后续备份

仓库当前使用 HTTPS 远端。此主机可用 `git-credential-libsecret` 将 GitHub Personal Access Token 保存到桌面密钥环。常规更新：

```bash
git -C "$HOME" status --short
git -C "$HOME" add -u
git -C "$HOME" commit -m "Update desktop configuration"
git -C "$HOME" push origin main
```

对于原仓库不存在、但确认需要纳入备份的新路径：

```bash
git -C "$HOME" add -f .config/example
```

提交前必须检查暂存内容，尤其避免加入令牌、密码、SSH 私钥、浏览器数据、剪贴板数据库、游戏存档和其他隐私文件。
