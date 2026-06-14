; Disassembly of "baserom.gbc"
; This file was created with:
; mgbdis v1.5 - Game Boy ROM disassembler by Matt Currie and contributors.
; https://github.com/mattcurrie/mgbdis

SECTION "ROM Bank $000", ROM0[$0]

INCLUDE "maps.inc"

RST_00::
    pop hl
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a

RST_08::		;called by RST10. Jumps to address at second and third bytes of ROM bank.
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    jp hl

    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ret

;Argument passed H is the new ROM bank, and L is doubled and 0x4001 added to
;find the address of the new function in a jump table. These jump tables are
;found at the top of each valid ROM bank that contains code.
RST_10::
    ld a, [$4000]
    push af
    ld a, h
    ld [$2100], a

RST_18::
    swap a		;swap A to prepare to find correct RAM bank
    rra
    and $03
    ld [$4100], a	;load ram bank

RST_20::
    add hl, hl
    ld h, $00
    ld bc, $4001
    add hl, bc
    db $cd		;call 0008

RST_28::
    ld [$f100], sp
    ld [$2100], a
    swap a

RST_30::
    rra
    and $03
    ld [$4100], a
    ret

    db $ff

RST_38::
    ld e, $01
    ld a, [de]
    inc a
    ld [de], a
    ret

    db $ff, $ff

VBlankInterrupt::
    di
    jp VBlankSaveAF

    ld bc, $181a
    cp b

LCDCInterrupt::
    jp LCDCInterruptHandler


DispatchCD90:
    ld a, [$cd90]
    jr RST_00

TimerOverflowInterrupt::
    reti

    ld a, [$c002]
    or a
    ret

    db $ff, $ff

SerialTransferCompleteInterrupt::
    jp SerialInterruptHandler


    reti


    db $ff, $ff, $ff, $ff

JoypadTransitionInterrupt::
    reti


    di

    push af
    push bc
    push de
    push hl
    ld hl, rLCDC
    res 0, [hl]
    res 1, [hl]
    ld hl, $ddc2
    inc [hl]
    ld a, [$c984]
    or a
    jr nz, VBlankAlternate

    inc a
    ld [$c984], a
    call $ff90
    call LoadCAndHRAM_CE
    add b
    ld b, $0a
    ld hl, $008e

CopyHRAMLoop:
    ld a, [hl+]
    ld [c], a
    inc c
    dec b
    jr nz, CopyHRAMLoop
    ret


    ld a, $c0
    ldh [rDMA], a
    ld a, $28

.wait:
    dec a
    jr nz, .wait
    ret


    inc de
    call $1290
    call $4000
    call $17ba
    xor a
    ld [$c984], a
    pop hl
    pop de
    pop bc
    pop af
    reti


VBlankAlternate:
    call SetScrollRegisters_00C2
    xor a
    ldh [rIF], a
    ld a, [$c999]
    ldh [rIE], a
    ei
    call LoadTileFromHL
    pop hl
    pop de
    pop bc
    pop af
    call $04a7
    reti


SetScrollRegisters_00C2:
    ld hl, $c991
    ld a, [hl+]
    ldh [rSCY], a
    ld a, [hl+]
    ldh [rSCX], a
    ld a, [hl+]
    ldh [rWY], a
    ld a, [hl+]
    ldh [rWX], a
    ld a, [hl+]
    ldh [rBGP], a
    ld a, [hl+]
    ldh [rOBP0], a
    ld a, [hl+]
    ldh [rOBP1], a
    ld a, [hl]
    ldh [rLYC], a
    ld a, [$ddc1]
    ld [$ddc0], a
    ld a, [$c990]
    ldh [rLCDC], a
    ld a, [$ddc7]
    or a
    ret z

    jp RetFromLCDEnable


    db $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff, $ff

Boot::
    nop
    jp BootMain


HeaderLogo::
    db $ce, $ed, $66, $66, $cc, $0d, $00, $0b, $03, $73, $00, $83, $00, $0c, $00, $0d
    db $00, $08, $11, $1f, $88, $89, $00, $0e, $dc, $cc, $6e, $e6, $dd, $dd, $d9, $99
    db $bb, $bb, $67, $63, $6e, $0e, $ec, $cc, $dd, $dc, $99, $9f, $bb, $b9, $33, $3e

HeaderTitle::
    db "DRAGON WMON"

HeaderManufacturerCode::
    db "AWQE"

HeaderCGBFlag::
    db $80

HeaderNewLicenseeCode::
    db $34, $46

HeaderSGBFlag::
    db $03

HeaderCartridgeType::
    db $1b

HeaderROMSize::
    db $06

HeaderRAMSize::
    db $02

HeaderDestinationCode::
    db $01

HeaderOldLicenseeCode::
    db $33

HeaderMaskROMVersion::
    db $00

HeaderComplementCheck::
    db $49

HeaderGlobalChecksum::
    db $52, $71

BootMain:
    cp $11    ;check if running on gameboy color
    ld a, $00 ;
    jr nz, .write_gb_type
    inc a

.write_gb_type:
    ld [wIsGBC], a

InitGameData:
    ld sp, $dfff
    call ClearInterruptFlags
    call ClearAllWRAM
    call $0080

    ld hl, $8000
    ld bc, $1c00
    xor a
    call FillNBytesWithRegA
    ld hl, wGameMode
    xor a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl], a
    ld a, $04
    ld [wTextSpeed], a
    ld a, $00
    ld [wGameMode], a
    ld a, $01
    ld [$6100], a
    ld a, $00
    ld [$4100], a
    ld a, $00
    ld [$6100], a
    ld a, $00
    ld [$4100], a
    ld a, $0a
    ld [$0100], a
    ld a, $01
    ld [$2100], a
    ld a, $00
    ld [$4100], a
    ld a, $01
    ld [wIsSGB], a
    ld a, $ff
    ld [wBGM], a
    ld [wSoundEffect], a
    call InitAudioSystem
    xor a
    ld [$c8c7], a
    ld a, [wIsGBC]
    or a
    jr z, AfterGBCInit

    xor a
    ldh [rVBK], a
    ldh [rSVBK], a
    ldh [rRP], a

AfterGBCInit:
    call InitAudioAndJoypadCheck
    jr c, InitSGBBorders

    xor a
    ld [wIsSGB], a
    jp InitDisplayAndRun


InitSGBBorders:      ;all SGB related
    ld bc, $000c
    call SGBDelay
    ld a, $14
    ld [$c774], a
    ld hl, $0800
    rst $10

    call DisableSRAM
    ld a, $02
    ld [$c774], a
    ld hl, $0800
    rst $10

    call DisableSRAM
    ld a, $03
    ld [$c774], a
    ld hl, $0800
    rst $10

    call DisableSRAM
    ld a, $04
    ld [$c774], a
    ld hl, $0800
    rst $10

    call DisableSRAM
    ld a, $05
    ld [$c774], a
    ld hl, $0800
    rst $10

    call DisableSRAM
    ld a, $06
    ld [$c774], a
    ld hl, $0800
    rst $10

    call DisableSRAM
    ld a, $07
    ld [$c774], a
    ld hl, $0800
    rst $10

    call DisableSRAM
    ld a, $08
    ld [$c774], a
    ld hl, $0800
    rst $10

    call DisableSRAM
    ld a, $09
    ld [$c774], a
    ld hl, $0800
    rst $10

    call DisableSRAM
    ld a, $0c
    ld de, $0803
    ld bc, $0800
    call TransferSGBPacket
    call DisableSRAM
    ld a, $0d
    ld de, $0804
    call LoadSGBTiles
    call DisableSRAM
    ld a, $12

TransferSGBFinal:
    ld [$c774], a
    ld hl, $0800
    rst $10

    call DisableSRAM
    ld a, $0a
    ld [$c774], a
    ld hl, $0800
    rst $10

    call DisableSRAM
    ld a, $13
    ld [$c774], a
    ld hl, $0800
    rst $10

    call DisableSRAM
    ld a, $01
    ld [wIsSGB], a
    ld a, $ff
    ld [$c81b], a

InitDisplayAndRun:
    call TileMapWrite_12A5
    call ClearOAMBuffer
    call SetDefaultPalette
    call ClearHRAMTimers
    call CachePalettesToHRAM

    xor a
    ld [$c86a], a
    ld [$c825], a
    ld [$c829], a
    ld [$c82a], a
    ld [$c8c8], a
    ld [$c8c9], a
    ld [$df0e], a
    call GameModeDispatch

    xor a
    ld [$c88e], a
    ld [$c88f], a
    ld [$c8a3], a
    ld [$c740], a
    ld [$c741], a
    ld [$c8a2], a
    ld [$c8a4], a
    ld [$c8a5], a
    ldh [$d3], a
    ld [$c8b9], a
    ld [$da78], a
    ld hl, $c8b1
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl], a

MainWaitLoop:
    ld a, [$c86c]
    or a
    call z, GenerateRNG
    ld a, [$c88e]
    or a
    jr z, MainWaitLoop
    ld a, [$c850]
    or a
    jr z, ExitWaitReinit

    bit 7, a
    jr z, MainWaitLoop

ExitWaitReinit:
    di
    ld a, [$c86c]
    or a
    call nz, InitAudioSystem
    call ClearInterruptFlags
    call DisableSRAM
    ld a, $00
    ld [$c774], a

    ld hl, $0800
    rst $10

    call DisableSRAM
    jp InitDisplayAndRun

GameModeDispatch:
    ld a, [wGameMode]
    rst $00


;all names were derived from the Japanese debug menu.
    dw Goto_Title
    dw Goto_Game
    dw Goto_Battle
    dw Goto_EvtDemo   ;plays ending cutscene by default, may have others.
    dw Goto_Staff
    dw Goto_Effect    ;attack animation debugger
    dw Goto_Result
    dw Goto_Debug
    dw Goto_ObjTest   ;monster follower sprite viewer
    dw Goto_No_More   ;Unused tutorial
    dw Goto_Unnamed1  ;corrupted version of unused tutorial
    dw Goto_Message_Debug  ;cannot be accessed from Goto Program menu.
    dw Goto_Unnamed2  ;unknown. screen goes white, game resets if A is pressed.

Goto_Title:
    ld hl, $1500
    rst $10
    ret

Goto_Game:
    ld hl, $0100
    rst $10
    ret

Goto_Battle:
    ld hl, $5000
    rst $10
    ret

Goto_EvtDemo:
    ld hl, $0201
    rst $10
    ret

Goto_Staff:
    ld hl, $5f00
    rst $10
    ret

Goto_Effect:
    ld hl, $5f08
    rst $10
    ret

Goto_Result:
    ld hl, $1800
    rst $10
    ret

Goto_Debug:
    ld hl, $550d
    rst $10
    ret

Goto_ObjTest:
    ld hl, $5900
    rst $10
    ret

Goto_No_More:
    ld hl, $5902
    rst $10
    ret

Goto_Unnamed1:
    ld hl, $5904
    rst $10
    ret

Goto_Message_Debug:
    ld hl, $5603
    rst $10
    ret

Goto_Unnamed2:
    ld hl, $5607
    rst $10
    ret


VBlankSaveAF:
    push af

GameStateUpdate_036F:
    push bc
    push de
    push hl
    ld hl, $c8a2
    bit 0, [hl]
    jp nz, VBlankReentry

    set 0, [hl]
    call $ff80
    call CheckScreenTransition

ScreenRefreshVBlank:
    call LoadGBCPalettes
    call ApplyScrollRegisters
    call CheckSoundQueueState
    call WaitVRAMAccess
    ld a, [$c86c]
    or a
    jr z, VBlankEnableInt

    ld a, [$c8b9]
    or a
    call z, SaveBankAndAudioState

VBlankEnableInt:
    ei
    ld a, [$c86c]
    or a
    jr nz, VBlankProcessAudio

    call UpdateSGBJoypad
    call UpdateJoypadState
    ld hl, $c8b9
    inc [hl]
    call SaveBankAndAudioState
    xor a
    ld [$c8b9], a

VBlankProcessAudio:
    call ProcessBGMQueue
    call ProcessFrameUpdate
    ld a, [$c86c]
    or a
    jr nz, SoftReset
    ld a, [$c825]
    or a
    call nz, CheckState_C826_0618
    call CheckState_C850_17EC
    ld a, [$c8a4]
    add $01
    ld [$c8a4], a
    ld a, [$c8a5]
    adc $00
    ld [$c8a5], a

SoftReset:
    ld a, [$c842]			;checks if A B Start and Select are pressed
    and $0f
    cp $0f
    jr nz, AfterResetCheck

    ld a, [$c86c]
    or a
    jp z, InitGameData

AfterResetCheck:
    ld a, [$c86c]
    or a
    jr nz, VBlankFinish

    ld a, [$c842]
    and $03				;check if A and B are being pressed
    cp $03
    jr VBlankFinish			;This jump seems to be here to disable the debug menu.
                        ;dummying it out makes the debug menu work from anywhere

    ld a, [wJoypad_current_frame]
    bit 2, a
    jr z, CheckSelectForDebug

    ld hl, $c8ad
    ld a, [wGameMode]
    ld [hl+], a
    ld a, [$c88b]
    ld [hl+], a
    ld a, [$c88c]
    ld [hl+], a
    ld a, [$c88d]
    ld [hl], a
    ld a, $07
    ld [wGameMode], a
    xor a
    ld [$c88b], a
    ld hl, $c88e
    inc [hl]

CheckSelectForDebug:
    ld a, [$c842]
    bit 3, a
    jr z, VBlankFinish

ReadJoypad:
    ld a, [wJoypad_current_frame]
    bit 2, a
    jr z, VBlankFinish

    ld hl, $c8ad
    ld a, [wGameMode]
    ld [hl+], a
    ld a, [$c88b]
    ld [hl+], a
    ld a, [$c88c]
    ld [hl+], a
    ld a, [$c88d]
    ld [hl], a
    ld a, $0c
    ld [wGameMode], a
    xor a
    ld [$c88b], a
    ld hl, $c88e
    inc [hl]

VBlankFinish:
    ld hl, $c8a2
    res 0, [hl]

VBlankReturn:
    ldh a, [rLY]
    ld [$c886], a
    pop hl
    pop de
    pop bc
    pop af
    reti


VBlankReentry:
    call WaitVRAMAccess
    ld a, [$c8b9]
    or a
    jr nz, VBlankReentryDone

    call SaveBankAndAudioState

VBlankReentryDone:
    ei
    jr VBlankReturn

ProcessFrameUpdate:
    xor a
    ldh [$cb], a
    call CheckAnimLockAndProcess
    ld a, [$c850]
    or a
    jr z, ProcessTilesIfReady

    bit 7, a
    ret z

ProcessTilesIfReady:
    call CheckVRAMTileCount
    ret


CheckState_C86c_047E:
    ld a, [$c86c]
    or a
    ret z

LinkFrameCounter:
    ld a, [$c8c8]
    add $01
    ld [$c8c8], a
    ld a, [$c8c9]
    adc $00
    ld [$c8c9], a
    ld a, [$c8c9]
    or a
    jp nz, InitGameData

    ld a, [$c863]
    bit 1, a
    ret nz

    ld a, [$c8a2]
    bit 1, a
    ret nz

    ld a, [$c842]
    ld [$c84e], a
    ld a, [$c843]
    ld [$c84f], a
    call UpdateSGBJoypad
    ld a, [$c873]
    cp $ff
    jr z, CheckStoredPointer

    ld a, $00
    ld [$c866], a
    ld a, [$c873]
    jp Jump_000_126b


CheckStoredPointer:
    ld hl, $c871
    ld a, [hl+]
    or [hl]
    jr z, SendBlankTile

GetStoredPointerHL:
    ld a, [$c874]
    ld l, a
    ld a, [$c875]
    ld h, a
    push hl
    ld a, [$c874]
    add $01
    ld [$c874], a
    ld a, [$c875]
    adc $00
    ld [$c875], a
    pop hl
    ld a, $00
    ld [$c866], a

LoadTileFromHL:
    ld a, [hl]
    jp Jump_000_126b


SendBlankTile:
    ld a, $00
    ld [$c866], a
    ld a, $f0
    jp Jump_000_126b


CheckAnimLockAndProcess:
    ld a, [$c88e]
    or a
    ret nz

    ld a, [$c86c]
    or a
    jr nz, DispatchByGameMode

    ld a, [$c850]
    or a
    jr z, DispatchByGameMode

    bit 7, a
    ret z

DispatchByGameMode:
    ld a, [wGameMode]

    rst $00

    dec l
    dec b

BankTrampolineTable:
Jump_000_0515:
    ld [hl-], a
    dec b
    scf
    dec b
    inc a
    dec b
    ld b, c
    dec b
    ld b, [hl]
    dec b
    ld c, e
    dec b
    ld d, b
    dec b
    ld d, l
    dec b
    ld e, d
    dec b
    ld e, a
    dec b
    ld h, h
    dec b
    ld l, c
    dec b

    ld hl, $1501
    rst $10
    ret


    ld hl, $0101
    rst $10
    ret


    ld hl, $5001
    rst $10
    ret


CallBank02Entry2:
    ld hl, $0202
    rst $10
    ret


CallBank5FEntry1_0541:
    ld hl, $5f01
    rst $10
    ret


    ld hl, $5f09
    rst $10

RetStub054A:
    ret


    ld hl, $1801
    rst $10
    ret


CallBank55Entry14_0550:
    ld hl, $550e
    rst $10
    ret


    ld hl, $5901
    rst $10
    ret


CallBank59Entry3_055A:
Jump_000_055a:
    ld hl, $5903
    rst $10
    ret


    ld hl, $5905
    rst $10
    ret


CallTextRenderer:
Jump_CallTextRenderer:
    ld hl, $5604
    rst $10
    ret


CallBank56Entry8_0569:
    ld hl, $5608

CrossBankCallRst10:
    rst $10

RetFromCrossBankCall:
    ret


CheckSoundQueueState:
Jump_000_056e:
    ld a, [$c8b1]
    or a
    jr z, CheckShakeX

    dec a
    ld [$c8b1], a
    ldh a, [rSCY]
    ld b, a
    ld a, [$c8b1]
    add a
    ld c, a
    and $07
    bit 3, c
    jr nz, ApplyShakeOffsetY

    xor $07

ApplyShakeOffsetY:
    sub $04
    add b
    ldh [rSCY], a

CheckShakeX:
    ld a, [$c8b2]
    or a
    jr z, ShakeDone

    dec a
    ld [$c8b2], a
    ldh a, [rSCX]
    ld b, a
    ld a, [$c8b2]
    add a
    ld c, a
    and $07
    bit 3, c
    jr nz, ApplyShakeOffsetX

InvertShakeX:
    xor $07

ApplyShakeOffsetX:
    sub $04
    add b
    ldh [rSCX], a

ShakeDone:
    ret


CheckScreenTransition:
    ld a, [$c8a3]
    or a
    ret z

    call GetSpritePointerDE
    ret


CallTextEngine:
    push de

CallBank56Entry5_05B7:
    ld hl, $5605
    rst $10
    ld a, [$c827]

LoadTextPointerHL:
    ld l, a
    ld a, [$c828]
    ld h, a

StoreMapPointerRegs:
Jump_000_05c3:
    ld a, l
    ld [$c82b], a
    ld a, h
    ld [$c82c], a

StoreScreenPointerHL:
    ld a, l

StoreScreenPointer:
    ld [$c82f], a
    ld a, h
    ld [$c830], a
    pop de
    call SaveBankAndSwitch
    ld a, e
    ld [$c82d], a
    ld a, d
    ld [$c82e], a
    ld a, e
    ld [$c831], a

TriggerMapRedraw:
Jump_000_05e3:
    ld a, d
    ld [$c832], a
    ld a, $01
    ld [$c825], a
    ld a, $00
    ld [$c826], a
    xor a
    ld [$c839], a
    ret


RunTextHandler:
    call SaveBankAndSwitch

LoadDestFromC837:
    ld a, [$c837]

LoadDestLow:
    ld l, a

LoadDestHigh:
    ld a, [$c838]

CopyDE2HL_0600:
Jump_000_0600:
    ld h, a

CopyDEtoHLByteAlias:
CopyDEtoHLByte:
    ld a, [de]
    ld [hl+], a
    inc de

CheckTextTerminator:
    cp $f0
    jr nz, CopyDEtoHLByte

RetUnused:
    ret


RequestScreenUpdate:
Jump_000_0609:
    ld hl, $c825

SetScreenUpdateFlag:
    set 1, [hl]

WaitScreenUpdateDone:
    call CheckState_C826_0618
    ld a, [$c825]
    or a
    jr nz, WaitScreenUpdateDone

    ret


CheckState_C826_0618:
    ld a, [$c826]

CheckScreenUpdateBit7:
    bit 7, a
    jr z, jr_000_062f

RetryScreenUpdate:
    ld hl, $c825

WaitScreenUpdateLoop:
    set 1, [hl]
    call SaveBankForTextDisplay
    ld a, [$c826]
    bit 7, a
    jr nz, RetryScreenUpdate

    ret


SaveBankForTextDisplay:
jr_000_062f:
    ld a, [$4000]

SetupTextBankSwitch:
    push af
    ld a, [$c824]
    ld [$2100], a
    swap a

SetROMBankHigh:
Jump_000_063b:
    rra

SetROMBankHighMask:
    and $03

WriteBankSwitch4100:
    ld [$4100], a
    ld a, [$c825]
    or a
    jp z, RestoreBankAndReturn

CheckTilemapBit5:
Jump_000_0648:
    bit 5, a
    jr z, CheckTextInputBitJR

    ld c, $ea
    ld a, [$c8a4]
    bit 4, a
    jr z, UseAlternateArrowTile

    ld c, $ee

UseAlternateArrowTile:
    ld hl, $0060

SetupTilemapRow:
    call AdjustTilemapOffset
    ld b, $09

DrawTilemapColumn:
    call TilemapAdvanceColumns
    ld a, c
    call Write_gfx_tile

CheckTextInputBit:
CheckTextInputBitJR:
    ld a, [$c825]
    bit 2, a
    jp z, CheckTextScrollBit

    ld a, [$c83a]
    cp $e6
    jp z, Jump_000_067e

    ld a, [$c83a]
    cp $ff
    jp nz, CheckDPadInput

WaitForJoypadInput:
Jump_000_067e:
    ld a, [wJoypad_current_frame]
    ld b, a
    ld a, [$c84a]
    or b

GameStateBit_0686:
Jump_000_0686:
    bit 6, a

CheckJoypadMask:
    jr z, jr_000_0698

CheckState_C83c_068A:
Jump_000_068a:
    ld a, [$c83c]

SetJoypadResult:
    cp $00

ClearJoypadState:
    jr z, SetArrowTiles

    ld a, $00

SetJoypadAction:
    ld [$c83c], a
    jr SetArrowTiles

JoypadActionDone:
jr_000_0698:
    bit 7, a
    jr z, SetArrowTiles

    ld a, [$c83c]
    cp $01
    jr z, SetArrowTiles

    ld a, $01
    ld [$c83c], a

SetArrowTiles:
    ld c, $e8
    ld b, $e0

CheckCursorState:
    ld a, [$c83c]
    or a
    jr z, CheckFrameBlinkBit

    ld c, $e0

CheckCursorInput:
    ld b, $e8

CheckFrameBlinkBit:
    ld a, [$c8a4]
    bit 4, a

InputBranchZero:
    jr z, DrawTextArrow

    ld c, $e0

SetBlankArrowTile:
    ld b, $e0

DrawTextArrow:
    push bc
    ld hl, $0120
    call GetTilemapRowAddr
    ld b, $0f
    call TilemapAdvanceColumns
    pop bc

ShowTextAndWait:
Jump_ShowTextAndWait:
    ld a, c
    call Write_gfx_tile
    push bc

DrawMenuRowTilemap:
    ld hl, $0160
    call GetTilemapRowAddr
    ld b, $0f
    call TilemapAdvanceColumns
    pop bc

ProcessJoypadRepeat:
    ld a, b
    call Write_gfx_tile
    ld a, [wJoypad_current_frame]
    ld b, a
    ld a, [$c84a]
    or b
    bit 0, a
    jr z, CheckBButton

    ld a, [$c83c]
    or a
    jr nz, SetCancelFlag

    ld a, [$c83a]

CheckTileE6:
Jump_000_06f8:
    cp $e6
    jp z, ClearTextBitsRedraw

PlayConfirmSound:
    ld a, $59

PlaySoundAndJump:
Jump_000_06ff:
    call PlaySoundEffect
    jr ClearTextBitsRedrawJR

CheckBButton:
    bit 1, a
    jp z, RestoreBankAndReturn

SetCancelFlag:
    ld a, $01
    ld [$c83c], a

ClearTextBitsRedraw:
ClearTextBitsRedrawJR:
    ld hl, $c825
    res 2, [hl]
    res 1, [hl]
    ld hl, $0000
    call GetTilemapRowAddr
    ld de, $c500
    ld c, $12

TilemapFillRow:
FillTilemapRowLoop:
    ld b, $20
    push hl

FillTilemapColLoop:
    ld a, [de]
    call Write_gfx_tile
    ld a, l

TilemapMaskHighBits:
    and $e0
    push af
    ld a, l

TilemapWrapX:
    inc a
    and $1f
    ld l, a

TilemapRecombineAddr:
RecombineTilemapAddr:
    pop af
    or l
    ld l, a

NextTilemapByte:
    inc de
    dec b

FillColumnContinue:
    jr nz, FillTilemapColLoop

    pop hl
    push bc
    ld bc, $0020
    add hl, bc
    ld a, h
    and $03
    or $98
    ld h, a

RestoreRowCounter:
    pop bc

NextTilemapRow:
    dec c
    jr nz, FillTilemapRowLoop

    ld de, $560b

CheckJoypadAB:
    ld hl, $8e50
    call WaitDMATransfer
    jp RestoreBankAndReturn


CheckDPadInput:
    ld a, [wJoypad_current_frame]
    ld b, a
    ld a, [$c84a]
    or b
    and $f7

CheckJoypadDPad:
Jump_000_075d:
    jp z, RestoreBankAndReturn

    ld hl, $c825
    res 2, [hl]
    res 1, [hl]
    call HandleScreenRefresh
    jp RestoreBankAndReturn


CheckTextScrollBit:
    bit 6, a
    jr z, CheckTextDelayBit

    ld a, [$c835]
    dec a
    ld [$c835], a
    or a
    jp z, ClearScrollBit

    ld a, [wJoypad_current_frame]
    ld b, a
    ld a, [$c84a]
    or b

CheckInputMasked:
CheckInputMaskedJP:
    and $f7
    jp z, RestoreBankAndReturn

ClearScrollBit:
    ld hl, $c825
    res 6, [hl]
    call HandleScreenRefresh
    jp RestoreBankAndReturn


CheckTextDelayBit:
    bit 7, a
    jr z, HandleTextCharacter

    ld a, [$c836]
    dec a
    ld [$c836], a
    or a
    jp nz, RestoreBankAndReturn

    ld hl, $c825
    res 7, [hl]
    jp RestoreBankAndReturn


HandleTextCharacter:
    ld a, [$c82d]
    ld l, a
    ld a, [$c82e]
    ld h, a
    ld a, [hl]			;read character for text box.
    cp $8d
    jp z, AdvanceTextPointer

    cp $8e

JoypadAutoRepeat:
    jp z, AdvanceTextPointer

    cp $e0			;e0 brings up the YES NO box.
    jp nc, HandleControlCode

    ld a, [$c825]
    bit 1, a
    jr nz, ResetTextCounter

    ld a, [wJoypad_current_frame]
    ld b, a

SetButtonFlags:
    ld a, [$c84a]
    or b

SetRefreshOnInput:
    and $f7
    jr z, SetDefaultTextSpeed

    ld hl, $c826
    set 7, [hl]

SetDefaultTextSpeed:
    ld a, $02

ScreenProcessA:
Jump_000_07dd:
    ld b, a
    ld a, [$c825]
    bit 3, a
    jr z, CheckCustomTextSpeed

    ld a, [$c833]

ScreenProcessB:
    ld b, a

CheckCustomTextSpeed:
    ld a, [$c839]
    cp b
    jp c, RestoreBankAndReturn

ResetTextCounter:
    xor a
    ld [$c839], a
    ld hl, $c826
    res 1, [hl]

GetNextTextByte:
    call GetTilemapByte

ReadCharFromHL:
    ld a, [hl]

CheckTileE0:
    cp $e0

ScreenBranchNC:
    jp nc, HandleControlCode

    call LoadTileBankAware
    ld a, [$c826]
    bit 0, a

CheckNewlineBit:
    jr z, RestoreBankReturn

CheckTile90:
    ld a, b
    cp $90

ScreenBranchZ:
    jr z, RestoreBankReturn

CheckTile9A:
    cp $9a
    jr z, RestoreBankReturn

    ld a, [$c840]
    call PlaySoundEffect
    ld hl, $c826
    set 1, [hl]
    jr RestoreBankReturn

AdvanceTextPointer:
    ld a, [$c82d]
    add $01
    ld [$c82d], a
    ld a, [$c82e]

AdvanceTextPtrHigh:
    adc $00

SetScreenStateA:
    ld [$c82e], a

ProcessScreenState:
LoadAndProcessTile:
    ld a, [hl]
    call LoadTileBankAware2
    jr RestoreBankReturn

CheckState_C82d_0838:
HandleControlCode:
    ld a, [$c82d]

IncrementA:
    add $01

