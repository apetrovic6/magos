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


;; Bind :connect-exec to `space H`, scoped to .connect and .http files -- helix
;; picks a keymap by the focused file's extension, so the key stays free
;; elsewhere. Bound from steel so the popup shows each command's @doc rather
;; than "Undocumented plugin command"; that only helps steel commands, not
;; native ones. The installer defers its own registration.
(connect-install-keybindings!)
