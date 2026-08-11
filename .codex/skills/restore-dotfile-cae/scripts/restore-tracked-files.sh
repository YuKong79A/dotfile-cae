#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  restore-tracked-files.sh --source REPO --target HOME --backup DIR [--list] [--apply]

Default mode is a read-only dry run. --apply backs up every existing tracked
target and then copies only files recorded in the source repository's HEAD.
The script never deletes target-only files, installs packages, or changes .git.
EOF
}

die() {
  printf 'ERROR=%s\n' "$*" >&2
  exit 1
}

quote_path() {
  printf '%q' "$1"
}

source_repo=''
target_home=''
backup_root=''
apply=0
list_paths=0

while (($#)); do
  case "$1" in
    --source)
      (($# >= 2)) || die '--source requires a value'
      source_repo=$2
      shift 2
      ;;
    --target)
      (($# >= 2)) || die '--target requires a value'
      target_home=$2
      shift 2
      ;;
    --backup)
      (($# >= 2)) || die '--backup requires a value'
      backup_root=$2
      shift 2
      ;;
    --apply)
      apply=1
      shift
      ;;
    --list)
      list_paths=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
done

[[ -n "$source_repo" ]] || die '--source is required'
[[ -n "$target_home" ]] || die '--target is required'
[[ -n "$backup_root" ]] || die '--backup is required'
[[ -d "$source_repo" ]] || die "source is not a directory: $source_repo"
[[ -d "$target_home" ]] || die "target is not a directory: $target_home"

source_repo=$(realpath -e -- "$source_repo")
target_home=$(realpath -e -- "$target_home")

[[ "$target_home" != / ]] || die 'target may not be /'
[[ $backup_root = /* ]] || die 'backup must be an absolute path'
[[ "$backup_root" != / && "$backup_root" != "$target_home" ]] || die 'unsafe backup path'
[[ ! -e "$backup_root" && ! -L "$backup_root" ]] || die "backup path already exists: $backup_root"
backup_parent=$(dirname -- "$backup_root")
[[ -d "$backup_parent" ]] || die 'backup parent does not exist'
backup_parent=$(realpath -e -- "$backup_parent")
[[ "$backup_parent" == "$target_home" ]] || die 'backup must be a new direct child of the target home'
backup_name=$(basename -- "$backup_root")
[[ "$backup_name" != . && "$backup_name" != .. ]] || die 'unsafe backup directory name'

((EUID != 0)) || die 'run as the target user, not root'
target_uid=$(stat -c '%u' -- "$target_home")
((target_uid == EUID)) || die "target is not owned by uid $EUID"

git -C "$source_repo" rev-parse --is-inside-work-tree >/dev/null 2>&1 || \
  die 'source is not a Git worktree'
commit=$(git -C "$source_repo" rev-parse --verify HEAD) || die 'source has no HEAD commit'
remote=$(git -C "$source_repo" remote get-url origin 2>/dev/null || printf '%s' '(no origin remote)')
if git -C "$source_repo" diff --quiet HEAD --; then
  source_tracked_state=clean
else
  source_tracked_state=dirty-head-only
fi

if git -C "$source_repo" ls-tree -r HEAD | awk '$2 == "commit" { found=1 } END { exit !found }'; then
  die 'HEAD contains a submodule; handle it explicitly before restoring'
fi

scratch=$(mktemp -d /tmp/dotfile-cae-restore-plan.XXXXXX)
cleanup() {
  rm -rf -- "$scratch"
}
trap cleanup EXIT

snapshot="$scratch/snapshot"
tracked="$scratch/tracked.nul"
conflicts="$scratch/conflicts.nul"
new_paths="$scratch/new.nul"
mkdir -p -- "$snapshot"
: >"$conflicts"
: >"$new_paths"

git -C "$source_repo" ls-tree -r --name-only -z HEAD >"$tracked"
git -C "$source_repo" archive --format=tar HEAD | tar -C "$snapshot" -xf -

has_symlink_parent() {
  local rel=$1 parent rest part current
  [[ $rel == */* ]] || return 1
  parent=${rel%/*}
  rest=$parent
  current=$target_home

  while :; do
    if [[ $rest == */* ]]; then
      part=${rest%%/*}
      rest=${rest#*/}
    else
      part=$rest
      rest=''
    fi
    current="$current/$part"
    [[ -L $current ]] && return 0
    [[ -n $rest ]] || break
  done
  return 1
}

tracked_count=0
conflict_count=0
new_count=0
hazard_count=0
declare -a hazards=()

while IFS= read -r -d '' rel; do
  ((tracked_count += 1))
  [[ -n $rel && $rel != /* && $rel != '..' && $rel != ../* && $rel != */../* && $rel != */.. ]] || \
    die "unsafe path in Git tree: $(quote_path "$rel")"
  [[ -e "$snapshot/$rel" || -L "$snapshot/$rel" ]] || \
    die "Git archive omitted tracked path: $(quote_path "$rel")"

  if [[ $rel == "$backup_name" || $rel == "$backup_name/"* ]]; then
    ((hazard_count += 1))
    hazards+=("backup path overlaps the Git tree: $rel")
    continue
  fi

  if has_symlink_parent "$rel"; then
    ((hazard_count += 1))
    hazards+=("symlink parent: $rel")
    continue
  fi

  if [[ -d "$target_home/$rel" && ! -L "$target_home/$rel" ]]; then
    ((hazard_count += 1))
    hazards+=("target directory blocks tracked file: $rel")
    continue
  fi

  if [[ -e "$target_home/$rel" || -L "$target_home/$rel" ]]; then
    ((conflict_count += 1))
    printf '%s\0' "$rel" >>"$conflicts"
  else
    ((new_count += 1))
    printf '%s\0' "$rel" >>"$new_paths"
  fi
done <"$tracked"

printf 'MODE=%s\n' "$([[ $apply == 1 ]] && printf apply || printf dry-run)"
printf 'SOURCE=%s\n' "$source_repo"
printf 'REMOTE=%s\n' "$remote"
printf 'COMMIT=%s\n' "$commit"
printf 'SOURCE_TRACKED_STATE=%s\n' "$source_tracked_state"
printf 'TARGET=%s\n' "$target_home"
printf 'BACKUP=%s\n' "$backup_root"
printf 'TRACKED_FILES=%d\n' "$tracked_count"
printf 'EXISTING_CONFLICTS=%d\n' "$conflict_count"
printf 'NEW_FILES=%d\n' "$new_count"
printf 'HAZARDS=%d\n' "$hazard_count"

if [[ $source_tracked_state != clean ]]; then
  printf '%s\n' 'WARNING=source has staged or tracked working-tree changes; this plan reads committed HEAD only' >&2
  if ((apply)); then
    die 'apply requires a source with no staged or tracked working-tree changes'
  fi
fi

if ((list_paths)); then
  if ((conflict_count)); then
    printf 'CONFLICT_PATHS_BEGIN\n'
    while IFS= read -r -d '' rel; do
      printf 'existing\t'
      quote_path "$rel"
      printf '\n'
    done <"$conflicts"
    printf 'CONFLICT_PATHS_END\n'
  fi

  if ((new_count)); then
    printf 'NEW_PATHS_BEGIN\n'
    while IFS= read -r -d '' rel; do
      printf 'new\t'
      quote_path "$rel"
      printf '\n'
    done <"$new_paths"
    printf 'NEW_PATHS_END\n'
  fi
fi

if ((hazard_count)); then
  printf 'HAZARD_PATHS_BEGIN\n' >&2
  for hazard in "${hazards[@]}"; do
    quote_path "$hazard" >&2
    printf '\n' >&2
  done
  printf 'HAZARD_PATHS_END\n' >&2
  die 'resolve path hazards manually; no files were changed'
fi

if ((!apply)); then
  printf 'RESULT=dry-run-only-no-files-changed\n'
  exit 0
fi

mkdir -p -- "$backup_root/files"
{
  printf 'source=%s\n' "$source_repo"
  printf 'remote=%s\n' "$remote"
  printf 'commit=%s\n' "$commit"
  printf 'target=%s\n' "$target_home"
  printf 'tracked_files=%d\n' "$tracked_count"
  printf 'existing_conflicts=%d\n' "$conflict_count"
  printf 'new_files=%d\n' "$new_count"
} >"$backup_root/restore-metadata.txt"

while IFS= read -r -d '' rel; do
  (
    cd "$target_home"
    cp -a --parents -- "$rel" "$backup_root/files"
  )
done <"$conflicts"

while IFS= read -r -d '' rel; do
  destination="$target_home/$rel"
  mkdir -p -- "$(dirname -- "$destination")"
  cp -a --remove-destination -- "$snapshot/$rel" "$destination"
done <"$tracked"

printf 'RESTORED_FILES=%d\n' "$tracked_count"
printf 'BACKED_UP_CONFLICTS=%d\n' "$conflict_count"
printf 'RESULT=applied\n'