IncrementScreenCounter:
    ld [$c82d], a
    ld a, [$c82e]
    adc $00
    ld [$c82e], a
    ld a, [hl]
    ld d, a
    ld hl, $5606
    rst $10
    ld hl, $c826
    res 1, [hl]

RestoreBankAndReturn:
RestoreBankReturn:
    ld hl, $c839

IncrementHLAndPop:
    inc [hl]
    pop af
    ld [$2100], a
    swap a
    rra
    and $03
    ld [$4100], a
    ret


HandleScreenRefresh:
    ld a, [$c825]	;
    bit 5, a
    ret z

    res 5, a
    ld [$c825], a
    ld hl, $0060
    call AdjustTilemapOffset
    ld b, $09
    call TilemapAdvanceColumns
    ld a, $ee
    call Write_gfx_tile

RetNop_087F:
    ret


LoadTileBankAware:
    ld l, a
    ld a, [$4000]
    push af
    ld a, $4f
    ld [$2100], a
    swap a
    rra
    and $03
    ld [$4100], a
    call LoadTile8Bytes
    pop af
    ld [$2100], a
    swap a
    rra
    and $03
    ld [$4100], a
    ret


LoadTile8Bytes:
    call ComputeTileDataAddr
    ld c, $08

LoadTileByteLoop:
    di

WaitSTATForTile:		;wait for vblank
    ldh a, [rSTAT]
    bit 1, a
    jr nz, WaitSTATForTile

WriteTileBytePair:
    ld a, [de]
    ld [hl+], a		;load tile data into vram and increment. Used when drawing text.
    inc e
    ld a, [de]
    ld [hl+], a
    ei
    inc de
    dec c
    jr nz, LoadTileByteLoop

    ld a, l
    ld [$c82b], a
    ld a, h
    ld [$c82c], a
    ret


LoadTileBankAware2:
    ld l, a
    ld a, [$4000]
    push af
    ld a, $4f
    ld [$2100], a
    swap a
    rra
    and $03
    ld [$4100], a
    call ComputeAndLoadTile

RestoreBankAfterTile:
    pop af
    ld [$2100], a
    swap a
    rra
    and $03
    ld [$4100], a
    ret


ComputeAndLoadTile:
    call ComputeTileDataAddr

SubtractTileOffset16:
    ld a, l
    sub $10
    ld l, a
    ld a, h
    sbc $00
    ld h, a
    ld b, $10

OverlayTileLoop:
    di
    ld a, b
    cp $0d
    jr z, WaitSTATForOverlayB

WaitSTATForOverlay:
    ldh a, [rSTAT]
    bit 1, a
    jr nz, WaitSTATForOverlay

    ld a, [de]
    or [hl]
    ld [hl+], a
    jr OverlayTileNext

WaitSTATForOverlayB:
    ldh a, [rSTAT]
    bit 1, a
    jr nz, WaitSTATForOverlayB

    ld a, [de]
    or [hl]
    and $fd
    ld [hl+], a

OverlayTileNext:
    ei
    inc de
    dec b
    jr nz, OverlayTileLoop

    ld a, l

StoreMapPointerHL:
    ld [$c82b], a
    ld a, h
    ld [$c82c], a
    ret


ComputeTileDataAddr:
    ld de, $4010
    ld h, $00

MultiplyHL_091F:
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, de
    ld e, l
    ld d, h
    ld a, [$c82b]
    ld l, a
    ld a, [$c82c]
    ld h, a
    ret


SaveBankAndSwitch:
    ld a, [$4000]
    push af
    ld a, [$4000]
    ld [$c824], a
    ld a, [$c822]
    ld l, a

LookupDoublePtrTable:
    ld h, $00
    add hl, hl

TextHandler_0940:
    add hl, de
    ld e, [hl]
    inc hl
    ld d, [hl]
    ld a, [$c823]
    ld l, a
    ld h, $00
    add hl, hl
    add hl, de
    ld e, [hl]
    inc hl
    ld d, [hl]
    pop af
    ld [$2100], a
    ret


GetTilemapByte:
    ld a, [$c82d]

ReadScreenState:
    ld l, a
    ld a, [$c82e]
    ld h, a
    ld a, [$c82d]
    add $01
    ld [$c82d], a
    ld a, [$c82e]
    adc $00
    ld [$c82e], a
    ret


; SetupTilemapTransfer: Store source/dest for tilemap VRAM transfer
SetupTilemapTransfer:
    ld a, h
    ld [$c822], a
    ld a, l
    ld [$c823], a
    ld hl, $4100
    rst $10
    ret


; SetupVRAMParams: Store DE/HL as VRAM transfer parameters
SetupVRAMParams:
    ld a, e
    ld [$c837], a
    ld a, d
    ld [$c838], a
    ld a, h
    ld [$c822], a
    ld a, l
    ld [$c823], a
    ld hl, $4101
    rst $10
    ret


SetupVRAMCopy:
    ld a, l
    ld [$c827], a
    ld a, h
    ld [$c828], a
    ld a, e
    ld [$c829], a
    ld a, d
    ld [$c82a], a
    ld hl, $5605
    rst $10
    ret


ExtractDigits:
    cp $64
    jr nc, ExtractHundredsDigit

    cp $0a
    jr nc, ExtractTensDigit

    jr StoreOnesAndTerminate

ExtractHundredsDigit:
    ld e, $64
    call SetDMinusOne

ExtractTensDigit:
    ld e, $0a
    call SetDMinusOne

StoreOnesAndTerminate:
    ld [hl+], a
    ld a, $f0
    ld [hl], a
    ret


SetDMinusOne:
    ld d, $ff

DivSubtractLoop:
    inc d

SubtractWithFloor:
    sub e
    jr nc, DivSubtractLoop
    add e
    ld [hl], d
    inc hl
    ret


FormatLargeNumber:
    ld a, $0f
    ldh [$db], a
    ld e, $40
    ld d, $42
    call ReadHRAM_d5_0A2E
    or a
    jp nz, FormatMillions

    ld a, $01
    ldh [$db], a
    ld e, $a0
    ld d, $86
    call ReadHRAM_d5_0A2E
    or a
    jr nz, FormatHundredThousands

    ld a, $00
    ldh [$db], a
    ld e, $10
    ld d, $27
    call ReadHRAM_d5_0A2E
    or a
    jr nz, FormatTenThousands

    ldh a, [$d5]
    ld c, a
    ldh a, [$d6]
    ld b, a
    jp Jump_FormatDecimalDigits


FormatMillions:
    ld a, $0f
    ldh [$db], a
    ld e, $40
    ld d, $42
    call GetHRAMPointerA
    call WriteByteAndTerminate

FormatHundredThousands:
    ld a, $01
    ldh [$db], a
    ld e, $a0
    ld d, $86
    call GetHRAMPointerA
    call WriteByteAndTerminate

FormatTenThousands:
    ld a, $00
    ldh [$db], a
    ld e, $10
    ld d, $27
    call GetHRAMPointerA
    call WriteByteAndTerminate
    ldh a, [$d5]
    ld c, a
    ldh a, [$d6]
    ld b, a
    jp WriteThousandsDigit


ReadHRAM_d5_0A2E:
    ldh a, [$d5]
    ld [wDebug_main_menu_option], a
    ldh a, [$d6]
    ld [$c0a1], a
    ldh a, [$d7]
    ld [$c0a2], a
    call GetHRAMPointerA
    push af
    ld a, [wDebug_main_menu_option]
    ldh [$d5], a
    ld a, [$c0a1]
    ldh [$d6], a
    ld a, [$c0a2]
    ldh [$d7], a
    pop af
    ret


GetHRAMPointerA:
    push hl
    ldh a, [$db]
    ld l, a
    ld h, $ff

Div24SubtractLoop:
    inc h
    ldh a, [$d5]
    sub e
    ldh [$d5], a
    ldh a, [$d6]
    sbc d
    ldh [$d6], a
    ldh a, [$d7]
    sbc l
    ldh [$d7], a
    jr nc, Div24SubtractLoop

    ldh a, [$d5]
    add e
    ldh [$d5], a
    ldh a, [$d6]
    adc d
    ldh [$d6], a
    ldh a, [$d7]
    adc l
    ldh [$d7], a
    ld a, h
    pop hl
    ret


FormatDecimalDigits:
Jump_FormatDecimalDigits:
    ld de, $03e8
    push bc
    call DivBCbyDE
    pop bc
    or a
    jr nz, WriteThousandsDigitJR

    ld de, $0064
    push bc
    call DivBCbyDE
    pop bc
    or a
    jr nz, WriteHundredsDigit

    ld de, $000a
    push bc
    call DivBCbyDE
    pop bc
    or a
    jr nz, WriteTensDigit

    jr WriteOnesDigit

WriteThousandsDigit:
WriteThousandsDigitJR:
    ld de, $03e8
    call DivBCbyDE
    call WriteByteAndTerminate

WriteHundredsDigit:
    ld de, $0064
    call DivBCbyDE
    call WriteByteAndTerminate

WriteTensDigit:
    ld de, $000a
    call DivBCbyDE
    call WriteByteAndTerminate

WriteOnesDigit:
    ld a, c
    call WriteByteAndTerminate
    ret


DivBCbyDE:
    push hl
    ld h, $ff

DivBCbyDELoop:
    inc h
    ld a, c
    sub e
    ld c, a
    ld a, b
    sbc d
    ld b, a
    jr nc, DivBCbyDELoop

    ld a, c
    add e
    ld c, a
    ld a, b
    adc d
    ld b, a
    ld a, h
    pop hl
    ret



; Queue text display. HL=text ID. Copies to DE, dispatches via RST $00.
; Jump table at $0ADD maps text_ID_high → script handler bank ($42-$4E).
QueueTextByID:
WriteByteAndTerminate:
    ld [hl+], a
    ld a, $f0
    ld [hl], a
    ret


TextBankDispatch:
    ld e, l
    ld d, h
    ld a, h
    rst $00
    pop af
    ld a, [bc]
    inc de
    dec bc
    ld a, $0b
    ld l, c
    dec bc
    sub e
    dec bc
    cp [hl]
    dec bc
    db $fd	;investigate this one byte that doesn't correspond to an instruction. May be a byte of data?


; RST $00 jump table for text dispatch (misassembled as instructions).
; Idx: 0→$42/$43, 1→$43/$44, 2→$44/$45, 3→$46/$47, 4→$47/$48,
; 5→$48/$49/$4A, 6→$4A, 7→$4A/$4B, 8→$4B/$4E, 9→$4E
TextDispatchJumpTable:
TextIdDispatch:
Jump_000_0aea:
    dec bc
    inc de
    inc c
    ccf
    inc c
    ld l, d
    inc c
    ld a, e
    cp $e2
    jr nc, DispatchAboveE2

    ld a, d
    ld [$c822], a
    ld a, e
    ld [$c823], a
    ld hl, $4200

DispatchBank42Rst:	;invalid. Needs to be fixed when bank 04 is merged.
    rst $10

    ret		;unused. May be from a time when RST10 returned.


DispatchAboveE2:
    sub $e2
    ld e, a
    ld a, d


; Text range → bank $43 (Castle mid-game text).
TextDispatch_Bank43:
RunScriptEngine:
Jump_RunScriptEngine:
    ld [$c822], a
    ld a, e
    ld [$c823], a
    ld hl, $4300
    rst $10

    ret


    ld a, e
    sub $00
    ld e, a
    ld a, d
    sbc $01
    ld d, a
    ld a, e
    cp $98
    jr nc, DispatchBank44

    inc d
    ld a, d
    ld [$c822], a
    ld a, e
    ld [$c823], a
    ld hl, $4300
    rst $10

    ret


DispatchBank44:
    sub $98
    ld e, a
    ld a, d
    ld [$c822], a
    ld a, e
    ld [$c823], a
    ld hl, $4400

CrossBankCallRet:
    rst $10

    ret


    ld a, e
    sub $00
    ld e, a
    ld a, d
    sbc $02
    ld d, a
    ld a, e
    cp $44
    jr nc, jr_000_0b59

    inc d
    ld a, d
    ld [$c822], a
    ld a, e
    ld [$c823], a
    ld hl, $4400
    rst $10

    ret


TextHandler_0B59:
jr_000_0b59:
    sub $44
    ld e, a
    ld a, d
    ld [$c822], a
    ld a, e
    ld [$c823], a
    ld hl, $4500
    rst $10

    ret


    ld a, e
    sub $00
    ld e, a
    ld a, d
    sbc $03
    ld d, a
    ld a, e
    cp $c8
    jr nc, DispatchBank47

    ld a, d
    ld [$c822], a
    ld a, e
    ld [$c823], a
    ld hl, $4600
    rst $10
    ret


DispatchBank47:
    sub $c8
    ld e, a
    ld a, d
    ld [$c822], a
    ld a, e
    ld [$c823], a
    ld hl, $4700
    rst $10

    ret

    ld a, e
    sub $00
    ld e, a
    ld a, d

SubtractBankOffset4:
    sbc $04
    ld d, a

CallScriptByType:
    ld a, e
    cp $74
    jr nc, DispatchBank48

    inc d

TextHandler_0BA1:
Jump_000_0ba1:
    ld a, d
    ld [$c822], a
    ld a, e
    ld [$c823], a
    ld hl, $4700
    rst $10
    ret


DispatchBank48:
    sub $74
    ld e, a
    ld a, d
    ld [$c822], a
    ld a, e
    ld [$c823], a
    ld hl, $4800

CrossBankCallRet_0BBC:
    rst $10
    ret


    ld a, e
    sub $00
    ld e, a
    ld a, d
    sbc $05
    ld d, a
    ld a, e
    cp $12
    jr nc, CheckBank49Range

    inc d
    ld a, d

TextHandler_0BCD:
    ld [$c822], a
    ld a, e
    ld [$c823], a
    ld hl, $4800
    rst $10
    ret


CheckBank49Range:
    cp $e0
    jr nc, DispatchBank4A

    sub $12
    ld e, a
    ld a, d
    ld [$c822], a
    ld a, e
    ld [$c823], a
    ld hl, $4900
    rst $10
    ret


DispatchBank4A:
    sub $e0
    ld e, a
    ld a, d
    ld [$c822], a
    ld a, e
    ld [$c823], a
    ld hl, $4a00
    rst $10
    ret


    ld a, e
    sub $00
    ld e, a
    ld a, d
    sbc $06
    ld d, a
    inc d
    ld a, d
    ld [$c822], a
    ld a, e
    ld [$c823], a
    ld hl, $4a00
    rst $10
    ret


LoadEtoA:
Jump_000_0c13:
    ld a, e
    sub $00
    ld e, a
    ld a, d
    sbc $07
    ld d, a
    ld a, e
    cp $c0
    jr nc, DispatchBank4BHigh

    inc d
    inc d
    ld a, d
    ld [$c822], a
    ld a, e
    ld [$c823], a
    ld hl, $4a00
    rst $10
    ret


DispatchBank4BHigh:
    sub $c0
    ld e, a
    ld a, d
    ld [$c822], a
    ld a, e
    ld [$c823], a

CallBank4B:
    ld hl, $4b00
    rst $10
    ret


    ld a, e
    sub $00
    ld e, a
    ld a, d
    sbc $08
    ld d, a
    ld a, e
    cp $68
    jr nc, DispatchBank4E

    inc d
    ld a, d
    ld [$c822], a
    ld a, e
    ld [$c823], a
    ld hl, $4b00
    rst $10

    ret


DispatchBank4E:
    sub $68
    ld e, a
    ld a, d
    ld [$c822], a
    ld a, e
    ld [$c823], a
    ld hl, $4e00
    rst $10
    ret


    ld a, e
    sub $00
    ld e, a
    ld a, d
    sbc $09
    ld d, a
    inc d
    ld a, d
    ld [$c822], a
    ld a, e
    ld [$c823], a
    ld hl, $4e00
    rst $10
    ret


; Copy4Bytes: Copy 4 bytes from [DE] to [HL]
Copy4Bytes:
    ld b, $04

CopyByteCheckCtrl:
    ld a, [de]
    ld [hl+], a
    inc de
    cp $8d
    jr z, CopyByteCheckCtrl

    cp $8e
    jr z, CopyByteCheckCtrl

    dec b
    jr nz, CopyByteCheckCtrl

    ld a, [de]
    cp $8d
    jr z, AppendCtrlTerminate

    cp $8e
    jr z, AppendCtrlTerminate

    ld [hl], $f0
    ret


AppendCtrlTerminate:
    ld [hl+], a
    ld [hl], $f0
    ret


StoreCursorPos:
    ld a, l
    ld [$c83e], a
    ld a, h
    ld [$c83f], a

GetScrollPixelPosition:
    ld a, [$c827]
    ld e, a

GetScrollTilePosition:
    ld a, [$c828]
    ld d, a
    srl d
    rr e
    srl d
    rr e

PixelToTileCoord:
Jump_000_0cb8:
    srl d
    rr e
    srl d
    rr e
    ld a, [$c829]
    ld c, a
    ld a, [$c82a]
    ld b, a
    ld a, [$c83e]
    ld l, a
    ld a, [$c83f]
    ld h, a

PushAndDrawColumn:
    push bc

DrawColumnTileLoop:
    ld a, e
    call Write_gfx_tile
    call TilemapNextColumn
    inc e
    dec b
    jr nz, DrawColumnTileLoop

    pop bc
    ld hl, $0040
    call AdjustTilemapOffset
    dec c
    jr nz, PushAndDrawColumn

    ret



; Near text dispatch area (4 refs).
TextRelated_0CE7:
TilemapAdvanceColumns:
jr_000_0ce7:
    call TilemapNextColumn
    dec b
    jr nz, jr_000_0ce7

    ret


TilemapNextColumn:
    push af
    ld a, l
    and $e0
    push af
    ld a, l
    inc a
    and $1f
    ld l, a
    pop af
    or l
    ld l, a
    pop af
    ret


AdjustTilemapOffset:
    ld a, [$c83e]
    add l
    ld l, a
    ld a, [$c83f]
    adc h
    and $03
    ld h, a
    ld a, [$c83f]
    and $fc
    or h
    ld h, a
    ret


GetTilemapRowAddr:
    push hl
    ldh a, [$bb]
    and $f8
    ld l, a
    ld h, $00

MultiplyHL_0D19:
Jump_000_0d19:
    add hl, hl
    add hl, hl
    ldh a, [$b7]
    and $f8
    rrca
    rrca
    rrca
    add l
    ld c, a
    ld b, h
    pop hl
    ld a, c
    add l
    ld l, a
    ld a, b
    adc h
    and $03
    ld h, a
    and $03
    or $98
    ld h, a
    ret


LoadTileE0:
jr_000_0d34:
    ld a, $e0
    call Write_gfx_tile
    call TilemapNextColumn
    dec b
    jr nz, jr_000_0d34

    ret


PushHLSetupL:
    push hl
    ld l, a
    ld de, $4010
    ld h, $00
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, de
    ld e, l
    ld d, h
    pop hl
    ld a, [$4000]
    push af
    ld a, $4f
    ld [$2100], a
    swap a
    rra
    and $03
    ld [$4100], a
    ld b, $08

CopyTileDataLoop:
    ld a, [de]
    ld [hl+], a
    inc e
    ld a, [de]
    ld [hl+], a
    inc de
    dec b
    jr nz, CopyTileDataLoop

    pop af
    ld [$2100], a
    swap a
    rra
    and $03
    ld [$4100], a
    ret


ReadNextTextByte:
    ld a, [$4000]
    push af
    ld a, [$c824]	;
    ld [$2100], a
    ld a, [hl]
    ld b, a
    pop af
    ld [$2100], a
    ld a, b
    ret


    db $30, $28, $36, $25, $38, $29	;@TEXT "MESBUF" ;0d8a

    ldh a, [$f0]
    set 7, [hl]
    daa
    ret nc

    ld hl, $ffbb
    ld a, [hl+]
    sub $11
    cpl
    ld c, a
    ld a, [hl]
    sbc $00
    cpl
    ld b, a
    ldh a, [$c5]
    add c
    ldh [$cd], a
    ldh a, [$c6]
    adc b
    ldh [$ce], a
    ld hl, $ffb7
    ld a, [hl+]
    sub $09
    cpl
    ld c, a
    ld a, [hl]
    sbc $00
    cpl
    ld b, a
    ld hl, $ffcf
    ldh a, [$c3]
    add c
    ld c, a
    ld [hl+], a
    ldh a, [$c4]
    adc b
    ld b, a
    ld [hl+], a
    ld a, c
    sub $08
    ld [hl+], a
    ld a, b
    sbc $00
    ld [hl], a
    ldh a, [$c7]
    add a
    add e
    ld l, a
    ld a, $00
    adc d
    ld h, a
    ld a, [hl+]
    ld d, [hl]
    ld e, a
    ldh a, [$c8]
    add a
    add e
    ld l, a
    ld a, $00
    adc d
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ldh a, [$cb]
    add a
    add a
    ld e, a
    ld d, $c0
    ldh a, [$d3]
    or a
    jp nz, SpriteGBCMode

    ldh a, [$c9]
    ld c, a
    ldh a, [$ca]
    and $20
    jr nz, SpriteFlippedYBounds

SpriteCheckYBounds:
    ld a, [hl+]
    cp $80
    ret z

    ld b, a
    jr nc, SpriteYNegOffset
    ldh a, [$cd]
    add b
    ld b, a
    ldh a, [$ce]
    adc $00
    jr nz, SpriteSkipEntry

    ld a, b
    cp $a8
    jr c, SpriteWriteYCoord

    jr SpriteSkipEntry

SpriteYNegOffset:
    ldh a, [$cd]
    add b
    ld b, a
    ldh a, [$ce]
    adc $ff
    jr nz, SpriteSkipEntry

    ld a, b
    cp $a8
    jr c, SpriteWriteYCoord

SpriteSkipEntry:
    inc hl
    inc hl
    inc hl
    jr SpriteCheckYBounds

SpriteWriteYCoord:
    ld a, b
    ld [de], a
    inc e
    ld a, [hl+]
    ld b, a
    rlca
    jr c, SpriteXNegOffset

    ldh a, [$cf]
    add b
    ld b, a
    ldh a, [$d0]
    adc $00
    jr nz, SpriteSkipXEntry

    ld a, b
    cp $b8
    jr c, SpriteWriteXCoord

    jr SpriteSkipXEntry

SpriteXNegOffset:
    ldh a, [$cf]
    add b
    ld b, a
    ldh a, [$d0]
    adc $ff
    jr nz, SpriteSkipXEntry

    ld a, b
    cp $b8
    jr c, SpriteWriteXCoord

SpriteSkipXEntry:
    inc hl
    inc hl
    dec e
    xor a
    ld [de], a
    jr SpriteCheckYBounds

SpriteWriteXCoord:
    ld a, b
    ld [de], a
    inc e
    ld a, [hl+]
    add c
    ld [de], a		;update sprite ID
    inc e
    ldh a, [$ca]
    xor [hl]
    inc hl
    ld [de], a
    inc e
    ldh a, [$cb]
    inc a
    ldh [$cb], a
    cp $28
    jr nz, SpriteCheckYBounds

    ret


SpriteFlippedYBounds:
    ld a, [hl+]
    cp $80
    ret z

    ld b, a
    jr nc, SpriteFlippedYNeg

    ldh a, [$cd]
    add b
    ld b, a
    ldh a, [$ce]
    adc $00
    jr nz, SpriteFlippedSkipY

    ld a, b
    cp $a8
    jr c, SpriteFlippedWriteY

    jr SpriteFlippedSkipY

SpriteFlippedYNeg:
    ldh a, [$cd]
    add b
    ld b, a
    ldh a, [$ce]
    adc $ff
    jr nz, SpriteFlippedSkipY

    ld a, b
    cp $a8
    jr c, SpriteFlippedWriteY

SpriteFlippedSkipY:
    inc hl
    inc hl
    inc hl
    jr SpriteFlippedYBounds

SpriteFlippedWriteY:
    ld a, b
    ld [de], a
    inc e
    ld a, [hl+]
    ld b, a
    rlca
    jr c, SpriteFlippedXNeg

    ldh a, [$d1]
    sub b
    ld b, a
    ldh a, [$d2]
    sbc $00
    jr z, SpriteFlippedWriteX

    jr nz, SpriteFlippedSkipX

    ld a, b
    cp $b8
    jr c, SpriteFlippedWriteX

    jr SpriteFlippedSkipX

SpriteFlippedXNeg:
    ldh a, [$d1]
    sub b
    ld b, a
    ldh a, [$d2]
    sbc $ff
    jr nz, SpriteFlippedSkipX

    ld a, b
    cp $b8
    jr c, SpriteFlippedWriteX

SpriteFlippedSkipX:
    inc hl
    inc hl
    dec e
    xor a
    ld [de], a
    jr SpriteFlippedYBounds

SpriteFlippedWriteX:
    ld a, b
    ld [de], a
    inc e
    ld a, [hl+]
    add c
    ld [de], a
    inc e
    ldh a, [$ca]
    xor [hl]
    inc hl
    ld [de], a
    inc e
    ldh a, [$cb]
    inc a
    ldh [$cb], a
    cp $28
    jr nz, SpriteFlippedYBounds

    ret


SpriteGBCMode:
    ldh a, [$ca]
    and $20
    jr nz, SpriteGBCFlippedRead

SpriteGBCReadEntry:
    ld a, [hl+]
    cp $80
    ret z

    ld c, a
    ld b, $00
    rlca
    jr nc, SpriteGBCYOffset

    dec b

SpriteGBCYOffset:
    ldh a, [$cd]
    add c

LoadCAndHRAM_CE:
    ld c, a
    ldh a, [$ce]
    adc b
    jr nz, SpriteGBCSkipEntry2

    ld a, c
    cp $a8
    jr nc, SpriteGBCSkipEntry2

    ldh a, [$d3]
    or a
    jr z, SpriteGBCWriteByte

    cp $01
    jr nz, SpriteGBCCheckWidth

    ld a, c
    cp $34
    jr c, SpriteGBCSkipEntry2

    jr SpriteGBCWriteByte

SpriteGBCCheckWidth:
    cp $02
    jr nz, SpriteGBCStoreByte

    ld a, c
    cp $71
    jr c, SpriteGBCWriteByte

    jr SpriteGBCSkipEntry2

SpriteGBCStoreByte:
    jr SpriteGBCWriteByte

SpriteGBCSkipEntry2:
    inc hl
    inc hl
    inc hl
    jr SpriteGBCReadEntry

SpriteGBCWriteByte:
    ld a, c
    ld [de], a
    inc e
    ld a, [hl+]
    ld c, a
    ld b, $00
    rlca
    jr nc, SpriteGBCXOffset

    dec b

SpriteGBCXOffset:
    ldh a, [$cf]
    add c
    ld c, a
    ldh a, [$d0]
    adc b
    jr nz, SpriteGBCSkipXEntry

    ld a, c
    cp $b8
    jr c, SpriteGBCWriteAndCheck

SpriteGBCSkipXEntry:
    inc hl
    inc hl
    dec e
    xor a
    ld [de], a
    jr SpriteGBCReadEntry

SpriteGBCWriteAndCheck:
    ld a, c
    ld [de], a
    call SaveHLBC
    jr nc, SpriteGBCSkipXEntry

    inc e
    ldh a, [$c9]
    ld b, a
    ld a, [hl+]
    add b
    ld [de], a
    inc e
    ldh a, [$ca]
    xor [hl]
    inc hl
    ld [de], a
    inc e
    ldh a, [$cb]
    inc a
    ldh [$cb], a
    cp $28
    jr nz, SpriteGBCReadEntry

    ret


SpriteGBCFlippedRead:
    ld a, [hl+]
    cp $80
    ret z

    ld c, a
    ld b, $00
    rlca
    jr nc, SpriteGBCFlippedYOfs

    dec b

SpriteGBCFlippedYOfs:
    ldh a, [$cd]
    add c
    ld c, a
    ldh a, [$ce]
    adc b
    jr nz, SpriteGBCFlipSkip

    ld a, c
    cp $a8
    jr nc, SpriteGBCFlipSkip

    ldh a, [$d3]
    or a
    jr z, SpriteGBCFlipWrite

    cp $01
    jr nz, SpriteGBCFlipCheckW

    ld a, c
    cp $34
    jr c, SpriteGBCFlipSkip

    jr SpriteGBCFlipWrite

SpriteGBCFlipCheckW:
    cp $02
    jr nz, SpriteGBCFlipStore

    ld a, c
    cp $71
    jr c, SpriteGBCFlipWrite

    jr SpriteGBCFlipSkip

SpriteGBCFlipStore:
    jr SpriteGBCFlipWrite

SpriteGBCFlipSkip:
    inc hl
    inc hl
    inc hl
    jr SpriteGBCFlippedRead

SpriteGBCFlipWrite:
    ld a, c
    ld [de], a
    inc e
    ld a, [hl+]
    ld c, a
    ld b, $00
    rlca
    jr nc, SpriteGBCFlipXOfs

    dec b

SpriteGBCFlipXOfs:
    ldh a, [$d1]
    sub c
    ld c, a
    ldh a, [$d2]
    sbc b
    jr nz, SpriteGBCFlipSkipX

    ld a, c
    cp $b8
    jr c, SpriteGBCFlipWriteX

SpriteGBCFlipSkipX:
    inc hl
    inc hl
    dec e
    xor a
    ld [de], a
    jr SpriteGBCFlippedRead

SpriteGBCFlipWriteX:
    ld a, c
    ld [de], a
    call SaveHLBC
    jr nc, SpriteGBCFlipSkipX

    inc e
    ldh a, [$c9]
    ld b, a
    ld a, [hl+]
    add b
    ld [de], a
    inc e
    ldh a, [$ca]
    xor [hl]
    inc hl
    ld [de], a
    inc e
    ldh a, [$cb]
    inc a
    ldh [$cb], a
    cp $28
    jr nz, SpriteGBCFlippedRead

    ret


