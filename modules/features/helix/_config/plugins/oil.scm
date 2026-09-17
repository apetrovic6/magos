;; oil -- file manager in a buffer: `:oil`, then `:oil-save` to apply edits.
;;
;; This is a *module*, not init.scm, so two things differ from top-level code:
;; it does not inherit init.scm's imports and has to require what it uses, and
;; nothing it defines or requires escapes unless it is in the provide below.
;;
;; oil's own `oil` comes in renamed to `oil-open` so the `oil` defined further
;; down -- the wrapper that records which buffer oil actually opened -- can take
;; its place as the :oil command. That rename is why every other oil export has
;; to be listed by hand: only-in is exhaustive, and a bare `(require
;; "oil/oil.scm")` alongside it would drag `oil` back in and collide with the
;; wrapper. Keep this list and the provide list below in step. Forgetting a name
;; here fails at module load with "free identifier", which is the loud direction
;; and the one to prefer.
(require (only-in "oil/oil.scm"
                  (oil oil-open)
                  oil-enter
                  oil-up
                  oil-root
                  oil-refresh
                  oil-save
                  oil-close
                  oil-toggle-hidden
                  oil-toggle-git-ignored
                  oil-toggle-metadata
                  oil-configure!
                  oil-yank
                  oil-cut
                  oil-paste
                  oil-clipboard-clear
                  OIL-BUFFER-NAME))
(require (only-in "helix/commands.scm"
                  (write hx-write)
                  (write-quit hx-write-quit)
                  (quit hx-quit)
                  (quit! hx-quit!)))
(require (only-in "helix/editor.scm"
                  editor-focus
                  editor->doc-id
                  editor-document->path
                  editor-doc-exists?))
(require (only-in "helix/misc.scm" enqueue-thread-local-callback))
;; Not only-in: this is a module, so nothing it requires leaks into the global
;; env anyway, and `keymap` is a macro rather than a plain binding.
(require "helix/keymaps.scm")

;; helix builds its typed command list from globals, and requiring oil in here
;; rather than in init.scm makes its bindings module-local -- so oil's own
;; commands have to be re-exported or :oil, :oil-save, ... disappear.
(provide oil
         oil-enter
         oil-up
         oil-root
         oil-refresh
         oil-save
         oil-close
         oil-toggle-hidden
         oil-toggle-git-ignored
         oil-toggle-metadata
         oil-configure!
         oil-yank
         oil-cut
         oil-paste
         oil-clipboard-clear
         w
         wq
         q
         q!)

