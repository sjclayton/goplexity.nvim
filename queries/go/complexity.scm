; ------------------------------------------------------------------
; goplexity.nvim - queries/go/complexity.scm
; Tree-sitter query for Go complexity analysis
;
; Uses a focused set of captures. All type-based disambiguation (loop
; kind, log increment, sqrt condition, etc.) is done in Lua so that
; the query itself stays maintainable and version-agnostic.
; ------------------------------------------------------------------

; All for loops — classified in Lua by inspecting named children.
(for_statement) @goplexity.loop

; Function declarations (standard and methods).
(function_declaration
  name: (identifier) @goplexity.func.name
  body: (block) @goplexity.func.body) @goplexity.func.decl

(method_declaration
  name: (field_identifier) @goplexity.func.name
  body: (block) @goplexity.func.body) @goplexity.func.decl

; Any selector call: obj.Method(...) or pkg.Function(...)
(call_expression
  function: (selector_expression)) @goplexity.call.qualified

; Unqualified calls — make, new, append, copy, delete, len, cap, go.
(call_expression
  function: (identifier)) @goplexity.call.builtin_expr

; Goroutines
(go_statement) @goplexity.go_stmt
