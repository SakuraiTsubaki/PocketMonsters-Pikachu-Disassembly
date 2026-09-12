EnterMap::
; Load a new map.
	ld a, PAD_BUTTONS | PAD_CTRL_PAD
	ld [wJoyIgnore], a
	call LoadMapData
	farcall ClearVariablesOnEnterMap
	ld hl, wStatusFlags2
	bit BIT_WILD_ENCOUNTER_COOLDOWN, [hl]
	jr z, .skipGivingThreeStepsOfNoRandomBattles
	ld a, 3 ; minimum number of steps between battles
	ld [wNumberOfNoRandomBattleStepsLeft], a
.skipGivingThreeStepsOfNoRandomBattles
	ld hl, wStatusFlags4
	bit BIT_BATTLE_OVER_OR_BLACKOUT, [hl]
	res BIT_BATTLE_OVER_OR_BLACKOUT, [hl]
	call z, ResetUsingStrengthOutOfBattleBit
	call nz, MapEntryAfterBattle
	ld hl, wStatusFlags6
	ld a, [hl]
	and (1 << BIT_FLY_WARP) | (1 << BIT_DUNGEON_WARP)
	jr z, .didNotEnterUsingFlyWarpOrDungeonWarp
	farcall EnterMapAnim
	call UpdateSprites
	ld hl, wStatusFlags6
	res BIT_FLY_WARP, [hl]
	ld hl, wStatusFlags4
	res BIT_NO_BATTLES, [hl]
.didNotEnterUsingFlyWarpOrDungeonWarp
	call IsSurfingPikachuInParty
	farcall CheckForceBikeOrSurf ; handle currents in SF islands and forced bike riding in cycling road
	ld hl, wStatusFlags6
	bit BIT_DUNGEON_WARP, [hl]
	res BIT_DUNGEON_WARP, [hl]
	ld hl, wStatusFlags3
	res BIT_NO_NPC_FACE_PLAYER, [hl]
	call UpdateSprites
	ld hl, wCurrentMapScriptFlags
	set BIT_CUR_MAP_LOADED_1, [hl]
	set BIT_CUR_MAP_LOADED_2, [hl]
	xor a
	ld [wJoyIgnore], a

OverworldLoop::
	call DelayFrame
OverworldLoopLessDelay::
	call DelayFrame
	call IsSurfingPikachuInParty
	call LoadGBPal
	call HandleMidJump
	ld a, [wWalkCounter]
	and a
	jp nz, .moveAhead ; if the player sprite has not yet completed the walking animation
	call JoypadOverworld ; get joypad state (which is possibly simulated)
	farcall SafariZoneCheck
	ld a, [wSafariZoneGameOver]
	and a
	jp nz, WarpFound2
	ld hl, wStatusFlags3
	bit BIT_WARP_FROM_CUR_SCRIPT, [hl]
	res BIT_WARP_FROM_CUR_SCRIPT, [hl]
	jp nz, WarpFound2
	ld a, [wStatusFlags6]
	and (1 << BIT_FLY_WARP) | (1 << BIT_DUNGEON_WARP)
	jp nz, HandleFlyWarpOrDungeonWarp
	ld a, [wCurOpponent]
	and a
	jp nz, .newBattle
	ld a, [wStatusFlags5]
	bit BIT_SCRIPTED_MOVEMENT_STATE, a
	jr z, .notSimulating
	ldh a, [hJoyHeld]
	jr .checkIfStartIsPressed
.notSimulating
	ldh a, [hJoyPressed]
.checkIfStartIsPressed
	bit B_PAD_START, a
	jr z, .startButtonNotPressed
; if START is pressed
	xor a ; TEXT_START_MENU
	ldh [hTextID], a
	jp .displayDialogue
.startButtonNotPressed
	bit B_PAD_A, a
	jp z, .checkIfDownButtonIsPressed
; if A is pressed
	ld a, [wStatusFlags5]
	bit BIT_UNKNOWN_5_2, a
	jp nz, .noDirectionButtonsPressed
	call IsPlayerCharacterBeingControlledByGame
	jr nz, .checkForOpponent
	call CheckForHiddenEventOrBookshelfOrCardKeyDoor
	ldh a, [hItemAlreadyFound]
	and a
	jp z, OverworldLoop ; jump if a hidden event or bookshelf was found, but not if a card key door was found
	xor a
	ld [wd435], a ; new yellow address
	call IsSpriteOrSignInFrontOfPlayer
	call Func_0ffe
	ldh a, [hTextID]
	and a
	jp z, OverworldLoop
.displayDialogue
	predef GetTileAndCoordsInFrontOfPlayer
	call UpdateSprites
	ld a, [wMiscFlags]
	bit BIT_TURNING, a
	jr nz, .checkForOpponent
	bit BIT_SEEN_BY_TRAINER, a
	jr nz, .checkForOpponent
	lda_coord 8, 9
	ld [wTilePlayerStandingOn], a ; checked when using Surf for forbidden tile pairs
	call DisplayTextID ; display either the start menu or the NPC/sign text
	ld a, [wEnteringCableClub]
	and a
	jr z, .checkForOpponent
	xor a
	ld [wEnteringCableClub], a
	jp EnterMap
