; VENDORED COPY of helix's own runtime queries/rust/injections.scm, plus the
; Leptos `view!` rule at the bottom.
;
; It has to be a full copy. Helix does NOT merge query files across runtime
; dirs -- load_runtime_file (helix-loader/src/grammar.rs) builds ONE path,
; queries/<lang>/<file>, and runtime_file returns the first runtime dir where
; it exists. So this file REPLACES the stock one rather than extending it, and
; anything dropped from it is simply lost: comment injection, rustdoc,
; format_args!, sqlx, regex, json, html!, slint!.
;
; Provenance: helix 25.7.1, via the helix-w-plugins input at
; 09d67dfe7300ab18c267e6b0cbfbb493cce21d37. REFRESH THIS FILE WHEN HELIX IS
; BUMPED -- diff it against $HELIX_DEFAULT_RUNTIME/queries/rust/injections.scm
; in the new build and re-apply the `view!` rule at the end.
;
; --- everything below this line is stock, do not edit -------------------------

([(line_comment !doc) (block_comment !doc)] @injection.content
 (#set! injection.language "comment"))

((doc_comment) @injection.content
 (#set! injection.language "markdown-rustdoc")
 (#set! injection.combined))

((macro_invocation
  (token_tree) @injection.content)
 (#set! injection.language "rust")
 (#set! injection.include-children))

((macro_rule
  (token_tree) @injection.content)
 (#set! injection.language "rust")
 (#set! injection.include-children))

((macro_invocation
   macro:
     [
       (scoped_identifier
         name: (_) @_macro_name)
       (identifier) @_macro_name
     ]
   (token_tree) @injection.content)
 (#eq? @_macro_name "html")
 (#set! injection.language "html")
 (#set! injection.include-children))

((macro_invocation
   macro:
     [
       (scoped_identifier
         name: (_) @_macro_name)
       (identifier) @_macro_name
     ]
   (token_tree) @injection.content)
 (#eq? @_macro_name "slint")
 (#set! injection.language "slint")
 (#set! injection.include-children))

((macro_invocation
   macro:
     [
       (scoped_identifier name: (_) @_macro_name)
       (identifier) @_macro_name
     ]
   (token_tree
     (token_tree . "{" "}" .) @injection.content))
 (#eq? @_macro_name "json")
 (#set! injection.language "json")
 (#set! injection.include-children))

(call_expression
  function: (scoped_identifier
    path: (identifier) @_regex (#any-of? @_regex "Regex" "RegexBuilder")
    name: (identifier) @_new (#eq? @_new "new"))
  arguments:
    (arguments
      [
        (string_literal (string_content) @injection.content)
        (raw_string_literal (string_content) @injection.content)
      ])
  (#set! injection.language "regex"))

(call_expression
  function: (scoped_identifier
    path: (scoped_identifier (identifier) @_regex (#any-of? @_regex "Regex" "RegexBuilder") .)
    name: (identifier) @_new (#eq? @_new "new"))
  arguments:
    (arguments
      [
        (string_literal (string_content) @injection.content)
        (raw_string_literal (string_content) @injection.content)
      ])
  (#set! injection.language "regex"))

; Highlight SQL in `sqlx::query!()`, `sqlx::query_scalar!()`, and `sqlx::query_scalar_unchecked!()`
(macro_invocation
  macro: (scoped_identifier
    path: (identifier) @_sqlx (#eq? @_sqlx "sqlx")
    name: (identifier) @_query (#match? @_query "^query(_scalar|_scalar_unchecked)?$"))
  (token_tree
    ; Only the first argument is SQL
    .
    [
      (string_literal (string_content) @injection.content)
      (raw_string_literal (string_content) @injection.content)
    ]
  )
  (#set! injection.language "sql"))

; Highlight SQL in `sqlx::query_as!()` and `sqlx::query_as_unchecked!()`
(macro_invocation
  macro: (scoped_identifier
    path: (identifier) @_sqlx (#eq? @_sqlx "sqlx")
    name: (identifier) @_query_as (#match? @_query_as "^query_as(_unchecked)?$"))
  (token_tree
    ; Only the second argument is SQL
    .
    ; Allow anything as the first argument in case the user has lower case type
    ; names for some reason
    (_)
    [
      (string_literal (string_content) @injection.content)
      (raw_string_literal (string_content) @injection.content)
    ]
  )
  (#set! injection.language "sql"))

; Highlight SQL in `sqlx::query*` and `sqlx::raw_sql` functions
(call_expression
  function: (scoped_identifier
    path: (identifier) @_sqlx
    (#eq? @_sqlx "sqlx")
    name: (identifier) @_query_function)
  (#match? @_query_function "^query.*|raw_sql$")
  arguments: (arguments
    .
    [
      (string_literal
        (string_content) @injection.content)
      (raw_string_literal
        (string_content) @injection.content)
    ])
  (#set! injection.language "sql"))

; Special language `tree-sitter-rust-format-args` for Rust macros,
; which use `format_args!` under the hood and therefore have
; the `format_args!` syntax.
;
; This language is injected into a hard-coded set of macros.
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
  (#any-of? @_macro_name
    ; 1st argument is `format_args!`

    ; std
    "print" "println" "eprint" "eprintln"
    "format" "format_args" "todo" "panic"
    "unreachable" "unimplemented" "compile_error"
    ; log
    "crit" "trace" "debug" "info" "warn" "error"
    ; anyhow
    "anyhow" "bail"
    ; syn
    "format_ident"
    ; indoc
    "formatdoc" "printdoc" "eprintdoc" "writedoc"
    ; iced
    "text"
    ; ratatui
    "span"
    ; eyre
    "eyre"
    ; miette
    "miette"

    ; 2nd argument is `format_args!`

    ; std
    "write" "writeln" "assert" "debug_assert"
    ; defmt
    "expect" "unwrap"
    ; ratatui
    "span"

    ; 3rd argument is `format_args!`

    ; std
    "assert_eq" "debug_assert_eq" "assert_ne" "debug_assert_ne"

    ; Dioxus's rsx! macro accepts string interpolation in all
    ; strings, across the entire token tree
    "rsx"
  )
  (#set! injection.language "rust-format-args-macro")
  (#set! injection.include-children)
)

; for some queries (e.g. when you have generic table names) you need to wrap it in `AssertSqlSafe`
; after `format!` so it can overwrite `format!` formatting correctly.
(call_expression
  function: [
    (scoped_identifier
      path: (identifier) @_sqlx
      (#eq? @_sqlx "sqlx")
      name: (identifier) @_AssertSqlSafe)
    (identifier) @_AssertSqlSafe
  ]
  (#eq? @_AssertSqlSafe "AssertSqlSafe")
  arguments: (arguments
    [
      (string_literal
        (string_content) @injection.content)
      (raw_string_literal
        (string_content) @injection.content)
      (macro_invocation
        macro: (identifier) @_format
        (#eq? @_format "format")
        (token_tree
          [
            (string_literal
              (string_content) @injection.content)
            (raw_string_literal
              (string_content) @injection.content)
          ]))
    ])
  (#set! injection.language "sql"))

; --- end stock ---------------------------------------------------------------

; Leptos `view!`: parse the macro body with tree-sitter-rstml rather than the
; generic macro->rust rule above. Ordering matters -- the stock file puts the
; catch-all `(macro_invocation (token_tree))` -> rust rule first and lets the
; specific ones (html!, slint!, json!) override it later, so this has to stay
; last.
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