SaveHLBC:
    push hl
    push bc
    ldh a, [$bb]
    ld b, a
    dec e
    ld a, [de]
    inc e
    add b
    sub $0c
    and $f8
    ld l, a
    ld h, $00
    add hl, hl
    add hl, hl
    ldh a, [$b7]
    ld b, a
    ld a, [de]
    add b
    sub $04
    and $f8
    rrca
    rrca
    rrca
    add l
    ld l, a
    ld a, h
    and $03
    adc $98
    ld h, a
    ldh a, [$d4]
    ld b, a
    di

WaitSTATCheck:
    ldh a, [rSTAT]
    bit 1, a
    jr nz, WaitSTATCheck
    ld a, [hl]
    ei
    cp b
    pop bc
    pop hl
    ret



; Most-called function (31 refs). Core utility.
CoreUtil_1013:
; DisableSRAM: Disable external SRAM access
DisableSRAM:
    ld a, [wIsSGB]
    or a
    ret z

    ld de, $1b58

SGBWaitLoop:		;may just be a .wait?
    nop
    nop
    nop
    dec de
    ld a, d
    or e
    jr nz, SGBWaitLoop

    ret


InitAudioAndJoypadCheck:
    ld a, $0b
    ld [$c774], a
    ld hl, $0800
    rst $10
    call DisableSRAM
    ldh a, [rP1]
    and $03
    cp $03
    jr nz, SGBCleanupReturn

    ld a, $20
    ldh [rP1], a
    ldh a, [rP1]
    ldh a, [rP1]
    ld a, $30
    ldh [rP1], a
    ld a, $10
    ldh [rP1], a
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ld a, $30
    ldh [rP1], a
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    and $03
    cp $03
    jr nz, SGBCleanupReturn

    ld a, $0a
    ld [$c774], a
    ld hl, $0800
    rst $10
    call DisableSRAM
    sub a
    ret


SGBCleanupReturn:
    ld a, $0a
    ld [$c774], a
    ld hl, $0800
    rst $10
    call DisableSRAM
    scf
    ret


ReadJoypadCombined:
    ldh a, [rP1]
    ld b, $04
    ld c, a
    jr ReadJoypadDecode

ReadJoypadRetry:
    ldh a, [rP1]
    cp c
    ret z

ReadJoypadDecode:
    cpl
    and $03
    sla a
    ld d, $00
    ld e, a
    ld hl, $c76c
    add hl, de
    ld a, $20
    ldh [rP1], a
    ldh a, [rP1]
    ldh a, [rP1]
    cpl
    and $0f
    swap a
    ld d, a
    ld a, $30
    ldh [rP1], a
    ld a, $10
    ldh [rP1], a
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    cpl
    and $0f
    or d
    ld d, a
    ld a, [hl+]
    xor d

SGBTransferByte:
    and d
    ld [hl-], a
    ld a, d
    ld [hl], a
    ld a, $30
    ldh [rP1], a
    dec b
    jp nz, ReadJoypadRetry

    ret


SGBDelay:
    ld a, [wIsSGB]
    or a
    ret z

SGBOuterDelay:
    ld de, $06d6

SGBInnerDelay:
    nop
    nop
    nop
    dec de
    ld a, d
    or e
    jr nz, SGBInnerDelay

    dec bc
    ld a, b
    or c
    jr nz, SGBOuterDelay

    ret


LoadSGBTiles:
    ld [$c774], a
    ld a, [wIsSGB]
    or a
    ret z

    call TurnOffLCD
    call ClearHRAMTimers
    xor a
    ldh [rSCX], a
    ldh [rSCY], a
    push de
    ld hl, $8800
    ld bc, $1000
    xor a
    call FillNBytesWithRegA
    pop de
    ld a, $e4
    ldh [rBGP], a
    ld hl, $8800
    call WaitLCDTransfer
    ld hl, $9800
    ld de, $000c
    ld a, $80
    ld c, $0d

SGBFillRowStart:
    ld b, $14

SGBFillTileLoop:
    ld [hl+], a
    inc a
    dec b
    jr nz, SGBFillTileLoop

    add hl, de
    dec c
    jr nz, SGBFillRowStart

    ld a, $81
    ldh [rLCDC], a
    ld [$c8a1], a
    ld bc, $0005
    call SGBDelay
    ld hl, $0800
    rst $10
    ld bc, $0006
    call SGBDelay
    call TurnOffLCD
    ret


; Core utility (9 refs).
CoreUtil_113E:
TransferSGBPacket:
    ld [$c774], a
    ld a, [wIsSGB]
    or a
    ret z

    push bc
    call TurnOffLCD
    call ClearHRAMTimers
    xor a
    ldh [rSCX], a
    ldh [rSCY], a
    ld a, $e4
    ldh [rBGP], a
    pop bc
    ld a, [$4000]
    push af
    push bc
    ld a, d
    ld [$2100], a
    swap a
    rra
    and $03
    ld [$4100], a
    ld a, e
    add a
    ld e, a
    ld d, $00
    ld hl, $4001
    add hl, de
    ld e, [hl]
    inc hl
    ld d, [hl]
    pop bc
    ld hl, $8800

SGBCopyDataLoop:
    ld a, [de]
    ld [hl+], a
    inc de
    dec bc
    ld a, b
    or c
    jr nz, SGBCopyDataLoop

    ld hl, $9800
    ld de, $000c
    ld a, $80
    ld c, $0d

SGBFillRowStart2:
    ld b, $14

SGBFillTileLoop2:
    ld [hl+], a
    inc a
    dec b
    jr nz, SGBFillTileLoop2

    add hl, de
    dec c

EnableLCD:
    jr nz, SGBFillRowStart2

    ld a, $81
    ldh [rLCDC], a
    ld [$c8a1], a
    ld bc, $0005
    call SGBDelay
    ld hl, $0800
    rst $10
    ld bc, $0006
    call SGBDelay
    call TurnOffLCD
    pop af
    ld [$2100], a
    swap a
    rra
    and $03
    ld [$4100], a
    ret


ClearPaletteBuffer:
    push hl
    push bc
    xor a
    ld hl, $c777
    ld c, $10

ClearPalLoop:
    ld [hl+], a
    dec c
    jr nz, ClearPalLoop

    pop bc
    pop hl
    ret


EnableLCDAndInterrupts:
    push af
    ld a, [$c86c]
    or a
    jr z, SkipLinkCheck

    call CheckScreenModeC86C

SkipLinkCheck:
    call EnableLCDScreen
    pop af
    call SetInterruptEnable
    ei
    ret


ClearInterruptFlags:
    xor a
    ldh [rIF], a
    ldh a, [rIE]
    and $e2
    ldh [rIE], a

TurnOffLCD:		;check the LCD status
    ld hl, $ff40
    bit 7, [hl]
    ret z		;if the LCD is off, return

.LCD_On:		;if the LCD is on,
    ldh a, [rLY]	;check for vblank
    cp $91
    jr nz, .LCD_On

    res 7, [hl]		;and once in vblank, turn the LCD off.
    ld hl, $c8a1
    res 7, [hl]
    ret


EnableLCDScreen:
    ld hl, $c8a1
    set 7, [hl]
    ld a, [hl]
    ldh [rLCDC], a
    ld a, [wIsSGB]
    or a
    ret z
    ld a, $01
    ld [$c774], a
    ld hl, $0800
    rst $10

    call DisableSRAM

RetFromLCDEnable:
    ret

    ret


    xor a
    ldh [rIF], a
    ldh a, [rIE]
    and $f7
    ldh [rIE], a
    ret


WaitForSerialTransferEnd:
.wait:
    ldh a, [rSC]
    bit 7, a
    jr nz, .wait

    ret


SetInterruptEnable:
    ld b, a
    xor a
    ldh [rIF], a
    ld a, b
    ldh [rIE], a
    ret


ApplyScrollRegisters:
    ldh a, [$b7]
    ldh [rSCX], a
    ldh a, [$bb]
    ldh [rSCY], a
    ldh a, [$b5]
    ldh [rWX], a
    ldh a, [$b6]
    ldh [rWY], a
    ret


WaitVRAMAccess:
jr_000_1240:
    ldh a, [rSTAT]
    bit 1, a
    jr nz, jr_000_1240

    ld a, [$c8a1]
    ldh [rLCDC], a
    ret


LoadGBCPalettes:
    ld hl, $1703
    rst $10
    ld hl, wBGPalette
    ld a, [hl+]
    ldh [rBGP], a
    ld a, [hl+]
    ldh [rOBP0], a
    ld a, [hl]
    ldh [rOBP1], a
    ret


EnableLYCInterrupt:
    ldh a, [rSTAT]
    or $40
    ldh [rSTAT], a
    ret


ClearSTATMode:
    ldh a, [rSTAT]
    and $07
    ldh [rSTAT], a
    ret


StartSerialTransfer:
Jump_000_126b:
    di
    call SerialTransferStart
    ld a, $81
    ldh [rSC], a
    ei
    ret


SerialTransfer:
Jump_000_1275:
    di
    call SerialTransferStart
    ld a, $80
    ldh [rSC], a
    ei
    ret


SerialTransferStart:
    ld b, a
    ld a, $00
    ldh [rSC], a


; Core utility (7 refs).
CoreUtil_1284:
SetSerialByte:
    ld a, b
    ldh [rSB], a
    ret


ClearAllWRAM:
    ld a, [wIsGBC]
    push af
    ld hl, $c000
    ld bc, $1e00
    xor a
    call FillNBytesWithRegA

ClearHRAMRegion:
    ld hl, $ff8a
    ld bc, $0074
    xor a
    call FillNBytesWithRegA
    pop af
    ld [wIsGBC], a
    ret


TileMapWrite_12A5:
    ld hl, $9800
    ld bc, $0800
    xor a
    call FillNBytesWithRegA
    ld a, [wIsGBC]
    or a
    ret z

    ld a, $01
    ldh [rVBK], a
    ld hl, $9800
    ld bc, $0800
    xor a
    call FillNBytesWithRegA
    ld a, $00
    ldh [rVBK], a
    ret


FillNBytesWithRegA:
    ld d, a

FillMemLoop:
    ld [hl], d 		;so far: breaks here when point set on inventory slot while opening ITEM option in bank. May just be for clearing or settings blocks of data to a single value.
    inc hl		;increment to next inv slot
    dec bc		;decrease counter, which is probably the number of total available inv slots.
    ld a, b		;load b into a to prepare for...
    or c 		;checking to see if the counter is 0
    jr nz, FillMemLoop

    ret


GenerateRNG:
    push hl
    push de
    ld a, [wRNG1]
    ld h, a
    ld a, [wRNG2]
    ld l, a
    ld d, h
    ld e, l
    add hl, hl
    add hl, hl
    add hl, de
    ld de, $1357
    add hl, de
    ld a, h
    ld [wRNG1], a
    ld a, l
    ld [wRNG2], a
    pop de
    pop hl
    ret


UpdateSGBJoypad:
    ld a, [wIsSGB]
    or a
    jr z, ReadJoypadDMG
    call ReadJoypadCombined
    ld a, [$c842]
    ld [$c843], a
    ld a, [$c76c]
    ld [$c842], a
    ld a, [$c844]
    ld [$c845], a
    ld a, [$c76e]
    ld [$c844], a
    ret


ReadJoypadDMG:
    xor a
    ld [$c841], a
    call ReadJoypadButtons
    ld a, [$c842]
    ld [$c843], a
    ld a, b
    ld [$c842], a
    ld a, $30
    ldh [rP1], a
    ret

    call ReadJoypadButtons
    ld a, [$c844]
    ld [$c845], a
    ld a, b
    ld [$c844], a
    ld a, $30
    ldh [rP1], a
    ret


ReadJoypadButtons:
    ld a, $20
    ldh [rP1], a
    ldh a, [rP1]
    ldh a, [rP1]

JoypadBitReformat:
    cpl
    and $0f
    swap a
    ld b, a
    ld a, $10
    ldh [rP1], a
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    ldh a, [rP1]
    cpl
    and $0f
    or b
    ld b, a
    ret


UpdateJoypadState:
    ld a, [$c86c]
    or a
    jr nz, jr_000_1377

    ld a, [$c841]
    or a
    jr nz, jr_000_1377

    xor a
    ld [$c844], a
    ld [$c845], a

WaitForJoypadRelease:
jr_000_1377:
    xor a
    ld [wJoypad_Current], a
    ld hl, $c842
    ld a, [hl]
    inc hl

JoypadDebounce:
    xor [hl]
    dec hl
    and [hl]
    ld [wJoypad_current_frame], a
    ld hl, $c842
    ld a, [hl+]
    or a
    jr z, SetNewJoypadState

    cp [hl]
    jr z, CheckAutoRepeat

SetNewJoypadState:
    ld a, [wJoypad_current_frame]
    ld [wJoypad_Current], a
    ld a, $14

ReadJoypadRaw:
    ld [$c848], a
    jr ClearJoypad2State

CheckAutoRepeat:
    ld hl, $c848
    ld a, [hl]
    or a
    jr nz, DecrementRepeatTimer

    ld [hl], $06
    ld a, [$c842]
    ld [wJoypad_Current], a

DecrementRepeatTimer:
    dec [hl]

ClearJoypad2State:
    xor a
    ld [$c84b], a
    ld hl, $c844
    ld a, [hl]
    inc hl
    xor [hl]
    dec hl
    and [hl]
    ld [$c84a], a
    ld hl, $c844
    ld a, [hl+]
    or a
    jr z, SetJoypad2NewPress

    cp [hl]
    jr z, CheckAutoRepeat2

SetJoypad2NewPress:
    ld a, [$c84a]
    ld [$c84b], a
    ld a, $14
    ld [$c84c], a
    jr RetFromJoypad

CheckAutoRepeat2:
    ld hl, $c84c
    ld a, [hl]
    or a
    jr nz, DecrementRepeatTimer2

    ld [hl], $06
    ld a, [$c844]
    ld [$c84b], a

DecrementRepeatTimer2:
    dec [hl]

RetFromJoypad:
    ret


    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ret


SetDefaultPalette:
    ld hl, wBGPalette
    ld a, $d2
    ld [hl+], a

TextCursorSetup:
    ld a, $d2
    ld [hl+], a
    ld a, $e2
    ld [hl], a
    ld hl, $c89e
    ld a, [wBGPalette]
    ld [hl+], a
    ld a, [wObj1Palette]
    ld [hl+], a
    ld a, [wObj2Palette]
    ld [hl], a
    ret


ClearHRAMTimers:
    xor a
    ld hl, $ffb7
    call TextCursorAdvance

TextCursorAdvance:
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ret


ClearOAMBuffer:
    xor a
    ldh [$cb], a
    ld hl, $c000
    ld bc, $00a0
    call FillNBytesWithRegA
    ret


CheckVRAMTileCount:
    ldh a, [$cb]
    cp $28
    ret z

    ld l, a
    sla l
    sla l
    ld h, $c0
    sub $28
    ld b, a
    xor a

ClearOAMLoop:
    ld [hl+], a
    inc l
    inc l
    inc l
    inc b
    jr nz, ClearOAMLoop

    ret


GetSpritePointerDE:
    ld a, [$c740]
    ld e, a
    ld a, [$c741]
    ld d, a
    ld a, d
    or e
    jr nz, ProcessSpriteTransfer

    ret


ProcessSpriteTransfer:
    ld a, [$c743]
    ld b, a
    ld hl, $c744
    ld a, [$c742]
    cp $ff
    ret z

    or a
    jr nz, CopyColTileLoop

    ld a, e
    and $e0
    ld c, a

CopyRowTileLoop:
    ld a, [hl+]
    ld [de], a
    inc e
    ld a, e
    and $1f
    or c
    ld e, a
    dec b
    jr nz, CopyRowTileLoop

    ld a, [wIsGBC]
    or a
    jr z, ClearSpritePointer

    ld a, $01
    ldh [rVBK], a
    ld a, [$c740]
    ld e, a
    ld a, [$c741]
    ld d, a
    ld a, [$c743]
    ld b, a

CopyRowAttrGBCLoop:
    ld a, [hl+]
    ld [de], a
    inc e
    ld a, e
    and $1f
    or c
    ld e, a
    dec b
    jr nz, CopyRowAttrGBCLoop

    ld a, $00
    ldh [rVBK], a
    jr ClearSpritePointer

CopyColTileLoop:
    ld a, [hl+]
    ld [de], a
    ld a, e
    add $20
    ld e, a
    ld a, d
    adc $00
    res 2, a
    ld d, a
    dec b
    jr nz, CopyColTileLoop

    ld a, [wIsGBC]
    or a
    jr z, ClearSpritePointer

    ld a, $01
    ldh [rVBK], a
    ld a, [$c740]
    ld e, a
    ld a, [$c741]
    ld d, a
    ld a, [$c743]
    ld b, a

CopyColAttrGBCLoop:
    ld a, [hl+]
    ld [de], a
    ld a, e
    add $20
    ld e, a
    ld a, d
    adc $00
    res 2, a
    ld d, a
    dec b
    jr nz, CopyColAttrGBCLoop

    ld a, $00
    ldh [rVBK], a

ClearSpritePointer:
    xor a
    ld [$c740], a
    ld [$c741], a
    ret


; WaitLCDTransfer: Busy-wait until $DA78 == 0 (LCD transfer complete)
WaitLCDTransfer:
jr_000_14cf:
    ld a, [$da78]
    or a
    jr nz, jr_000_14cf

    inc a
    ld [$da78], a
    call LoadSpriteFrame
    xor a
    ld [$da78], a
    ret


LoadSpriteFrame:
    ld a, [$4000]
    push af
    call DecompressTileLayout

LoadSpriteByteAlias:
LoadSpriteByteLoop:
    ld a, [de]
    inc de
    push hl
    ld hl, $ffab
    cp [hl]
    jr z, HandleCompressedRun

    pop hl
    ld [hl], a
    inc hl
    dec bc
    ld a, b
    or c
    jr nz, LoadSpriteByteLoop

    jp RestoreBankFromSprite


HandleCompressedRun:
    pop hl
    ld a, [de]

LoadSpriteCoords:
    ldh [$b0], a
    inc de
    ld a, [de]
    ldh [$af], a
    inc de
    ldh a, [$af]
    push af
    and $0f
    add $04
    cp $13
    jr nz, StoreRunLength
    ld a, [de]
    inc de
    add $13

StoreRunLength:
    ldh [$af], a
    pop af
    push de
    swap a
    and $0f
    ld d, a
    ldh a, [$b0]
    ld e, a
    push hl
    ldh a, [$ac]
    ld l, a
    ldh a, [$ad]
    ld h, a
    add hl, de
    ld e, l
    ld d, h
    pop hl

CheckViewportUpper:
    ldh a, [$b2]
    cp d
    jr z, CheckViewportUpperX

    jr c, AdjustForViewport

    jr LoadVisibleByte

CheckViewportUpperX:
    ldh a, [$b1]
    cp e
    jr z, AdjustForViewport

    jr nc, LoadVisibleByte

AdjustForViewport:
    ld a, $f0
    add d
    ld d, a
    ldh a, [$b4]
    cp d
    jr z, CheckViewportLowerX

    jr nc, MakeVisible

    jr LoadVisibleByte

CheckViewportLowerX:
    ldh a, [$b3]
    cp e
    jr z, LoadVisibleByte

    jr c, LoadVisibleByte

MakeVisible:
    ld a, $10
    add d
    ld d, a
    xor a
    jr StoreSpriteAndAdvance

LoadVisibleByte:
    ld a, [de]

StoreSpriteAndAdvance:
    ld [hl+], a
    inc de
    dec bc
    ld a, b
    or c
    jr z, PopDEDone

    ldh a, [$af]
    dec a
    ldh [$af], a
    jr nz, CheckViewportUpper

    pop de
    jp LoadSpriteByteAlias


PopDEDone:
    pop de

RestoreBankFromSprite:
    pop af
    ld [$2100], a
    swap a
    rra
    and $03
    ld [$4100], a
    ret


; WaitDMATransfer: Busy-wait until $DA78 == 0 (DMA transfer complete)
WaitDMATransfer:
jr_000_1577:
    ld a, [$da78]
    or a
    jr nz, jr_000_1577

    inc a
    ld [$da78], a
    call TextScrollWindow
    xor a
    ld [$da78], a
    ret


TextScrollWindow:
    ld a, [$4000]
    push af
    call DecompressTileLayout

TextTileByteAlias:
TextTileByteLoop:
    ld a, [de]
    inc de
    push hl
    ld hl, $ffab
    cp [hl]
    jr z, HandleTextRun

    pop hl
    call Write_gfx_tile_and_inc_HL
    dec bc
    ld a, b
    or c
    jr nz, TextTileByteLoop

    jp RestoreBankFromText


HandleTextRun:
    pop hl
    ld a, [de]
    ldh [$b0], a
    inc de
    ld a, [de]
    ldh [$af], a
    inc de
    ldh a, [$af]
    push af
    and $0f
    add $04
    cp $13
    jr nz, StoreTextRunLength

    ld a, [de]
    inc de
    add $13

StoreTextRunLength:
    ldh [$af], a
    pop af
    push de
    swap a
    and $0f
    ld d, a
    ldh a, [$b0]
    ld e, a
    push hl
    ldh a, [$ac]
    ld l, a
    ldh a, [$ad]
    ld h, a
    add hl, de
    ld e, l
    ld d, h
    pop hl

CheckTextViewUpper:
    ldh a, [$b2]
    cp d
    jr z, CheckTextViewUpperX

    jr c, AdjustTextViewport

    jr TextReadVisible

CheckTextViewUpperX:
    ldh a, [$b1]
    cp e
    jr z, AdjustTextViewport

    jr nc, TextReadVisible

AdjustTextViewport:
    ld a, $f0

TextWaitInput:
Jump_000_15e6:
    add d
    ld d, a
    ldh a, [$b4]
    cp d
    jr z, CheckTextViewLowerX

    jr nc, TextMakeVisible

    jr TextReadVisible

CheckTextViewLowerX:
    ldh a, [$b3]
    cp e

TextEndOfLine:
Jump_000_15f4:
    jr z, TextReadVisible

    jr c, TextReadVisible

TextMakeVisible:
    ld a, $10
    add d
    ld d, a
    xor a
    jr TextWriteAndAdvance

TextReadVisible:
    di
    call WaitVRAM
    ld a, [de]
    ei

TextWriteAndAdvance:
    call Write_gfx_tile_and_inc_HL
    inc de
    dec bc

TextNewLine:
    ld a, b
    or c
    jr z, TextPopDEDone
    ldh a, [$af]
    dec a
    ldh [$af], a
    jr nz, CheckTextViewUpper

    pop de

BankSwitch_1616:
    jp TextTileByteAlias


TextPopDEDone:
    pop de

RestoreBankFromText:
    pop af
    ld [$2100], a
    swap a
    rra
    and $03

WriteBankReg4100:
    ld [$4100], a
    ret


DecompressTileLayout:
    ld a, d

TextWriteBank:
    ld [$2100], a
    swap a
    rra

TextSetBank:
    and $03
    ld [$4100], a
    push hl
    ld l, e
    ld h, $00
    add hl, hl
    ld de, $4001
    add hl, de
    ld e, [hl]
    inc hl
    ld d, [hl]
    pop hl

ReadDEMetadata3B:
    ld a, [de]
    ld c, a
    inc de
    ld a, [de]
    ld b, a
    inc de
    ld a, [de]
    ldh [$ab], a
    inc de
    ld a, l

SetViewportParams:
    ldh [$ac], a
    ld a, h
    ldh [$ad], a
    push hl
    add hl, bc
    ld a, l
    ldh [$b1], a
    ld a, h
    ldh [$b2], a
    pop hl

SetViewportEnd:
    ld a, l
    ldh [$b3], a
    ld a, h
    ldh [$b4], a
    ret


CachePalettesToHRAM:
    ld hl, $c853
    ld a, [wBGPalette]
    ld [hl+], a
    ld a, [wObj1Palette]
    ld [hl+], a
    ld a, [wObj2Palette]
    ld [hl], a
    jr InitFadeState

InitFadeState:
    xor a
    ld hl, $c856
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl], a
    ld [$c850], a
    ld a, $07
    ld [$c851], a
    ld a, $1f
    ld [$c852], a
    ret


; SetGBCPalette: Set palette B, handles GBC color mode
SetGBCPalette:
    ld b, a
    ld a, [wIsGBC]
    or a
    jp nz, SetPaletteGBC

    ld a, [wIsSGB]
    or a
    jp z, SetPaletteDMG

    bit 7, b
    jr nz, SetFadeOutSGB

    ld a, b
    ld [$c850], a
    ld hl, $c7f7
    ld de, $c7d7
    ld c, $20

CopyPaletteLoop:
    ld a, [de]
    ld [hl+], a
    inc de
    dec c
    jr nz, CopyPaletteLoop

    ld a, $00
    ld [$c856], a
    ld a, [$c850]
    srl a
    srl a
    ld [$c857], a
    ld [$c858], a
    call CheckAnimBusy
    jp RetFromPalette


SetFadeOutSGB:
    ld a, b
    ld [$c850], a
    ld a, $20
    ld [$c856], a
    ld a, [$c850]
    cpl
    srl a
    srl a
    ld [$c857], a
    ld [$c858], a
    ld hl, $c7f7
    ld de, $c7d7
    ld c, $20

CopyDE2HL_16E4:
jr_000_16e4:
    ld a, [de]
    ld [hl+], a
    inc de
    dec c
    jr nz, jr_000_16e4

    ld de, $7fff
    ld a, [$c851]
    bit 7, a
    jr z, FillTargetPalette

    ld de, $0000

FillTargetPalette:
    ld hl, $c7d7
    ld c, $10

FillPalLoop:
    ld [hl], e
    inc hl
    ld [hl], d
    inc hl
    dec c
    jr nz, FillPalLoop

    call ClearPaletteBuffer
    ld hl, $c7d7
    ld de, $c777
    ld a, $01
    ld [de], a
    inc de
    call Copy8BytesHL2DE
    call DisableSRAM
    ld a, [$c852]
    bit 4, a
    jp z, RetFromPalette

    call ClearPaletteBuffer
    ld hl, $c7e7
    ld de, $c777
    ld a, $09
    ld [de], a
    inc de
    call Copy8BytesHL2DE
    call DisableSRAM
    jp RetFromPalette


SetPaletteGBC:
    ld a, b
    ld [$c850], a
    ld hl, $1704
    rst $10
    jp RetFromPalette


SetPaletteDMG:
    ld a, [$c851]
    bit 7, a
    jr nz, CheckInvertedFade

    bit 7, b
    jr nz, FadeOutDMG

    ld a, b
    ld [$c850], a
    ld hl, $c853
    ld a, [wBGPalette]
    ld [hl+], a
    ld a, [wObj1Palette]
    ld [hl+], a
    ld a, [wObj2Palette]
    ld [hl], a
    ld a, $00
    ld [$c856], a
    ld a, [$c850]
    add $02
    ld [$c857], a
    ld [$c858], a
    call CheckAnimBusy
    jr RetFromPaletteJR

FadeOutDMG:
    ld a, b
    ld [$c850], a
    ld a, $04
    ld [$c856], a
    ld a, [$c850]
    cpl
    add $02
    ld [$c857], a
    ld [$c858], a
    ld a, $00
    ld hl, wBGPalette
    ld [hl+], a
    ld [hl+], a
    ld [hl], a
    jp RetFromPalette


CheckInvertedFade:
    bit 7, b
    jr nz, FadeOutInverted

    ld a, b
    ld [$c850], a
    ld hl, $c853
    ld a, [wBGPalette]
    ld [hl+], a
    ld a, [wObj1Palette]
    ld [hl+], a
    ld a, [wObj2Palette]
    ld [hl], a
    ld a, $00
    ld [$c856], a
    ld a, [$c850]
    add $02
    ld [$c857], a
    ld [$c858], a
    call CheckAnimBusy
    jr RetFromPaletteJR

FadeOutInverted:
    ld a, b
    ld [$c850], a
    ld a, $04
    ld [$c856], a
    ld a, [$c850]
    cpl
    add $02
    ld [$c857], a
    ld [$c858], a
    ld a, $ff
    ld hl, wBGPalette
    ld [hl+], a
    ld [hl+], a
    ld [hl], a

RetFromPalette:
RetFromPaletteJR:
    ret


    add hl, hl
    add hl, hl
    add hl, hl
    ld bc, $8800
    add hl, bc
    ld c, $08

ReadTileRow:
    ld a, [hl+]
    ld [de], a
    inc de
    dec c
    jr nz, ReadTileRow

    ret


CheckState_C850_17EC:
    ld a, [$c850]
    or a
    ret z

    bit 7, a
    call z, CheckAnimBusyAndProcess
    ld a, [wIsGBC]
    or a
    jp nz, FadeStepGBC

    ld a, [wIsSGB]
    or a
    jp z, FadeStepDMG

    ld a, [$c850]
    bit 7, a
    jr nz, FadeOutCheckDelay

    ld a, [$c858]
    or a
    jr z, FadeInStepSGB

    dec a
    ld [$c858], a
    ret


FadeInStepSGB:
    ld a, [$c856]
    add $05
    cp $1f
    jr c, ApplyFadeStepSGB
    ld a, $1f

