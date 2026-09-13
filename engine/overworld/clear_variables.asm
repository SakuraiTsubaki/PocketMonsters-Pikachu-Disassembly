; Bank 03 fine-grained family reconstruction.
; Common source lines are emitted once; only source-family differences are conditional.
; JP: Narishma-gb/pokeyellow-jp @ f282e72ae26232790fdb780aa5a5db7ec8ebf572
; INT: pret/pokeyellow @ e89ead154b9968aa50eed9328ff2b38b6c194382

ClearVariablesOnEnterMap::
	ld a, SCREEN_HEIGHT_PX
	ldh [hWY], a
	ldh [rWY], a
	xor a
	ldh [hAutoBGTransferEnabled], a
	ld [wStepCounter], a
	ld [wLoneAttackNo], a
	ldh [hJoyPressed], a
	ldh [hJoyReleased], a
	ldh [hJoyHeld], a
	ld [wActionResultOrTookBattleTurn], a
	ld [wUnusedMapVariable], a
	ld hl, wCardKeyDoorY
	ld [hli], a
	ld [hl], a
	ld hl, wWhichTrade
IF DEF(_JAPAN)
	ld bc, wMiscFlags - wWhichTrade
ELSE
	ld bc, wStandingOnWarpPadOrHole - wWhichTrade
ENDC
	call FillMemory
	ret
