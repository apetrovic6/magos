; Appended to helix's own queries/rust/injections.scm at build time -- see
; customQueries in ../default.nix. Not a standalone query file: helix takes the
; first runtime dir holding queries/rust/injections.scm and does not merge, so
; the stock rules have to travel with this one or they are lost. They are
; concatenated from the very build being wrapped
; (hxPkgs.helix.HELIX_DEFAULT_RUNTIME), so a helix bump carries its own rules
; forward and there is no copy here to drift.

; Leptos `view!`: parse the macro body with tree-sitter-rstml rather than the
; generic macro -> rust rule. Ordering matters -- the stock file puts the
; catch-all `(macro_invocation (token_tree))` -> rust rule first and lets the
; specific ones (html!, slint!, json!) override it later, so this is appended
; rather than prepended.
;
; `rstml` resolves via `injection-regex` on the rstml language entry in
; languages.nix, not by its name.
;
; The whole token_tree is handed over, braces included: the grammar's root rule
; is `choice($.delim_nodes, repeat1($._node_except_block))` with
; `delim_nodes: seq('{', repeat($._node), '}')`, i.e. it expects them.
(
  (macro_invocation
    macro:
      [
        (scoped_identifier
          name: (_) @_macro_name)
        (identifier) @_macro_name
      ]
    (token_tree) @injection.content
  )
  (#eq? @_macro_name "view")
  (#set! injection.language "rstml")
  (#set! injection.include-children)
)