ApplyFadeStepSGB:
    ld [$c856], a
    call CheckState_C852_185F
    ld a, [$c857]
    ld [$c858], a
    ld a, [$c856]
    cp $1f
    jp z, FadeDone

    ret


FadeOutCheckDelay:
    ld a, [$c858]
    or a
    jr z, FadeOutStepSGB

    dec a
    ld [$c858], a
    ret


FadeOutStepSGB:
    ld a, [$c856]
    sub $05
    bit 7, a
    jr z, ApplyFadeOutSGB

    xor a

ApplyFadeOutSGB:
    ld [$c856], a
    call CheckState_C852_185F
    ld a, [$c857]
    ld [$c858], a
    ld a, [$c856]
    or a
    jp z, FadeDone

    ret


CheckState_C852_185F:
    ld a, [$c852]
    bit 0, a
    ld a, $00
    ld [$c85a], a
    call nz, AdvanceAnimState3x
    ld a, [$c852]
    bit 1, a
    ld a, $08
    ld [$c85a], a
    call nz, AdvanceAnimState3x
    ld a, [$c852]
    bit 4, a
    jr z, UpdateSGBPaletteBuffer

    ld a, [$c852]
    bit 2, a
    ld a, $10
    ld [$c85a], a
    call nz, AdvanceAnimState3x
    ld a, [$c852]
    bit 3, a
    ld a, $18
    ld [$c85a], a
    call nz, AdvanceAnimState3x

UpdateSGBPaletteBuffer:
    call ClearPaletteBuffer
    ld hl, $c7d7
    ld de, $c777
    ld a, $01
    ld [de], a
    inc de
    call Copy8BytesHL2DE
    ld a, [$c852]
    bit 4, a
    ret z

    call DisableSRAM
    call ClearPaletteBuffer
    ld hl, $c7e7
    ld de, $c777
    ld a, $09
    ld [de], a
    inc de

Copy8BytesHL2DE:
    ld c, $08

CopyPalBlock1:
    ld a, [hl+]
    ld [de], a
    inc de
    dec c
    jr nz, CopyPalBlock1

    inc hl
    inc hl
    ld c, $06

CopyPalBlock2:
    ld a, [hl+]
    ld [de], a
    inc de
    dec c
    jr nz, CopyPalBlock2

    ld a, $ff
    ld [$c774], a
    ld hl, $0800
    rst $10
    ret


AdvanceAnimState3x:
    call GetAnimFrameByIndex
    call CheckState_C85a_18E5
    call CheckState_C85a_18E5

CheckState_C85a_18E5:
    ld a, [$c85a]
    add $02
    ld [$c85a], a

GetAnimFrameByIndex:
    ld hl, $c7f7
    ld a, [$c85a]
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld e, [hl]
    inc hl
    ld d, [hl]
    push de
    ld hl, $0000
    ld a, [$c856]
    ld b, a
    ld a, e
    call CheckBit7_C851
    ld l, a
    sla e
    rl d
    sla e
    rl d
    sla e
    rl d
    ld a, d
    call CheckBit7_C851
    ld d, a
    ld e, $00
    srl d
    rr e
    srl d
    rr e
    srl d
    rr e
    add hl, de
    pop de
    ld a, d
    srl a
    srl a
    call CheckBit7_C851
    sla a
    sla a
    add h
    ld h, a
    push hl
    pop de
    ld hl, $c7d7
    ld b, $00
    ld a, [$c85a]
    ld c, a
    add hl, bc
    ld [hl], e
    inc hl
    ld [hl], d
    ret


CheckBit7_C851:
    push af
    ld a, [$c851]
    ld c, a
    pop af
    bit 7, c
    jr nz, SubtractFade

    and $1f
    add b
    cp $1f
    jr c, RetFromFadeCalc

    ld a, $1f
    jr RetFromFadeCalc

SubtractFade:
    and $1f
    sub b
    jr nc, RetFromFadeCalc

    xor a

RetFromFadeCalc:
    ret


FadeStepGBC:
    ld hl, $1705
    rst $10
    ret


FadeStepDMG:
    ld a, [$c851]
    bit 7, a
    jp nz, FadeInvertedDMG

    ld a, [$c850]
    bit 7, a
    jr nz, FadeOutCheckDMG

    ld a, [$c858]
    or a
    jr z, FadeInStepDMG

    dec a
    ld [$c858], a
    ret


FadeInStepDMG:
    call ApplyPaletteBuffer_BG
    ld a, [$c857]
    ld [$c858], a
    ld a, [$c856]
    inc a
    ld [$c856], a
    cp $04
    jp z, FadeDone

    ret


FadeOutCheckDMG:
    ld a, [$c858]
    or a
    jr z, FadeOutStepDMG

    dec a
    ld [$c858], a
    ret


FadeOutStepDMG:
    call ApplyPaletteBuffer_BG
    ld a, [$c857]
    ld [$c858], a
    ld a, [$c856]
    dec a
    ld [$c856], a
    cp $ff
    jp z, FadeDone

    ret


ApplyPaletteBuffer_BG:
    ld a, [$c851]
    bit 0, a
    ld a, [$c853]
    ld hl, wBGPalette
    call nz, CoordCalcSetup
    ld a, [$c851]
    bit 1, a
    ld a, [$c854]
    inc hl
    call nz, CoordCalcSetup
    ld a, [$c851]
    bit 2, a
    ld a, [$c855]
    inc hl
    jr nz, jr_000_19e0

    ret


CoordCalcSetup:
jr_000_19e0:
    ld d, a
    ld a, [$c856]
    ld b, a
    ld c, $00
    ld a, d
    call CoordCalcApply
    call PaletteRotateSub
    call PaletteRotateSub
    call PaletteRotateSub
    ld [hl], c
    ret


PaletteRotateSub:
    rrc d
    rrc d
    ld a, d

CoordCalcApply:
    and $03
    sub b
    jr nc, OrColorComponent

    xor a

OrColorComponent:
    or c
    ld c, a
    rrc c
    rrc c
    ret


FadeInvertedDMG:
    ld a, [$c850]
    bit 7, a
    jr nz, FadeOBJOutCheck

    ld a, [$c858]
    or a
    jr z, FadeOBJInStep

    dec a
    ld [$c858], a
    ret


FadeOBJInStep:
    call ApplyPaletteBuffer_OBJ
    ld a, [$c857]
    ld [$c858], a
    ld a, [$c856]
    inc a
    ld [$c856], a
    cp $04
    jp z, FadeDone

    ret


FadeOBJOutCheck:
    ld a, [$c858]
    or a
    jr z, FadeOBJOutStep

    dec a
    ld [$c858], a
    ret


FadeOBJOutStep:
    call ApplyPaletteBuffer_OBJ
    ld a, [$c857]
    ld [$c858], a
    ld a, [$c856]
    dec a
    ld [$c856], a
    cp $ff
    jr z, FadeDoneJR

    ret


ApplyPaletteBuffer_OBJ:
    ld a, [$c851]
    bit 0, a
    ld a, [$c853]
    ld hl, wBGPalette
    call nz, PaletteAnimStep
    ld a, [$c851]
    bit 1, a
    ld a, [$c854]
    inc hl
    call nz, PaletteAnimStep
    ld a, [$c851]
    bit 2, a
    ld a, [$c855]
    inc hl
    jr nz, jr_000_1a76

    ret


PaletteAnimStep:
jr_000_1a76:
    ld d, a
    ld a, [$c856]
    ld b, a
    ld c, $00
    ld a, d
    call ClampPaletteIndex3
    call PaletteRotateAdd
    call PaletteRotateAdd
    call PaletteRotateAdd
    ld [hl], c
    ret


PaletteRotateAdd:
    rrc d
    rrc d
    ld a, d

ClampPaletteIndex3:
    and $03
    add b
    cp $03
    jr c, OrColorOBJ

    ld a, $03

OrColorOBJ:
    or c
    ld c, a
    rrc c

RotateRegC:
    rrc c
    ret


FadeDone:
FadeDoneJR:
    xor a
    ld [$c850], a
    ret


; WaitVRAM: Wait for VRAM access window (LCD STAT bit 1 clear)
WaitVRAM:
jr_000_1aa6:
    ldh a, [rSTAT]
    bit 1, a
    ret z

RetFromWaitVRAM:
    jr jr_000_1aa6

Write_gfx_tile:
    push af
    di

WriteVRAMByte:
jr_000_1aaf:
    ldh a, [rSTAT]
    bit 1, a
    jr nz, jr_000_1aaf

    pop af
    ld [hl], a
    ei
    ret


Write_gfx_tile_and_inc_HL:			;called by debug menu. Probably other things too
    push af
    di

.check_vblank:
    ldh a, [rSTAT]
    bit 1, a					;check if OAM can be written to
    jr nz, .check_vblank			;if not, loop until it can.

    pop af
    ld [hl+], a					;write passed tile data into VRAM
    ei
    ret


GBCOnlyGuard:
    push af
    ld a, [wIsGBC]
    or a
    jr nz, GBCOnlyDisableInt

    pop af
    ret


GBCOnlyDisableInt:
    di

WaitSTATForAudio:
    ldh a, [rSTAT]
    bit 1, a
    jr nz, WaitSTATForAudio

    ld a, $01
    ldh [rVBK], a
    pop af
    ld [hl], a
    ld a, $00
    ldh [rVBK], a
    ei
    ret


SetBGM:
    ld [wBGM], a
    ret


InitBGM:
    ld [wCurrPlayingBGM], a
    di
    call InitAudioSystem
    ld a, [wCurrPlayingBGM]
    or a
    jr z, InitBGMReturn

    ld [$de24], a
    cp $27
    jr z, InitBGMPlayback

    cp $3a
    jr z, InitBGMAlt

    cp $3f
    jr z, InitBGMAlt

    cp $47
    jr z, InitBGMAlt

    cp $49
    jr z, InitBGMAlt

    cp $4b
    jr z, InitBGMAlt

    cp $4d
    jr z, InitBGMAlt

    cp $4f
    jr z, InitBGMAlt

    cp $5d
    jr z, InitBGMAlt

    cp $9d
    jr z, InitBGMAlt

    call AudioUpdate2x
    ei
    ret


InitBGMPlayback:
    call AudioUpdate3x
    ei
    ret


InitBGMAlt:
    call AudioUpdate1x

InitBGMReturn:
    ei
    ret


PlaySoundEffect:
    ld [wSoundEffect], a
    ret


LoadSE:
    push af
    push bc
    push de
    push hl
    ld [$de24], a
    cp $3f
    jr z, LoadSEWithUpdate

    cp $41
    jr z, LoadSEDouble

    cp $44
    jr z, LoadSEDouble

    cp $47
    jr z, LoadSEWithUpdate

    cp $49
    jr z, LoadSEWithUpdate

    cp $4b
    jr z, LoadSEWithUpdate

    cp $4d
    jr z, LoadSEWithUpdate

    cp $4f
    jr z, LoadSEWithUpdate

    cp $57
    jr z, LoadSEWithUpdate

    cp $5d
    jr z, LoadSEWithUpdate

    cp $63
    jr z, LoadSEWithUpdate

    cp $61
    jr z, LoadSEDouble

    cp $69
    jr z, LoadSEWithUpdate

    cp $74
    jr z, LoadSEWithUpdate

    cp $76
    jr z, LoadSEWithUpdate

    cp $78
    jr z, LoadSEWithUpdate

    cp $7c
    jr z, LoadSEWithUpdate

    cp $86
    jr z, LoadSEWithUpdate

    cp $8a
    jr z, LoadSEWithUpdate

    cp $90
    jr z, LoadSEWithUpdate

    cp $97
    jr z, LoadSEWithUpdate

    cp $99
    jr z, LoadSEWithUpdate

    cp $9d
    jr z, LoadSEWithUpdate

    di
    call AudioProcess
    ei
    pop hl
    pop de
    pop bc
    pop af
    ret


LoadSEWithUpdate:
    di
    call AudioUpdate1x
    ei
    pop hl
    pop de
    pop bc
    pop af
    ret


LoadSEDouble:
    di
    call AudioUpdate2x
    ei
    pop hl
    pop de
    pop bc
    pop af
    ret


ProcessBGMQueue:
    ld a, [wBGM]
    cp $ff
    jr z, CheckSEQueue

    cp $9d
    jr z, CheckSEQueue

    call InitBGM
    ld a, $ff
    ld [wBGM], a

CheckSEQueue:
    ld a, [wSoundEffect]
    cp $ff
    jr z, RetFromBGMQueue

    call LoadSE
    ld a, $ff
    ld [wSoundEffect], a

RetFromBGMQueue:
    ret


    ret


CheckAnimBusy:
    ld b, a
    ld a, [$c88f]
    or a
    jr nz, ClearAnimBusyFlag

    ld a, b
    bit 7, a
    jr nz, ClearAnimBusyFlag

    or a
    jr z, ClearAnimBusyFlag

    ld [$c894], a
    ld a, [wIsSGB]
    or a
    jr nz, CheckNR50Volume

    ld a, [$c894]
    sra a
    ld [$c894], a

CheckNR50Volume:
    ldh a, [rNR50]
    bit 7, a
    jr nz, ClearAnimBusyFlag

    bit 3, a
    jr nz, ClearAnimBusyFlag

    or a
    jr z, ClearAnimBusyFlag

    ld a, [$c894]
    ld [$c895], a
    ld a, $08
    ld [$c896], a
    ldh a, [rNR50]
    ld [$c897], a
    ret


ClearAnimBusyFlag:
    xor a
    ld [$c894], a
    ret


CheckAnimBusyAndProcess:
    ld a, [$c88f]
    or a
    jr nz, ClearAnimProcessed

    ld a, [$c894]
    bit 7, a
    jr nz, ClearAnimProcessed

    or a
    ret z

    ld a, [$c895]
    or a
    jr z, CheckNR50ForProcess

    dec a
    ld [$c895], a
    ret


CheckNR50ForProcess:
    ldh a, [rNR50]
    and $88
    cp $88
    jr z, ClearAnimProcessed

    ld a, [$c897]
    or a
    jr z, ClearAnimProcessed

    ld b, a
    and $0f
    ld d, a
    ld a, b
    swap a
    and $0f
    ld c, a
    bit 3, c
    jr nz, CheckChannel3Bit

    ld a, c
    or a
    jr z, CheckChannel3Bit

    dec c

CheckChannel3Bit:
    bit 3, d
    jr nz, SwapAndMaskChannel

    ld a, d
    or a
    jr z, SwapAndMaskChannel

    dec d

SwapAndMaskChannel:
    ld a, c
    swap a
    or d
    ldh [rNR50], a
    ld [$c897], a
    or a
    jr z, CheckLinkForVolume

    ld a, [$c896]
    or a
    jr z, ClearAnimProcessed

    dec a
    ld [$c896], a
    ld a, [$c894]
    ld [$c895], a
    ret


CheckLinkForVolume:
    ld a, [$c86c]
    or a
    jr nz, ClearAnimProcessed

    di
    call InitAudioSystem
    ei

ClearAnimProcessed:
    xor a
    ld [$c894], a
    ret


SetColorMode:
    ld hl, $c81b
    cp [hl]
    ret z

    ld [hl], a
    cp $00
    jr nz, CheckColorMode1

    ld a, $10
    ld de, $0805
    ld bc, $1000
    call TransferSGBPacket
    call DisableSRAM
    ld a, $11
    ld de, $0806
    ld bc, $1000
    call TransferSGBPacket
    call DisableSRAM
    ld a, $0f
    ld de, $0807
    call LoadSGBTiles
    jr RetFromColorMode

CheckColorMode1:
    cp $01
    jr nz, CheckColorMode2

    ld a, $10
    ld de, $0808
    ld bc, $1000
    call TransferSGBPacket
    call DisableSRAM
    ld a, $11
    ld de, $2c00
    ld bc, $1000
    call TransferSGBPacket
    call DisableSRAM
    ld a, $0f
    ld de, $0809
    call LoadSGBTiles
    jr RetFromColorMode

CheckColorMode2:
    cp $02
    jr nz, CheckColorMode3

    ld a, $10
    ld de, $2c01
    ld bc, $1000
    call TransferSGBPacket
    call DisableSRAM
    ld a, $11
    ld de, $3211
    ld bc, $1000
    call TransferSGBPacket
    call DisableSRAM
    ld a, $0f
    ld de, $3212
    call LoadSGBTiles
    jr RetFromColorMode

CheckColorMode3:
    cp $03
    jr nz, RetFromColorMode

    ld a, $10
    ld de, MenuBorderFillRight
    ld bc, $1000
    call TransferSGBPacket
    call DisableSRAM
    ld a, $11
    ld de, $2e25
    ld bc, $1000
    call TransferSGBPacket
    call DisableSRAM
    ld a, $0f
    ld de, $3213
    call LoadSGBTiles
    jr RetFromColorMode

RetFromColorMode:
    ret


    ld a, b
    ld [$de26], a
    ld a, c
    ld [$de27], a
    xor a
    ld [$de28], a
    ret


CheckScreenModeC86C:
    ld a, [$c86c]
    or a
    jr z, LinkClearState

    ld a, $08
    call SetInterruptEnable
    ld a, [$c864]
    set 7, a
    res 6, a
    ld [$c864], a
    ld a, [$c863]
    bit 1, a
    jr nz, LinkEnableAndCall

    ld hl, $6000

LinkDecrementHL:
    dec hl
    ld a, h
    or l
    jr nz, LinkDecrementHL

LinkEnableAndCall:
    ei
    call LinkCableTransfer
    call WaitForSerialTransferEnd
    ldh a, [rSB]
    cp $f5
    call nz, LinkCableTransfer
    di
    ld a, [$c864]
    res 7, a
    ld [$c864], a
    ld a, [$c864]
    res 0, a
    res 1, a
    ld [$c864], a
    ld a, [$c863]
    bit 1, a
    ld a, $f8
    call nz, SerialTransfer

LinkClearState:
    xor a
    ld [$c866], a
    ld hl, $c842
    ld b, $0e

LinkCopyLoop:
    ld [hl+], a
    dec b
    jr nz, LinkCopyLoop

    ret


LinkCableTransfer:
    ld a, [$c863]
    bit 1, a
    ld a, $f5
    call nz, SerialTransfer
    ld a, [$c863]
    bit 1, a
    ld a, $f5
    call z, StartSerialTransfer

WaitLinkResponse:
    ld a, [$c864]
    bit 6, a
    jr z, WaitLinkResponse

    ret


; Mul8x8To16: HL = A * C
Mul8x8To16:
    ld b, $00
    ld h, b
    ld l, b
    call CoordSubtract16

CoordSubtract16:
    rrca
    jr nc, MulShiftBit1

    add hl, bc
MulShiftBit1:
    sla c
    rl b
    rrca
    jr nc, MulShiftBit2

    add hl, bc

MulShiftBit2:
    sla c
    rl b
    rrca
    jr nc, MulShiftBit3

    add hl, bc

MulShiftBit3:
    sla c
    rl b
    rrca
    jr nc, MulShiftBit4

    add hl, bc

MulShiftBit4:
    sla c
    rl b
    ret



; Multiply A × BC → result.
Multiply_A_x_BC:
; Mul16x8To24: E:HL = BC * A
Mul16x8To24:
    push af
    push bc
    ld c, b
    call Mul8x8To16
    pop bc
    pop af
    push hl
    call Mul8x8To16
    pop bc

CoordMultiply:
    ld a, c
    add h
    ld h, a
    ld a, b
    adc $00
    ld e, a
    ret


; Div8x8: B = B // A; A = B % A — 8-bit unsigned division
Div8x8:
    ld d, $08
    ld e, a
    xor a

Div8Loop:
    sla b
    rla
    jr c, Div8Subtract

    cp e
    jr c, Div8NextBit

Div8Subtract:
    sub e
    inc b

Div8NextBit:
    dec d
    jr nz, Div8Loop

    ret


; Div16x8To16: HL = HL // A; A = HL % A
Div16x8To16:
    ld d, $10
    ld e, a
    xor a

Div16Loop:
    add hl, hl
    rla
    jr c, Div16Subtract

    cp e
    jr c, Div16NextBit

Div16Subtract:
    sub e
    inc l

Div16NextBit:
    dec d
    jr nz, Div16Loop

    ret


; Div24x8To16: HL = E:HL // A; A = E:HL % A
Div24x8To16:
    ld d, $18
    ld b, a
    xor a

Div24Loop:
    add hl, hl
    rl e
    rla
    jr c, Div24Subtract

    cp b
    jr c, Div24NextBit

Div24Subtract:
    sub b
    inc l

Div24NextBit:
    dec d
    jr nz, Div24Loop

    ret


WaitInputRelease:
    ld a, $ff
    ldh [$a9], a
    ldh a, [$a6]
    bit 7, a
    ret nz

    ldh a, [$a8]
    bit 7, a
    ret nz

    ld hl, $ff9d
    ldh a, [$a5]
    sub [hl]
    inc hl
    ldh a, [$a6]
    sbc [hl]
    ret nc

    ld hl, $ff9f
    ldh a, [$a7]
    sub [hl]
    inc hl
    ldh a, [$a8]
    sbc [hl]
    ret nc

    ld a, $0f
    ldh [$a9], a
    ld a, [wGameState]
    bit 2, a
    ret nz

    ld hl, $ffb7
    ldh a, [$a5]
    sub [hl]

SubHLFromHRAM_A5:
Jump_000_1e65:
    ldh [$a5], a
    ld b, a
    inc hl
    ldh a, [$a6]
    sbc [hl]
    ldh [$a6], a
    or a
    ret nz

    ld a, b
    cp $a0
    ret nc

SubHLFromHRAM_A7:
    ld hl, $ffbb
    ldh a, [$a7]
    sub [hl]
    ldh [$a7], a
    ld b, a
    inc hl
    ldh a, [$a8]

AddHLToHRAM:
    sbc [hl]
    ldh [$a8], a
    or a
    ret nz

    ld a, b
    cp $80
    ret nc

    ldh a, [$a7]
    and $f8

GetSpriteAddress:
    ld l, a
    ldh a, [$a8]
    sla l
    rla
    sla l
    rla

TileBuffer_1E96:
    ld h, a
    ld de, $c300
    add hl, de
    ldh a, [$a6]
    ld d, a
    ldh a, [$a5]
    srl d
    rra
    srl d
    rra
    srl d
    rra
    and $1f
    ld e, a
    ld d, $00
    add hl, de
    ld c, [hl]
    ld a, [hl]
    ldh [$aa], a
    ld de, $26e3
    ld a, [wInGateworld]
    or a
    jr z, UseGateWorldTable

    ld de, $2a63

UseGateWorldTable:
    call MapIDClampForPalette       ; ROM0: A=mapID or $16 for custom rooms
    ld l, a
    ld h, $00
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, de
    ld a, c
    ld b, $ff
    cp [hl]
    jr c, StoreSpriteResult

    ld b, $0f

StoreSpriteResult:
    ld a, b
    ldh [$a9], a
    ret


ScrollCalcDelta:
    ld hl, $c777
    ld bc, $0020
    xor a
    call FillNBytesWithRegA
    ld a, $20
    ld [$c777], a
    ld a, $00
    ld [$c778], a
    ld hl, $c779
    ld a, l
    ld [$c775], a
    ld a, h
    ld [$c776], a
    ret


    ld d, a
    add a
    add a
    or d
    add a
    add a
    or d
    push af
    ld a, [$c775]
    ld e, a
    ld a, [$c776]
    ld d, a
    ld a, $02
    ld [de], a
    inc de
    pop af
    ld [de], a
    inc de
    ld a, h
    ld [de], a
    inc de
    ld a, l
    ld [de], a
    inc de
    ld a, h
    add b
    ld [de], a
    inc de
    ld a, l
    add c
    ld [de], a
    inc de
    ld a, e
    ld [$c775], a
    ld a, d
    ld [$c776], a
    ld hl, $c778
    inc [hl]
    ret


DataTable_1F27:
    ld e, a
    add a
    add a
    or e
    add a
    add a
    or e
    push af
    push de
    ld a, [$c775]
    ld e, a
    ld a, [$c776]
    ld d, a
    pop af
    ld [de], a
    inc de
    pop af
    ld [de], a
    inc de
    ld a, h
    ld [de], a
    inc de
    ld a, l
    ld [de], a
    inc de
    ld a, h
    add b
    ld [de], a
    inc de
    ld a, l
    add c
    ld [de], a
    inc de
    ld a, e
    ld [$c775], a
    ld a, d
    ld [$c776], a
    ld hl, $c778
    inc [hl]
    ret


CheckSGBFlag:
    ld a, [$c778]
    or a
    ret z

    ld a, [$c775]
    ld l, a
    ld a, [$c776]
    ld h, a
    ld a, l
    sub $77
    ld l, a
    ld a, h
    sbc $c7
    ld h, a
    srl h
    rr l
    srl h
    rr l
    srl h
    rr l
    srl h
    rr l
    ld a, l
    and $07
    add $21
    ld [$c777], a
    ld a, $ff
    ld [$c774], a
    ld hl, $0800
    rst $10
    ret


CoordBoundsCheck:
    ld a, $0f
    ldh [$db], a

CoordClampLow:
    ld e, $40
    ld d, $42
    call ReadHRAM_d5_2012
    or a
    jp nz, FormatMillionsPass2

    call WriteBlankTile
    call PrintDigit

CoordClampHigh:
    ld a, $01
    ldh [$db], a
    ld e, $a0
    ld d, $86
    call ReadHRAM_d5_2012
    or a

CoordApplyDelta:
    jr nz, Format100KPass2

    call WriteBlankTile
    call PrintDigit

ConvertNumberToText:
    ld a, $00
    ldh [$db], a
    ld e, $10
    ld d, $27
    call ReadHRAM_d5_2012
    or a
    jr nz, Format10KPass2

    call WriteBlankTile
    call PrintDigit
    ldh a, [$d5]
    ld c, a
    ldh a, [$d6]
    ld b, a
    jp FormatThousands


FormatMillionsPass2:
    ld a, $0f
    ldh [$db], a
    ld e, $40
    ld d, $42
    call GetHRAMPointerB
    call WriteDigitTile
    call PrintDigit

Format100KPass2:
    ld a, $01
    ldh [$db], a
    ld e, $a0
    ld d, $86
    call GetHRAMPointerB
    call WriteDigitTile
    call PrintDigit

InitNumberFormat:
Format10KPass2:
    ld a, $00
    ldh [$db], a
    ld e, $10
    ld d, $27
    call GetHRAMPointerB

WriteDigitAndPrint:
    call WriteDigitTile

PrintAndAdvance:
    call PrintDigit

GetDigitFromHRAM:
Jump_000_2009:
    ldh a, [$d5]

StoreDigitC:
    ld c, a

GetUpperDigit:
Jump_000_200c:
    ldh a, [$d6]

StoreDigitB:
    ld b, a

JumpToPrintLoop:
    jp PrintThousandsLoop


ReadHRAM_d5_2012:
    ldh a, [$d5]
    ld [wDebug_main_menu_option], a
    ldh a, [$d6]
    ld [$c0a1], a
    ldh a, [$d7]
    ld [$c0a2], a
    call GetHRAMPointerB

RestoreHRAMAfterDiv:
    push af
    ld a, [wDebug_main_menu_option]
    ldh [$d5], a
    ld a, [$c0a1]
    ldh [$d6], a

SavePrintContext:
    ld a, [$c0a2]
    ldh [$d7], a
    pop af
    ret


GetHRAMPointerB:
    push hl
    ldh a, [$db]
    ld l, a

InitDivCounter:
    ld h, $ff

AdvancePrintRow:
Div24Loop2:
    inc h
    ldh a, [$d5]

SubtractDigitValue:
    sub e
    ldh [$d5], a

ReadHRAM_d6_2042:
    ldh a, [$d6]
    sbc d
    ldh [$d6], a
    ldh a, [$d7]
    sbc l
    ldh [$d7], a
    jr nc, Div24Loop2

    ldh a, [$d5]
    add e
    ldh [$d5], a
    ldh a, [$d6]
    adc d
    ldh [$d6], a
    ldh a, [$d7]
    adc l
    ldh [$d7], a
    ld a, h
    pop hl
    ret


FormatThousands:
    ld de, $03e8
    push bc
    call ExtractDigit16
    pop bc
    or a
    jr nz, PrintThousandsLoopJR

    call WriteBlankTile
    call PrintDigit

FillMemory:
    ld de, $0064
    push bc
    call ExtractDigit16

CheckLeadingZero:
    pop bc
    or a
    jr nz, jr_000_20a1

    call WriteBlankTile

PrintDigitAndCopy:
    call PrintDigit

CopyHLtoDE:
    ld de, $000a
    push bc
    call ExtractDigit16
    pop bc
    or a
    jr nz, jr_000_20ad

    call WriteBlankTile
    call PrintDigit
    jr PrintLastDigit

PrintThousandsLoop:
PrintThousandsLoopJR:
    ld de, $03e8
    call ExtractDigit16
    call WriteDigitTile
    call PrintDigit

ExtractHundreds:
jr_000_20a1:
    ld de, $0064
    call ExtractDigit16
    call WriteDigitTile
    call PrintDigit

PrintNumber:
jr_000_20ad:
    ld de, $000a
    call ExtractDigit16
    call WriteDigitTile
    call PrintDigit

PrintLastDigit:
    ld a, c
    call WriteDigitTile
    ret


ExtractDigit16:
    push hl
    ld h, $ff

DigitExtractLoop:
jr_000_20c1:
    inc h
    ld a, c

SubDigitValue:
    sub e

DigitSubtractStep:
    ld c, a
    ld a, b
    sbc d
    ld b, a

