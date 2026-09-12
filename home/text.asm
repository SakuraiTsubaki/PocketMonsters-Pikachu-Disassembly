; Unified Bank 00 text engine.
; Shared control flow is kept common; only real release-family and locale
; differences are conditionalized. See docs/TEXT_ENGINE.md and
; config/text_locale_matrix.json for the evidence/verification matrix.

INCLUDE "home/text/box_and_string.asm"
INCLUDE "home/text/locale_literals.asm"
INCLUDE "home/text/pagination.asm"
INCLUDE "home/text/commands.asm"
