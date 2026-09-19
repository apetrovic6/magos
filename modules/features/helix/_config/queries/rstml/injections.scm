; Push Rust back into the Rust-shaped holes in the markup. The grammar ships
; only highlights.scm, so without this the interesting half of a `view!` --
; every expression block and event handler -- renders unhighlighted.
;
; Ported from zed-extensions/leptos (languages/rstml/injections.scm), which
; drives the same grammar.

; Attribute values: on:click=move |_| set_count(0), class:active=is_active, ...
; `#not-match?` leaves string-valued attributes alone so the rstml highlights
; keep styling them as strings instead of parsing them as Rust.
((rust_expression) @injection.content
 (#not-match? @injection.content "^(r#*)?\"")
 (#set! injection.language "rust"))

; Braced blocks in the markup: {move || count.get()}
;
; The braces go along for the ride. Rust's root rule wants items, not a bare
; expression, so this parses with errors -- tree-sitter recovers and still
; highlights the tokens. It is the same trade helix already makes for the
; generic macro -> rust injection in queries/rust/injections.scm.
((block) @injection.content
 (#set! injection.language "rust")
 (#set! injection.include-children))