DigitCheckBorrow:
    jr nc, jr_000_20c1

    ld a, c
    add e
    ld c, a
    ld a, b
    adc d

DigitLoopCleanup:
    ld b, a
    ld a, h
    pop hl

RetFromDigit:
    ret



; Display utility (7 refs).
DisplayUtil_20D3:
WriteDigitTile:
    add $f0
    call Write_gfx_tile
    ret


WriteBlankTile:
    ld a, $e0
    call Write_gfx_tile
    ret



; Display/UI utility (12 refs).
DisplayUtil_20DF:
PrintDigit:
    push af
    ld a, l
    and $e0
    push af
    ld a, l
    inc a
    and $1f

ReformatDigitResult:
    ld l, a
    pop af
    or l
    ld l, a
    pop af
    ret


; EnableSRAM: Enable external SRAM access (write $0A to $0100)
EnableSRAM:
    di
    ld a, $0a
    ld [$0100], a
    ld a, [hl]
    push af
    ld a, $00
    ld [$0100], a
    pop af
    ei
    ret


DisableIntAndPush:
    di

PushAFSafe:
Jump_000_20ff:
    push af

EnableSRAMAccess:
    ld a, $0a
    ld [$0100], a
    pop af
    ld [hl], a

DisableSRAMAccess:
    ld a, $00
    ld [$0100], a
    ei
    ret


SRAMWriteBlock:
    ld a, $0a
    ld [$0100], a
    ld de, $4638

SRAMChecksumLoop:
    ld a, [hl+]
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    dec bc
    ld a, b
    or c
    jr nz, SRAMChecksumLoop

    ld a, $00
    ld [$0100], a
    ret


SaveGameState:
    ld hl, $ff8a
    ld de, $a003
    ld bc, $0021
    call CopySRAMBlock
    ld hl, $c8ea

SavePartyData:
    ld de, $a024
    ld bc, $1100
    call CopySRAMBlock
    ld hl, $c300
    ld de, $bcc8
    ld bc, $0200
    call CopySRAMBlock
    ld hl, $c200

SaveExtraData:
    ld de, $bec8
    ld bc, Boot
    call CopySRAMBlock

SaveTimestamp:
    ld hl, $a002

GetMonsterField1:
    ld a, $01
    push af

GetMonsterField2:
    ld a, $0a
    ld [$0100], a
    pop af
    ld [hl], a
    ld a, $00
    ld [$0100], a
    ld hl, $a002
    ld bc, $1ffe
    call SRAMWriteBlock
    ld a, $0a
    ld [$0100], a
    ld hl, $a000
    ld [hl], e
    inc hl
    ld [hl], d
    ld a, $00
    ld [$0100], a
    ret


CopySRAMBlock:
Jump_CopySRAMBlock:
    ld a, $0a
    ld [$0100], a

CopySRAMLoop:
    ld a, [hl+]
    ld [de], a
    inc de
    dec bc
    ld a, b
    or c
    jr nz, CopySRAMLoop

    ld a, $00
    ld [$0100], a
    ret


SavePartyToSRAM:
    ld hl, $cac1

GetMonsterStatPtr:
    ld de, $a1fb
    ld bc, $0ba4
    call CopySRAMBlock
    ld hl, $ca8d
    ld de, $a1c7
    ld bc, $0007
    call CopySRAMBlock
    jp SaveTimestamp

;read a byte from sram and check if it is 0. If yes, return.
SRAMAccess_21B2:
    ld hl, $a002
    ld a, $0a
    ld [$0100], a ;enable SRAM
    ld a, [hl]
    push af
    ld a, $00
    ld [$0100], a ;disable SRAM
    pop af
    or a
    ret z

    ld hl, $ff8a
    ld de, $a003
    ld bc, $0021
    call CopyFromSRAM
    ld hl, $c8ea
    ld de, $a024
    ld bc, $1100
    call CopyFromSRAM
    ld hl, $c300

LoadExtraFromSRAM:
    ld de, $bcc8
    ld bc, $0200
    call CopyFromSRAM
    ld hl, $c200
    ld de, $bec8
    ld bc, Boot
    call CopyFromSRAM
    ret


CopyFromSRAM:
    ld a, $0a
    ld [$0100], a

CopyFromSRAMLoop:
    ld a, [de]
    ld [hl+], a
    inc de
    dec bc

CheckCopyDone:
    ld a, b
    or c

BranchIfNonZero:
RetFromSRAMCopy:
    jr nz, CopyFromSRAMLoop

    ld a, $00
    ld [$0100], a
    ret



; Display utility (7 refs).
DisplayUtil_2208:
GetMonsterSlotContext:
    push bc
    ld b, a

CheckScreenActiveC86C:
    ld a, [$c86c]
    or a
    jr z, ResolveBattleContext

CheckBattleContext:
    ld a, [wGameMode]
    cp $02

CheckBattleModeJR:
    jr nz, ResolveBattleContext

    ld a, b
    pop bc
    ret


ResolveBattleContext:
    ld a, b
    pop bc
    ld hl, $ca8e
    and $7f
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ret


; GetCurrentMonsterPtr: Resolve current context → pointer to monster's 149B struct
GetCurrentMonsterPtr:
    push af
    push bc
    push de
    push hl
    call GetMonsterSlotContext
    ld c, $95
    call Mul8x8To16

AddBCToHL:
Jump_000_2235:
    pop bc
    add hl, bc
    pop de
    pop bc
    pop af
    ret



; Display/render utility (10 refs).
DisplayUtil_223B:
; GetMonsterDataPtr: HL = HL + (A & $7F) × $95 — pointer to monster's 149-byte struct
GetMonsterDataPtr:
    push bc
    push de
    push hl

MonsterFieldCalc:
    ld c, $95
    and $7f

ComputeMonsterOffset:
    call Mul8x8To16

MonsterFieldWrite:
    pop bc
    add hl, bc
    pop de
    pop bc
    ret


; ReadMonsterByte: Read byte from current monster struct → A
ReadMonsterByte:
    call GetCurrentMonsterPtr
    ld a, [hl]
    ret


; ReadMonsterWord: Read 16-bit LE value from current monster struct → BC
ReadMonsterWord:
Jump_000_224f:
    call GetCurrentMonsterPtr
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ret


    push bc
    call GetCurrentMonsterPtr
    pop bc
    ld [hl], c
    ret


WriteMonsterWord:
    push bc
    call GetCurrentMonsterPtr
    pop bc
    ld a, c
    ld [hl+], a
    ld [hl], b
    ret


GetActiveMonsterPtr:
    push af
    push bc
    push de
    push hl
    ld hl, $ca8e
    ld a, [$cac0]
    and $7f
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld c, $95
    call Mul8x8To16
    pop bc
    add hl, bc

RestoreRegisters3:
    pop de
    pop bc
    pop af
    ret


ReadActiveMonsterByte:
    call GetActiveMonsterPtr
    ld a, [hl]
    ret


ReadActiveMonsterWord:
    call GetActiveMonsterPtr
    ld a, [hl+]
    ld b, [hl]
    ld c, a
    ret


    push bc
    call GetActiveMonsterPtr
    pop bc
    ld [hl], c
    ret


    push bc
    call GetActiveMonsterPtr
    pop bc
    ld a, c
    ld [hl+], a
    ld [hl], b
    ret


GetMonsterSkillData:
    push hl
    call GetMonsterSlotContext
    pop hl
    push hl
    push af
    ld hl, $cb13
    call GetMonsterDataPtr
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    pop af
    push hl
    ld hl, $cb11
    call GetMonsterDataPtr
    pop bc
    pop de

Wrapper_22BA:
    call SaturatingAdd16
    ret


GetMonsterLevelPtr:
    push hl
    call GetMonsterSlotContext
    pop hl
    push hl

ClearMonsterLevel:
    ld hl, $cb11
    call GetMonsterDataPtr
    pop de
    ld bc, $0000
    call SaturatingSubtract16
    ret


GetMonsterSlotAndPush:
    push hl
    call GetMonsterSlotContext
    pop hl
    push hl
    push af
    ld hl, $cb17
    call GetMonsterDataPtr
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    pop af
    push hl
    ld hl, $cb15
    call GetMonsterDataPtr
    pop bc
    pop de
    call SaturatingAdd16
    ret


GetMonsterHPContext:
    push hl
    call GetMonsterSlotContext
    pop hl

ClearMonsterMaxHP:
    push hl
    ld hl, $cb15
    call GetMonsterDataPtr
    pop de
    ld bc, $0000
    call SaturatingSubtract16
    ret


SetATKMax999:
    call MonsterStatAddContext

AddMonsterATK:
    ld de, $cb19

AddStatMax999:
    ld bc, $03e7
    call MonsterStatAdd

RetStatAddDone:
Jump_000_2310:
    ret


    call MonsterStatSubContext

SubMonsterATK:
    ld de, $cb19
    ld bc, $0001
    call MonsterStatSubtract
    ret


SubMonsterATK_Alt:
    call MonsterStatAddContext

AddMonsterDEF:
    ld de, $cb1b
    ld bc, $03e7
    call MonsterStatAdd
    ret


    call MonsterStatSubContext

SubMonsterDEF:
    ld de, $cb1b

MonsterStatDecrement:
    ld bc, $0001
    call MonsterStatSubtract
    ret


MonsterStatDecLoop:
    call MonsterStatAddContext

AddMonsterAGL:
    ld de, $cb1d
    ld bc, $01ff
    call MonsterStatAdd
    ret


    call MonsterStatSubContext

SubMonsterAGL:
    ld de, $cb1d
    ld bc, $0001
    call MonsterStatSubtract
    ret


AddMonsterINT_Alt:
    call MonsterStatAddContext

AddMonsterINT:
    ld de, $cb1f
    ld bc, $00ff

AddINTAndReturn:
    call MonsterStatAdd
    ret


    call MonsterStatSubContext

SubMonsterINT:
    ld de, $cb1f
    ld bc, $0001
    call MonsterStatSubtract
    ret


    call MonsterStatAddContext
    ld de, $cb21
    ld bc, $00ff
    call MonsterStatAdd
    ret


ClearMonsterAGL:
    call MonsterStatSubContext
    ld de, $cb21
    ld bc, $0000
    call MonsterStatSubtract
    ret


SetMonsterSkill1:
    call MonsterStatAddContext
    ld de, $cb25
    ld c, $ff
    call MonsterStatCopyIn
    ret


ClearMonsterSkill1:
    call MonsterStatSubContext
    ld de, $cb25

ClearSkillSlot:
    ld c, $00
    call MonsterStatCopyOut
    ret


SetMonsterSkill3:
    call MonsterStatAddContext
    ld de, $cb28
    ld c, $ff
    call MonsterStatCopyIn
    ret


ClearMonsterSkill3:
    call MonsterStatSubContext
    ld de, $cb28
    ld c, $00
    call MonsterStatCopyOut
    ret


    call MonsterStatAddContext
    ld de, $cb27
    ld c, $ff
    call MonsterStatCopyIn
    ret


    call MonsterStatSubContext
    ld de, $cb27
    ld c, $00

ClearSkill3Return:
    call MonsterStatCopyOut
    ret


SetMonsterSkill2:
    call MonsterStatAddContext
    ld de, $cb26
    ld c, $ff
    call MonsterStatCopyIn
    ret


ClearMonsterSkill2:
    call MonsterStatSubContext
    ld de, $cb26
    ld c, $00
    call MonsterStatCopyOut
    ret


AddMonsterHP_Setup:
    call MonsterStatAddContext

AddMonsterHP:
    ld de, $cb13
    ld bc, $03e7
    call MonsterStatAdd
    ret


    call MonsterStatSubContext

SubMonsterHP:
    ld de, $cb13
    ld bc, $0001

Wrapper_23FC:
    call MonsterStatSubtract
    ret


MonsterStatAddWrap:
Jump_000_2400:
    call MonsterStatAddContext

AddMonsterMP:
Jump_000_2403:
    ld de, $cb17
    ld bc, $03e7
    call MonsterStatAdd
    ret


    call MonsterStatSubContext

DecrementMonsterMP:
Jump_000_2410:
    ld de, $cb17
    ld bc, $0001
    call MonsterStatSubtract
    ret


CompareGold:
    ld c, e
    ld d, h
    ld e, l
    ld hl, wCurrGoldLo

Wrapper_2420:
    call WriteStatAndRet
    ret


AddGold:
    ld c, e
    ld d, h
    ld e, l

CheckGoldAmount:
    ld hl, wCurrGoldLo
    call CompareGoldHL
    ret


CompareGoldAndSub:
    ld c, e
    ld d, h
    ld e, l
    ld hl, $ca4e
    call StatMultiply
    ret


SubtractGold:
    ld c, e
    ld d, h
    ld e, l
    ld hl, $ca4e
    call CompareGoldHL
    ret



; Graphics utility (11 refs).
GraphicsUtil_2442:
MonsterStatAddContext:
    push hl
    call GetMonsterSlotContext
    pop hl
    ret


MonsterStatAdd:
    push bc
    push hl
    ld l, e
    ld h, d
    call GetMonsterDataPtr
    pop de
    pop bc
    call SaturatingAdd16
    ret


MonsterStatCopyIn:
    push bc
    push hl
    ld l, e
    ld h, d
    call GetMonsterDataPtr
    pop de
    pop bc
    call StatAddClamped
    ret



; Graphics utility (11 refs).
GraphicsUtil_2462:
MonsterStatSubContext:
    push hl
    call GetMonsterSlotContext
    pop hl
    ret


MonsterStatSubtract:
    push bc
    push hl
    ld l, e

SubtractFromMonster:
    ld h, d
    call GetMonsterDataPtr
    pop de
    pop bc
    call SaturatingSubtract16

RetNop_2474:
    ret


MonsterStatCopyOut:
    push bc
    push hl
    ld l, e
    ld h, d
    call GetMonsterDataPtr
    pop de
    pop bc
    call StatSubClamped
    ret


SaturatingAdd16:
    push hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    add hl, de
    jr c, SatAddCapBC

    ld a, l
    sub c
    ld a, h
    sbc b
    jr nc, SatAddStoreLow

SatAddCapBC:
    ld c, l
    ld b, h

SatAddStoreLow:
    pop hl
    ld a, c
    ld [hl+], a
    ld [hl], b
    ret


SaturatingSubtract16:
    push hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a
    ld a, l
    sub e
    ld l, a
    ld a, h
    sbc d
    ld h, a
    jr c, SatSubStoreLow

    ld a, l
    sub c
    ld a, h
    sbc b
    jr c, SatSubStoreLow

    ld c, l
    ld b, h

SatSubStoreLow:
    pop hl
    ld a, c
    ld [hl+], a
    ld [hl], b
    ret


StatAddClamped:
    ld a, [hl]
    add e
    jr c, ClampedAddLow

    cp c
    jr c, StoreClampedResult

ClampedAddLow:
    ld a, c

StoreClampedResult:
    ld [hl], a
    ret


StatSubClamped:
    ld a, [hl]
    sub e
    jr c, ClampedSubLow

    cp c
    jr nc, jr_000_24c1

ClampedSubLow:
    ld a, c

WriteHLAndRet:
jr_000_24c1:
    ld [hl], a
    ret


WriteStatAndRet:
    push hl
    ld a, [hl+]
    add e

StatBoundsCheck:
    ld e, a
    ld a, [hl+]
    adc d
    ld d, a
    ld a, [hl]
    adc c
    ld c, a
    ld a, e
    sub $9f
    ld a, d
    sbc $86
    ld a, c
    sbc $01
    jr c, PopAndStoreResult

    ld de, $869f

SetMinValue1:
    ld c, $01

PopAndStoreResult:
    pop hl
    ld a, e
    ld [hl+], a
    ld a, d
    ld [hl+], a
    ld [hl], c
    ret


StatMultiply:
    push hl
    ld a, [hl+]
    add e
    ld e, a
    ld a, [hl+]
    adc d
    ld d, a
    ld a, [hl]
    adc c
    ld c, a
    ld a, e
    sub $3f
    ld a, d

SubtractGoldHigh:
    sbc $42
    ld a, c
    sbc $0f
    jr c, PopAndStoreResult

    ld de, $423f

StatDivide:
    ld c, $0f
    jr PopAndStoreResult

CompareGoldHL:
Jump_000_2500:
    push hl     ;either current goldLo, or Bank Gold Lo
    ld a, [hl+]  ;load amount of current gold into a, and increment to goldMid
    sub e
    ld e, a
    ld a, [hl+]
    sbc d
    ld d, a
    ld a, [hl]
    sbc c
    ld c, a
    jr nc, PopAndCheckGold

    ld de, $0000
    ld c, $00

PopAndCheckGold:
    pop hl
    ld a, e
    ld [hl+], a
    ld a, d
    ld [hl+], a
    ld [hl], c
    ret


UpdateOAMSprites:
    ld a, [$ca8d]
    or a
    jr nz, LoadOAMBase

    ld hl, $c1c0
    ld bc, $0040
    ld a, $dc
    call FillNBytesWithRegA
    ret


LoadOAMBase:
    ld hl, $c1c0

SetCountBC64:
    ld bc, $0040

ClearUnusedOAM:
    ld a, $e0
    call FillNBytesWithRegA

CheckPartyData:
Jump_000_2535:
    ld a, [$ca8d]
    or a
    ret z

    ld hl, $c1c0

SetStatDisplayZero:
    ld a, $00

CallStatDisplay:
    call SetupStatDisplay

CheckPartyCount:
    ld a, [$ca8d]
    cp $01
    ret z

    ld hl, $c1c7
    ld a, $01
    call SetupStatDisplay
    ld a, [$ca8d]
    cp $02
    ret z

    ld hl, $c1ce
    ld a, $02
    call SetupStatDisplay
    ret


SetupStatDisplay:
    ldh [$d5], a
    ld a, [wMonsterInfoToggle]
    or a
    jr nz, PushReadHRAMStat

    push hl
    ldh a, [$d5]
    add $da
    ld [hl+], a
    ld a, $e1
    ld [hl+], a
    ld a, $e3
    ld [hl+], a
    push hl
    ld hl, $cb11
    ldh a, [$d5]
    call ReadMonsterWord
    pop hl
    call FillMemory

AdvanceTilemapRow:
    pop hl
    ld a, l
    add $20
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, $e0
    ld [hl+], a
    ld a, $e2
    ld [hl+], a
    ld a, $e3
    ld [hl+], a

PushAndReadStat:
    push hl
    ld hl, $cb15
    ldh a, [$d5]
    call ReadMonsterWord
    pop hl
    call FillMemory
    ret


PushReadHRAMStat:
    push hl
    ldh a, [$d5]
    add $da
    ld [hl+], a
    ld a, $de
    ld [hl+], a
    ld a, $df
    ld [hl+], a
    ld a, $e4
    ld [hl+], a
    push hl
    ld hl, $cb0c
    ldh a, [$d5]
    call ReadMonsterByte
    pop hl
    ld c, a
    ld b, $00
    call CopyHLtoDE
    pop hl
    ld a, l
    add $21
    ld l, a
    ld a, h
    adc $00
    ld h, a

PushReadMonsterStat:
    push hl
    ld hl, $cb0b
    ldh a, [$d5]
    call ReadMonsterByte
    ld b, a
    pop hl
    bit 0, b
    ld a, $e0
    jr z, CopyStatBytes

    ld a, $d7

CopyStatBytesAlias:
CopyStatBytes:
    ld [hl+], a
    inc hl
    bit 2, b
    ld a, $e0
    jr z, CopyMoreStatBytes

    ld a, $d8

CopyMoreStatBytes:
    ld [hl+], a
    inc hl
    bit 7, b
    ld a, $e0
    jr z, StoreLastStat

    ld a, $d9

StoreLastStat:
    ld [hl], a
    ret


GetBGMapAddress:
    ldh a, [$bb]
    and $f8
    ld l, a
    xor a
    sla l
    rla
    sla l
    rla
    ld h, $98

AddBGMapOffset:
    add h
    ld h, a
    ldh a, [$b7]
    rrca
    rrca
    rrca
    and $1f
    add l
    ld l, a
    ld a, $00

AddCarryToH:
    adc h
    ld h, a

CalcAddressLow:
    ld a, l

AddOffsetToAddress:
    add $00
    ld l, a
    ld a, h
    adc $02
    ld h, a
    res 2, h
    ld de, $c1c0
    ld c, $02

DrawPartyStatsRow:
    ld b, $14
    push hl

DrawPartyStatLoop:
    ld a, [de]
    call Write_gfx_tile
    ld a, $07
    call GBCOnlyGuard
    ld a, l
    and $e0
    push af
    ld a, l

TilemapWrapX_2:
    inc a
    and $1f
    ld l, a
    pop af
    or l
    ld l, a
    inc de
    dec b
    jr nz, DrawPartyStatLoop

    pop hl

AdvanceStatOffset12:
    ld a, e
    add $0c
    ld e, a

AdvanceStatRow:
    ld a, d

AddCarryToD:
    adc $00
    ld d, a
    push bc
    ld bc, $0020
    add hl, bc
    ld a, h
    and $03
    or $98
    ld h, a
    pop bc
    dec c
    jr nz, DrawPartyStatsRow

    ret


CheckGateWorldMapType:
    ld a, [wInGateworld]
    or a
    jr nz, ReturnWithCarry

    ld a, [wMapID]
    cp MAP_BTLDEMO
    jr z, ReturnZeroFlag

    cp MAP_CSLBG
    jr z, ReturnZeroFlag

    ld a, [wMapID]
    cp MAP_OLDWELL
    jr nc, ReturnWithCarry

ReturnZeroFlag:
    xor a
    ret


ReturnWithCarry:
    ld a, $01
    or a
    ret


SetBitInArray:
    call GetBitAndMask
    or [hl]
    ld [hl], a
    ret


    call GetBitAndMask
    xor $ff
    and [hl]

WriteHLAndRet2:
    ld [hl], a
    ret


TestBitInArray:
    call GetBitAndMask
    and [hl]
    ret


GetBitAndMask:
    push af
    srl a
    srl a
    srl a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    pop af
    push hl
    ld hl, $26d5
    and $07
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    pop hl
    ret


; ---------------------------------------------------------------------------
; SetEventFlag — Set a single event flag bit in the $D99B bitfield
; ---------------------------------------------------------------------------
; Input:  BC = event flag index
; Effect: Sets the bit at $D99B + (BC/8), bit position (C & 7)
; Used by script command $03 to mark story events as triggered.
; ---------------------------------------------------------------------------
SetEventFlag:
    call ComputeFlagAddress       ; Compute mask → A, address → HL
    or [hl]                  ; Set the bit
    ld [hl], a               ; Write back
    ret


; ---------------------------------------------------------------------------
; ClearEventFlag — Clear a single event flag bit in the $D99B bitfield
; ---------------------------------------------------------------------------
; Input:  BC = event flag index
; Effect: Clears the bit at $D99B + (BC/8), bit position (C & 7)
; Used by script command $02 to reset event state.
; ---------------------------------------------------------------------------
ClearEventFlag:
    call ComputeFlagAddress       ; Compute mask → A, address → HL
    xor $ff                  ; Invert mask
    and [hl]                 ; Clear the target bit, keep all others
    ld [hl], a               ; Write back
    ret


; ---------------------------------------------------------------------------
; CheckEventFlag — Test a single event flag in the $D99B bitfield
; ---------------------------------------------------------------------------
; Input:  BC = event flag index (16-bit)
; Output: Z flag = bit is CLEAR (event not triggered)
;         NZ flag = bit is SET (event has been triggered)
;
; Calculation:
;   byte_address = $D99B + (BC / 8)
;   bit_mask     = bitmask_table[C & 7]  (table at $26D5: $80,$40,$20,$10,$08,$04,$02,$01)
;   result       = [byte_address] AND bit_mask
;
; Used by script commands $00 (ConditionalBranchNZ) and $01 (ConditionalBranchZ)
; to check story progression flags. 182 unique flags are used across all scripts.
; Flag range covers $D99B-$DAxx (event bitfield).
; ---------------------------------------------------------------------------
TestEventFlag:
    call ComputeFlagAddress       ; Compute bit mask → A, byte address → HL

TestFlagDirect:
    and [hl]                 ; Test: is this event flag set?
    ret                      ; Z = flag clear, NZ = flag set


; ---------------------------------------------------------------------------
; ComputeFlagAddress — Compute byte address and bit mask for event flag
; ---------------------------------------------------------------------------
; Input:  BC = flag index
; Output: A = bit mask, HL = byte address in event bitfield
; ---------------------------------------------------------------------------
ComputeFlagAddress:
    push bc
    srl b
    rr c                     ; BC >>= 1
    srl b
    rr c                     ; BC >>= 2
    srl b
    rr c                     ; BC >>= 3 (BC / 8 = byte offset)
    ld hl, $d99b
    add hl, bc               ; HL = $D99B + (flag_index / 8) = byte address
    pop bc
    push hl
    ld hl, $26d5             ; Bit mask lookup table
    ld a, c
    and $07                  ; C & 7 = bit position within byte
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a                  ; HL = $26D5 + (C & 7)
    ld a, [hl]               ; A = bit mask ($80,$40,$20,$10,$08,$04,$02,$01)
    pop hl                   ; HL = byte address
    ret


    add b

DataTable_26D6:
    ld b, b
    jr nz, @+$12

    ld [$0204], sp
    ld bc, $2a00
    ld b, b
    ld bc, Boot
    ld d, a
    nop
    ld [$402a], sp

SetFlagBCHigh:
    ld bc, $0200
    ld d, b
    nop
    inc d
    ld a, [hl+]
    ldh [rSB], a
    nop
    ld bc, $0049
    ld hl, $402a

SetFlagBCLow:
    ld bc, Boot
    jr nc, SetFlagResult

SetFlagResult:
    ld bc, $e029

ClearFlagBCSetup:
    ld bc, Boot
    ld a, [hl-]
    nop
    add hl, bc

ClearFlagShift:
    add hl, hl
    ldh [rSB], a
    add b

DataTable_270A:
    nop
    ld d, b
    nop
    ld c, $29
    ldh [rSB], a
    add b

TestFlagSetup:
    nop
    ld e, d
    nop

MultiplyHL_2715:
Jump_000_2715:
    ld [de], a
    add hl, hl
    ldh [rSB], a
    nop
    ld bc, $0052
    inc e
    add hl, hl

MultiplyResult:
    and b
    nop
    add b
    nop
    and d
    nop
    rra
    add hl, hl
    ld b, b
    ld bc, Boot
    jr MultiplyShiftLoop

MultiplyShiftLoop:
    inc hl
    add hl, hl
    ld b, b

SetCountBC128:
Jump_000_2730:
SetCount128:
    ld bc, $0080
    jr jr_000_2735

TilemapPadding:
jr_000_2735:
    nop

DataLookup_2736:
    ld a, [hl+]
    ld b, b
    ld bc, Boot
    ld d, a
    nop
    ld h, $29
    and b

Data_2740:
    nop
    add b
    nop
    jr nc, Data_2745

Data_2745:
    nop
    jr nc, SetFlagBCHigh

Data_2748:
    nop
    add b
    nop
    ld b, b
    nop
    nop
    ld a, [hl+]
    ld b, b

SetCount256Alias:
SetCount256:
    ld bc, Boot
    ld d, a
    nop
    ld [bc], a
    jr nc, SetFlagBCLow

Data_2758:
    nop
    add b
    nop
    ld d, b
    nop
    inc b
    jr nc, ClearFlagBCSetup

Data_2760:
    nop
    add b
    nop
    jr c, Data_2765

Data_2765:
    nop
    ld a, [hl+]
    ld b, b

Data_2768:
    ld bc, Boot
    ld d, a
    nop
    rlca
    jr nc, @-$5e

Data_2770:
    nop
    nop
    ld bc, $0040
    ld a, [bc]
    jr nc, @-$5e

DataTable_2778:
    nop
    add b
    nop
    ld b, b

DataTable_277C:
    nop
    nop
    ld a, [hl+]
    ld b, b
    ld bc, Boot
    ld d, a
    nop
    nop
    ld a, [hl+]
    ld b, b
    ld bc, Boot
    ld d, a
    nop
    inc c
    jr nc, SetCount128

DataLookup_2790:
    nop
    add b
    nop
    ld b, b
    nop
    nop
    ld a, [hl+]
    ld b, b
    ld bc, Boot
    ld d, a
    nop
    rrca
    jr nc, Data_2740

    nop
    nop
    ld bc, $004e
    inc de
    jr nc, Data_2748

    nop
    add b
    nop
    ld b, b
    nop
    dec d
    jr nc, SetCount256

    nop
    add b
    nop
    ld b, b
    nop
    rla
    jr nc, Data_2758

    nop
    add b
    nop
    ld d, b
    nop
    add hl, de
    jr nc, Data_2760

    nop
    add b

DataLookup_27C2:
    nop
    ld d, b
    nop
    dec de
    jr nc, Data_2768

    nop
    add b
    nop
    jr nc, Data_27CD

Data_27CD:
    dec e
    jr nc, Data_2770

    nop
    add b
    nop
    inc h
    nop
    nop
    dec l
    and b
    nop
    add b
    nop
    jr nc, Data_27DD

Data_27DD:
    nop
    ld a, [hl+]
    ld b, b
    ld bc, Boot
    ld d, a
    nop
    nop
    ld a, [hl+]
    ld b, b
    ld bc, Boot
    ld d, a
    nop
    nop
    ld a, [hl+]
    ld b, b
    ld bc, Boot
    ld d, a
    nop
    ld [bc], a
    dec l
    and b
    nop
    add b
    nop
    jr nz, Data_27FD