;; show-dotfiles, show-git-ignored -- both #false is the oil default
(oil-configure! #false #false)


;; --- which buffer is the oil buffer -------------------------------------
;;
;; Read this before touching `w`, `wq`, `q` or `q!`, because those four are not
;; scoped to this buffer the way they look. execute_command_line
;; (helix-term/src/commands/typed.rs:4145) asks the scripting engine BEFORE it
;; consults TYPABLE_COMMAND_MAP, and the builtin only wins the tie when
;; identifier_available_at_startup says so (commands/engine/steel/mod.rs:1721) --
;; a set populated from a bare Engine::new(), which means steel primitives and
;; nothing else. `q` is not in it. So whatever `q` is defined to here is what :q
;; runs, in every buffer, for the whole session; keymap-invoked typed commands
;; take the same path (commands.rs:255). The discriminator below is therefore
;; load-bearing for being able to leave the editor at all, and it has to be
;; exact rather than merely plausible.
;;
;; It used to be "the focused buffer has no path", which is wrong in a way that
;; cost a while to find: editor-document->path returns #false for ANY scratch
;; buffer (mod.rs:4891), and the buffer helix starts up with is a scratch. So in
;; a fresh `hx` the test was spuriously true and :q, :q! and :wq all did
;; NOTHING -- no error, no message, editor still running -- because oil-close is
;; buffer-close!, and closing the last document is a visual no-op:
;; Editor::close_document (helix-view/src/editor.rs:2241) turns round and
;; recreates a fresh scratch doc and view. :w was just as bad, popping oil's
;; "no active oil buffer / Run :oil first" where helix would have said "Can't
;; save with no path set!". Any pathless buffer had it, a `:new` scratch too,
;; not merely the startup one.
;;
;; The fix is to record the doc-id when oil opens rather than trying to
;; recognise the buffer afterwards. Recognising it afterwards is not possible:
;; set-scratch-buffer-name! (mod.rs:4824) writes doc.name with no getter beside
;; it, #%add-reverse-mapping (mod.rs:542) only ever writes into
;; BUFFER_EXTENSION_KEYMAP.reverse, and oil keeps its own *oil-doc-id* out of
;; its provide list. Recording is also the sturdier half of the bargain:
;; DocumentIds come off a monotonic counter and are never reused
;; (helix-view/src/editor.rs:2079), so a stale id can stop matching but can
;; never quietly come to mean some other buffer.
(define *oil-doc-id* #false)

;; Guarded on "pathless" -- not as the discriminator this time, just as a
;; promise about what can ever be recorded. If oil ever managed to fail after
;; leaving focus on a real file, recording unguarded would pin that file's
;; doc-id, and :q on it would then buffer-close! the file instead of quitting.
;; A file buffer has a path, so this makes that branch unreachable. Every other
;; way this can go wrong leaves a stale id, which fails toward the native
;; command -- "actually quit" -- and that is the safe direction to fail in.
(define (record-oil-doc-id!)
  (let ([doc-id (editor->doc-id (editor-focus))])
    (when (not (editor-document->path doc-id))
      (set! *oil-doc-id* doc-id))))

;; Deferred, because oil does not have the doc-id yet when it returns: opening
;; a fresh buffer goes helix.new first and sets *oil-doc-id* from its own
;; enqueued callback (oil.scm:320). Ours is enqueued after oil's and so runs
;; after it, by which point focus is the oil buffer. The already-open path
;; switches synchronously and is focused either way, so one order serves both.
;;
;; Ends in a bare `void` deliberately: a non-Void steel return value gets
;; written to the status line (mod.rs:1750), and without this :oil would report
;; whatever enqueue-thread-local-callback happened to hand back.
;;
;; Bare, and NOT `(void)`. In steel `void` is a value, not a nullary procedure
;; the way it is in racket -- the whole stdlib uses it as one (`return! void`,
;; `[else void]`). Calling it costs you ":oil" every time with
;; "BadSyntax: TailCall - Application not a procedure" on the status line, and
;; confusingly the buffer still opens and still works, because the error lands
;; after oil-open has already done its job.
;;
;; The @doc matters beyond documentation: it is what the space-menu popup shows
;; for this binding. keybindings->docs reads the docstring of whatever `:oil`
;; resolves to, and since this wrapper shadows the cog's own `oil`, it is this
;; comment that gets picked up rather than oil's "Open oil file manager". Without
;; it the row falls back to helix's "Undocumented plugin command".
;;@doc
;; Open the oil file manager
(define (oil)
  (oil-open)
  (enqueue-thread-local-callback record-oil-doc-id!)
  void)

;; Three conditions, and every one of them falls through to the native command
;; when it fails: nothing recorded yet, the recorded buffer is gone (oil-close
;; and buffer-close! both land here, which is what makes this self-healing), or
;; focus is simply somewhere else.
(define (in-oil-buffer?)
  (and *oil-doc-id*
       (editor-doc-exists? *oil-doc-id*)
       (equal? *oil-doc-id* (editor->doc-id (editor-focus)))))


(define (w . args)
  (if (in-oil-buffer?)
      (oil-save)
      (apply hx-write args)))

;; oil-save finishes by enqueueing a callback that repopulates the buffer, so
;; closing synchronously would race it -- the close would land first and the
;; repopulate would then run against a dead doc-id. Enqueueing our own close
;; puts it behind oil's in the same queue. oil-close is buffer-close!, the
;; forced variant, which is what a modified scratch buffer needs.
(define (wq . args)
  (if (in-oil-buffer?)
      (begin
        (oil-save)
        (enqueue-thread-local-callback oil-close))
      (apply hx-write-quit args)))

;; :q closes the oil buffer rather than the view. Without this, :q in the oil
;; buffer closes the whole view -- and exits helix when it is the only one --
;; because oil opens via helix.new in the current view rather than a split.
;; Worse than it sounds, and the reason plain buffer-local keymaps are not an
;; adequate substitute here: oil names its scratch buffer, and
;; buffers_remaining_impl (typed.rs) skips named scratches when it checks for
;; unsaved work ("Named scratch documents should not be included here"), so
;; native :q in the oil buffer would not even stop to ask -- it would exit with
;; staged renames still pending. Keymaps cannot cover for this either way; they
;; bind keys, and :q is a typed command.
(define (q . args)
  (if (in-oil-buffer?)
      (oil-close)
      (apply hx-quit args)))

;; :q! must stay a real escape hatch, so the non-oil branch goes to quit!,
;; not quit -- otherwise :q! on a modified buffer gets refused like :q and
;; there is no way out of the editor short of :quit!. Which does still work,
;; for what it is worth: :quit and :quit! are separate entries in
;; TYPABLE_COMMAND_MAP and nothing here shadows them, so they remain the way
;; out if anything in this file ever throws on the way to hx-quit!.
(define (q! . args)
  (if (in-oil-buffer?)
      (oil-close)
      (apply hx-quit! args)))



;; Enter descends into the entry under the cursor.
;;
;; oil already registers its buffer under the label OIL-BUFFER-NAME (via
;; #%add-reverse-mapping when it creates the buffer); this attaches a keymap to
;; that label. Only the keys named here are overridden -- helix looks up the
;; buffer keymap first and falls back to the global one on a miss
;; (ui/editor.rs: handle_keymap_event(..).unwrap_or_else(|| keymaps.get(..))),
;; so the rest of your normal-mode bindings still work inside the oil buffer.
;; Wrapped because this runs at module load: an error here aborts the whole
;; require, so `w`, `wq`, `q`, `q!` below never get defined -- which surfaces
;; later as "free identifier: w" on :w, nowhere near the actual mistake. A bad
;; command name is the usual cause: values need the `:` prefix, or helix looks
;; them up as static commands and fails ("No command named 'oil-up'").
;;
;; Containment only, and silent: steel's with-handler swallows the error and
;; continues but does not actually invoke the handler, so the log call below
;; never fires. If these keys quietly stop working, suspect this block.
;; Deferred rather than run inline: this is module-load code, and an error
;; here would abort the whole require, leaving `w`, `wq`, `q`, `q!` undefined
;; and surfacing later as "free identifier: w" on :w -- nowhere near the real
;; mistake. Registering from a callback means the module finishes loading
;; first, so a bad binding costs you the keys and an editor error, not the
;; commands. (steel's with-handler is not an option here: it swallows the
;; error AND stops the keymap registering at all.)
(enqueue-thread-local-callback
 (lambda ()
   (keymap (buffer OIL-BUFFER-NAME)
           (normal (ret ":oil-enter")
                   (backspace ":oil-up")))))

;; The oil bindings, kept here rather than in keybinds.nix.
;;
;; Not a stylistic choice: only the steel keymap path attaches documentation.
;; merge-keybindings feeds keymap-update-documentation! the `@doc` of every
;; bound command, so `space O` reads "Open the oil file manager". Bound from the
;; editor config it would read "Undocumented plugin command" -- the fallback in
;; MappableCommand::from_str for any `:command` absent from TYPABLE_COMMAND_MAP,
;; which is every steel command.
;;
;; `space O` is a LEAF rather than a `space o` submenu, and that is what makes
;; it visible in the space menu at all. A submenu's description is its
;; KeyTrieNode name; that field is #[serde(skip)] and update_documentation only
;; walks MappableCommand leaves, so it cannot be set from config or from steel.
;; An empty description renders as no row rather than a blank one, because
;; Info::new skips a key whose desc yields no lines -- so a grouped binding
;; works but is never listed. Leaves are the only bindings that can be found by
;; reading the menu.
;;
;; Deferred and separate from the buffer keymap above so a failure in either one
;; cannot take the other down with it.
(enqueue-thread-local-callback
 (lambda ()
   (keymap (global)
           (normal (space (O ":oil"))
                   ("C-." ":oil-toggle-hidden")))))
