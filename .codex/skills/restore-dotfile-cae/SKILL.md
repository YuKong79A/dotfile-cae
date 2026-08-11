---
name: restore-dotfile-cae
description: Safely restore YuKong79A/dotfile-cae after a CachyOS or Arch Linux reinstall, including environment preflight, tracked-file-only recovery, conflict backup, username and path adaptation, dependency planning, home Git worktree setup, and static versus live desktop validation. Use when the user asks to reinstall, restore, recover, deploy, or verify this dotfiles repository, or provides https://github.com/YuKong79A/dotfile-cae for system recovery.
---

# Restore dotfile-cae

Restore the repository's user configuration without treating the target home as disposable. Treat the checked-out repository's current `README.md` and Git tree as the source of truth; do not rely on stale file counts or remembered package lists.

## Establish the source and target

1. Resolve the target account with `id`, `getent passwd`, and `printf '%s\n' "$HOME"`. Do not assume the account is named `yukong` or that its home is `/home/yukong`.
2. Use an existing clean checkout only after verifying its remote and `HEAD`. Otherwise clone `https://github.com/YuKong79A/dotfile-cae.git` into a directory created by `mktemp -d`.
3. Read the checkout's `README.md` completely. Inspect `git status --short --branch`, `git remote -v`, `git rev-parse HEAD`, and `git ls-tree -r --name-only HEAD`.
4. Check the target distribution, desktop session, commands, and services named by the current README. Query installed packages before proposing package names.
5. Search tracked text for `/home/yukong`. If the target home differs, classify each match before proposing a narrow replacement.

Never clone directly over the target home. Never use `git reset --hard`, `git clean`, or recursive deletion as a restore mechanism.

## Produce a restore plan

Choose one exact, not-yet-existing backup directory inside the target user's home. Run the bundled helper without `--apply`:

```bash
skill_dir="${CODEX_HOME:-$HOME/.codex}/skills/restore-dotfile-cae"
bash "$skill_dir/scripts/restore-tracked-files.sh" \
  --source "$restore_root/repo" \
  --target "$target_home" \
  --backup "$backup_root" \
  --list
```

The helper reads committed `HEAD` through `git archive`, not the checkout's possibly modified working tree. It reports `SOURCE_TRACKED_STATE=dirty-head-only` when tracked changes differ from `HEAD`, and refuses `--apply` until the source is clean. It does not change the target in dry-run mode.

Before applying, report:

- the source URL and exact commit;
- the target account and home;
- the number and paths of existing conflicts and new tracked files;
- the exact backup directory;
- path-type or symlink-parent hazards;
- missing commands and proposed packages;
- every separate system-level action involving root, `/etc`, `/boot`, PAM, greetd, Btrfs, Snapper, or service state.

Obtain explicit confirmation before overwriting conflicts, installing packages, or performing any administrative action. If the user asked only for an audit or plan, stop after the report.

## Restore user files

After confirmation, rerun the same command with `--apply`:

```bash
bash "$skill_dir/scripts/restore-tracked-files.sh" \
  --source "$restore_root/repo" \
  --target "$target_home" \
  --backup "$backup_root" \
  --list \
  --apply
```

Run it as the target user, never as root. The helper must finish with `RESULT=applied`; otherwise retain the backup and inspect the reported failure. It deliberately does not delete target-only files and does not install packages or change system configuration.

If the target username or home differs from the source machine, inspect the earlier absolute-path matches and edit only confirmed dependencies. Do not perform a blind global replacement.

## Connect the home worktree

Only after user files are copied and inspected, follow the current README's home-worktree procedure. Before changing Git metadata, check whether the target home already contains `.git` and preserve any unrelated repository.

Use a mixed index baseline rather than a hard reset. Keep the local `/*` exclusion in `.git/info/exclude` so unrelated untracked home data stays outside the dotfiles repository. Force-add only a new path the user explicitly chooses to back up. Preserve repository-only README and Markdown documentation even when it was absent from the pre-restore home.

Do not recreate source-machine `skip-worktree` flags automatically. They are local index state and can hide real changes.

## Restore dependencies in layers

Separate these layers and verify each before continuing:

1. User files and file ownership.
2. Commands and packages required by the current README.
3. Caelestia-generated state, themes, and post-hooks.
4. Hyprland and graphical-session behavior.
5. Optional greeter, PAM, boot, Btrfs, or Snapper work.

Never infer that system configuration was restored from user dotfiles. For Arch or CachyOS, query official repositories and the available AUR helper before presenting an install transaction. List packages and affected system paths, then request authorization.

Keep Foot as the default terminal unless the user explicitly asks to change it. Preserve Nerd Font terminal-grid behavior when resolving font dependencies.

## Validate and hand off

Run the static checks specified by the current README, adapting only paths that were intentionally changed. Then, when a real Hyprland session is available, run its live checks and reopen the relevant applications.

Report these evidence classes separately:

- files restored and backup created;
- syntax, JSON, shell, or Git checks passed;
- live Hyprland commands passed;
- fresh-login, application-restart, or visual checks completed by the user;
- system-level items intentionally deferred.

Finish with `git status --short --branch` and verify that unrelated home data, secrets, browser profiles, clipboard databases, and game data are not tracked. Keep the conflict backup until the user confirms the restored session works.
