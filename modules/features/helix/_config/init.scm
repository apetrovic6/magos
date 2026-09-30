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


;; Bind connect.hx under `space H` (c exec, x clear), scoped to .connect and
;; .http files -- helix
;; picks a keymap by the focused file's extension, so the key stays free
;; elsewhere. Bound from steel so the popup shows each command's @doc rather
;; than "Undocumented plugin command"; that only helps steel commands, not
;; native ones. The installer defers its own registration.
(connect-install-keybindings!)

(require "scooter/scooter.scm")
(require "scopeline/scopeline.scm")

;; vista -- markdown rendered in the buffer itself (styled inlay hints +
;; overlays), so headings, bullets, quote bars and code fences get drawn over
;; the source instead of previewing elsewhere. On by default for .md buffers;
;; `:vista-toggle` off/on, `:vista-render` after a theme change.
;; It is only loadable because the helix build is patched with the styled
;; inlay hint / overlay API -- see ../default.nix and
;; ../steel-inlay-hints/README.md, and drop this require together with
;; `p.vista` if the patch is ever dropped.
(require "vista/vista.scm")

;; Rendering is ON: vista re-walks the whole tree and re-issues every decoration
;; on each cursor move and each edit, and it hides characters by adding one
;; overlay per hidden character (~28k overlays for a 1500-line table-heavy plan
;; document). That is only affordable because of the linear-scaling patch in
;; ../steel-inlay-hints -- without it the same navigation costs ~1.7s of CPU per
;; keystroke. `space m m` / `:vista-disable` if you want the raw source back
;; while editing a big one; `(vista-configure! (hash 'enabled #f))` here would
;; make that the default instead (it is global, not per buffer).

;; Only clip the top row when scopeline actually has a scope to show.
;;
;; always-reserved? defaults to #t, which calls set-editor-clip-top! with 1
;; unconditionally -- one row taken off the top of every pane, whether or not
;; there is anything to put in it. That hides line 1 everywhere, which is how
;; the connect.hx response header went missing.
(scopeline-configure! #:always-reserved? #f)
