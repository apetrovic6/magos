;; oil -- file manager in a buffer: `:oil`, then `:oil-save` to apply edits.
;;
;; This is a *module*, not init.scm, so two things differ from top-level code:
;; it does not inherit init.scm's imports and has to require what it uses, and
;; nothing it defines or requires escapes unless it is in the provide below.
(require "oil/oil.scm")
(require (only-in "helix/commands.scm"
                  (write hx-write)
                  (write-quit hx-write-quit)
                  (quit hx-quit)
                  (quit! hx-quit!)))
(require (only-in "helix/editor.scm"
                  editor-focus
                  editor->doc-id
                  editor-document->path))
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

;; The oil buffer is a scratch buffer, so "no path" is the discriminator:
;; helix exposes set-scratch-buffer-name! but no getter, oil keeps its doc-id
;; private, and #%add-reverse-mapping is write-only from steel -- there is
;; nothing more precise to test against.
(define (in-oil-buffer?)
  (not (editor-document->path (editor->doc-id (editor-focus)))))

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
(define (q . args)
  (if (in-oil-buffer?)
      (oil-close)
      (apply hx-quit args)))

;; :q! must stay a real escape hatch, so the non-oil branch goes to quit!,
;; not quit -- otherwise :q! on a modified buffer gets refused like :q and
;; there is no way out of the editor short of :quit!.
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
