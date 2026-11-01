; extends

; Highlight YAML between Go template actions in Helm manifests.
((text) @injection.content
  (#set! injection.language "yaml")
  (#set! injection.combined))