Data_27FD:
    inc b

DataTable_27FE:
    dec l
    and b

DataTable_2800:
    nop
    add b
    nop
    jr Data_2805

Data_2805:
    ld b, $2d
    and b

DataTable_2808:
    nop
    add b
    nop
    jr nz, Data_280D

Data_280D:
    ld [$a02d], sp

DataLookup_2810:
    nop
    add b

DataLookup_2812:
    nop
    jr nc, Data_2815

ReadByteFromBC:
Jump_000_2815:
Data_2815:
    ld a, [bc]
    dec l
    and b
    nop
    add b

DataLookup_281A:
    nop
    stop
    inc c
    dec l
    and b
    nop
    add b
    nop
    jr nc, Data_2825

Data_2825:
    ld c, $2d
    and b
    nop
    add b
    nop
    jr nz, Data_282D

Data_282D:
    db $10
    dec l

DataTable_282F:
    and b

DataLookup_2830:
    nop
    add b
    nop
    jr nz, Data_2835

Data_2835:
    ld [de], a
    dec l
    and b
    nop
    add b
    nop
    jr nz, Data_283D

Data_283D:
    inc d
    dec l
    and b
    nop
    add b
    nop
    jr nz, Data_2845

Data_2845:
    ld d, $2d
    and b
    nop
    add b
    nop
    jr nc, Data_284D

Data_284D:
    jr Data_287C

    and b
    nop
    add b
    nop

DataTable_2853:
DataLookup_2853:
    jr z, Data_2855

Data_2855:
    ld a, [de]
    dec l
    ld b, b
    ld bc, Boot
    ld [hl], b
    nop
    inc c

DataTable_285E:
    ld h, $a0
    nop
    add b
    nop
    ld b, b
    nop
    rrca
    ld h, $a0
    nop
    add b
    nop
    ld d, b
    nop
    dec d
    inc h
    and b
    nop
    add b
    nop
    jr nz, Data_2875

Data_2875:
    ld [de], a

DataTable_2876:
    ld h, $a0
    nop
    add b
    nop
    ld b, b

Data_287C:
    nop
    dec d
    ld h, $a0
    nop
    add b
    nop
    ld d, b
    nop
    jr Data_28AD

    and b
    nop
    add b
    nop
    jr nz, Data_288D

Data_288D:
    dec de
    ld h, $a0
    nop
    add b
    nop
    ld d, b
    nop
    ld a, [de]
    dec h
    and b
    nop
    add b
    nop
    ld b, b
    nop
    nop
    dec h
    and b
    nop
    add b
    nop
    ld d, b
    nop
    inc bc
    inc hl
    and b
    nop
    add b
    nop
    jr nz, Data_28AD

Data_28AD:
    inc bc
    dec h
    and b
    nop
    add b
    nop
    ld b, b
    nop
    ld b, $24
    and b
    nop
    add b
    nop
    ld d, b
    nop
    ld b, $23
    and b
    nop
    add b
    nop
    ld h, [hl]
    nop
    ld b, $25

DataLookup_28C7:
    and b
    nop
    add b
    nop

DataTable_28CB:
    stop
    ld [$a025], sp
    nop
    add b
    nop
    ld d, b
    nop
    nop
    inc h
    and b
    nop
    add b
    nop
    ld d, b
    nop
    dec d
    dec h
    and b
    nop
    add b
    nop
    ld b, b

DataLookup_28E4:
    nop
    rla
    dec h
    and b
    nop
    add b
    nop
    ld b, b
    nop
    ld [de], a
    inc h
    and b
    nop
    add b
    nop
    ld d, b
    nop
    rrca
    inc h
    and b
    nop
    add b
    nop
    ld b, b

DataTable_28FC:
    nop
    jr Data_2923

DataTable_28FF:
    and b

DataLookup_2900:
    nop
    add b
    nop
    jr nz, Data_2905

Data_2905:
    add hl, bc
    inc h
    and b
    nop
    add b
    nop
    ld d, b
    nop
    nop
    inc hl
    and b
    nop
    add b
    nop
    ld d, b
    nop

DataLookup_2915:
    dec de
    inc h
    and b
    nop
    add b
    nop
    ld h, l
    nop
    inc c
    inc h
    and b

DataTable_2920:
DataLookup_2920:
    nop
    add b
    nop

Data_2923:
    ld b, b
    nop
    dec bc
    dec h
    and b
    nop

DataTable_2929:
    add b
    nop
    ld d, b
    nop
    ld a, [bc]
    inc hl

DataLookup_292F:
    and b

DataLookup_2930:
    nop
    add b
    nop
    ld b, b
    nop
    dec c
    inc hl
    and b
    nop
    add b
    nop
    inc d
    nop
    db $10
    inc hl
    and b

DataLookup_2940:
    nop
    add b
    nop
    ld l, b
    nop

DataLookup_2945:
    ld c, $25
    and b
    nop
    add b
    nop
    ld b, b
    nop
    ld de, $a025

DataLookup_2950:
    nop
    nop
    ld bc, $0055
    inc bc
    inc h
    and b
    nop
    add b
    nop
    ld h, b
    nop
    nop

DataLookup_295E:
    ld h, $a0
    nop
    add b
    nop
    jr nz, Data_2965

Data_2965:
    ld [bc], a
    ld h, $a0
    nop
    add b
    nop
    jr nz, Data_296D

Data_296D:
    inc b
    ld h, $a0
    nop
    add b
    nop
    dec hl
    nop
    jr Data_299A

    and b
    nop
    add b
    nop
    jr nc, Data_297D

Data_297D:
    nop
    scf

DataLookup_297F:
    ldh [rSB], a
    add b
    ld bc, $0030
    ld a, [bc]
    scf
    ldh [rSB], a
    add b
    ld bc, $0030
    inc d
    scf
    ldh [rSB], a
    add b
    ld bc, $0030
    ld e, $37
    ldh [rSB], a
    add b

Data_299A:
    ld bc, $0030
    jr z, Data_29D6

    ldh [rSB], a
    add b
    ld bc, $0030
    ld [hl-], a
    scf
    ldh [rSB], a
    add b
    ld bc, $0030

DataLookup_29AD:
    ld b, $26
    and b
    nop
    add b
    nop
    scf
    nop
    ld [$a026], sp
    nop
    add b
    nop
    scf
    nop
    ld a, [bc]
    ld h, $a0
    nop
    add b
    nop
    scf
    nop
    inc de
    inc hl
    and b
    nop
    add b
    nop
    ld h, b
    nop
    ld d, $23
    and b
    nop
    add b
    nop
    nop
    nop
    nop

Data_29D6:
    ld h, $a0
    nop
    add b
    nop
    jr nz, Data_29DD

Data_29DD:
    ld [de], a

DataTable_29DE:
    inc h
    and b

Data_29E0:
    nop
    add b
    nop
    ld d, b
    nop
    jr Data_2A0A

    and b
    nop
    add b
    nop
    jr nc, Data_29ED

Data_29ED:
    jr DataLookup_2A12

    and b

Data_29F0:
    nop
    add b
    nop
    jr nc, Data_29F5

Data_29F5:
    jr Data_2A1A

    and b

Data_29F8:
    nop
    add b
    nop
    jr nc, Data_29FD

Data_29FD:
    jr Data_2A22

    and b

Data_2A00:
    nop

DataLookup_2A01:
    add b
    nop
    jr nc, Data_2A05

Data_2A05:
    ld [de], a
    inc h
    and b

DataTable_2A08:
jr_000_2a08:
    nop
    add b

Data_2A0A:
    nop
    ld d, b
    nop
    ld [de], a
    inc h

DataTable_2A0F:
    and b
    nop
    add b

DataLookup_2A12Alias:
DataLookup_2A12:
    nop
    ld d, b
    nop

DataLookup_2A15:
    ld [de], a
    inc h
    and b

Data_2A18:
    nop
    add b

Data_2A1A:
    nop
    ld d, b
    nop
    ld [de], a
    inc h
    and b
    nop
    add b

Data_2A22:
    nop
    ld d, b
    nop
    ld [de], a
    inc h
    and b

Data_2A28:
    nop
    add b
    nop
    ld d, b
    nop
    ld [de], a
    inc h
    and b

Data_2A30:
    nop
    add b
    nop
    ld d, b
    nop
    ld [de], a
    inc h
    and b

Data_2A38:
    nop
    add b
    nop
    ld d, b
    nop

DataTable_2A3D:
    ld [de], a
    inc h
    and b

DataLookup_2A40Alias:
DataLookup_2A40:
    nop
    add b
    nop
    ld d, b
    nop
    ld [de], a
    inc h
    and b

Data_2A48:
    nop
    add b
    nop
    ld d, b
    nop
    ld [de], a
    inc h
    and b
    nop
    add b
    nop
    ld d, b
    nop
    ld [de], a

DataTable_2A56:
    inc h
    and b

Data_2A58:
    nop

DataLookup_2A59:
    add b
    nop
    ld d, b
    nop
    nop
    jr z, Data_29E0

    ld [bc], a
    nop
    ld [bc], a
    jr nc, Data_2A65

Data_2A65:
    ld bc, $8028
    ld [bc], a
    nop
    ld [bc], a
    jr nc, Data_2A6D

Data_2A6D:
    ld [bc], a
    jr z, Data_29F0

    ld [bc], a
    nop
    ld [bc], a
    jr nc, Data_2A75

Data_2A75:
    inc bc
    jr z, Data_29F8

    ld [bc], a
    nop
    ld [bc], a
    jr nc, Data_2A7D

Data_2A7D:
    inc b
    jr z, Data_2A00

    ld [bc], a
    nop
    ld [bc], a
    jr nc, Data_2A85

Data_2A85:
    dec b
    jr z, jr_000_2a08

    ld [bc], a
    nop
    ld [bc], a
    jr nc, Data_2A8D

Data_2A8D:
    ld b, $28
    add b

DataTable_2A90:
    ld [bc], a
    nop
    ld [bc], a
    jr nc, Data_2A95

Data_2A95:
    rlca
    jr z, Data_2A18

    ld [bc], a
    nop
    ld [bc], a
    jr nc, Data_2A9D

Data_2A9D:
    ld [$8028], sp
    ld [bc], a
    nop
    ld [bc], a
    jr nc, Data_2AA5

Data_2AA5:
    add hl, bc
    jr z, Data_2A28

    ld [bc], a
    nop
    ld [bc], a

DataTable_2AAB:
    jr nc, Data_2AAD

Data_2AAD:
    ld a, [bc]
    jr z, Data_2A30

    ld [bc], a
    nop
    ld [bc], a
    jr nc, Data_2AB5

Data_2AB5:
    dec bc
    jr z, Data_2A38

    ld [bc], a
    nop
    ld [bc], a
    jr nc, Data_2ABD

Data_2ABD:
    inc c
    jr z, DataLookup_2A40

    ld [bc], a
    nop
    ld [bc], a
    jr nc, Data_2AC5

Data_2AC5:
    dec c
    jr z, Data_2A48

    ld [bc], a
    nop
    ld [bc], a
    jr nc, Data_2ACD

Data_2ACD:
    ld c, $28
    add b
    ld [bc], a
    nop
    ld [bc], a
    jr nc, Data_2AD5

Data_2AD5:
    rrca
    jr z, Data_2A58

    ld [bc], a
    nop
    ld [bc], a
    jr nc, Data_2ADD

Data_2ADD:
    nop
    nop
    nop
    ld sp, $3101
    ld [bc], a
    ld sp, $3103
    inc b
    ld sp, $3105
    ld b, $31
    rlca
    ld sp, $3108
    add hl, bc
    ld sp, $310a
    dec bc
    ld sp, $310c
    dec c
    ld sp, $310e
    rrca
    ld sp, $3110

DataLookup_2B01:
    ld de, $1231
    ld sp, $3113
    inc d

DataTable_2B08:
DataLookup_2B08:
    ld sp, $3115
    ld d, $31
    rla
    ld sp, $3118
    add hl, de
    ld sp, $311a

DataLookup_2B15:
    dec de
    ld sp, $311c
    dec e
    ld sp, $311e
    rra
    ld sp, $3120
    ld hl, $2231
    ld sp, $3123
    inc h
    ld sp, $3125
    ld h, $31
    daa
    ld sp, $3128
    add hl, hl
    ld sp, $312a
    dec hl
    ld sp, $312c
    dec l
    ld sp, $312e
    cpl
    ld sp, $3130
    ld sp, $3231
    ld sp, $3133
    inc [hl]
    ld sp, $3135
    ld [hl], $31
    scf
    ld sp, $3138
    add hl, sp
    ld sp, $2f09
    inc b
    jr c, @+$36

    jr c, Data_2B91

    jr c, @+$0a

    add hl, sp

DataLookup_2B5D:
    ld e, $39

DataLookup_2B5F:
    dec l
    add hl, sp
    inc bc
    ld a, [hl-]
    ld h, $3a
    ld a, [hl+]
    ld a, [hl-]
    ld a, $38
    ld sp, $0438
    add hl, sp
    add hl, sp
    jr c, @+$0d

    ld a, [hl-]
    inc d
    ld a, [hl-]
    ld b, $39
    add hl, hl
    jr c, Data_2B78

Data_2B78:
    jr c, Data_2BBC

    ld sp, $3100
    nop
    ld sp, $313a
    dec sp
    ld sp, $313c
    dec a
    ld sp, $313e
    ccf
    ld sp, $3140
    ld b, c
    ld sp, $313a

Data_2B91:
    ld a, [hl-]
    ld sp, $313a
    ld a, [hl-]
    ld sp, $313a
    ld a, [hl-]
    ld sp, $2f00
    add hl, de
    ld l, $11
    cpl
    ld [de], a
    cpl
    inc de
    cpl
    inc d
    cpl
    dec d
    cpl
    ld d, $2f
    rla
    cpl
    jr @+$31

    add hl, de
    cpl
    ld a, [de]
    cpl
    dec de
    cpl
    inc e
    cpl
    dec e
    cpl
    ld e, $2f
    rra

Data_2BBC:
    cpl
    jr nz, TilemapFillBorder01

    ld hl, $222f
    cpl
    inc hl

TilemapScrollCalc:
    cpl
    inc h
    cpl
    dec h
    cpl
    ld h, $2f
    daa

BitComplementAndBranch:
    cpl
    jr z, WriteTileBorderMid

    add hl, hl
    cpl
    ld a, [hl+]
    cpl
    dec hl
    cpl
    inc l
    cpl
    dec l
    cpl
    ld l, $2f
    cpl
    cpl

TilemapDrawRegion:
    jr nc, WriteTileBorderBot

    ld sp, $322f
    cpl
    inc sp
    cpl
    inc [hl]
    cpl
    dec [hl]
    cpl
    ld [hl], $2f
    scf

TilemapFillRegion:
    cpl
    nop

TilemapFillBorder01:
    ld [hl], $01

TilemapFillBorder02:
    ld [hl], $02
    ld [hl], $03
    ld [hl], $04
    ld [hl], $05
    ld [hl], $06
    ld [hl], $07

TilemapClearLine:
    ld [hl], $08

WriteTileBorderMid:
    ld [hl], $09
    ld [hl], $0a
    ld [hl], $0b

WriteTileSequence:
    ld [hl], $0c
    ld [hl], $0d
    ld [hl], $0e
    ld [hl], $0f
    ld [hl], $10

WriteTileBorderBot:
    ld [hl], $11
    ld [hl], $12

WriteTileBorderInner:
    ld [hl], $13
    ld [hl], $14
    ld [hl], $15
    ld [hl], $16
    ld [hl], $17
    ld [hl], $18
    ld [hl], $19
    ld [hl], $1a
    ld [hl], $1b
    ld [hl], $1c
    ld [hl], $1d
    ld [hl], $1e
    ld [hl], $1f
    ld [hl], $20
    ld [hl], $21
    ld [hl], $22
    ld [hl], $23
    ld [hl], $24
    ld [hl], $25
    ld [hl], $26
    ld [hl], $27
    ld [hl], $00
    dec [hl]
    ld bc, $0235
    dec [hl]
    inc bc
    dec [hl]
    inc b
    dec [hl]
    dec b
    dec [hl]
    ld b, $35
    rlca
    dec [hl]
    ld [$0935], sp
    dec [hl]
    ld a, [bc]
    dec [hl]
    dec bc
    dec [hl]
    inc c
    dec [hl]
    dec c
    dec [hl]
    ld c, $35
    rrca
    dec [hl]
    db $10
    dec [hl]
    ld de, $1235
    dec [hl]
    inc de
    dec [hl]
    inc d
    dec [hl]

TileSequenceMid:
    dec d
    dec [hl]
    ld d, $35
    rla
    dec [hl]
    jr TileSeqIncrementC

    add hl, de
    dec [hl]
    ld a, [de]
    dec [hl]
    dec de
    dec [hl]
    inc e
    dec [hl]
    dec e
    dec [hl]
    ld e, $35
    rra
    dec [hl]
    jr nz, TileSeqIncrementD

    ld hl, AddBCToHL
    dec [hl]
    inc hl
    dec [hl]
    inc h
    dec [hl]
    dec h
    dec [hl]
    ld h, $35
    daa
    dec [hl]
    nop
    inc [hl]
    ld bc, $0234
    inc [hl]
    inc bc
    inc [hl]
    inc b
    inc [hl]
    dec b
    inc [hl]
    ld b, $34
    rlca
    inc [hl]
    ld [$0934], sp
    inc [hl]
    ld a, [bc]
    inc [hl]
    dec bc

TileSeqIncrementC:
    inc [hl]
    inc c
    inc [hl]
    dec c
    inc [hl]
    ld c, $34
    rrca
    inc [hl]
    db $10
    inc [hl]
    ld de, $1234
    inc [hl]
    inc de

TileSeqIncrementD:
    inc [hl]
    inc d
    inc [hl]
    dec d
    inc [hl]
    ld d, $34
    rla
    inc [hl]
    jr TileDataContinue

    add hl, de
    inc [hl]
    ld a, [de]
    inc [hl]

TileSeqDecrementDE:
    dec de
    inc [hl]
    inc e
    inc [hl]
    dec e
    inc [hl]
    ld e, $34
    rra
    inc [hl]
    jr nz, TileNextInSeq

    ld hl, $2234
    inc [hl]
    inc hl
    inc [hl]
    inc h
    inc [hl]
    dec h
    inc [hl]
    ld h, $34
    daa
    inc [hl]
    nop
    inc sp
    ld bc, $0233
    inc sp
    inc bc
    inc sp
    inc b
    inc sp
    dec b

TileDataBlock1:
    inc sp
    ld b, $33
    rlca

TileDataBlock2:
    inc sp
    ld [$0933], sp
    inc sp
    ld a, [bc]
    inc sp

TileDataContinue:
    dec bc
    inc sp
    inc c
    inc sp
    dec c
    inc sp
    ld c, $33

TilemapWriteByte:
    rrca

TilemapWriteByte2:
    inc sp
    db $10
    inc sp

TilemapNextTile:
    ld de, $1233
    inc sp

TileNextInSeq:
    inc de
    inc sp
    inc d
    inc sp
    dec d
    inc sp
    ld d, $33
    rla
    inc sp
    jr TileStoreReverseLoop

TileAddDE:
    add hl, de
    inc sp

TileReadDE:
    ld a, [de]
    inc sp
    dec de
    inc sp
    inc e
    inc sp
    dec e
    inc sp
    ld e, $33
    rra
    inc sp
    jr nz, TileStoreEnd

    ld hl, $2233
    inc sp
    inc hl
    inc sp
    inc h
    inc sp
    dec h
    inc sp
    ld h, $33
    daa
    inc sp
    nop
    ld [hl-], a
    ld bc, $0232
    ld [hl-], a
    inc bc
    ld [hl-], a

TileStoreReverse:
    inc b
    ld [hl-], a
    dec b
    ld [hl-], a
    ld b, $32
    rlca
    ld [hl-], a
    ld [$0932], sp
    ld [hl-], a
    ld a, [bc]

TileStoreReverseLoop:
    ld [hl-], a
    dec bc
    ld [hl-], a
    inc c
    ld [hl-], a
    dec c
    ld [hl-], a
    ld c, $32
    rrca
    ld [hl-], a
    db $10
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca

TileStoreEnd:
    ld [hl-], a

TilemapRotateWrite:
    rrca
    ld [hl-], a
    rrca

WriteRotatedBytesDown:
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a

TilemapRotateCont:
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a
    rrca
    ld [hl-], a
    nop

TileRotatePadding:
    nop
    nop
    nop
    and b
    nop
    nop
    nop
    ld b, b
    ld bc, $0000
    ldh [rSB], a
    nop
    nop
    nop
    nop
    add b
    nop
    and b
    nop
    add b
    nop
    ld b, b
    ld bc, $0080
    ldh [rSB], a
    add b
    nop
    nop

MenuBorderDraw:
    nop
    nop
    ld bc, $00a0
    nop
    ld bc, $0140
    nop
    ld bc, $01e0
    nop
    ld bc, $0000
    add b
    ld bc, $00a0
    add b
    ld bc, $0140
    add b
    ld bc, $01e0
    add b
    ld bc, $0000
    ld a, [bc]
    nop
    inc d

MenuBorderTop:
    nop
    ld e, $00
    nop
    ld [$080a], sp
    inc d
    ld [$081e], sp
    nop
    db $10
    ld a, [bc]
    db $10
    inc d

MenuBorderSide:
    db $10
    ld e, $10
    nop
    jr MenuBorderLeftEdge

    jr MenuBorderFillLeft

MenuBorderBottom:
    jr MenuBorderFillRight

MenuBorderCorner:
Jump_000_2e06:
    jr TileRotatePadding

    ld bc, $effa
    rst $28

MenuBorderLeftEdge:
    rst $28
    rst $28
    rst $28
    rst $28

MenuBorderRightEdge:
    rst $28

MenuBorderFill:
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28

MenuBorderFillLeft:
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $b0
    or c
    or d
    or e
    or h

MenuBorderFillRight:
    or l
    or [hl]
    or a
    cp b
    cp c
    cp d
    cp e
    cp h
    cp l
    cp [hl]
    cp a
    ret nz

    pop bc
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a

WriteHRAMMultiple:
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $c2
    jp $c5c4


    add $c7
    ret z

    ret


    jp z, $cccb

    call $cfce
    ret nc

    pop de
    jp nc, $ffd3

    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    db $fd
    reti


    nop
    nop

DataTable_2E74:
    ld a, [$efef]
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    ei
    ret c

    cp $b0
    or c
    or d
    or e
    or h
    or l
    or [hl]
    or a
    cp b
    cp c
    cp d
    cp e
    cp h
    cp l
    cp [hl]
    cp a
    ret nz

    pop bc
    rst $38
    ret c

    cp $e0
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [rIE], a
    ret c

    cp $c2
    jp $c5c4


    add $c7
    ret z

    ret


    jp z, $cccb

    call $cfce

DataLookup_2EC2:
    ret nc

    pop de
    jp nc, $ffd3

    ret c

    db $fc
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    xor $ee
    db $fd

SerialTransferEpilogue:
    reti


SerialInterruptHandler:
    push af
    push bc
    push de
    push hl
    ld hl, $0300
    rst $10
    pop hl
    pop de
    pop bc
    pop af
    reti


LCDCInterruptHandler:
    push af
    push bc
    push de
    push hl
    ld a, [$c892]
    rst $00
    ld b, b

LCDCHandlerBody:
    cpl

MenuClearContents:
    ld a, [$082e]
    cpl
    inc h
    cpl

WaitSTATForLCDC:
    ldh a, [rSTAT]
    and $03
    jr nz, WaitSTATForLCDC

    ldh a, [rLCDC]
    res 1, a
    ldh [rLCDC], a
    jr LCDCEpilogue

    ldh a, [rLY]
    ld l, a
    ld h, $c1
    ld a, [hl]
    ldh [rSCX], a
    ldh a, [rLYC]
    add $02
    ldh [rLYC], a
    cp $80
    jr c, LCDCEpilogue

    ldh a, [$b7]
    ldh [rSCX], a
    ld a, $01
    ldh [rLYC], a
    jr LCDCEpilogue

    ldh a, [rLY]
    ld l, a
    ld h, $c1
    ld a, [hl]
    ldh [rSCY], a

LCDCScrollHandler:
    ldh a, [rLYC]
    add $02
    ldh [rLYC], a
    cp $81

LCDCCheckEnd:
    jr c, LCDCEpilogue

    ldh a, [$bb]
    ldh [rSCY], a
    ld a, $00
    ldh [rLYC], a
    jr LCDCEpilogue

LCDCEpilogue:
    pop hl
    pop de
    pop bc
    pop af
    reti


; CmpHLvsBC: Compare HL vs BC, set flags
CmpHLvsBC:
    ld a, h
    cp b
    ret nz

    ld a, l
    cp c
    ret


; Div16x16To16: DE = HL // BC; BC = HL % BC
Div16x16To16:
    ld de, $0000
    ld a, b
    or a
    jr z, Div16x16Simple

Div16x16Loop:
    ld a, l
    sub c
    ld l, a
    ld a, h
    sbc b

Div16x16CheckHigh:
    ld h, a
    jr c, Div16x16Remainder

    inc de
    jr Div16x16Loop

Div16x16Simple:
    ld a, c
    call Div16x8To16
    ld c, a
    ld b, $00
    jr RetFromHL8

Div16x16Remainder:
    add hl, bc
    ld b, h

MenuCalcPosition:
    ld c, l
    ld h, d
    ld l, e

RetFromHL8:
    ret


; HL_AddA_x8: HL += A × 8 — index into array with 8-byte entries
HL_AddA_x8:
    add a
    add a
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ret


GetMonsterSlotInfo:
    push hl
    push bc
    ld c, a
    call CheckMonsterSlot
    jr c, ReturnSlotResult

    ld a, c
    ld hl, $db02
    add a
    add a
    add a
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl+]
    and $d0
    jr nz, SetSlotCarryFlag

    inc hl
    inc hl
    ld a, [hl+]
    and $3f
    jr nz, SetSlotCarryFlag

MenuCalcWidth:
    inc hl

ReadSlotInfoByte:
    ld a, [hl]

MenuCalcHeight:
    and $c0
    jr nz, SetSlotCarryFlag

    xor a
    jr ReturnSlotResult

SetSlotCarryFlag:
    scf

ReturnSlotResult:
    ld a, c
    pop bc
    pop hl
    ret


; CheckMonsterSlot: Check if party/battle slot A (0-7) has a valid monster. CF=valid
CheckMonsterSlot:
    push hl
    push bc
    ld c, a
    cp $08
    jr nc, InvalidSlotClear

    ld hl, $dd1b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    and a
    jr z, ValidateSlotRange

    cp $ff
    jr z, InvalidSlotClear

    scf
    jr ReturnSlotA

InvalidSlotClear:
    xor a
    scf
    jr ReturnSlotA

ValidateSlotRange:
    ld a, $0a
    cp $01

ReturnSlotA:
    ld a, c
    pop bc
    pop hl
    ret


GetCombatantATK:
    ld hl, wBattleATK
    call IndexPtrTable
    ret


GetCombatantDEF:
    ld hl, wBattleDEF
    call IndexPtrTable
    ret


GetCombatantMaxHP:
    ld hl, wBattleMaxHP
    call IndexPtrTable
    ret


GetCombatantMaxMP:
    ld hl, wBattleMaxMP
    call IndexPtrTable
    ret


GetCombatantHP:
    ld hl, wBattleHP
    call IndexPtrTable
    ret


GetCombatantMP:
    ld hl, wBattleMP
    call IndexPtrTable
    ret



; Utility function (6 refs).
IndexPtrTable:
    add a
    add l
    ld l, a
    ld a, $00
    adc h

MenuDrawComplete:
    ld h, a
    ld a, [hl+]
    ld h, [hl]

MenuEndDraw:
    ld l, a

NopReturn:
Jump_NopReturn:
    ret


ReadBattleStateDA80:
DataLookup_3001:
    ld a, [$da80]

RetIfZeroA:
DataLookup_3004:
    or a
    ret z

InitBattleState:
    ld a, [$c863]
    and $02
    sla a
    ld b, a
    ld a, [wBattleAttackerIdx]
    xor b

CheckBattleIndex4:
    cp $04
    jr nc, CallBank5FEntry7

    ld a, [wBattleTargetIdx]
    xor b
    cp $04
    jr nc, CallBank5FEntry7

    ld a, $00

StoreBattleState:
    ld [$dd60], a
    ld a, $00

StoreBattleDD62:
    ld [$dd62], a

RetNop_3028:
    ret


CallBank5FEntry7:
    ld hl, $5f07
    rst $10
    ld a, [$da81]

CheckFFReturn:
    cp $ff
    ret z

    cp $0e
    jr c, jr_000_3048

    cp $15
    jr z, CheckDB8AState

    cp $21
    jr c, CallBank5DEntry0

CheckSaveSlot:
DataLookup_303F:
    cp $2c
    jr z, CheckDB75State

    ld hl, $5e00
    rst $10
    ret


CallBank5CEntry0_3048:
jr_000_3048:
    ld hl, $5c00
    rst $10
    ret


CallBank5DEntry0:
    ld hl, $5d00
    rst $10
    ret


CheckDB8AState:
    ld a, [$db8a]
    cp $c5
    jr nz, CallBank5DEntry0

CheckDB75State:
    ld a, [$db75]
    cp $01
    jr z, CheckDD1FState

