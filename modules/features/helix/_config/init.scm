;; Run by helix at startup, from $HELIX_STEEL_CONFIG/init.scm.
;;
;; init.scm is evaluated in the *global* environment, so everything a module
;; required here `provide`s becomes a global -- and helix builds its typed
;; command list from the globals defined after startup. That is what turns
;; the oil exports into the `:oil`, `:oil-save`, ... commands; there is no
;; separate registration step.
;;
;; Relative requires resolve against this file, which lives in a read-only
;; store dir -- so any file named here must also be linked into steelConfig
;; in ../default.nix, not just exist in the repo.
;;
;; Cogs come from the `selectPlugins` list in ../default.nix. Requiring a cog
;; that is not in that list fails at editor startup, not at build time.
(require "plugins/oil.scm")

;; file watcher -- required but NOT auto-started: calling (spawn-watcher)
;; here deadlocks helix at startup ~80% of the time (the watcher thread
;; never reaches its event loop while init.scm still holds the engine).
;; Requiring it exposes :spawn-watcher to start it by hand instead.
(require "helix-file-watcher/file-watcher.scm")

;; connect.hx -- ConnectRPC client, developed out of tree at ~/clan/connect.hx.
;; Required here at top level, not from a wrapper module, so its provides land
;; in the global env and helix turns them into typed commands. Right now that
;; is only :connect-doctor, which reports which executors are on PATH.
(require "connect.hx/connect-client.scm")

;; Needed for the `keymap` macro below. Requiring it at top level is fine --
;; init.scm is the global environment, which is where these bindings belong.
(require "helix/keymaps.scm")
;; only-in: init.scm is the global environment, so a bare require would publish
;; every name in misc.scm as a global -- and helix turns post-startup globals
;; into typed commands.
(require (only-in "helix/misc.scm" enqueue-thread-local-callback))

;; Bind connect.hx under `space c`. Done here rather than in keybinds.nix
;; because only the steel keymap path attaches documentation: it reads each
;; bound command's `@doc` string, which is what the space-menu popup shows. A
;; keymap written in the editor config cannot supply that text -- helix skips
;; KeyTrieNode's label when deserialising, so a config-defined submenu renders
;; with a blank description.
;;
;; The installer defers its own registration, for the reason documented at its
;; definition.
(connect-install-keybindings!)

;; Buffer closing under `space B`.
;;
;; Bound here rather than in keybinds.nix so the rows carry their real
;; descriptions ("Close the current buffer.", and the forceful variant). Only
;; the steel keymap path attaches documentation: merge-keybindings feeds
;; keymap-update-documentation! the `@doc` of each bound command. The editor
;; config cannot -- MappableCommand::from_str in this fork builds a typable
;; command's doc as `:name args`, dropping upstream's branch that used the
;; command's own doc when no arguments were given.
;;
;; The names take HYPHENS. `:buffer_close` is not a command at all: the typable
;; commands are buffer-close and buffer-close!, and an unknown `:name` does not
;; fail loudly -- from_str falls back to a placeholder command that only errors
;; when the key is pressed.
;;
;; `B` itself stays absent from the space menu, as every submenu does: its
;; description would be its KeyTrieNode name, which is #[serde(skip)] and
;; untouched by update_documentation. The two entries inside it are documented;
;; the group holding them cannot be.
(enqueue-thread-local-callback
 (lambda ()
   (keymap (global)
           (normal (space (B (c ":buffer-close")
                             (C ":buffer-close!")))))))
