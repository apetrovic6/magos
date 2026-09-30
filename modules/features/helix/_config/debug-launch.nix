# One-keystroke `cargo` debugging: the two shell helpers behind the `space G d`
# binding in keybinds.nix.
#
# Why they exist at all: helix's own launch flow (`space G l`) prompts for every
# template parameter, and our rust template needs two -- the binary and a tty for
# the debuggee (see the comment above `templates` in languages.nix for why a tty
# has to come from outside helix). `:debug-start <template> <p0> <p1>` takes both
# as arguments instead, and helix expands `%sh{...}` inside them, so a keybind can
# fill them in. These two scripts are what it runs.
#
# Neither builds anything. A `cargo build` inside `%sh{}` would block helix's UI
# for as long as it takes, so an out-of-date or missing binary is reported rather
# than fixed.
{
  pkgs,
  terminalPkg,
}: let
  inherit (pkgs) lib;

  # Resolves the binary to debug from the path of the buffer you are in.
  #
  # Pure shell on purpose: `cargo metadata` would be the principled way, but it
  # needs cargo on PATH (i.e. the dev shell) and can stall on a registry update,
  # and this runs synchronously inside helix's UI thread.
  #
  # Always prints exactly one path, even on failure -- an empty expansion would
  # shift the template's positional parameters, silently handing the tty to
  # `program`. A /nonexistent/... path instead surfaces as a legible adapter
  # error in the statusline.
  resolveBinary = pkgs.writeShellScriptBin "hx-debug-binary" ''
    set -eu

    fail() { printf '%s' "/nonexistent/$1"; exit 0; }

    buf=''${1:-}
    [ -n "$buf" ] || fail "hx-debug-no-buffer"

    dir=$(cd -- "$(dirname -- "$buf")" 2>/dev/null && pwd) || dir=$PWD

    # The crate is the nearest Cargo.toml that actually declares a package: a
    # workspace root has a Cargo.toml too, with only [workspace] in it.
    crate=""
    d=$dir
    while [ "$d" != "/" ]; do
      if [ -f "$d/Cargo.toml" ] && grep -q '^\[package\]' "$d/Cargo.toml"; then
        crate=$d
        break
      fi
      d=$(dirname "$d")
    done
    [ -n "$crate" ] || fail "hx-debug-no-crate-above-''${buf##*/}"

    # An explicit [[bin]] name overrides the package name; take the first one.
    name=$(${lib.getExe pkgs.gnused} -n '/^\[\[bin\]\]/,/^\[[^[]/ s/^[[:space:]]*name[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$crate/Cargo.toml" | head -1)
    if [ -z "$name" ]; then
      name=$(${lib.getExe pkgs.gnused} -n '/^\[package\]/,/^\[/ s/^[[:space:]]*name[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' "$crate/Cargo.toml" | head -1)
    fi
    [ -n "$name" ] || fail "hx-debug-no-package-name"

    # cargo puts every workspace member's output in one target/ at the workspace
    # root, which is the nearest Cargo.lock at or above the crate.
    root=$crate
    d=$crate
    while [ "$d" != "/" ]; do
      if [ -f "$d/Cargo.lock" ]; then
        root=$d
        break
      fi
      d=$(dirname "$d")
    done

    bin="$root/target/debug/$name"

    # Build before launching, with cargo's own output going to the debug console
    # so there is something to watch. Opening the console here rather than
    # letting the second expansion do it is what makes that possible: helix
    # expands arguments left to right, so without this the window would not exist
    # until after the build had already finished.
    #
    # --no-banner because the "launching" line belongs after the build, and the
    # second expansion prints it then.
    console=$(${lib.getExe' ensureConsole "hx-debug-console"} --no-banner) || console=""
    case "$console" in /nonexistent/*) console="" ;; esac

    if command -v cargo >/dev/null 2>&1; then
      if [ -n "$console" ]; then
        {
          printf '\n\033[1m-- cargo build (%s)\033[0m\n' "$name"
          printf '\033[2m   helix cannot redraw until this finishes\033[0m\n'
        } > "$console" 2>/dev/null || true
      fi

      # stdout and stderr both to the tty: cargo checks isatty on its output, so
      # this is what keeps the progress bar and colours rather than the plain
      # log it would emit into a pipe. And the wait is exactly why the console is
      # opened first -- helix is blocked reading this script's stdout to EOF, so
      # the window is the only thing that can show progress.
      if [ -n "$console" ]; then
        ( cd "$crate" && cargo build ) > "$console" 2>&1 || {
          printf '\n\033[1m-- build failed, not launching\033[0m\n' > "$console" 2>/dev/null || true
          fail "hx-debug-build-failed-$name"
        }
      else
        ( cd "$crate" && cargo build ) >/dev/null 2>&1 || fail "hx-debug-build-failed-$name"
      fi
    elif [ -n "$console" ]; then
      # Not fatal: whatever was built last still debugs fine, it may just not be
      # the code on screen. The age in the launch banner below is the warning.
      printf '\n\033[2m-- no cargo on PATH; launching the last build. Start hx from `devenv shell` to build here.\033[0m\n' \
        > "$console" 2>/dev/null || true
    fi

    [ -x "$bin" ] || fail "hx-debug-not-built-$name--run-cargo-build"

    # Leave a banner for hx-debug-console to print. helix expands the arguments
    # left to right, so this always runs before the console script reads it.
    #
    size=$(du -h "$bin" 2>/dev/null | cut -f1)

    # Age rather than a hand-rolled staleness check: cargo above is the authority
    # on whether the binary matches the sources, and a `-newer` heuristic was
    # wrong in practice -- a workspace-wide one fired on `tools/xtask`, which
    # nothing in the counter app depends on. This is only still worth printing
    # for the no-cargo path, where nothing was rebuilt.
    age=$(( $(date +%s) - $(stat -c %Y "$bin") ))
    if   [ "$age" -lt 3600 ];  then age="$((age / 60))m ago"
    elif [ "$age" -lt 86400 ]; then age="$((age / 3600))h ago"
    else                            age="$((age / 86400))d ago"
    fi
    printf '%s (%s, built %s)' "$name" "$size" "$age" > "''${XDG_RUNTIME_DIR:-/tmp}/hx-debug-banner"

    printf '%s' "$bin"
  '';

  # Prints the tty of the debug console window, opening it first if it is not
  # already up. Reused across launches, so this costs a window once per session.
  ensureConsole = pkgs.writeShellScriptBin "hx-debug-console" ''
    set -eu

    state=''${XDG_RUNTIME_DIR:-/tmp}/hx-debug-console
    tty_file=$state.tty
    pid_file=$state.pid

    # Announce the launch in the window the debuggee is about to take over.
    # Without it the only feedback between the keystroke and the app appearing is
    # helix's statusline, which stays empty while codelldb loads symbols --
    # seconds on a large binary, with nothing to say whether anything is
    # happening. hx-debug-binary leaves the text; helix expands arguments left to
    # right, so it has always run by now.
    #
    # Called on both paths below, not just after spawning: reusing an open window
    # is the common case, and that is exactly when the banner is the only sign of
    # life. Best effort -- a window closed behind our back must not fail a launch.
    # --no-banner is for hx-debug-binary, which opens the window early so the
    # build has somewhere to print; the launch line belongs after the build.
    quiet=""
    [ "''${1:-}" = "--no-banner" ] && quiet=1

    announce() {
      [ -z "$quiet" ] || return 0
      banner=''${XDG_RUNTIME_DIR:-/tmp}/hx-debug-banner
      {
        printf '\n\033[2m-- launching %s\033[0m\n' "$(cat "$banner" 2>/dev/null || echo debuggee)"
        printf '\033[2m   loading debug symbols; the app appears when that finishes\033[0m\n\n'
      } > "$1" 2>/dev/null || true
    }

    if [ -r "$pid_file" ] && [ -s "$tty_file" ] && kill -0 "$(cat "$pid_file")" 2>/dev/null; then
      announce "$(cat "$tty_file")"
      printf '%s' "$(cat "$tty_file")"
      exit 0
    fi
    rm -f "$tty_file" "$pid_file"

    # The redirections are load-bearing, not tidiness. helix runs a `%sh{...}`
    # expansion by reading the shell's stdout to EOF, and a backgrounded child
    # inherits that pipe -- leaving foot holding it open, so the expansion never
    # returns and the launch silently never happens. Detaching all three streams
    # (and the session, so closing helix does not take the window with it) is
    # what lets this script exit.
    #
    # `sleep infinity` rather than a shell: a shell sitting at its prompt would
    # read the keystrokes meant for the debuggee. The window reports its own tty
    # from the inside, which is the only place that knows it.
    HX_DEBUG_TTY_FILE=$tty_file setsid ${lib.getExe terminalPkg} \
      --app-id hx-debug-console \
      --title "helix debug console" \
      sh -c 'tty > "$HX_DEBUG_TTY_FILE"; clear; exec sleep infinity' \
      </dev/null >/dev/null 2>&1 &
    printf '%s' "$!" > "$pid_file"

    i=0
    while [ ! -s "$tty_file" ] && [ "$i" -lt 100 ]; do
      i=$((i + 1))
      sleep 0.05
    done

    if [ ! -s "$tty_file" ]; then
      printf '%s' "/nonexistent/hx-debug-console-did-not-start"
      exit 0
    fi

    tty_path=$(cat "$tty_file")
    announce "$tty_path"
    printf '%s' "$tty_path"
    exit 0
  '';
in {
  inherit resolveBinary ensureConsole;
}