CheckFieldMode2:
    cp $02
    jr z, CheckDD1FMode2

    ld a, [$dd1f]
    or a
    jr nz, jr_000_307f

    ld a, $20
    ldh [$c3], a
    ld a, [$da81]
    cp $15
    jr nz, CallBank5EEntry0

    ld hl, $5d00

CallBank5EEntry0_3078:
    rst $10
    jr jr_000_307f

CallBank5EEntry0:
    ld hl, $5e00
    rst $10

CheckFieldStateDD20:
jr_000_307f:
    ld a, [$dd20]
    or a
    jr nz, CheckDD21State

    ld a, $50
    ldh [$c3], a
    ld a, [$da81]
    cp $15
    jr nz, CallBank5E_DD20

    ld hl, $5d00
    rst $10
    jr CheckDD21State

CallBank5E_DD20:
    ld hl, $5e00
    rst $10

CheckDD21State:
    ld a, [$dd21]
    or a
    ret nz

    ld a, $80
    ldh [$c3], a
    ld a, [$da81]
    cp $15
    jr nz, CallBank5E_DD1F

    ld hl, $5d00
    rst $10
    ret


CallBank5E_DD1F:
    ld hl, $5e00
    rst $10
    ret


CheckDD1FState:
    ld a, [$dd1f]
    or a
    ret nz

    ld a, $50
    ldh [$c3], a
    ld a, [$da81]
    cp $15
    jr nz, CallBank5E_Mode2

    ld hl, $5d00
    rst $10
    ret


CallBank5E_Mode2:
    ld hl, $5e00
    rst $10
    ret


CheckDD1FMode2:
    ld a, [$dd1f]
    or a
    jr nz, CheckDD20Final

    ld a, $38
    ldh [$c3], a
    ld a, [$da81]
    cp $15
    jr nz, CallBank5E_Final

CallBank5D_Fallback:
    ld hl, $5d00
    rst $10
    jr CheckDD20Final

CallBank5E_Final:
    ld hl, $5e00
    rst $10

CheckDD20Final:
    ld a, [$dd20]
    or a
    ret nz

    ld a, $68

AudioGetTimerHRAM:
    ldh [$c3], a
    ld a, [$da81]
    cp $15
    jr nz, CallBank5E_Extra

    ld hl, $5d00
    rst $10
    ret


CallBank5E_Extra:
    ld hl, $5e00
    rst $10
    ret


CallBank5FEntry7_3103:
    ld hl, $5f07
    rst $10
    ld a, [$da81]
    cp $ff

RetIfZero:
    ret z

    ld hl, wBGPalette

AdvanceHLAndSetup:
    inc hl
    ld a, $d0
    ld [hl+], a
    ld a, $e0
    ld [hl], a
    ld hl, $3141
    ld a, [$da81]
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    ld [wObj1Palette], a
    ld a, [$da81]

CheckBankIndexRange:
    cp $0e
    jr c, CallBank5CEntry1

    cp $21

CallBank5EEntry1_3130:
    jr c, CallBank5DEntry1

    ld hl, $5e01

CrossBankCallAndRet2:
    rst $10
    ret


CallBank5CEntry1:
    ld hl, $5c01
    rst $10
    ret


CallBank5DEntry1:
    ld hl, $5d01
    rst $10
    ret


    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ret nc

    ret nc

    ret nc

    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ret nc

RetNCFromField:
    ret nc

    ldh [$e0], a
    ldh [$e0], a
    ldh [$d0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$e0], a
    ldh [$d0], a
    nop
    ld bc, $3512
    adc d
    call $ffee
    rst $38
    cp $ed
    jp z, AudioWave_3285

    ld de, Boot
    inc hl
    ld b, l
    ld h, a
    adc c
    xor e
    call $feef
    call c, $98ba
    db $76
    ld d, h
    ld [hl-], a
    db $10
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    xor $dd
    call z, $aabb
    sbc c
    adc b
    ld [hl], a
    ld h, [hl]
    ld d, l
    ld b, h
    inc sp
    ld [hl+], a
    ld de, $ff00
    rst $38
    sbc $bd
    inc h
    ld [de], a
    nop
    nop
    nop
    nop
    ld hl, $db42
    db $ed
    rst $38
    rst $38
    rst $38
    rst $38
    xor $ca
    ld d, e

AudioWave_31C3:
    ld de, $0000
    nop
    nop
    ld de, $ac35
    xor $ff
    rst $38

AudioWave_31CE:
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    rst $38
    nop
    nop
    nop
    ld h, [hl]
    xor d
    cp e
    db $dd
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    xor $ed
    db $dd
    call z, $bacb
    xor c
    sbc b
    add a
    ld h, l
    ld d, h
    ld b, e
    ld sp, $ff10
    rst $38

AudioWaveData_3200:
    rst $38
    rst $38
    rst $38
    rst $38
    nop
    nop
    nop
    xor d
    cp e
    call z, $eedd

AudioWave_320C:
    rst $38
    rst $38

AudioWave_320E:
    nop

AudioWave_320F:
    nop

AudioWave_3210:
    nop
    nop
    xor d
    xor d
    cp e

AudioWave_3215:
    call z, $dddd

AudioWave_3218:
    rst $38
    rst $38
    rst $38
    rst $38
    nop
    rst $38
    nop
    nop
    nop
    nop
    xor d
    xor d
    cp e

AudioWave_3225:
    call z, $dddd
    rst $38
    rst $38
    rst $38
    rst $38
    xor d
    rst $38
    ld bc, $2212
    inc sp
    dec [hl]
    ld d, l
    ld [hl], a

AudioWaveData_3235:
    sbc c
    ld d, l

AudioWave_3237:
    sbc c
    xor d
    cp e
    call z, $eedd
    rst $38
    db $fc
    call c, $90ba
    ld [hl], b
    ld d, b
    jr nc, @+$17

    dec d
    dec d
    dec d
    ld [hl+], a
    ld d, l
    ld [hl], a
    xor d
    call z, $eeee
    call $35ac
    inc hl
    ld de, $1111
    ld de, $5332
    jp z, $eedc

    xor $dd
    db $dd
    db $dd
    db $dd
    db $dd
    db $dd
    db $dd
    db $dd
    ld [hl+], a
    ld [hl+], a

Fill6BytesHL:
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl+], a
    ld [hl], b
    ld [hl-], a
    pop af
    ret nc

AudioWaveData_3272:
    or b
    sub b
    ld [hl], b
    ld d, b
    jr nc, AudioWaveEntry_328D

    dec d
    dec d
    dec d
    dec d
    dec d
    dec d
    dec d
    dec d
    di
    ret nc

    or b
    sub b
    ld [hl], b

AudioWave_3285:
    ld d, b
    jr nc, AudioWaveEntry_3298

    ld d, c
    ld b, b
    jr nc, AudioWaveEntry_32AC

    dec d

AudioWaveEntry_328D:
    dec d
    dec d
    dec d
    adc c
    sbc b
    xor b
    cp b
    ret z

    ret c

    add sp, -$0b

AudioWaveEntry_3298:
    push af
    push af
    push af
    push af
    push af
    push af
    push af
    push af
    cp c
    ret z

    ret c

    add sp, -$0f
    ret nc

    or b
    sub b
    ld [hl], b
    ld d, b
    jr nc, jr_000_32c1

AudioWaveEntry_32AC:
    dec d
    dec d
    dec d
    dec d
    sbc c
    xor b
    cp b
    ret z

    ret c

    add sp, -$0c
    db $f4
    ldh a, [$e0]
    ret nc

    or b
    sub b
    ld [hl], b
    ld d, b
    dec [hl]

AudioWaveData_32C0:
    db $db

AudioWaveData_32C1:
jr_000_32c1:
    di
    ret nc

AudioWave_32C3:
    or b
    sub b
    add c
    ld [hl], b
    ld h, b
    ld d, b
    ld b, b
    jr nc, AudioWaveEntry_32EC

AudioWaveData_32CC:
Jump_000_32cc:
    dec d
    dec d
    dec d
    dec d
    pop af
    ldh [$d0], a
    ret nz

    or b
    and b
    sub b
    add b
    ld [hl], b
    ld h, b
    ld d, b
    ld b, b
    jr nc, AudioWaveEntry_32FE

    db $10
    dec b
    pop af
    ld [hl], b
    ld d, b
    jr nc, @+$22

    dec d
    dec d
    dec d
    dec d
    dec b
    dec b
    dec b

AudioWaveEntry_32EC:
    dec b
    dec b
    dec b
    dec b
    pop af
    or b
    ld [hl], b
    ld d, b
    jr nc, AudioWaveEntry_3316

    jr nz, AudioWaveEntry_330D

    dec d
    dec d
    dec d
    dec d

AudioWaveData_32FC:
    dec d

AudioWaveData_32FD:
    dec d

AudioWaveEntry_32FE:
    dec d

AudioWave_32FF:
    dec b

AudioWaveData_3300:
    pop af
    or b
    ld [hl], b

AudioWaveData_3303:
    ld d, b
    jr nc, AudioWaveEntry_3316

    ld d, c

AudioWaveData_3307:
    ld b, b
    jr nc, AudioWaveEntry_332A

    dec d
    dec d
    dec d

AudioWaveEntry_330D:
    dec d
    dec d
    dec b

AudioWave_3310:
    di

AudioWave_3311:
    ret nc

    or b
    sub b
    ld [hl], b
    ld d, b

AudioWaveEntry_3316:
    jr nc, AudioWaveEntry_3328

AudioWaveData_3318:
    ld d, c
    ld b, b
    jr nc, InitAudioRegisters

    dec d
    dec d
    dec d
    dec b

AudioWave_3320:
    add hl, bc
    jr @+$2a

    jr c, jr_000_336d

    ld e, b
    ld l, b
    ld a, b

AudioWaveEntry_3328:
    adc b
    sbc b

AudioWaveEntry_332A:
    xor b
    cp b
    ret z

    ret c

    add sp, -$0b
    ret


InitAudioSystem:
    ld bc, $0000
    call AudioSetChannelDE26
    ld a, $80
    ldh [rNR52], a
    xor a

InitAudioRegisters:
    ldh [rNR51], a
    ld [$de1d], a
    ld a, $77

AudioWave_3343:
    ldh [rNR50], a
    ld hl, $dd80
    ld b, $06
    ld a, $ff

ClearAudioChannels:
    ld [hl], a
    ld de, $0019
    add hl, de
    ld [hl], a
    ld de, $0001
    add hl, de
    dec b
    jr nz, ClearAudioChannels

    xor a
    ld [$de29], a
    ret


ClearAudioState:
    xor a
    ld [$de29], a
    ret


    ld a, $04
    ld [$de29], a
    xor a
    ld [$de1d], a
    ret


AudioSetChannelDE26:
jr_000_336d:
    ld a, b
    ld [$de26], a
    ld a, c
    ld [$de27], a
    xor a
    ld [$de28], a
    ret


AudioSetupChannel:
    ld a, [$de23]
    inc a
    ld b, a
    ld a, $01

AudioSetupBranch:
    dec b
    jr z, AudioReadConfig

    add a
    jr AudioSetupBranch

AudioReadConfig:
    ld b, a
    ld a, [$de28]
    or b
    ld [$de28], a
    ret


AudioInitRegisters:
    ld a, [$de28]
    ld hl, $de26
    and [hl]
    cp [hl]
    jr nz, AudioClearDE28

    ld hl, $dd84
    ld a, [$de27]
    and $0f
    ld b, a
    ld a, [$de26]

AudioShiftRight:
    srl a
    ld [$de28], a
    jr nc, AudioAddOffset18

    ld a, [hl]
    and $f0
    or b
    ld [hl], a

AudioAddOffset18:
    ld a, l
    add $1a
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, [$de28]
    and a
    jr nz, AudioShiftRight

    xor a
    ld [$de26], a

AudioClearDE28:
    xor a
    ld [$de28], a
    ret


AudioUpdate3x:
    call AudioProcess

AudioUpdate2x:
    call AudioProcess

AudioUpdate1x:
    call AudioProcess

AudioProcess:
    push bc
    push de
    push hl
    ld a, [$de24]
    ld hl, $3466

AudioCompareAndJump:
    cp [hl]
    jr c, AudioSaveBankState

    inc hl

AudioLoadWaveRAM:
    inc hl
    inc hl
    inc hl
    jr AudioCompareAndJump

AudioSaveBankState:
    ld a, [$4000]		;load rom bank ID into a
    push af
    dec hl
    ld a, [hl-]
    ld [$2100], a
    swap a
    rra
    and $03
    ld [$4100], a
    ld a, [hl-]

AudioResetChannel:
    ld d, a

AudioResetFromHL:
    ld a, [hl-]
    ld e, a
    ld a, [$de24]
    sub [hl]
    ld l, a
    ld h, $00

MultiplyHL_3400:
AudioData_3400:
    add hl, hl
    add hl, hl

AudioAddHLDE:
AudioData_3402:
    add hl, de
    push hl

AudioPopDE:
    pop de

AudioReadDE:
    ld a, [de]

AudioNextByte:
    inc de
    ld c, a
    ld b, $00

AudioSetHLToDD80:
    ld hl, $dd80
    add hl, bc
    ld a, [hl]
    cp $ff
    jr z, AudioClearHL

    inc hl
    ld a, [hl-]

AudioMaskAndSetup:
    ld b, $ee
    and $03
    jr z, AudioReadDE1D

    ld b, $dd
    cp $01
    jr z, AudioReadDE1D

    ld b, $bb
    cp $02

AudioCheckZeroBranch:
    jr z, AudioReadDE1D

    ld b, $77

AudioReadDE1D:
    ld a, [$de1d]
    and b
    ld [$de1d], a

AudioClearHLAlias:
AudioClearHL:
    xor a
    ld [hl+], a

AudioReadDEByte:
    ld a, [de]
    inc de

AudioStoreHLByte:
    ld [hl+], a

CopyDE2HL_3435:
    ld a, [de]
    inc de

CopyDE2HL_3437:
Jump_000_3437:
    ld [hl+], a
    ld a, [de]
    inc de
    ld [hl+], a
    ld a, [$4000]
    ld [hl], a
    push hl

AudioSkipTwoBytes:
    inc hl
    inc hl
    inc hl
    inc hl
    inc hl
    ld a, $ff
    ld [hl], a

AudioPopHLAdvance21:
    pop hl
    ld de, $0015
    add hl, de
    xor a
    ld [hl], a

AudioRestoreBank:
    pop af
    ld [$2100], a
    swap a
    rra
    and $03
    ld [$4100], a
    ld a, [$de24]
    inc a
    ld [$de24], a
    pop hl
    pop de
    pop bc
    ret


    nop
    ld bc, $1c40
    ld hl, $4001
    dec e
    scf

AudioSetBC1E40:
    ld bc, $1e40
    rst $38

SaveBankAndAudioState:
    ld a, [$4000]

SaveAudioBankState:
    push af
    ld a, [$de29]
    ld [$de23], a
    xor a
    ld [$de1c], a
    ld hl, $de22
    inc [hl]
    ld hl, $dd80

AudioSaveToHRAM:
    push hl
    ld de, $ffe4
    ld b, $03

AudioSaveLoop:
    ld a, [hl+]
    ld [de], a
    inc e
    ld a, [hl+]
    ld [de], a
    inc e
    ld a, [hl+]
    ld [de], a
    inc e
    ld a, [hl+]
    ld [de], a
    inc e
    ld a, [hl+]
    ld [de], a
    inc e
    ld a, [hl+]
    ld [de], a
    inc e
    ld a, [hl+]
    ld [de], a
    inc e
    ld a, [hl+]
    ld [de], a
    inc e
    dec b
    jr nz, AudioSaveLoop

    ld a, [hl+]
    ld [de], a
    inc e
    ld a, [hl]
    ld [de], a

AudioGetChannelMask:
    ldh a, [$e5]
    and $03
    ld [$de1e], a
    ld b, a
    add a
    add a
    add b
    ld [$de21], a
    inc b
    ld a, $88

AudioRotateChannel:
    rlca
    dec b
    jr nz, AudioRotateChannel

    ld [$de1f], a
    ld [$de20], a
    ldh a, [$e4]
    ld b, a
    ldh a, [$fd]
    and b
    cp $ff
    jp z, AudioPopSetDE

    ldh a, [$e8]
    ld [$2100], a
    swap a
    rra
    and $03
    ld [$4100], a
    ldh a, [$fd]
    or b
    and a
    jp z, AudioReadE6

    call AudioProcessChannel
    call AudioNoteOn
    ldh a, [$f1]
    ld b, a

AudioGetFrequency:
    ldh a, [$f2]

AudioCompareFreq:
    inc a
    cp b
    jr c, AudioStoreFreqHL

    ld a, b

AudioStoreFreqHL:
    ldh [$f2], a
    ld hl, $ffea
    ldh a, [$e9]

AudioAddFreqOffset:
    and $0f
    add [hl]
    cp $10

AudioCheckCarry:
    jr c, AudioStoreAndSetVol

    sub $10
    ld [hl], a
    jr AudioReadDE1F

AudioStoreAndSetVol:
    ld [hl], a
    call AudioSetVolume
    ldh a, [$fb]
    and a
    jr z, AudioDecrementEC

    dec a

AudioSetRegFB:
AudioData_3515:
    ldh [$fb], a

AudioDecrementEC:
    ld hl, $ffec
    dec [hl]
    jr nz, AudioReadDE1F

    call AudioSetupChannel

AudioCopyFAtoFB:
    ldh a, [$fa]
    ldh [$fb], a
    call AudioGetEnvelope

AudioReadDE1F:
    ld a, [$de1f]
    ld b, a
    ld a, [$de1c]
    or b
    ld [$de1c], a

AudioPopAndPushHL:
    pop hl
    push hl
    ld de, $ffe4
    ld b, $03

AudioCopyDEtoHL:
    ld a, [de]
    ld [hl+], a
    inc e
    ld a, [de]
    ld [hl+], a
    inc e
    ld a, [de]
    ld [hl+], a
    inc e
    ld a, [de]
    ld [hl+], a
    inc e

AudioCopyDEtoHL2:
    ld a, [de]
    ld [hl+], a

AudioIncEReadDE:
    inc e
    ld a, [de]
    ld [hl+], a

CopyDE2HL_354A:
    inc e
    ld a, [de]
    ld [hl+], a
    inc e
    ld a, [de]
    ld [hl+], a
    inc e

AudioCopyLoop:
    dec b
    jr nz, AudioCopyDEtoHL

    ld a, [de]
    ld [hl+], a
    inc e
    ld a, [de]
    ld [hl+], a

AudioPopSetDE:
    pop hl
    ld de, $001a
    add hl, de
    ld a, [$de23]
    inc a
    ld [$de23], a
    cp $06
    jp c, AudioSaveToHRAM

    ld a, [$de1d]
    ldh [rNR51], a
    pop af
    ld [$2100], a
    swap a
    rra
    and $03
    ld [$4100], a
    call AudioInitRegisters
    ret


AudioReadE6:
    ldh a, [$e6]
    ld l, a
    ldh a, [$e7]
    ld h, a
    xor a
    ldh [$ea], a
    ld a, [hl+]
    and $0f
    ld d, a
    ld a, [$de1e]
    cp $02
    jr z, AudioStoreF1

    ld a, [hl+]
    rrca
    rrca
    and $c0
    or d

AudioStoreE9:
    ldh [$e9], a
    ld a, [hl+]
    swap a
    ldh [$eb], a
    ld a, [$de1e]
    cp $02
    jr z, AudioDisableNR30

    ld a, [hl+]
    ldh [$ed], a

AudioClearEE:
    xor a
    ldh [$ee], a
    ldh [$ef], a
    ldh [$f0], a
    ldh [$f3], a
    ldh [$fd], a
    dec a
    ldh [$f9], a
    ld a, $02
    ldh [$e4], a
    jp AudioCopyFAtoFB


AudioStoreF1:
    ld a, [hl+]
    ldh [$f1], a
    ld a, d
    jr AudioStoreE9

AudioDisableNR30:
    xor a
    ldh [rNR30], a
    ld d, a
    ldh a, [$ed]
    ld e, a
    cp $ff
    jr nz, AudioStoreDE2B

AudioReadEAndSwap:
    ld e, [hl]
    ld a, e
    ldh [$ed], a

AudioStoreDE2B:
    ld [$de2b], a
    swap e
    ld hl, $316e
    add hl, de

CopyBlock_35DD:
    ld de, $ff30
    ld b, $10

AudioBlockCopy:
    ld a, [hl+]
    ld [de], a
    inc de
    dec b
    jr nz, AudioBlockCopy

    jr AudioClearEE

AudioGetEnvelope:
Jump_000_35ea:
    ldh a, [$e4]
    ld l, a
    ldh a, [$fd]
    ld h, a
    add hl, hl
    ldh a, [$e6]
    ld e, a
    ldh a, [$e7]
    ld d, a

AudioAddOffset:
    add hl, de

AudioAdvancePointerAlias:
AudioAdvancePointer:
    ldh a, [$e4]
    add $01
    ldh [$e4], a
    ldh a, [$fd]

AudioAdvanceHigh:
    adc $00
    ldh [$fd], a
    ld a, [hl+]
    cp $d0
    jr nc, AudioCheckF0

    cp $b0
    jr nc, AudioCheckC0

AudioProcessNote:
    cp $a0

AudioJPNCProcess:
    jp nc, AudioCheckA0

AudioJPToNote:
    jp AudioLoadNoteB


AudioCheckFD:
    cp $fd
    jr nz, AudioCheckFF

    ldh a, [$e4]
    ldh [$f8], a
    ldh a, [$fd]
    ldh [$fe], a

AudioIncHLLoop:
    inc hl
    jr AudioAdvancePointer

AudioCheckFF:
    cp $ff
    jr nz, AudioIncHLLoop

    ldh [$e4], a
    ldh [$fd], a
    call AudioSetSweep
    ret


AudioCheckF0:
    cp $f0
    jr nc, AudioCheckFD

    cp $e0
    jr nc, AudioMask0F

    and $0f
    jr AudioLoadDE1E

AudioMask0F:
    and $0f

AudioNegate:
    cpl
    inc a

AudioLoadDE1E:
    ld b, a
    ld a, [$de1e]

AudioCheckChannel2:
    cp $02
    jr z, AudioIncAndLoop

    ld a, b
    ldh [$f3], a
    ld a, [hl]
    ldh [$f4], a
    ldh [$f5], a

AudioIncAndLoop:
    inc hl
    jr AudioAdvancePointer

AudioMask0FFromA:
    and $0f
    ld b, a
    ld a, [$de1e]
    cp $02
    jr z, AudioIncAndLoop2

AudioReadEB:
    ldh a, [$eb]
    and $0f
    jr nz, AudioIncAndLoop2

    ld a, [hl]
    ldh [$f1], a
    ld a, b
    swap a
    ldh [$f0], a

AudioIncAndLoop2:
    inc hl
    jr AudioAdvancePointer

AudioCheckC0:
    cp $c0
    jr nc, AudioMask0FFromA

    and $0f
    jr z, AudioCheckFC

    ld e, a
    ld a, [hl]
    and a
    jr nz, AudioDecrementEF

    ldh a, [$ee]
    dec a
    ldh [$ee], a
    jr z, AudioJPToLoopStart

    bit 7, a
    jr z, AudioCheckFC

    ld a, e
    ldh [$ee], a
    jr AudioCheckFC

AudioDecrementEF:
    ldh a, [$ef]
    dec a
    ldh [$ef], a
    jr z, AudioAdvancePtrAlt

    bit 7, a
    jr z, AudioCheckFC

    ld a, e

ProcessTextCharLoop:
    ldh [$ef], a

AudioCheckFC:
    ld a, [hl]
    cp $fc
    jr z, AudioReadPairHL

    ldh a, [$f8]
    ldh [$e4], a
    ldh a, [$fe]
    ldh [$fd], a
    jp Jump_000_35ea


AudioReadPairHL:
    inc hl
    ld a, [hl+]
    ldh [$e4], a

AudioStoreFD:
    ld a, [hl]
    ldh [$fd], a

AudioJPToLoopStart:
    jp Jump_000_35ea


    ldh a, [$e4]
    add $01
    ldh [$e4], a
    ldh a, [$fd]
    adc $00
    ldh [$fd], a
    jp Jump_000_35ea


AudioAdvancePtrAlt:
    ldh a, [$e4]
    add $01
    ldh [$e4], a
    jp Jump_000_35ea


AudioCheckA0:
    cp $a0
    jr nz, AudioCheckA1

    ld a, [hl+]
    swap a
    ldh [$eb], a
    ld a, [$de1f]
    ld b, a
    ld a, [$de1c]
    and b
    jp nz, AudioAdvancePointerAlias

    call AudioCommandHandler
    jp AudioAdvancePointerAlias


AudioCheckA1:
    cp $a1
    jr nz, AudioCheckA2

    ld a, [$de1e]

AudioCheckWaveRAM:
    cp $02
    jr z, AudioClearAndLoadWave

    ld a, [hl+]
    ldh [$ed], a
    jp AudioAdvancePointerAlias


AudioClearAndLoadWave:
    xor a
    ldh [rNR30], a
    ld d, a
    ld a, [hl+]
    ld e, a

AudioGetNoteLength:
    ldh [$ed], a
    ld a, [$de1f]
    ld b, a
    ld a, [$de1c]

AudioCheckAndBranch:
    and b
    jr z, AudioPushAndCalc

AudioJPLoop:
    jp AudioAdvancePointerAlias


AudioPushAndCalc:
    push hl
    ld a, e
    ld [$de2b], a
    swap e
    ld hl, $316e

AudioLoadWaveData:
    add hl, de
    ld de, $ff30
    ld b, $10

AudioWaveCopyLoop:
    ld a, [hl+]
    ld [de], a
    inc de
    dec b
    jr nz, AudioWaveCopyLoop

    pop hl

AudioJumpToFreqCalc:
Jump_000_3722:
    jp AudioAdvancePointerAlias


AudioCheckA2:
    cp $a2
    jr nz, AudioCheckA3

    ld a, [$de1e]
    cp $02

AudioBranchIfZero:
    jr z, AudioStoreF1Entry

AudioRotateAndStore:
    ld a, [hl+]
    rrca

AudioExtractBits:
    rrca
    and $c0
    ld d, a
    ldh a, [$e9]
    and $3f
    or d
    ldh [$e9], a

AudioJPToAdvance:
    jp AudioAdvancePointerAlias


AudioStoreF1Alias:
AudioStoreF1Entry:
    ld a, [hl+]
    ldh [$f1], a
    jp AudioAdvancePointerAlias


AudioCheckA3:
    cp $a3
    jr nz, AudioCheckA5

    ld a, [hl+]
    bit 7, a
    jr nz, AudioReadE5Low

    ld b, a
    and $0f
    add a
    ldh [$fa], a
    ldh [$fb], a
    ld a, b
    and $70

AudioLoadChannelState:
    ld e, a
    ldh a, [$e5]
    and $0f
    or e
    or $80

AudioStoreE5JP:
    ldh [$e5], a
    jp AudioAdvancePointerAlias


AudioReadE5Low:
    ldh a, [$e5]
    and $0f
    jr AudioStoreE5JP

AudioCheckA5:
    cp $a5
    jr nz, AudioCheckA6

    ld a, [hl+]
    cp $01
    jr nz, AudioStoreF9JP

    ldh a, [$f9]
    swap a

AudioStoreF9JP:
    ldh [$f9], a
    jp AudioAdvancePointerAlias


AudioCheckA6Alias:
AudioCheckA6:
    cp $a6
    jr nz, AudioCheckA7

    ld a, [hl+]
    ldh [rNR50], a
    jp AudioAdvancePointerAlias


AudioCheckA7:
    cp $a7
    jr nz, AudioCheckA8

    ld a, [hl]
    ldh [$ec], a
    jp AudioReadDE20


AudioCheckA8:
    cp $a8
    jr nz, AudioCheckAE

    ld a, [hl+]
    ldh [$fc], a
    jp AudioAdvancePointerAlias


AudioCheckAE:
    cp $ae
    jr nz, AudioCheckAF

    ld a, [hl+]
    and $10
    ld b, a
    ldh a, [$e9]
    and $ef
    or b
    ldh [$e9], a
    jp AudioAdvancePointerAlias


AudioCheckAF:
    cp $af
    jr nz, AudioIncHLJPLoop

    ld a, [hl+]
    and $0f
    ld b, a
    ldh a, [$e9]
    and $f0
    or b
    ldh [$e9], a
    jp AudioAdvancePointerAlias


AudioNoteEnd:
Jump_000_37c1:
AudioIncHLJPLoop:
    inc hl
    jp AudioAdvancePointerAlias


    nop
    ld bc, $1211
    inc d
    inc hl
    rlca
    dec d
    rla
    ld [hl-], a
    inc sp
    ld h, b
    ld h, c
    ld b, l
    ld d, e
    ld h, d

AudioClearChannel:
Jump_000_37d5:
AudioClearF6:
    xor a
    ldh [$f6], a
    ld a, $80
    ldh [$f7], a
    ld a, [$de1e]
    cp $02
    jr z, AudioCheckFlagClear

    call AudioSetDuty
    ret


AudioCheckFlagClear:
    call CheckAudioFlag
    xor a
    ldh [rNR30], a
    ret


AudioLoadNoteB:
    ld b, a
    ld a, [hl]
    ldh [$ec], a
    ld a, [$de1e]
    cp $03
    jr nz, AudioMaskLow4

    ld a, b
    cp $1f

AudioBranchZ_37FC:
Jump_000_37fc:
    jr z, AudioClearF6

