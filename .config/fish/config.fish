# NyxNiri package-manager selection (Paru > Yay > Shelly > Pacman)
fish_add_path --path $HOME/.local/bin

function _nyxniri_pkg_helper
    if command -v paru &>/dev/null
        echo paru
    else if command -v yay &>/dev/null
        echo yay
    else if command -v shelly &>/dev/null
        echo shelly
    else
        echo pacman
    end
end

if status is-interactive
    # Starship custom prompt
    command -v starship &> /dev/null && starship init fish | source

    # Direnv + Zoxide
    command -v direnv &> /dev/null && direnv hook fish | source
    command -v zoxide &> /dev/null && zoxide init fish --cmd cd | source

    # Better ls
    command -v eza &> /dev/null && alias ls='eza --icons --group-directories-first -1'
    command -v fastfetch &> /dev/null && alias fa=fastfetch

    # Abbrs
    abbr lg 'lazygit'
    abbr gd 'git diff'
    abbr ga 'git add .'
    abbr gc 'git commit -am'
    abbr gl 'git log'
    abbr gs 'git status'
    abbr gst 'git stash'
    abbr gsp 'git stash pop'
    abbr gp 'git push'
    abbr gpl 'git pull'
    abbr gsw 'git switch'
    abbr gsm 'git switch main'
    abbr gb 'git branch'
    abbr gbd 'git branch -d'
    abbr gco 'git checkout'
    abbr gsh 'git show'

    abbr l 'ls'
    abbr ll 'ls -l'
    abbr la 'ls -a'
    abbr lla 'ls -la'

    # NyxNiri cache cleanup helper
    alias clean='$HOME/.config/fish/clean-cache'

    # NyxNiri one-command system update
    function up --description "一键系统与软件包更新 (Arch / CachyOS)"
        set -l helper (_nyxniri_pkg_helper)
        set -l res 0

        switch "$helper"
            case paru
                paru -Syu $argv
                set res $status
            case yay
                yay -Syu $argv
                set res $status
            case shelly
                shelly upgrade all $argv
                set res $status
            case '*'
                sudo pacman -Syu $argv
                set res $status
        end

        if test $res -eq 130 -o $res -eq 143
            set_color yellow
            echo "[!] 更新操作已由用户取消"
            set_color normal
            return 130
        end

        if test $res -ne 0 -a "$helper" = shelly
            set_color yellow
            echo "[!] Shelly 更新遇到异常，尝试使用备用包管理器..."
            set_color normal
            if command -v paru &>/dev/null
                paru -Syu $argv
            else if command -v yay &>/dev/null
                yay -Syu $argv
            else
                sudo pacman -Syu $argv
            end
        end
    end
    alias update=up

    # Custom colours
    cat ~/.local/state/caelestia/sequences.txt 2> /dev/null

    # For jumping between prompts in foot terminal
    function mark_prompt_start --on-event fish_prompt
        echo -en "\e]133;A\e\\"
    end

    # Custom fish config
    set -q XDG_CONFIG_HOME && set -l cConf $XDG_CONFIG_HOME/caelestia || set -l cConf $HOME/.config/caelestia
    source $cConf/user-config.fish 2> /dev/null
end