.checkForOpponent
	ld a, [wCurOpponent]
	and a
	jp nz, .newBattle
	jp OverworldLoop

.noDirectionButtonsPressed
	call UpdateSprites
	ld hl, wMiscFlags
	res BIT_TURNING, [hl]
	xor a
	ld [wPikachuCollisionCounter], a
	ld a, 1
	ld [wCheckFor180DegreeTurn], a
	ld a, [wPlayerMovingDirection] ; the direction that was pressed last time
	and a
	jr z, .overworldloop
; if a direction was pressed last time
	ld [wPlayerLastStopDirection], a ; save the last direction
	xor a
	ld [wPlayerMovingDirection], a ; zero the direction
.overworldloop
	jp OverworldLoop

.checkIfDownButtonIsPressed
	ldh a, [hJoyHeld] ; current joypad state
	bit B_PAD_DOWN, a
	jr z, .checkIfUpButtonIsPressed
	ld a, 1
	ld [wSpritePlayerStateData1YStepVector], a
	ld a, PLAYER_DIR_DOWN
	jr .handleDirectionButtonPress

.checkIfUpButtonIsPressed
	bit B_PAD_UP, a
	jr z, .checkIfLeftButtonIsPressed
	ld a, -1
	ld [wSpritePlayerStateData1YStepVector], a
	ld a, PLAYER_DIR_UP
	jr .handleDirectionButtonPress

.checkIfLeftButtonIsPressed
	bit B_PAD_LEFT, a
	jr z, .checkIfRightButtonIsPressed
	ld a, -1
	ld [wSpritePlayerStateData1XStepVector], a
	ld a, PLAYER_DIR_LEFT
	jr .handleDirectionButtonPress

.checkIfRightButtonIsPressed
	bit B_PAD_RIGHT, a
	jr z, .noDirectionButtonsPressed
	ld a, 1
	ld [wSpritePlayerStateData1XStepVector], a
	ld a, PLAYER_DIR_RIGHT

.handleDirectionButtonPress
	ld [wPlayerDirection], a ; new direction
	ld a, [wStatusFlags5]
	bit BIT_SCRIPTED_MOVEMENT_STATE, a
	jr nz, .noDirectionChange ; ignore direction changes if we are
	ld a, [wCheckFor180DegreeTurn]
	and a
	jr z, .noDirectionChange
	ld a, [wPlayerDirection] ; new direction
	ld b, a
	ld a, [wPlayerLastStopDirection] ; old direction
	cp b
	jr z, .noDirectionChange
	ld a, 8
	ld [wPikachuCollisionCounter], a
; unlike in red/blue, yellow does not have the 180 degrees odd code
	ld hl, wMiscFlags
	set BIT_TURNING, [hl]
	xor a
	ld [wCheckFor180DegreeTurn], a
	ld a, [wPlayerDirection]
	ld [wPlayerMovingDirection], a
	call NewBattle
	jp c, .battleOccurred
	jp OverworldLoop

.noDirectionChange
	ld a, [wPlayerDirection] ; current direction
	ld [wPlayerMovingDirection], a ; save direction
	call UpdateSprites
	ld a, [wWalkBikeSurfState]
	cp $02 ; surfing
	jr z, .surfing
; not surfing
	call CollisionCheckOnLand
	jr nc, .noCollision
; collision occurred
	push hl
	ld hl, wMovementFlags
	bit BIT_STANDING_ON_WARP, [hl]
	pop hl
	jp z, OverworldLoop
; collision occurred while standing on a warp
	push hl
	call ExtraWarpCheck ; sets carry if there is a potential to warp
	pop hl
	jp c, CheckWarpsCollision
	jp OverworldLoop

.surfing
	call CollisionCheckOnWater
	jp c, OverworldLoop

.noCollision
	ld a, $08
	ld [wWalkCounter], a
	callfar Func_fcc08
	jr .moveAhead2

.moveAhead
	call IsSpinning
	call UpdateSprites

.moveAhead2
	ld hl, wMiscFlags
	res BIT_TURNING, [hl]
	xor a
	ld [wPikachuCollisionCounter], a
	call DoBikeSpeedup
	call AdvancePlayerSprite
	ld a, [wWalkCounter]
	and a
	jp nz, CheckMapConnections ; it seems like this check will never succeed (the other place where CheckMapConnections is run works)
; walking animation finished
	call StepCountCheck
	CheckEvent EVENT_IN_SAFARI_ZONE
	jr z, .notSafariZone
	farcall SafariZoneCheckSteps
	ld a, [wSafariZoneGameOver]
	and a
	jp nz, WarpFound2
