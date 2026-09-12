PlayerPC::
IF DEF(_JAPAN)
	ld hl, wStatusFlags5
	set BIT_NO_TEXT_DELAY, [hl]
ENDC
	ld a, ITEM_NAME
	ld [wNameListType], a
	call SaveScreenTilesToBuffer1
	xor a
	ld [wBagSavedMenuItem], a
	ld [wParentMenuItem], a
	ld a, [wMiscFlags]
	bit BIT_USING_GENERIC_PC, a
	jr nz, PlayerPCMenu
	ld a, SFX_TURN_ON_PC
	call PlaySound
	ld hl, TurnedOnPC2Text
	call PrintText

PlayerPCMenu:
IF !DEF(_JAPAN)
	ld hl, wStatusFlags5
	set BIT_NO_TEXT_DELAY, [hl]
ENDC
	ld a, [wParentMenuItem]
	ld [wCurrentMenuItem], a
	ld hl, wMiscFlags
	set BIT_NO_MENU_BUTTON_SOUND, [hl]
	call LoadScreenTilesFromBuffer2
	hlcoord 0, 0
IF DEF(_JAPAN)
	lb bc, 8, 10
ELIF DEF(_GERMAN)
	lb bc, 8, 15
ELIF DEF(_ITALIAN)
	lb bc, 8, 16
ELSE
	; English, French, and Spanish.
	lb bc, 8, 14
ENDC
	call TextBoxBorder
	call UpdateSprites
	hlcoord 2, 2
	ld de, PlayersPCMenuEntries
	call PlaceString
	ld hl, wTopMenuItemY
	ld a, 2
	ld [hli], a
	dec a
	ld [hli], a
	inc hl
	inc hl
	ld a, 3
	ld [hli], a
	ld a, PAD_A | PAD_B
	ld [hli], a
	xor a
	ld [hl], a
	ld hl, wListScrollOffset
	ld [hli], a
	ld [hl], a
	ld [wPlayerMonNumber], a
	ld hl, WhatDoYouWantText
	call PrintText
	call HandleMenuInput
	bit B_PAD_B, a
	jp nz, ExitPlayerPC
	call PlaceUnfilledArrowMenuCursor
	ld a, [wCurrentMenuItem]
	ld [wParentMenuItem], a
	and a
	jp z, PlayerPCWithdraw
	dec a
	jp z, PlayerPCDeposit
	dec a
	jp z, PlayerPCToss

ExitPlayerPC:
	ld a, [wMiscFlags]
	bit BIT_USING_GENERIC_PC, a
	jr nz, .next
	ld a, SFX_TURN_OFF_PC
	call PlaySound
	call WaitForSoundToFinish
.next
	ld hl, wMiscFlags
	res BIT_NO_MENU_BUTTON_SOUND, [hl]
	call LoadScreenTilesFromBuffer2
	xor a
	ld [wListScrollOffset], a
	ld [wBagSavedMenuItem], a
	ld hl, wStatusFlags5
	res BIT_NO_TEXT_DELAY, [hl]
	xor a
	ld [wDoNotWaitForButtonPressAfterDisplayingText], a
	ret

PlayerPCDeposit:
	xor a
	ld [wCurrentMenuItem], a
	ld [wListScrollOffset], a
	ld a, [wNumBagItems]
	and a
	jr nz, .loop
	ld hl, NothingToDepositText
	call PrintText
	jp PlayerPCMenu
.loop
	ld hl, WhatToDepositText
	call PrintText
	ld hl, wNumBagItems
	ld a, l
	ld [wListPointer], a
	ld a, h
	ld [wListPointer + 1], a
	xor a
	ld [wPrintItemPrices], a
	ld a, ITEMLISTMENU
	ld [wListMenuID], a
	call DisplayListMenuID
	jp c, PlayerPCMenu
	call IsKeyItem
	ld a, 1
	ld [wItemQuantity], a
	ld a, [wIsKeyItem]
	and a
	jr nz, .next
	ld hl, DepositHowManyText
	call PrintText
	call DisplayChooseQuantityMenu
	cp $ff
	jp z, .loop
.next
	ld hl, wNumBoxItems
	call AddItemToInventory
	jr c, .roomAvailable
	ld hl, NoRoomToStoreText
	call PrintText
	jp .loop
.roomAvailable
	ld hl, wNumBagItems
	call RemoveItemFromInventory
	call WaitForSoundToFinish
	ld a, SFX_WITHDRAW_DEPOSIT
	call PlaySound
	call WaitForSoundToFinish
	ld hl, ItemWasStoredText
	call PrintText
	jp .loop

PlayerPCWithdraw:
	xor a
	ld [wCurrentMenuItem], a
	ld [wListScrollOffset], a
	ld a, [wNumBoxItems]
	and a
	jr nz, .loop
	ld hl, NothingStoredText
	call PrintText
	jp PlayerPCMenu
.loop
	ld hl, WhatToWithdrawText
	call PrintText
	ld hl, wNumBoxItems
	ld a, l
	ld [wListPointer], a
	ld a, h
	ld [wListPointer + 1], a
	xor a
	ld [wPrintItemPrices], a
	ld a, ITEMLISTMENU
	ld [wListMenuID], a
	call DisplayListMenuID
	jp c, PlayerPCMenu
	call IsKeyItem
	ld a, 1
	ld [wItemQuantity], a
	ld a, [wIsKeyItem]
	and a
	jr nz, .next
	ld hl, WithdrawHowManyText
	call PrintText
	call DisplayChooseQuantityMenu
	cp $ff
	jp z, .loop
