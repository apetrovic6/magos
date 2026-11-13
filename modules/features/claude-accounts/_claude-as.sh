# shellcheck shell=bash
# claude-as -- start a Claude Code session as a chosen subscription account.
#
# The account is chosen per session and pinned through the environment
# (CLAUDE_CONFIG_DIR, plus OMARCHY_AGENT_CLAUDE_HOME for Omarchy's dispatch
# wrapper), so everything the session starts -- Agent-tool subagents, which run
# in-process, and any nested `claude` -- stays on the same account.
#
# Two backends, picked at runtime so one binary serves every machine:
#   omarchy     omarchy-agent-account-state is on PATH (nixarchy). Its
#               registry is the source of truth, shared with the agents widget.
#   standalone  everywhere else. Homes live in $XDG_STATE_HOME/claude-accounts.
#
# @labels@ is substituted by Nix with a JSON file mapping id -> label.

labels_file="${CLAUDE_AS_LABELS:-@labels@}"

primary="$HOME/.claude"
state_root="${XDG_STATE_HOME:-$HOME/.local/state}/claude-accounts"

# Kept identical to Omarchy's PROVIDERS["claude"] in omarchy-agent-account-state,
# so an account made by either backend looks the same.
shared_dirs=(projects skills agents commands plugins hooks themes output-styles file-history todos plans)
shared_files=(settings.json CLAUDE.md history.jsonl keybindings.json)
carried_keys='["mcpServers","projects","theme","hasCompletedOnboarding","lastOnboardingVersion","editorMode"]'

die() {
  echo "claude-as: $*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage:
  claude-as <account> [claude args...]   start Claude as <account>
  claude-as                               pick an account interactively
  claude-as list                          id, home and label of every account
  claude-as current                       the account this session runs as
  claude-as add <name>                    sign in to another account

`main` is always the primary account (~/.claude).
EOF
}

have_omarchy() {
  command -v omarchy-agent-account-state >/dev/null 2>&1
}

# id<TAB>home, one per account, main first.
homes() {
  if have_omarchy; then
    # Columns: id, home, primary flag. The primary row is keyed by its label,
    # so normalise it to `main`.
    omarchy-agent-account-state homes claude | awk -F'\t' '
      $3 == "1" { print "main\t" $2; next }
      { print tolower($1) "\t" $2 }'
  else
    printf 'main\t%s\n' "$primary"
    if [[ -d $state_root ]]; then
      local dir
      for dir in "$state_root"/*/; do
        [[ -d $dir ]] || continue
        dir=${dir%/}
        printf '%s\t%s\n' "${dir##*/}" "$dir"
      done
    fi
  fi
}

label_of() {
  local label=""
  if [[ -r $labels_file ]]; then
    label=$(jq -r --arg id "$1" '.[$id] // empty' "$labels_file")
  fi
  printf '%s' "${label:-$1}"
}

home_of() {
  local id
  id=$(tr '[:upper:]' '[:lower:]' <<<"$1")
  homes | awk -F'\t' -v id="$id" '$1 == id { print $2; exit }'
}

# Same as Omarchy's link_shared: an existing link or real file is never
# replaced, so anything an account wrote for itself survives.
link_shared() {
  local home=$1 name
  mkdir -p "$home"
  chmod 700 "$home"
  for name in "${shared_dirs[@]}"; do
    mkdir -p "$primary/$name"
  done
  for name in "${shared_dirs[@]}" "${shared_files[@]}"; do
    [[ -e $home/$name || -L $home/$name ]] && continue
    ln -s "$primary/$name" "$home/$name"
  done
}