.notSafariZone
	ld a, [wIsInBattle]
	and a
	jp nz, CheckWarpsNoCollision
	predef ApplyOutOfBattlePoisonDamage ; also increment daycare mon exp
	ld a, [wOutOfBattleBlackout]
	and a
	jp nz, HandleBlackOut ; if all pokemon fainted
.newBattle
	call NewBattle
	ld hl, wMovementFlags
	res BIT_STANDING_ON_WARP, [hl]
	jp nc, CheckWarpsNoCollision ; check for warps if there was no battle
.battleOccurred
	ld hl, wStatusFlags3
	res BIT_TALKED_TO_TRAINER, [hl]
	ld hl, wStatusFlags7
	res BIT_TRAINER_BATTLE, [hl]
	ld hl, wCurrentMapScriptFlags
	set BIT_CUR_MAP_LOADED_1, [hl]
	set BIT_CUR_MAP_LOADED_2, [hl]
	xor a
	ldh [hJoyHeld], a
	ld a, [wCurMap]
	cp CINNABAR_GYM
	jr nz, .notCinnabarGym
	SetEvent EVENT_2A7
.notCinnabarGym
	ld hl, wStatusFlags4
	set BIT_BATTLE_OVER_OR_BLACKOUT, [hl]
	ld a, [wCurMap]
	cp OAKS_LAB
	jp z, .noFaintCheck ; no blacking out if the player lost to the rival in Oak's lab
	callfar AnyPartyAlive
	ld a, d
	and a
	jr z, AllPokemonFainted
.noFaintCheck
	ld c, 10
	call DelayFrames
	jp EnterMap

StepCountCheck::
	ld a, [wStatusFlags5]
	bit BIT_SCRIPTED_MOVEMENT_STATE, a
	jr nz, .doneStepCounting ; if button presses are being simulated, don't count steps
; step counting
	ld hl, wStepCounter
	dec [hl]
	ld a, [wStatusFlags2]
	bit BIT_WILD_ENCOUNTER_COOLDOWN, a
	jr z, .doneStepCounting
	ld hl, wNumberOfNoRandomBattleStepsLeft
	dec [hl]
	jr nz, .doneStepCounting
	ld hl, wStatusFlags2
	res BIT_WILD_ENCOUNTER_COOLDOWN, [hl] ; indicate that the player has stepped thrice since the last battle
.doneStepCounting
	ret

AllPokemonFainted::
	ld a, LOST_BATTLE
	ld [wIsInBattle], a
	call RunMapScript
	jp HandleBlackOut

; function to determine if there will be a battle and execute it (either a trainer battle or wild battle)
; sets carry if a battle occurred and unsets carry if not
NewBattle::
	ld a, [wStatusFlags3]
	bit BIT_ON_DUNGEON_WARP, a
	jr nz, .noBattle
	call IsPlayerCharacterBeingControlledByGame
	jr nz, .noBattle ; no battle if the player character is under the game's control
	ld a, [wStatusFlags4]
	bit BIT_NO_BATTLES, a
	jr nz, .noBattle
	farjp InitBattle
.noBattle
	and a
	ret

; function to make bikes twice as fast as walking
DoBikeSpeedup::
	ld a, [wWalkBikeSurfState]
	dec a ; riding a bike?
	ret nz
	ld a, [wMovementFlags]
	bit BIT_LEDGE_OR_FISHING, a
	ret nz
	ld a, [wNPCMovementScriptPointerTableNum]
	and a
	ret nz
	ld a, [wCurMap]
	cp ROUTE_17 ; Cycling Road
	jr nz, .goFaster
	ldh a, [hJoyHeld]
	and PAD_UP | PAD_LEFT | PAD_RIGHT
	ret nz
.goFaster
	call AdvancePlayerSprite
	ret

; check if the player has stepped onto a warp after having not collided
CheckWarpsNoCollision::
	ld a, [wNumberOfWarps]
	and a
	jp z, CheckMapConnections
	ld b, 0
	ld a, [wNumberOfWarps]
	ld c, a
	ld a, [wYCoord]
	ld d, a
	ld a, [wXCoord]
	ld e, a
	ld hl, wWarpEntries
CheckWarpsNoCollisionLoop::
	ld a, [hli] ; check if the warp's Y position matches
	cp d
	jr nz, CheckWarpsNoCollisionRetry1
	ld a, [hli] ; check if the warp's X position matches
	cp e
	jr nz, CheckWarpsNoCollisionRetry2
; if a match was found
	push hl
	push bc
	ld hl, wMovementFlags
	set BIT_STANDING_ON_WARP, [hl]
	farcall IsPlayerStandingOnDoorTileOrWarpTile
	pop bc
	pop hl
	jr c, WarpFound1 ; jump if standing on door or warp
	push hl
	push bc
	call ExtraWarpCheck
	pop bc
	pop hl
	jr nc, CheckWarpsNoCollisionRetry2
; if the extra check passed
	ld a, [wStatusFlags7]
	bit BIT_FORCED_WARP, a
	jr nz, WarpFound1
	push de
	push bc
	call Joypad