.next
	ld hl, wNumBagItems
	call AddItemToInventory
	jr c, .roomAvailable
	ld hl, CantCarryMoreText
	call PrintText
	jp .loop
.roomAvailable
	ld hl, wNumBoxItems
	call RemoveItemFromInventory
	call WaitForSoundToFinish
	ld a, SFX_WITHDRAW_DEPOSIT
	call PlaySound
	call WaitForSoundToFinish
	ld hl, WithdrewItemText
	call PrintText
	jp .loop

PlayerPCToss:
	xor a
	ld [wCurrentMenuItem], a
	ld [wListScrollOffset], a
	ld a, [wNumBoxItems]
	and a
	jr nz, .loop
	ld hl, NothingStoredText
	call PrintText
	jp PlayerPCMenu
.loop
	ld hl, WhatToTossText
	call PrintText
	ld hl, wNumBoxItems
	ld a, l
	ld [wListPointer], a
	ld a, h
	ld [wListPointer + 1], a
	xor a
	ld [wPrintItemPrices], a
	ld a, ITEMLISTMENU
	ld [wListMenuID], a
	push hl
	call DisplayListMenuID
	pop hl
	jp c, PlayerPCMenu
	push hl
	call IsKeyItem
	pop hl
	ld a, 1
	ld [wItemQuantity], a
	ld a, [wIsKeyItem]
	and a
	jr nz, .next
	ld a, [wCurItem]
	call IsItemHM
	jr c, .next
	push hl
	ld hl, TossHowManyText
	call PrintText
	call DisplayChooseQuantityMenu
	pop hl
	cp $ff
	jp z, .loop
.next
	call TossItem
	jp .loop

PlayersPCMenuEntries:
IF DEF(_JAPAN)
	db   "どうぐを　ひきだす"
	next "どうぐを　あずける"
	next "どうぐを　すてる"
	next "スイッチを　きる@"
ELIF DEF(_FRENCH)
	db   "RETIRER OBJET"
	next "STOCKER OBJET"
	next "JETER OBJET"
	next "DECONNEXION@"
ELIF DEF(_GERMAN)
	db   "ITEM AUFNEHMEN"
	next "ITEM ABLEGEN"
	next "ITEM WEGWERFEN"
	next "AUSLOGGEN@"
ELIF DEF(_ITALIAN)
	db   "RITIRA STRUM."
	next "DEPOSITA STRUM."
	next "BUTTA STRUM."
	next "DISCONNETTI@"
ELIF DEF(_SPANISH)
	db   "SACAR OBJETO"
	next "DEJAR OBJETO"
	next "TIRAR OBJETO"
	next "DESCONEXI", $cc, "N@" ; Ó = $cc
ELSE
	db   "WITHDRAW ITEM"
	next "DEPOSIT ITEM"
	next "TOSS ITEM"
	next "LOG OFF@"
ENDC

IF DEF(_JAPAN)
TurnedOnPC2Text:
	text "<PLAYER>は"
	line "<PC>の　スイッチを　いれた！"
	prompt
WhatDoYouWantText:
	text "なにを　しますか？"
	done
WhatToDepositText:
	text "なにを　あずけますか？"
	done
DepositHowManyText:
	text "いくつ　あずけますか？"
	done
ItemWasStoredText:
	text "<PC>つうしんで"
	line "@"
	text_ram wNameBuffer
	text "を　あずけた！"
	prompt
NothingToDepositText:
	text "あずけられる　どうぐを"
	line "もっていません！"
	prompt
NoRoomToStoreText:
	text "どうぐが　いっぱいです"
	line "もう　あずけられません！"
	prompt
WhatToWithdrawText:
	text "なにを　ひきだしますか？"
	done
WithdrawHowManyText:
	text "いくつ　ひきだしますか？"
	done
WithdrewItemText:
	text "<PC>つうしんで"
	line "@"
	text_ram wNameBuffer
	text "を　ひきだした！"
	prompt
NothingStoredText:
	text "なにも　あずけていません！"
	prompt
CantCarryMoreText:
	text "どうぐが　いっぱいです"
	line "もう　もてません！"
	prompt
WhatToTossText:
	text "なにを　すてますか？"
	done
TossHowManyText:
	text "いくつ　すてますか？"
	done
ELSE
TurnedOnPC2Text:
	text_far _TurnedOnPC2Text
	text_end
WhatDoYouWantText:
	text_far _WhatDoYouWantText
	text_end
WhatToDepositText:
	text_far _WhatToDepositText
	text_end
DepositHowManyText:
	text_far _DepositHowManyText
	text_end
ItemWasStoredText:
	text_far _ItemWasStoredText
	text_end
NothingToDepositText:
	text_far _NothingToDepositText
	text_end
NoRoomToStoreText:
	text_far _NoRoomToStoreText
	text_end
WhatToWithdrawText:
	text_far _WhatToWithdrawText
	text_end
WithdrawHowManyText:
	text_far _WithdrawHowManyText
	text_end
WithdrewItemText:
	text_far _WithdrewItemText
	text_end
NothingStoredText:
	text_far _NothingStoredText
	text_end
CantCarryMoreText:
	text_far _CantCarryMoreText
	text_end
WhatToTossText:
	text_far _WhatToTossText
	text_end
TossHowManyText:
	text_far _TossHowManyText
	text_end
ENDC