# Copy the carried ~/.claude.json keys into an account's own .claude.json.
#   once  only keys the account doesn't have yet (a new account)
#   mcp   refresh mcpServers, the primary's entries winning on a name clash,
#         so servers added after the account was created still reach it
carry_settings() {
  local home=$1 mode=$2 src="$HOME/.claude.json" dst="$1/.claude.json" tmp
  [[ -r $src ]] || return 0
  [[ -s $dst ]] || echo '{}' >"$dst"
  tmp=$(mktemp "$home/.claude.json.XXXXXX")
  if [[ $mode == once ]]; then
    jq --slurpfile src "$src" --argjson keys "$carried_keys" '
      reduce $keys[] as $k (.;
        if has($k) or ($src[0] | has($k) | not) then . else .[$k] = $src[0][$k] end)
    ' "$dst" >"$tmp"
  else
    jq --slurpfile src "$src" '
      if ($src[0] | has("mcpServers"))
      then .mcpServers = ((.mcpServers // {}) + $src[0].mcpServers)
      else . end
    ' "$dst" >"$tmp"
  fi
  chmod 600 "$tmp"
  mv "$tmp" "$dst"
}

launch() {
  local id=$1 home
  shift
  home=$(home_of "$id")
  [[ -n $home ]] || die "no account '$id'. Known: $(homes | cut -f1 | paste -sd' ')"

  if [[ $(tr '[:upper:]' '[:lower:]' <<<"$id") == main ]]; then
    # Main stays implicit: Claude's default home also selects ~/.claude.json.
    # The empty pin tells Omarchy's dispatch wrapper "Main", not "unset".
    unset CLAUDE_CONFIG_DIR
    export OMARCHY_AGENT_CLAUDE_HOME=
  else
    link_shared "$home"
    carry_settings "$home" mcp
    export CLAUDE_CONFIG_DIR="$home"
    export OMARCHY_AGENT_CLAUDE_HOME="$home"
  fi
  exec claude "$@"
}

current() {
  local home=""
  if [[ -n ${CLAUDE_CONFIG_DIR:-} ]]; then
    home=$CLAUDE_CONFIG_DIR
  elif [[ -v OMARCHY_AGENT_CLAUDE_HOME ]]; then
    home=$OMARCHY_AGENT_CLAUDE_HOME
  elif have_omarchy; then
    # Not inside a session: the account a new one would start as.
    home=$(omarchy-agent-account-home claude 2>/dev/null || true)
  fi
  if [[ -z $home || $home == "$primary" ]]; then
    echo main
    return
  fi
  homes | awk -F'\t' -v h="$home" '$2 == h { print $1; found = 1; exit } END { if (!found) exit 1 }' ||
    die "this session's home ($home) is not a registered account"
}

list() {
  local id home
  while IFS=$'\t' read -r id home; do
    printf '%s\t%s\t%s\n' "$id" "$home" "$(label_of "$id")"
  done < <(homes)
}

pick() {
  # stdout is captured by the caller; gum draws on the terminal via stderr.
  [[ -t 0 && -t 2 ]] || die "no account given and no terminal to pick one in"
  local choice
  choice=$(list | awk -F'\t' '{ printf "%s  (%s)\n", $3, $1 }' |
    gum choose --header "Start Claude as") || exit 130
  choice=${choice##*(}
  printf '%s' "${choice%)}"
}

add() {
  local name=${1:-}
  [[ -n $name ]] || die "usage: claude-as add <name>"
  if have_omarchy; then
    # The registry derives the id from the label (Codilas -> codilas).
    exec omarchy-agent-account-add claude "$name"
  fi

  local id home
  id=$(tr '[:upper:]' '[:lower:]' <<<"$name")
  [[ $id =~ ^[a-z0-9][a-z0-9_-]*$ && $id != main ]] || die "invalid account name '$name'"
  home="$state_root/$id"
  [[ -s $home/.credentials.json ]] && die "'$id' is already signed in ($home)"

  link_shared "$home"
  carry_settings "$home" once

  cat <<EOF

Sign in as the account you're adding. If the browser reuses another
claude.ai login, open the link in a private window instead.
Don't run \`claude auth logout\` to switch users: it revokes that sign-in.

EOF
  CLAUDE_CONFIG_DIR="$home" claude auth login
  echo
  echo "Added '$id'. Start it with: claude-as $id"
}

case "${1:-}" in
-h | --help | help) usage ;;
list) list ;;
current) current ;;
add)
  shift
  add "$@"
  ;;
"")
  id=$(pick)
  launch "$id"
  ;;
*) launch "$@" ;;
esac
