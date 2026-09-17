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


;; Bind connect.hx under `space c`.
;;
;; Bound from steel rather than keybinds.nix because these are steel commands:
;; merge-keybindings feeds keymap-update-documentation! the `@doc` of each one,
;; so the rows read "Execute the request under the cursor..." instead of
;; helix's "Undocumented plugin command" fallback, which is what a steel
;; command bound from the editor config gets.
;;
;; That only applies to STEEL commands. A native typable command gains nothing
;; from being bound here -- see the `space B` bindings in keybinds.nix.
;;
;; `c` itself will not be listed in the space menu, as no user-defined submenu
;; is: a submenu's description is its KeyTrieNode name, which is
;; #[serde(skip)] and untouched by update_documentation, and Info::new writes
;; no row at all for an empty description rather than a blank one. Only the
;; built-in submenus (`space w`) have names, set by the keymap! macro in rust.
;; The bindings work; they are just not discoverable from the menu.
;;
;; The installer defers its own registration, for the reason documented at its
;; definition.
(connect-install-keybindings!)