AudioCheckRange16:
    cp $10

AudioBranchNC_3800:
Jump_000_3800:
    jr nc, AudioSetupHL

    ld hl, $37c5

AudioAddLOffset:
    add l
    ld l, a
    ld a, h

AudioCarryToH:
    adc $00
    ld h, a
    ld l, [hl]
    ld h, $00
    jr AudioClearF2

AudioSetupHL:
    ld l, a
    ld h, $00
    jr AudioClearF2

AudioMaskLow4Alias:
AudioMaskLow4:
    ld a, b
    and $0f

AudioCheckRange12:
    cp $0c
    jr nc, AudioClearF6

    add a
    ld e, a
    ldh a, [$e9]

AudioCheckBit4:
    and $10

AudioBranchZ_3822:
    jr z, AudioLookupNote

    ld a, e
    add $18
    ld e, a

AudioLookupNote:
    ld d, $00
    ld hl, $3a53
    add hl, de
    ld a, [hl+]
    ld h, [hl]

AudioLoadLA:
    ld l, a
    ld a, b
    swap a
    and $0f
    jr z, AudioNegateL

AudioStoreBfromA:
    ld b, a

AudioShiftHL:
    srl h
    rr l
    dec b
    jr nz, AudioShiftHL

AudioNegateL:
    ld a, $00
    sub l

AudioSetLength8:
    ld l, a
    ld a, $08
    sbc h
    ld h, a

AudioClearF2:
    xor a
    ldh [$f2], a

AudioSetNoteParams:
    call CheckAudioFlag
    ld a, [$de1e]
    cp $02
    jr nz, AudioPushAndLoad

    call ScreenTransE
    ld a, $80
    ldh [rNR30], a

AudioPushAndLoad:
    push hl
    call AudioLoadInstrument
    pop hl
    ld a, [$de1e]
    and a
    ldh a, [$ed]
    ld c, $10
    call z, WriteAudioRegister
    ld a, l
    ld c, $13
    call WriteAudioRegister
    ld a, l
    cp $02
    jr c, AudioSetF6_2

    cp $fe
    jr c, AudioStoreF6ReadDE1E

    ld a, $fd
    jr AudioStoreF6ReadDE1E

AudioSetF6_2:
    ld a, $02

AudioStoreF6ReadDE1E:
    ldh [$f6], a
    ld a, [$de1e]
    cp $02
    jr z, AudioClearNR31

    cp $02
    jr nc, AudioStoreH

    ldh a, [$e9]
    and $c0
    or $3f
    ld c, $11
    call WriteAudioRegister

AudioStoreH:
    ld a, h

AudioWriteNR51:
    and $07

AudioSetPanning:
    or $80

AudioStoreF7Setup:
    ldh [$f7], a
    ld c, $14
    call WriteAudioRegister

AudioReadDE20:
    ld a, [$de20]
    ld b, a
    cpl
    ld c, a
    ldh a, [$f9]
    and b
    ld b, a
    ld a, [$de1d]
    and c
    or b
    ld [$de1d], a
    ret


AudioClearNR31:
    xor a
    ldh [rNR31], a
    ldh a, [rNR52]
    and $04
    jr z, AudioStoreH

    ld a, h
    and $07

AudioWriteNR50:
    jr AudioStoreF7Setup

AudioSetVolume:
    ld a, [$de1e]
    cp $02
    ret z

CheckDMAState:
    ldh a, [$f3]
    and a
    ret z

    ld hl, $fff5
    dec [hl]
    ret nz

    ldh a, [$eb]
    swap a
    cp $10
    ret nc

    and $0f
    ld b, a
    ldh a, [$f4]

AudioStoreF5:
    ldh [$f5], a
    ld hl, $fff3
    ld a, [hl]
    bit 7, a
    jr nz, AudioIncrementHL

    dec [hl]
    ld a, b
    cp $0f
    ret z

    ldh a, [$eb]
    add $10

AudioSetEffect:
    ldh [$eb], a
    jp Jump_000_393c


AudioIncrementHL:
    inc [hl]
    ld a, b
    and a

AudioWriteChannelReg:
    ret z

AudioSetEffectAlt:
    ldh a, [$eb]

AudioChannelUpdate:
    sub $10
    ldh [$eb], a
    jr AudioMaskLow3

AudioProcessChannel:
AudioReadAndJP:
    call CheckAudioFlag

AudioCheckDE1EIs3:
    ld a, [$de1e]
    cp $03
    ret z

    ldh a, [$fb]
    and a
    ret nz

AudioReadE5Bit7:
    ldh a, [$e5]
    bit 7, a
    ret z

    and $70
    ld b, a
    ld a, [$de22]
    and $0f

AudioOrB:
    or b

AudioSetEDZero:
    ld e, a
    ld d, $00
    ld hl, $3b83
    add hl, de
    ldh a, [$f6]
    add [hl]
    ld c, $13
    jr jr_000_3954

AudioLoadInstrument:
    ld a, [$de1e]
    cp $02
    jr z, AudioReadEB_12

AudioGetPanning:
AudioMaskHigh:
    ldh a, [$f0]
    and a
    jr nz, AudioReadF1

    ldh a, [$eb]

AudioCommandHandler:
Jump_000_393c:
AudioMaskLow3:
    ld b, a
    and $07
    jr nz, AudioReadDE21

    ld a, b
    or $08
    ld b, a

AudioReadDE21Alias:
AudioReadDE21:
    ld a, [$de21]
    add $12
    ld c, a
    ld a, [c]
    cp b
    ret z

    ld a, b

AudioWritePort:
    ld [c], a
    ldh a, [$f7]
    ld c, $14

WriteAudioRegister:
jr_000_3954:
    ld b, a
    ld a, [$de21]
    add c
    ld c, a
    ld a, b
    ld [c], a
    ret


AudioReadEB_12:
    ldh a, [$eb]
    ld c, $12
    jr jr_000_3954

AudioShiftAndSetup:
    ld a, e
    srl a
    add $02
    swap a
    ld hl, $ffeb
    cp [hl]
    ret c

    and $60
    ldh [rNR32], a
    ret


AudioNoteOn:
    call CheckAudioFlag
    ldh a, [$f6]
    and a
    jr nz, AudioCheckCh2

    ldh a, [$f7]
    and $7f
    jp z, AudioBitManipHL

AudioCheckCh2:
    ld a, [$de1e]
    cp $02
    jr z, AudioReadF1

    ldh a, [$f0]
    and a
    ret z

AudioReadF1:
    ldh a, [$f1]
    and a
    ret z

    ld e, $00
    ld c, a
    ldh a, [$f2]
    ld b, $04

AudioDoubleCompare:
    add a
    cp c
    jr c, AudioCarryRotateE

    sub c

AudioCarryRotateE:
    ccf
    rl e
    dec b
    jr nz, AudioDoubleCompare

    ld a, [$de1e]
    cp $02
    jr z, AudioShiftAndSetup

    ldh a, [$f0]
    or e
    ld e, a
    ld d, $00
    push de
    ldh a, [$fc]

AudioNoteOff:
    ld de, $326e
    sla a
    add e
    ld e, a
    xor a
    adc d
    ld d, a
    ld a, [de]
    ld l, a
    inc de
    ld a, [de]

AudioShiftH:
    ld h, a
    pop de
    ld a, l
    sub $10
    ld l, a
    ld a, h
    sbc $00
    ld h, a
    add hl, de
    ldh a, [$eb]

AudioSwapToE:
    swap a
    ld e, a
    ld a, [hl]
    ld h, a
    and $f0
    or e
    ld e, a
    bit 2, h
    jr nz, AudioJump39FC

    inc b

AudioSetTempo:
    ld a, c
    swap a
    and $0f
    jr z, AudioJump39FC

    ld b, a
    bit 3, e
    jr nz, AudioLoadB

    sla b
    bit 2, e
    jr nz, AudioLoadB

    sla b
    bit 1, e
    jr z, AudioClearB

AudioLoadB:
    ld a, b

AudioCompare8:
    cp $08
    jr c, AudioJump39FC

AudioClearB:
    ld b, $00

AudioSetLoop:
AudioJump39FC:
    bit 1, h

AudioCheckZero:
    jr z, AudioCheckBit3

AudioEndLoop:
    ld a, b
    jr z, AudioCheckBit3

AudioShiftB:
    srl b

AudioCheckBit3:
    ld a, h
    and $08

AudioOrBSetup:
    or b
    ld b, a

AudioSetTranspose:
    bit 0, h

AudioCheckZero2:
    jr z, AudioSetupC12

AudioLookupTable:
    ld hl, $3a83
    add hl, de
    ld a, [hl]
    or b
    jp Jump_000_393c


AudioSetupC12:
    ld c, $12
    ld a, [$de21]
    add c
    ld c, a
    ld a, [c]
    and $08
    ld l, a
    ld a, h
    and $08
    cp l
    ret z

    ld hl, $3a83

AudioLookupAndLoad:
    add hl, de
    ld a, [hl]
    or b
    jp Jump_000_393c


AudioSetDuty:
AudioBitManipHL:
    call CheckAudioFlag
    ld a, $00
    jp Jump_000_393c


AudioSetSweep:
    call CheckAudioFlag
    ld a, [$de1f]
    cpl
    ld b, a
    ld a, [$de1d]
    and b

AudioStoreDE1D:
    ld [$de1d], a
    ret



; Utility function (6 refs).
Util_3A48:
CheckAudioFlag:
    ld a, [$de1f]
    ld b, a
    ld a, [$de1c]
    and b
    ret z

AudioPopAndRet:
    pop af
    ret


    call nc, $6407
    rlca
    ld sp, hl
    ld b, $95

AudioSetEnvelope2:
    ld b, $37
    ld b, $dd

AudioDecBADCC:
    dec b
    adc c
    dec b
    ld a, [hl-]
    dec b
    ldh a, [rDIV]
    xor b

AudioIncBHdrL:
    inc b
    ld h, l

AudioVibratoSetup:
    inc b
    ld h, $04

AudioSBCHRLCA:
    sbc h
    rlca
    ld l, $07
    rst $00
    ld b, $66
    ld b, $0a
    ld b, $b3
    dec b
    ld h, c

AudioDecBDecD:
    dec b
    dec d
    dec b
    call z, $8604
    inc b
    ld b, l
    inc b
    ld [$0004], sp
    nop

AudioNOPBlock:
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    db $10
    db $10
    db $10
    db $10
    db $10
    db $10
    db $10
    stop
    nop
    nop
    nop
    db $10
    db $10
    db $10
    db $10
    db $10

AudioVibratoProcess:
    db $10
    db $10
    db $10
    jr nz, PortaData_3AD1

    jr nz, jr_000_3ad3

    nop
    nop

AudioVibratoStep:
    nop
    db $10
    db $10
    db $10

AudioVibratoApply:
    db $10
    db $10
    jr nz, @+$22

    jr nz, PortaData_3ADF

    jr nz, FreqData_3AF1

    jr nc, FreqData_3AF3

    nop
    nop
    db $10

AudioPortamento:
    db $10
    db $10
    db $10
    jr nz, PortaData_3AEB

    jr nz, PortaData_3AED

    jr nc, FreqData_3AFF

    jr nc, FreqData_3B01

PortaData_3AD1:
    ld b, b
    ld b, b

AudioPortaStep:
jr_000_3ad3:
    nop
    nop
    db $10
    db $10
    db $10
    jr nz, @+$22

    jr nz, FreqData_3B0C

    jr nc, FreqData_3B0E

    ld b, b

PortaData_3ADFAlias:
PortaData_3ADF:
    ld b, b
    ld b, b
    ld d, b
    ld d, b
    nop
    nop
    db $10
    db $10
    jr nz, @+$22

    jr nz, FreqData_3B1B

PortaData_3AEB:
    jr nc, FreqData_3B2D

PortaData_3AED:
    ld b, b

AudioUpdateFreq:
    ld b, b
    ld d, b
    ld d, b

FreqData_3AF1:
    ld h, b
    ld h, b

FreqData_3AF3:
    nop
    nop
    db $10
    db $10
    jr nz, @+$22

    jr nc, FreqData_3B2B

    ld b, b
    ld b, b
    ld d, b
    ld d, b

FreqData_3AFF:
    ld h, b
    ld h, b

FreqData_3B01:
    ld [hl], b
    ld [hl], b

AudioWriteFreqRegs:
    nop
    db $10
    db $10
    jr nz, FreqData_3B28

    jr nc, AudioStopData_3B3A

    ld b, b
    ld b, b

FreqData_3B0C:
    ld d, b
    ld d, b

FreqData_3B0E:
    ld h, b

DataLookup_3B0F:
    ld h, b
    ld [hl], b
    ld [hl], b
    add b
    nop
    db $10
    db $10
    jr nz, AudioStopData_3B38

    jr nc, AudioStopData_3B5A

    ld b, b

FreqData_3B1B:
    ld d, b
    ld d, b
    ld h, b
    ld [hl], b
    ld [hl], b
    add b
    add b
    sub b
    nop
    db $10
    db $10
    jr nz, @+$32

FreqData_3B28:
    jr nc, AudioStopData_3B6A

    ld d, b

FreqData_3B2B:
    ld d, b
    ld h, b

FreqData_3B2D:
    ld [hl], b
    ld [hl], b
    add b
    sub b
    sub b

AudioStopChannel:
    and b
    nop
    db $10
    db $10
    jr nz, AudioStopData_3B68

AudioStopData_3B38:
    ld b, b
    ld b, b

AudioStopData_3B3A:
    ld d, b
    ld h, b
    ld [hl], b
    ld [hl], b
    add b
    sub b
    and b
    and b
    or b
    nop
    db $10
    jr nz, AudioStopData_3B67

    jr nc, AudioLookup_3B89

    ld d, b
    ld h, b
    ld h, b
    ld [hl], b
    add b
    sub b
    and b
    and b
    or b
    ret nz

    nop
    db $10
    jr nz, @+$32

    jr nc, @+$42

    ld d, b

AudioStopData_3B5A:
    ld h, b
    ld [hl], b
    add b
    sub b
    and b
    and b
    or b
    ret nz

    ret nc

    nop
    db $10
    jr nz, AudioLookup_3B97

AudioStopData_3B67:
    ld b, b

AudioStopData_3B68:
    ld d, b
    ld h, b

AudioStopData_3B6A:
    ld [hl], b
    ld [hl], b
    add b
    sub b
    and b
    or b
    ret nz

    ret nc

DataLookup_3B72:
    ldh [rP1], a
    db $10
    jr nz, AudioLookup_3BA7

    ld b, b
    ld d, b
    ld h, b
    ld [hl], b

DataTable_3B7B:
    add b

DataLookup_3B7C:
    sub b
    and b
    or b
    ret nz

    ret nc

    ldh [$f0], a
    nop
    nop
    ld bc, $0001
    nop

AudioLookup_3B89:
    rst $38
    rst $38
    nop
    nop
    ld bc, $0001
    nop
    rst $38
    rst $38
    nop
    nop
    nop
    nop

AudioLookup_3B97:
    ld bc, $0101
    ld bc, $0000
    nop
    nop
    rst $38
    rst $38
    rst $38
    rst $38
    nop
    ld bc, $0102

AudioLookup_3BA7:
    nop
    rst $38
    cp $ff
    nop
    ld bc, $0102
    nop
    rst $38
    cp $ff
    nop
    nop
    ld bc, $0201
    ld [bc], a
    ld bc, $0001
    nop
    rst $38
    rst $38
    cp $fe
    rst $38

AudioWavePatternData:
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    cp $fe
    cp $fe
    cp $fe
    cp $fe
    cp $fe
    cp $fe
    cp $fe
    cp $fe
    ld bc, $0101
    ld bc, $0101
    ld bc, $0101
    ld bc, $0101
    ld bc, $0101
    ld bc, $0202

ScreenTransA:
    ld [bc], a
    ld [bc], a
    ld [bc], a
    ld [bc], a
    ld [bc], a

ScreenTransB:
    ld [bc], a
    ld [bc], a
    ld [bc], a
    ld [bc], a
    ld [bc], a
    ld [bc], a

ScreenTransC:
ScreenTransitionSetup:
    ld [bc], a

ScreenTransD:
    ld [bc], a
    ld [bc], a

ScreenTransE:
    ld a, [$de2b]
    ld b, a

AudioGetNoteLenAlt:
    ldh a, [$ed]

ScreenTransF:
    cp b
    ret z

    ld [$de2b], a
    ld e, a
    swap e
    xor a
    ldh [rNR30], a
    ld d, a
    ld hl, $316e

ScreenLoadWaveRAM:
    add hl, de
    ld de, $ff30

CopyBlock_3C1C:
    ld b, $10

ScreenWaveCopyLoop:
    ld a, [hl+]
    ld [de], a
    inc de
    dec b
    jr nz, ScreenWaveCopyLoop

    ret


    ld a, [$cdff]
    dec a
    cp $f7
    jr nc, ScreenClearState

    ld a, [hl]
    or $7f
    cpl
    ld [hl], a
    bit 7, [hl]

RetNop_3C34:
    ret


ScreenClearState:
    xor a
    ld [hl], a

RetNop_3C37:
    ret


    call DispatchCD90
    ld b, e

ScreenFadeStep:
ScreenFadeInit:
    inc a
    ld c, d
    inc a
    add e
    inc a
    add $3c
    call $3dab
    ret nz

    jp PaletteStoreCD80Alt


    ld d, $c1
    call $07c1
    ld hl, $53b0

ScreenReadAndFade:
    call ReadScreenState
    ld a, [$c9c1]
    cp $03
    call z, CheckAndTriggerEvent
    call $3bf0
    jp PaletteStoreCD80Alt


CheckAndTriggerEvent:
    ld hl, $cda1
    ld a, [hl]
    ld [hl], $01
    or a
    ret z

    ld hl, $53b0
    ld a, $05
    jp $095a


ScreenSetDelay:
    ld a, $08
    ld [$c9c0], a
    ld a, $04
    ld [$c993], a
    ld [$cda1], a
    jp PaletteClearCD90


    call DataTable_3B7B
    jp z, PaletteStoreCD80Alt

    ld a, [$c9c1]
    cp $02
    jr nz, ScreenCallAndLookup

    ld a, [$cd98]
    cp $04
    jr nc, ScreenSetDelay

    cp $03
    jr nz, ScreenCallAndLookup

    ld a, [$cda1]
    or a
    jr nz, ScreenSetDelay

ScreenCallAndLookup:
    call $3dab
    ld hl, DataTable_3CBC

PushHLAndProcess:
Jump_000_3ca7:
    push hl
    call $3c13
    ld a, [hl]
    and $80
    rlca
    ld b, a
    pop hl
    ld a, [$c9c1]
    add a
    add b
    rst $28
    ld a, [hl]
    ld d, $cc
    rst $20
    ret


DataTable_3CBC:
    ld d, b
    ld d, c
    ld d, b
    ld d, c
    ld d, b
    ld d, c
    ld d, b

ScreenDispatchData:
    ld d, c
    ld d, b
    ld d, c
    ld a, [$c9c1]
    rst $00
    call nc, $d43c
    inc a
    call nc, $da3c
    inc a

PaletteSetup:
    call nc, $3e3c
    dec b
    ld [$c9c0], a
    ret


    call $12ff
    call AdvancePrintRow
    xor a
    ld [$c9c0], a
    ret


PaletteStoreCD80:
    ld [$cd80], a

PaletteApply:
PaletteStoreCD80Alt:
    ld hl, $cd90
    inc [hl]
    ret


PaletteClearCD90:
    xor a
    ld [$cd90], a
    ret


    call SetSerialByte
    jp $74d0


    call SetSerialByte
    jp $5a3d


    ld h, l

PaletteRetSBC:
    sbc h

PaletteRetLD:
    ld l, e

PaletteRetSBC2:
    sbc h

CheckPartyFlags:
    ld a, [$c98b]
    bit 0, a
    jp nz, RetFromWaitVRAM

    ld a, [$c9c1]
    dec a
    rst $00
    scf
    dec a
    rla
    dec a
    ld c, e
    dec a
    rla
    dec a
    call DispatchCD90
    ld b, e
    inc a
    ld [hl+], a
    dec a
    jr z, @+$3f

    scf
    dec a
    ld hl, $55b1
    jp ScreenReadAndFade


    call DataTable_3B7B
    jp z, PaletteStoreCD80Alt

    call $3dab
    ld hl, DataTable_3CBC
    jp Jump_000_3ca7


    ld d, $cc

MenuInputCheck:
    call TilemapRecombineAddr

MenuCheckAndCall:
    ld a, $20
    call $0510
    ld hl, $c98b
    set 0, [hl]
    ld a, $07
    jp $1c9d


    call SetSerialByte
    jp $6a57


    ld a, [$c98b]
    bit 0, a
    jp nz, RetFromWaitVRAM

    call ClearHRAMRegion
    call CopyDE2HL_354A

MenuCursorUpdate:
    call $128a
    call ClearSkillSlot
    call $6dc8
    call $71f7
    call $747b
    call SetSerialByte
    call MenuCursorDraw
    call $420e
    call TextHandler_0BCD
    jp $17ba


MenuCursorDraw:
    ld d, $c0
    ld a, [$c9c1]
    rst $00
    inc c
    ld c, h
    inc c
    ld c, h
    ld a, [de]
    ld e, c
    ret nz

    ld l, d
    dec l
    ld a, h
    ld a, [$c9c1]
    rst $00
    sbc e
    dec a
    sbc e
    dec a
    add hl, hl
    ld a, $67
    ld a, $7b
    ld a, $cd
    add h
    ld [de], a
    call DispatchCD90
    push hl
    dec a
    db $ec
    dec a
    ld a, [c]
    dec a
    dec bc
    ld a, $1c
    ld a, $cd
    call c, WriteBankReg4100
    ret nz

    call $0557
    xor a

SetMenuPosition:
    ld [$cd99], a
    call RotateRegC
    push bc
    ld a, [$cd9a]
    ld [hl-], a
    ld a, [$cd99]

MenuPositionCalc:
    ld [hl], a
    call $17b0
    xor a
    ld [$cd9a], a
    pop bc
    call $1a97
    ld de, $c008
    ld a, [de]
    cp $02
    ret nz

    ld hl, $c007
    res 5, [hl]
    ld a, [$c014]
    cp $70
    jr c, MenuReturnZero

    set 5, [hl]

MenuReturnZero:
    xor a
    ret


    call $3dab
    ret nz

    jp PaletteStoreCD80Alt


    call $3dab
    jp $420e


    call DataTable_3B7B
    jp z, PaletteStoreCD80Alt

    call $3dab
    ld hl, $3e01
    jp Jump_000_3ca7


    ld d, b

MenuDispatchData:
    ld d, c
    ld d, b
    ld d, c
    ld d, b
    ld d, c
    ld d, b
    ld d, c
    ld l, a

MenuDrawText:
    ld h, a
    ld a, $10
    ld [$cd9a], a
    call SetMenuPosition
    ld a, [$c00f]
    cp $34
    ret nc

    jp PaletteStoreCD80Alt


    ld b, $8d
    call $2043
    ld bc, $0537
    call $1196
    jr MenuClearState

    call SetSerialByte
    call DispatchCD90
    push hl
    dec a

MenuStoreResult:
    ld a, [c]
    dec a
    ld d, e
    ld a, $3e

StoreAndCallMenu:
    ld [de], a
    ld [$cd9a], a
    call SetMenuPosition
    ld a, [$c001]
    cp $01
    ret nz

    ld d, $c0
    call $0557
    ld a, $01
    ld [$cd9a], a
    call SetMenuPosition
    jp PaletteStoreCD80Alt


    ld b, $c9
    call $2043

MenuCallBank5B:
    ld a, $5b
    call $0510

MenuClearStateAlias:
MenuClearState:
    xor a
    ld [$c9c0], a
    ld hl, $c98b
    res 1, [hl]
    ret


    call SetSerialByte
    call DispatchCD90
    push hl
    dec a
    ld a, [c]
    dec a
    ld [hl], e
    ld a, $21
    inc c
    rra
    call ReadHRAM_d6_2042
    jr MenuCallBank5B

    ld b, $03
    call WriteHRAMMultiple
    jr nz, @+$13

    call SetSerialByte
    call $7b0c
    call DispatchCD90
    push hl
    dec a
    ld a, [c]
    dec a
    dec [hl]
    ld a, $58
    ld a, $cd
    ld c, e
    nop
    push hl
    dec a
    or h
    ld a, $cb
    ld a, $e4
    ld a, $66
    ccf
    srl [hl]
    db $e4
    ld a, $22
    ccf
    inc l
    ccf
    inc sp
    ccf
    ld d, b
    ccf
    ld [hl+], a
    ccf
    ld [hl+], a
    ccf
    ld h, [hl]
    ccf
    ld e, d
    ccf
    call DataTable_3B7B
    ld a, [$cd98]
    cp $03
    ret nz

NPCAnimFrame:
    inc a
    ld [$cd98], a
    xor a

SetMenuDimensions:
    ld [$cd81], a
    ld bc, $020b
    jp MenuStoreAndInit


    call PartyMenuSetup
    ret nz

    xor a
    ld [$ccb7], a

MenuLoadDimensions:
    ld hl, $3ed9
    jp $091e


    ld h, [hl]
    sbc h
    scf
    jr c, @+$3b

DataTable_3EDE:
    nop
    nop
    nop
    inc hl
    inc h
    rst $38
    call PartyMenuDraw
    ld a, [$ccb7]
    and a
    jr z, MenuLoadHLState

    ld a, [$cd90]
    cp $03
    ld bc, $040f
    jp z, MenuStoreAndInit

    ld bc, $0710
    jp MenuStoreAndInit


MenuLoadHLState:
    ld hl, $c9f5

CheckPartySize:
    ld a, [hl]
    cp $05
    jr c, MenuSetSmallSize

    ld hl, $cb80
    ld [hl], $f4
    inc l
    ld [hl], $01
    ld a, $08
    ld [$cd90], a
    ld a, $20
    jp Jump_000_0ba1


MenuSetSmallSize:
    ld bc, $0c0e
    jp MenuStoreAndInit

    ld h, [hl]
    sbc h
    ld l, e
    sbc h
    call PartyMenuSetup
    ret nz

    ld bc, $0d0c
    jp MenuStoreAndInit


    call CallScriptByType
    ret nz

    jp PaletteStoreCD80Alt


    ld hl, $cb80
    ld a, [hl]
    sub $01
    ld [hl+], a
    ld a, [hl]
    sbc $00
    ld [hl], a
    jr c, MenuCallTextHandler

    ld a, $01
    ld bc, $9fcb
    jp Jump_000_0c13


MenuCallTextHandler:
    ld a, $20
    call TextHandler_0BA1
    jp PaletteStoreCD80Alt


    call CallScriptByType
    ret nz

    ld bc, $0b0d
    jp MenuStoreAndInit


    call DataTable_3B7B
    ret nz

    ld b, $ec
    call $2043
    jp MenuClearStateAlias


PartyMenuSetup:
    call LookupDoublePtrTable
    push af
    ld hl, $3e01
    call PushHLAndProcess
    pop af
    ret nz

    call PaletteApply
    xor a
    ret


MenuStoreAndInit:
    ld a, b
    ld [$cd90], a
    ld a, c
    ld hl, $55ce
    call $095a
    jp SubtractBankOffset4


PartyMenuDraw:
    ld hl, $3f1e
    call CallBank5FEntry1_0541
    ld a, $0f
    jp nz, Jump_000_0515

    call $1290
    call $68f1
    pop bc
    ret


PartyMenuSelect:
    ld a, $0a
    ld [$c9c0], a
    ld hl, $c98b
    set 1, [hl]
    ret


PartyMenuConfirm:
    ld a, $06
    ld [$cd82], a
    push de
    ld hl, $55ce
    call ReadScreenState
    pop de
    jp $3bf0


    call CopyDE2HL_16E4
    ld hl, $76e9
    call $04b6
    ld a, [hl]
    and $0f
    ld [$ca8d], a
    ld a, [hl+]
    swap a
    and $0f
    ld [$ca86], a
    ld b, $01
    ld a, [$ca94]
    bit 0, a
    jr z, MenuReadEntry

    ld b, $10

MenuReadEntry:
    ld e, [hl]
    inc hl
    ld d, $d7

MenuCheckEnd:
    ld a, [hl+]
    cp $ff
    ret z

    cp $fe
    jr z, MenuReadEntry

    ld [de], a
    ld a, b
    call ReadDEMetadata3B
    jr MenuCheckEnd

; =============================================================================
; MapIDClampForDispatch — ROM0 helper for bank $01 per-room VRAM dispatch
; =============================================================================
; Returns A = wMapID if < CUSTOM_ROOM_START, else A = 0 (falls through to
; Castle's VRAM handler, which is harmless — just a VRAM update to $94D0).
; Called from bank $01 instead of `ld a, [wMapID]` before rst $00.
; 8 bytes, fits in ROM0 free space at $3FE8.
; =============================================================================
MapIDClampForDispatch::
    ld a, [wMapID]
    cp CUSTOM_ROOM_START
    ret c
    xor a                   ; A=0 → Castle handler (maintains VRAM state)
    ret

; Also used by bank $17 palette lookup — returns safe mapID for AttrPtrTable
MapIDClampForPalette::
    ld a, [wMapID]
    cp CUSTOM_ROOM_START
    ret c
    cp $6C                      ; room $6C+ = Castle source
    jr nc, .useCastle
    ld a, $04                   ; room $6B = Farm source
    ret
.useCastle:
    xor a                       ; A = $00 (Castle)
    ret
    rst $38
