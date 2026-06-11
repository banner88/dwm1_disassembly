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
    jp Jump_000_036e

    ld bc, $181a
    cp b

LCDCInterrupt::
    jp Jump_000_2eea


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
    jp Jump_000_2edd


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
    jr nz, jr_000_00ab

    inc a
    ld [$c984], a
    call $ff90
    call LoadCAndHRAM_CE
    add b
    ld b, $0a
    ld hl, $008e

jr_000_0087:
    ld a, [hl+]
    ld [c], a
    inc c
    dec b
    jr nz, jr_000_0087
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


jr_000_00ab:
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

    jp Jump_000_1214


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
    jr z, jr_000_01c6

    xor a
    ldh [rVBK], a
    ldh [rSVBK], a
    ldh [rRP], a

jr_000_01c6:
    call InitAudioAndJoypadCheck
    jr c, jr_000_01d2

    xor a
    ld [wIsSGB], a
    jp Jump_000_028b


jr_000_01d2:      ;all SGB related
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

Jump_000_025f:
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

Jump_000_028b:
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

jr_000_02db:
    ld a, [$c86c]
    or a
    call z, GenerateRNG
    ld a, [$c88e]
    or a
    jr z, jr_000_02db
    ld a, [$c850]
    or a
    jr z, jr_000_02f2

    bit 7, a
    jr z, jr_000_02db

jr_000_02f2:
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
    jp Jump_000_028b

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


Jump_000_036e:
    push af

GameStateUpdate_036F:
    push bc
    push de
    push hl
    ld hl, $c8a2
    bit 0, [hl]
    jp nz, Jump_000_045c

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
    jr z, jr_000_039b

    ld a, [$c8b9]
    or a
    call z, SaveBankAndAudioState

jr_000_039b:
    ei
    ld a, [$c86c]
    or a
    jr nz, jr_000_03b3

    call UpdateSGBJoypad
    call UpdateJoypadState
    ld hl, $c8b9
    inc [hl]
    call SaveBankAndAudioState
    xor a
    ld [$c8b9], a

jr_000_03b3:
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
    jr nz, jr_000_03e9

    ld a, [$c86c]
    or a
    jp z, InitGameData

jr_000_03e9:
    ld a, [$c86c]
    or a
    jr nz, jr_000_044d

    ld a, [$c842]
    and $03				;check if A and B are being pressed
    cp $03
    jr jr_000_044d			;This jump seems to be here to disable the debug menu.
                        ;dummying it out makes the debug menu work from anywhere

    ld a, [wJoypad_current_frame]
    bit 2, a
    jr z, jr_000_041f

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

jr_000_041f:
    ld a, [$c842]
    bit 3, a
    jr z, jr_000_044d

ReadJoypad:
    ld a, [wJoypad_current_frame]
    bit 2, a
    jr z, jr_000_044d

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

jr_000_044d:
    ld hl, $c8a2
    res 0, [hl]

jr_000_0452:
    ldh a, [rLY]
    ld [$c886], a
    pop hl
    pop de
    pop bc
    pop af
    reti


Jump_000_045c:
    call WaitVRAMAccess
    ld a, [$c8b9]
    or a
    jr nz, jr_000_0468

    call SaveBankAndAudioState

jr_000_0468:
    ei
    jr jr_000_0452

ProcessFrameUpdate:
    xor a
    ldh [$cb], a
    call CheckAnimLockAndProcess
    ld a, [$c850]
    or a
    jr z, jr_000_047a

    bit 7, a
    ret z

jr_000_047a:
    call CheckVRAMTileCount
    ret


CheckState_C86c_047E:
    ld a, [$c86c]
    or a
    ret z

Jump_000_0483:
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
    jr z, jr_000_04c7

    ld a, $00
    ld [$c866], a
    ld a, [$c873]
    jp Jump_000_126b


jr_000_04c7:
    ld hl, $c871
    ld a, [hl+]
    or [hl]
    jr z, jr_000_04f1

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


jr_000_04f1:
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
    jr nz, jr_000_050f

    ld a, [$c850]
    or a
    jr z, jr_000_050f

    bit 7, a
    ret z

jr_000_050f:
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


Jump_000_053c:
    ld hl, $0202
    rst $10
    ret


CallBank5FEntry1_0541:
    ld hl, $5f01
    rst $10
    ret


    ld hl, $5f09
    rst $10

Jump_000_054a:
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

Jump_000_056d:
    ret


CheckSoundQueueState:
Jump_000_056e:
    ld a, [$c8b1]
    or a
    jr z, jr_000_058d

    dec a
    ld [$c8b1], a
    ldh a, [rSCY]
    ld b, a
    ld a, [$c8b1]
    add a
    ld c, a
    and $07
    bit 3, c
    jr nz, jr_000_0588

    xor $07

jr_000_0588:
    sub $04
    add b
    ldh [rSCY], a

jr_000_058d:
    ld a, [$c8b2]
    or a
    jr z, jr_000_05ac

    dec a
    ld [$c8b2], a
    ldh a, [rSCX]
    ld b, a
    ld a, [$c8b2]
    add a
    ld c, a
    and $07
    bit 3, c
    jr nz, jr_000_05a7

Jump_000_05a5:
    xor $07

jr_000_05a7:
    sub $04
    add b
    ldh [rSCX], a

jr_000_05ac:
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

Jump_000_05be:
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

Jump_000_05f9:
    ld a, [$c837]

Jump_000_05fc:
    ld l, a

Jump_000_05fd:
    ld a, [$c838]

CopyDE2HL_0600:
Jump_000_0600:
    ld h, a

Jump_000_0601:
jr_000_0601:
    ld a, [de]
    ld [hl+], a
    inc de

Jump_000_0604:
    cp $f0
    jr nz, jr_000_0601

RetUnused:
    ret


RequestScreenUpdate:
Jump_000_0609:
    ld hl, $c825

SetScreenUpdateFlag:
    set 1, [hl]

jr_000_060e:
    call CheckState_C826_0618
    ld a, [$c825]
    or a
    jr nz, jr_000_060e

    ret


CheckState_C826_0618:
    ld a, [$c826]

CheckScreenUpdateBit7:
    bit 7, a
    jr z, jr_000_062f

jr_000_061f:
    ld hl, $c825

WaitScreenUpdateLoop:
    set 1, [hl]
    call SaveBankForTextDisplay
    ld a, [$c826]
    bit 7, a
    jr nz, jr_000_061f

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
    jp z, Jump_000_0853

CheckTilemapBit5:
Jump_000_0648:
    bit 5, a
    jr z, jr_000_0666

    ld c, $ea
    ld a, [$c8a4]
    bit 4, a
    jr z, jr_000_0657

    ld c, $ee

jr_000_0657:
    ld hl, $0060

SetupTilemapRow:
    call AdjustTilemapOffset
    ld b, $09

DrawTilemapColumn:
    call TilemapAdvanceColumns
    ld a, c
    call Write_gfx_tile

Jump_000_0666:
jr_000_0666:
    ld a, [$c825]
    bit 2, a
    jp z, Jump_000_076d

    ld a, [$c83a]
    cp $e6
    jp z, Jump_000_067e

    ld a, [$c83a]
    cp $ff
    jp nz, Jump_000_0753

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
    jr z, jr_000_06a8

    ld a, $00

SetJoypadAction:
    ld [$c83c], a
    jr jr_000_06a8

JoypadActionDone:
jr_000_0698:
    bit 7, a
    jr z, jr_000_06a8

    ld a, [$c83c]
    cp $01
    jr z, jr_000_06a8

    ld a, $01
    ld [$c83c], a

jr_000_06a8:
    ld c, $e8
    ld b, $e0

Jump_000_06ac:
    ld a, [$c83c]
    or a
    jr z, jr_000_06b6

    ld c, $e0

CheckCursorInput:
    ld b, $e8

jr_000_06b6:
    ld a, [$c8a4]
    bit 4, a

InputBranchZero:
    jr z, jr_000_06c1

    ld c, $e0

Jump_000_06bf:
    ld b, $e0

jr_000_06c1:
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
    jr z, jr_000_0704

    ld a, [$c83c]
    or a
    jr nz, jr_000_0709

    ld a, [$c83a]

CheckTileE6:
Jump_000_06f8:
    cp $e6
    jp z, Jump_000_070e

Jump_000_06fd:
    ld a, $59

PlaySoundAndJump:
Jump_000_06ff:
    call PlaySoundEffect
    jr jr_000_070e

jr_000_0704:
    bit 1, a
    jp z, Jump_000_0853

jr_000_0709:
    ld a, $01
    ld [$c83c], a

Jump_000_070e:
jr_000_070e:
    ld hl, $c825
    res 2, [hl]
    res 1, [hl]
    ld hl, $0000
    call GetTilemapRowAddr
    ld de, $c500
    ld c, $12

TilemapFillRow:
jr_000_0720:
    ld b, $20
    push hl

jr_000_0723:
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
Jump_000_0730:
    pop af
    or l
    ld l, a

Jump_000_0733:
    inc de
    dec b

Jump_000_0735:
    jr nz, jr_000_0723

    pop hl
    push bc
    ld bc, $0020
    add hl, bc
    ld a, h
    and $03
    or $98
    ld h, a

Jump_000_0743:
    pop bc

Jump_000_0744:
    dec c
    jr nz, jr_000_0720

    ld de, $560b

CheckJoypadAB:
    ld hl, $8e50
    call WaitDMATransfer
    jp Jump_000_0853


Jump_000_0753:
    ld a, [wJoypad_current_frame]
    ld b, a
    ld a, [$c84a]
    or b
    and $f7

CheckJoypadDPad:
Jump_000_075d:
    jp z, Jump_000_0853

    ld hl, $c825
    res 2, [hl]
    res 1, [hl]
    call HandleScreenRefresh
    jp Jump_000_0853


Jump_000_076d:
    bit 6, a
    jr z, jr_000_0794

    ld a, [$c835]
    dec a
    ld [$c835], a
    or a
    jp z, Jump_000_0789

    ld a, [wJoypad_current_frame]
    ld b, a
    ld a, [$c84a]
    or b

CheckInputMasked:
Jump_000_0784:
    and $f7
    jp z, Jump_000_0853

Jump_000_0789:
    ld hl, $c825
    res 6, [hl]
    call HandleScreenRefresh
    jp Jump_000_0853


jr_000_0794:
    bit 7, a
    jr z, HandleTextCharacter

    ld a, [$c836]
    dec a
    ld [$c836], a
    or a
    jp nz, Jump_000_0853

    ld hl, $c825
    res 7, [hl]
    jp Jump_000_0853


HandleTextCharacter:
    ld a, [$c82d]
    ld l, a
    ld a, [$c82e]
    ld h, a
    ld a, [hl]			;read character for text box.
    cp $8d
    jp z, Jump_000_0822

    cp $8e

JoypadAutoRepeat:
    jp z, Jump_000_0822

    cp $e0			;e0 brings up the YES NO box.
    jp nc, Jump_000_0838

    ld a, [$c825]
    bit 1, a
    jr nz, jr_000_07f0

    ld a, [wJoypad_current_frame]
    ld b, a

SetButtonFlags:
    ld a, [$c84a]
    or b

SetRefreshOnInput:
    and $f7
    jr z, jr_000_07db

    ld hl, $c826
    set 7, [hl]

jr_000_07db:
    ld a, $02

ScreenProcessA:
Jump_000_07dd:
    ld b, a
    ld a, [$c825]
    bit 3, a
    jr z, jr_000_07e9

    ld a, [$c833]

ScreenProcessB:
    ld b, a

jr_000_07e9:
    ld a, [$c839]
    cp b
    jp c, Jump_000_0853

jr_000_07f0:
    xor a
    ld [$c839], a
    ld hl, $c826
    res 1, [hl]

Jump_000_07f9:
    call GetTilemapByte

Jump_000_07fc:
    ld a, [hl]

CheckTileE0:
    cp $e0

ScreenBranchNC:
    jp nc, Jump_000_0838

    call LoadTileBankAware
    ld a, [$c826]
    bit 0, a

Jump_000_080a:
    jr z, jr_000_0853

CheckTile90:
    ld a, b
    cp $90

ScreenBranchZ:
    jr z, jr_000_0853

Jump_000_0811:
    cp $9a
    jr z, jr_000_0853

    ld a, [$c840]
    call PlaySoundEffect
    ld hl, $c826
    set 1, [hl]
    jr jr_000_0853

Jump_000_0822:
    ld a, [$c82d]
    add $01
    ld [$c82d], a
    ld a, [$c82e]

Jump_000_082d:
    adc $00

SetScreenStateA:
    ld [$c82e], a

ProcessScreenState:
Jump_000_0832:
    ld a, [hl]
    call LoadTileBankAware2
    jr jr_000_0853

CheckState_C82d_0838:
Jump_000_0838:
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

Jump_000_0853:
jr_000_0853:
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

jr_000_08a7:
    di

jr_000_08a8:		;wait for vblank
    ldh a, [rSTAT]
    bit 1, a
    jr nz, jr_000_08a8

Jump_000_08ae:
    ld a, [de]
    ld [hl+], a		;load tile data into vram and increment. Used when drawing text.
    inc e
    ld a, [de]
    ld [hl+], a
    ei
    inc de
    dec c
    jr nz, jr_000_08a7

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

Jump_000_08d6:
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

jr_000_08f0:
    di
    ld a, b
    cp $0d
    jr z, jr_000_0901

jr_000_08f6:
    ldh a, [rSTAT]
    bit 1, a
    jr nz, jr_000_08f6

    ld a, [de]
    or [hl]
    ld [hl+], a
    jr jr_000_090c

jr_000_0901:
    ldh a, [rSTAT]
    bit 1, a
    jr nz, jr_000_0901

    ld a, [de]
    or [hl]
    and $fd
    ld [hl+], a

jr_000_090c:
    ei
    inc de
    dec b
    jr nz, jr_000_08f0

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
    jr nc, jr_000_09ae

    cp $0a
    jr nc, jr_000_09b3

    jr jr_000_09b8

jr_000_09ae:
    ld e, $64
    call SetDMinusOne

jr_000_09b3:
    ld e, $0a
    call SetDMinusOne

jr_000_09b8:
    ld [hl+], a
    ld a, $f0
    ld [hl], a
    ret


SetDMinusOne:
    ld d, $ff

jr_000_09bf:
    inc d

SubtractWithFloor:
    sub e
    jr nc, jr_000_09bf
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
    jp nz, Jump_000_09fb

    ld a, $01
    ldh [$db], a
    ld e, $a0
    ld d, $86
    call ReadHRAM_d5_0A2E
    or a
    jr nz, jr_000_0a09

    ld a, $00
    ldh [$db], a
    ld e, $10
    ld d, $27
    call ReadHRAM_d5_0A2E
    or a
    jr nz, jr_000_0a17

    ldh a, [$d5]
    ld c, a
    ldh a, [$d6]
    ld b, a
    jp Jump_FormatDecimalDigits


Jump_000_09fb:
    ld a, $0f
    ldh [$db], a
    ld e, $40
    ld d, $42
    call GetHRAMPointerA
    call WriteByteAndTerminate

jr_000_0a09:
    ld a, $01
    ldh [$db], a
    ld e, $a0
    ld d, $86
    call GetHRAMPointerA
    call WriteByteAndTerminate

jr_000_0a17:
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
    jp Jump_000_0a9f


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

jr_000_0a58:
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
    jr nc, jr_000_0a58

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
    jr nz, jr_000_0a9f

    ld de, $0064
    push bc
    call DivBCbyDE
    pop bc
    or a
    jr nz, jr_000_0aa8

    ld de, $000a
    push bc
    call DivBCbyDE
    pop bc
    or a
    jr nz, jr_000_0ab1

    jr jr_000_0aba

Jump_000_0a9f:
jr_000_0a9f:
    ld de, $03e8
    call DivBCbyDE
    call WriteByteAndTerminate

jr_000_0aa8:
    ld de, $0064
    call DivBCbyDE
    call WriteByteAndTerminate

jr_000_0ab1:
    ld de, $000a
    call DivBCbyDE
    call WriteByteAndTerminate

jr_000_0aba:
    ld a, c
    call WriteByteAndTerminate
    ret


DivBCbyDE:
    push hl
    ld h, $ff

jr_000_0ac2:
    inc h
    ld a, c
    sub e
    ld c, a
    ld a, b
    sbc d
    ld b, a
    jr nc, jr_000_0ac2

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
    jr nc, jr_000_0b03

    ld a, d
    ld [$c822], a
    ld a, e
    ld [$c823], a
    ld hl, $4200

Jump_000_0b01:	;invalid. Needs to be fixed when bank 04 is merged.
    rst $10

    ret		;unused. May be from a time when RST10 returned.


jr_000_0b03:
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
    jr nc, jr_000_0b2e

    inc d
    ld a, d
    ld [$c822], a
    ld a, e
    ld [$c823], a
    ld hl, $4300
    rst $10

    ret


jr_000_0b2e:
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
    jr nc, jr_000_0b83

    ld a, d
    ld [$c822], a
    ld a, e
    ld [$c823], a
    ld hl, $4600
    rst $10
    ret


jr_000_0b83:
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

Jump_000_0b98:
    sbc $04
    ld d, a

CallScriptByType:
    ld a, e
    cp $74
    jr nc, jr_000_0bae

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


jr_000_0bae:
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
    jr nc, jr_000_0bd9

    inc d
    ld a, d

TextHandler_0BCD:
    ld [$c822], a
    ld a, e
    ld [$c823], a
    ld hl, $4800
    rst $10
    ret


jr_000_0bd9:
    cp $e0
    jr nc, jr_000_0bed

    sub $12
    ld e, a
    ld a, d
    ld [$c822], a
    ld a, e
    ld [$c823], a
    ld hl, $4900
    rst $10
    ret


jr_000_0bed:
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
    jr nc, jr_000_0c2f

    inc d
    inc d
    ld a, d
    ld [$c822], a
    ld a, e
    ld [$c823], a
    ld hl, $4a00
    rst $10
    ret


jr_000_0c2f:
    sub $c0
    ld e, a
    ld a, d
    ld [$c822], a
    ld a, e
    ld [$c823], a

Jump_000_0c3a:
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
    jr nc, jr_000_0c5a

    inc d
    ld a, d
    ld [$c822], a
    ld a, e
    ld [$c823], a
    ld hl, $4b00
    rst $10

    ret


jr_000_0c5a:
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

jr_000_0c82:
    ld a, [de]
    ld [hl+], a
    inc de
    cp $8d
    jr z, jr_000_0c82

    cp $8e
    jr z, jr_000_0c82

    dec b
    jr nz, jr_000_0c82

    ld a, [de]
    cp $8d
    jr z, jr_000_0c9c

    cp $8e
    jr z, jr_000_0c9c

    ld [hl], $f0
    ret


jr_000_0c9c:
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

jr_000_0cd0:
    push bc

jr_000_0cd1:
    ld a, e
    call Write_gfx_tile
    call TilemapNextColumn
    inc e
    dec b
    jr nz, jr_000_0cd1

    pop bc
    ld hl, $0040
    call AdjustTilemapOffset
    dec c
    jr nz, jr_000_0cd0

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

jr_000_0d62:
    ld a, [de]
    ld [hl+], a
    inc e
    ld a, [de]
    ld [hl+], a
    inc de
    dec b
    jr nz, jr_000_0d62

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
    jp nz, Jump_000_0ee3

    ldh a, [$c9]
    ld c, a
    ldh a, [$ca]
    and $20
    jr nz, jr_000_0e6f

jr_000_0dfd:
    ld a, [hl+]
    cp $80
    ret z

    ld b, a
    jr nc, jr_000_0e15
    ldh a, [$cd]
    add b
    ld b, a
    ldh a, [$ce]
    adc $00
    jr nz, jr_000_0e24

    ld a, b
    cp $a8
    jr c, jr_000_0e29

    jr jr_000_0e24

jr_000_0e15:
    ldh a, [$cd]
    add b
    ld b, a
    ldh a, [$ce]
    adc $ff
    jr nz, jr_000_0e24

    ld a, b
    cp $a8
    jr c, jr_000_0e29

jr_000_0e24:
    inc hl
    inc hl
    inc hl
    jr jr_000_0dfd

jr_000_0e29:
    ld a, b
    ld [de], a
    inc e
    ld a, [hl+]
    ld b, a
    rlca
    jr c, jr_000_0e42

    ldh a, [$cf]
    add b
    ld b, a
    ldh a, [$d0]
    adc $00
    jr nz, jr_000_0e51

    ld a, b
    cp $b8
    jr c, jr_000_0e58

    jr jr_000_0e51

jr_000_0e42:
    ldh a, [$cf]
    add b
    ld b, a
    ldh a, [$d0]
    adc $ff
    jr nz, jr_000_0e51

    ld a, b
    cp $b8
    jr c, jr_000_0e58

jr_000_0e51:
    inc hl
    inc hl
    dec e
    xor a
    ld [de], a
    jr jr_000_0dfd

jr_000_0e58:
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
    jr nz, jr_000_0dfd

    ret


jr_000_0e6f:
    ld a, [hl+]
    cp $80
    ret z

    ld b, a
    jr nc, jr_000_0e87

    ldh a, [$cd]
    add b
    ld b, a
    ldh a, [$ce]
    adc $00
    jr nz, jr_000_0e96

    ld a, b
    cp $a8
    jr c, jr_000_0e9b

    jr jr_000_0e96

jr_000_0e87:
    ldh a, [$cd]
    add b
    ld b, a
    ldh a, [$ce]
    adc $ff
    jr nz, jr_000_0e96

    ld a, b
    cp $a8
    jr c, jr_000_0e9b

jr_000_0e96:
    inc hl
    inc hl
    inc hl
    jr jr_000_0e6f

jr_000_0e9b:
    ld a, b
    ld [de], a
    inc e
    ld a, [hl+]
    ld b, a
    rlca
    jr c, jr_000_0eb6

    ldh a, [$d1]
    sub b
    ld b, a
    ldh a, [$d2]
    sbc $00
    jr z, jr_000_0ecc

    jr nz, jr_000_0ec5

    ld a, b
    cp $b8
    jr c, jr_000_0ecc

    jr jr_000_0ec5

jr_000_0eb6:
    ldh a, [$d1]
    sub b
    ld b, a
    ldh a, [$d2]
    sbc $ff
    jr nz, jr_000_0ec5

    ld a, b
    cp $b8
    jr c, jr_000_0ecc

jr_000_0ec5:
    inc hl
    inc hl
    dec e
    xor a
    ld [de], a
    jr jr_000_0e6f

jr_000_0ecc:
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
    jr nz, jr_000_0e6f

    ret


Jump_000_0ee3:
    ldh a, [$ca]
    and $20
    jr nz, jr_000_0f63

jr_000_0ee9:
    ld a, [hl+]
    cp $80
    ret z

    ld c, a
    ld b, $00
    rlca
    jr nc, jr_000_0ef4

    dec b

jr_000_0ef4:
    ldh a, [$cd]
    add c

LoadCAndHRAM_CE:
    ld c, a
    ldh a, [$ce]
    adc b
    jr nz, jr_000_0f1f

    ld a, c
    cp $a8
    jr nc, jr_000_0f1f

    ldh a, [$d3]
    or a
    jr z, jr_000_0f24

    cp $01
    jr nz, jr_000_0f12

    ld a, c
    cp $34
    jr c, jr_000_0f1f

    jr jr_000_0f24

jr_000_0f12:
    cp $02
    jr nz, jr_000_0f1d

    ld a, c
    cp $71
    jr c, jr_000_0f24

    jr jr_000_0f1f

jr_000_0f1d:
    jr jr_000_0f24

jr_000_0f1f:
    inc hl
    inc hl
    inc hl
    jr jr_000_0ee9

jr_000_0f24:
    ld a, c
    ld [de], a
    inc e
    ld a, [hl+]
    ld c, a
    ld b, $00
    rlca
    jr nc, jr_000_0f2f

    dec b

jr_000_0f2f:
    ldh a, [$cf]
    add c
    ld c, a
    ldh a, [$d0]
    adc b
    jr nz, jr_000_0f3d

    ld a, c
    cp $b8
    jr c, jr_000_0f44

jr_000_0f3d:
    inc hl
    inc hl
    dec e
    xor a
    ld [de], a
    jr jr_000_0ee9

jr_000_0f44:
    ld a, c
    ld [de], a
    call SaveHLBC
    jr nc, jr_000_0f3d

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
    jr nz, jr_000_0ee9

    ret


jr_000_0f63:
    ld a, [hl+]
    cp $80
    ret z

    ld c, a
    ld b, $00
    rlca
    jr nc, jr_000_0f6e

    dec b

jr_000_0f6e:
    ldh a, [$cd]
    add c
    ld c, a
    ldh a, [$ce]
    adc b
    jr nz, jr_000_0f99

    ld a, c
    cp $a8
    jr nc, jr_000_0f99

    ldh a, [$d3]
    or a
    jr z, jr_000_0f9e

    cp $01
    jr nz, jr_000_0f8c

    ld a, c
    cp $34
    jr c, jr_000_0f99

    jr jr_000_0f9e

jr_000_0f8c:
    cp $02
    jr nz, jr_000_0f97

    ld a, c
    cp $71
    jr c, jr_000_0f9e

    jr jr_000_0f99

jr_000_0f97:
    jr jr_000_0f9e

jr_000_0f99:
    inc hl
    inc hl
    inc hl
    jr jr_000_0f63

jr_000_0f9e:
    ld a, c
    ld [de], a
    inc e
    ld a, [hl+]
    ld c, a
    ld b, $00
    rlca
    jr nc, jr_000_0fa9

    dec b

jr_000_0fa9:
    ldh a, [$d1]
    sub c
    ld c, a
    ldh a, [$d2]
    sbc b
    jr nz, jr_000_0fb7

    ld a, c
    cp $b8
    jr c, jr_000_0fbe

jr_000_0fb7:
    inc hl
    inc hl
    dec e
    xor a
    ld [de], a
    jr jr_000_0f63

jr_000_0fbe:
    ld a, c
    ld [de], a
    call SaveHLBC
    jr nc, jr_000_0fb7

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
    jr nz, jr_000_0f63

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

jr_000_1007:
    ldh a, [rSTAT]
    bit 1, a
    jr nz, jr_000_1007
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

jr_000_101b:		;may just be a .wait?
    nop
    nop
    nop
    dec de
    ld a, d
    or e
    jr nz, jr_000_101b

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
    jr nz, jr_000_1074

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
    jr nz, jr_000_1074

    ld a, $0a
    ld [$c774], a
    ld hl, $0800
    rst $10
    call DisableSRAM
    sub a
    ret


jr_000_1074:
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
    jr jr_000_108d

Jump_000_1089:
    ldh a, [rP1]
    cp c
    ret z

jr_000_108d:
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
    jp nz, Jump_000_1089

    ret


SGBDelay:
    ld a, [wIsSGB]
    or a
    ret z

jr_000_10d4:
    ld de, $06d6

jr_000_10d7:
    nop
    nop
    nop
    dec de
    ld a, d
    or e
    jr nz, jr_000_10d7

    dec bc
    ld a, b
    or c
    jr nz, jr_000_10d4

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

jr_000_1118:
    ld b, $14

jr_000_111a:
    ld [hl+], a
    inc a
    dec b
    jr nz, jr_000_111a

    add hl, de
    dec c
    jr nz, jr_000_1118

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

jr_000_1178:
    ld a, [de]
    ld [hl+], a
    inc de
    dec bc
    ld a, b
    or c
    jr nz, jr_000_1178

    ld hl, $9800
    ld de, $000c
    ld a, $80
    ld c, $0d

jr_000_118a:
    ld b, $14

jr_000_118c:
    ld [hl+], a
    inc a
    dec b
    jr nz, jr_000_118c

    add hl, de
    dec c

EnableLCD:
    jr nz, jr_000_118a

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

jr_000_11c4:
    ld [hl+], a
    dec c
    jr nz, jr_000_11c4

    pop bc
    pop hl
    ret


Jump_000_11cb:
    push af
    ld a, [$c86c]
    or a
    jr z, jr_000_11d5

    call CheckScreenModeC86C

jr_000_11d5:
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

Jump_000_1214:
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

jr_000_12c8:
    ld [hl], d 		;so far: breaks here when point set on inventory slot while opening ITEM option in bank. May just be for clearing or settings blocks of data to a single value.
    inc hl		;increment to next inv slot
    dec bc		;decrease counter, which is probably the number of total available inv slots.
    ld a, b		;load b into a to prepare for...
    or c 		;checking to see if the counter is 0
    jr nz, jr_000_12c8

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
    jr z, jr_000_1310
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


jr_000_1310:
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
    jr z, jr_000_1390

    cp [hl]
    jr z, jr_000_139d

jr_000_1390:
    ld a, [wJoypad_current_frame]
    ld [wJoypad_Current], a
    ld a, $14

ReadJoypadRaw:
    ld [$c848], a
    jr jr_000_13ad

jr_000_139d:
    ld hl, $c848
    ld a, [hl]
    or a
    jr nz, jr_000_13ac

    ld [hl], $06
    ld a, [$c842]
    ld [wJoypad_Current], a

jr_000_13ac:
    dec [hl]

jr_000_13ad:
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
    jr z, jr_000_13c6

    cp [hl]
    jr z, jr_000_13d3

jr_000_13c6:
    ld a, [$c84a]
    ld [$c84b], a
    ld a, $14
    ld [$c84c], a
    jr jr_000_13e3

jr_000_13d3:
    ld hl, $c84c
    ld a, [hl]
    or a
    jr nz, jr_000_13e2

    ld [hl], $06
    ld a, [$c844]
    ld [$c84b], a

jr_000_13e2:
    dec [hl]

jr_000_13e3:
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

jr_000_1434:
    ld [hl+], a
    inc l
    inc l
    inc l
    inc b
    jr nz, jr_000_1434

    ret


GetSpritePointerDE:
    ld a, [$c740]
    ld e, a
    ld a, [$c741]
    ld d, a
    ld a, d
    or e
    jr nz, jr_000_1449

    ret


jr_000_1449:
    ld a, [$c743]
    ld b, a
    ld hl, $c744
    ld a, [$c742]
    cp $ff
    ret z

    or a
    jr nz, jr_000_148f

    ld a, e
    and $e0
    ld c, a

jr_000_145d:
    ld a, [hl+]
    ld [de], a
    inc e
    ld a, e
    and $1f
    or c
    ld e, a
    dec b
    jr nz, jr_000_145d

    ld a, [wIsGBC]
    or a
    jr z, jr_000_14c7

    ld a, $01
    ldh [rVBK], a
    ld a, [$c740]
    ld e, a
    ld a, [$c741]
    ld d, a
    ld a, [$c743]
    ld b, a

jr_000_147e:
    ld a, [hl+]
    ld [de], a
    inc e
    ld a, e
    and $1f
    or c
    ld e, a
    dec b
    jr nz, jr_000_147e

    ld a, $00
    ldh [rVBK], a
    jr jr_000_14c7

jr_000_148f:
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
    jr nz, jr_000_148f

    ld a, [wIsGBC]
    or a
    jr z, jr_000_14c7

    ld a, $01
    ldh [rVBK], a
    ld a, [$c740]
    ld e, a
    ld a, [$c741]
    ld d, a
    ld a, [$c743]
    ld b, a

jr_000_14b4:
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
    jr nz, jr_000_14b4

    ld a, $00
    ldh [rVBK], a

jr_000_14c7:
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

Jump_000_14e8:
jr_000_14e8:
    ld a, [de]
    inc de
    push hl
    ld hl, $ffab
    cp [hl]
    jr z, jr_000_14fc

    pop hl
    ld [hl], a
    inc hl
    dec bc
    ld a, b
    or c
    jr nz, jr_000_14e8

    jp Jump_000_156a


jr_000_14fc:
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
    jr nz, jr_000_1514
    ld a, [de]
    inc de
    add $13

jr_000_1514:
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

jr_000_152b:
    ldh a, [$b2]
    cp d
    jr z, jr_000_1534

    jr c, jr_000_153b

    jr jr_000_1556

jr_000_1534:
    ldh a, [$b1]
    cp e
    jr z, jr_000_153b

    jr nc, jr_000_1556

jr_000_153b:
    ld a, $f0
    add d
    ld d, a
    ldh a, [$b4]
    cp d
    jr z, jr_000_1548

    jr nc, jr_000_154f

    jr jr_000_1556

jr_000_1548:
    ldh a, [$b3]
    cp e
    jr z, jr_000_1556

    jr c, jr_000_1556

jr_000_154f:
    ld a, $10
    add d
    ld d, a
    xor a
    jr jr_000_1557

jr_000_1556:
    ld a, [de]

jr_000_1557:
    ld [hl+], a
    inc de
    dec bc
    ld a, b
    or c
    jr z, jr_000_1569

    ldh a, [$af]
    dec a
    ldh [$af], a
    jr nz, jr_000_152b

    pop de
    jp Jump_000_14e8


jr_000_1569:
    pop de

Jump_000_156a:
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

Jump_000_1590:
jr_000_1590:
    ld a, [de]
    inc de
    push hl
    ld hl, $ffab
    cp [hl]
    jr z, jr_000_15a5

    pop hl
    call Write_gfx_tile_and_inc_HL
    dec bc
    ld a, b
    or c
    jr nz, jr_000_1590

    jp Jump_000_161a


jr_000_15a5:
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
    jr nz, jr_000_15bd

    ld a, [de]
    inc de
    add $13

jr_000_15bd:
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

jr_000_15d4:
    ldh a, [$b2]
    cp d
    jr z, jr_000_15dd

    jr c, jr_000_15e4

    jr jr_000_15ff

jr_000_15dd:
    ldh a, [$b1]
    cp e
    jr z, jr_000_15e4

    jr nc, jr_000_15ff

jr_000_15e4:
    ld a, $f0

TextWaitInput:
Jump_000_15e6:
    add d
    ld d, a
    ldh a, [$b4]
    cp d
    jr z, jr_000_15f1

    jr nc, jr_000_15f8

    jr jr_000_15ff

jr_000_15f1:
    ldh a, [$b3]
    cp e

TextEndOfLine:
Jump_000_15f4:
    jr z, jr_000_15ff

    jr c, jr_000_15ff

jr_000_15f8:
    ld a, $10
    add d
    ld d, a
    xor a
    jr jr_000_1605

jr_000_15ff:
    di
    call WaitVRAM
    ld a, [de]
    ei

jr_000_1605:
    call Write_gfx_tile_and_inc_HL
    inc de
    dec bc

TextNewLine:
    ld a, b
    or c
    jr z, jr_000_1619
    ldh a, [$af]
    dec a
    ldh [$af], a
    jr nz, jr_000_15d4

    pop de

BankSwitch_1616:
    jp Jump_000_1590


jr_000_1619:
    pop de

Jump_000_161a:
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
    jr jr_000_1671

jr_000_1671:
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
    jp nz, Jump_000_1734

    ld a, [wIsSGB]
    or a
    jp z, Jump_000_173f

    bit 7, b
    jr nz, jr_000_16c5

    ld a, b
    ld [$c850], a
    ld hl, $c7f7
    ld de, $c7d7
    ld c, $20

jr_000_16a7:
    ld a, [de]
    ld [hl+], a
    inc de
    dec c
    jr nz, jr_000_16a7

    ld a, $00
    ld [$c856], a
    ld a, [$c850]
    srl a
    srl a
    ld [$c857], a
    ld [$c858], a
    call CheckAnimBusy
    jp Jump_000_17db


jr_000_16c5:
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
    jr z, jr_000_16f7

    ld de, $0000

jr_000_16f7:
    ld hl, $c7d7
    ld c, $10

jr_000_16fc:
    ld [hl], e
    inc hl
    ld [hl], d
    inc hl
    dec c
    jr nz, jr_000_16fc

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
    jp z, Jump_000_17db

    call ClearPaletteBuffer
    ld hl, $c7e7
    ld de, $c777
    ld a, $09
    ld [de], a
    inc de
    call Copy8BytesHL2DE
    call DisableSRAM
    jp Jump_000_17db


Jump_000_1734:
    ld a, b
    ld [$c850], a
    ld hl, $1704
    rst $10
    jp Jump_000_17db


Jump_000_173f:
    ld a, [$c851]
    bit 7, a
    jr nz, jr_000_1792

    bit 7, b
    jr nz, jr_000_1772

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
    jr jr_000_17db

jr_000_1772:
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
    jp Jump_000_17db


jr_000_1792:
    bit 7, b
    jr nz, jr_000_17be

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
    jr jr_000_17db

jr_000_17be:
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

Jump_000_17db:
jr_000_17db:
    ret


    add hl, hl
    add hl, hl
    add hl, hl
    ld bc, $8800
    add hl, bc
    ld c, $08

jr_000_17e5:
    ld a, [hl+]
    ld [de], a
    inc de
    dec c
    jr nz, jr_000_17e5

    ret


CheckState_C850_17EC:
    ld a, [$c850]
    or a
    ret z

    bit 7, a
    call z, CheckAnimBusyAndProcess
    ld a, [wIsGBC]
    or a
    jp nz, Jump_000_1964

    ld a, [wIsSGB]
    or a
    jp z, Jump_000_1969

    ld a, [$c850]
    bit 7, a
    jr nz, jr_000_1836

    ld a, [$c858]
    or a
    jr z, jr_000_1816

    dec a
    ld [$c858], a
    ret


jr_000_1816:
    ld a, [$c856]
    add $05
    cp $1f
    jr c, jr_000_1821
    ld a, $1f

jr_000_1821:
    ld [$c856], a
    call CheckState_C852_185F
    ld a, [$c857]
    ld [$c858], a
    ld a, [$c856]
    cp $1f
    jp z, Jump_000_1aa1

    ret


jr_000_1836:
    ld a, [$c858]
    or a
    jr z, jr_000_1841

    dec a
    ld [$c858], a
    ret


jr_000_1841:
    ld a, [$c856]
    sub $05
    bit 7, a
    jr z, jr_000_184b

    xor a

jr_000_184b:
    ld [$c856], a
    call CheckState_C852_185F
    ld a, [$c857]
    ld [$c858], a
    ld a, [$c856]
    or a
    jp z, Jump_000_1aa1

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
    jr z, jr_000_189a

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

jr_000_189a:
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

jr_000_18c2:
    ld a, [hl+]
    ld [de], a
    inc de
    dec c
    jr nz, jr_000_18c2

    inc hl
    inc hl
    ld c, $06

jr_000_18cc:
    ld a, [hl+]
    ld [de], a
    inc de
    dec c
    jr nz, jr_000_18cc

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
    jr nz, jr_000_195d

    and $1f
    add b
    cp $1f
    jr c, jr_000_1963

    ld a, $1f
    jr jr_000_1963

jr_000_195d:
    and $1f
    sub b
    jr nc, jr_000_1963

    xor a

jr_000_1963:
    ret


Jump_000_1964:
    ld hl, $1705
    rst $10
    ret


Jump_000_1969:
    ld a, [$c851]
    bit 7, a
    jp nz, Jump_000_1a08

    ld a, [$c850]
    bit 7, a
    jr nz, jr_000_1999

    ld a, [$c858]
    or a
    jr z, jr_000_1983

    dec a
    ld [$c858], a
    ret


jr_000_1983:
    call ApplyPaletteBuffer_BG
    ld a, [$c857]
    ld [$c858], a
    ld a, [$c856]
    inc a
    ld [$c856], a
    cp $04
    jp z, Jump_000_1aa1

    ret


jr_000_1999:
    ld a, [$c858]
    or a
    jr z, jr_000_19a4

    dec a
    ld [$c858], a
    ret


jr_000_19a4:
    call ApplyPaletteBuffer_BG
    ld a, [$c857]
    ld [$c858], a
    ld a, [$c856]
    dec a
    ld [$c856], a
    cp $ff
    jp z, Jump_000_1aa1

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
    jr nc, jr_000_1a01

    xor a

jr_000_1a01:
    or c
    ld c, a
    rrc c
    rrc c
    ret


Jump_000_1a08:
    ld a, [$c850]
    bit 7, a
    jr nz, jr_000_1a30

    ld a, [$c858]
    or a
    jr z, jr_000_1a1a

    dec a
    ld [$c858], a
    ret


jr_000_1a1a:
    call ApplyPaletteBuffer_OBJ
    ld a, [$c857]
    ld [$c858], a
    ld a, [$c856]
    inc a
    ld [$c856], a
    cp $04
    jp z, Jump_000_1aa1

    ret


jr_000_1a30:
    ld a, [$c858]
    or a
    jr z, jr_000_1a3b

    dec a
    ld [$c858], a
    ret


jr_000_1a3b:
    call ApplyPaletteBuffer_OBJ
    ld a, [$c857]
    ld [$c858], a
    ld a, [$c856]
    dec a
    ld [$c856], a
    cp $ff
    jr z, jr_000_1aa1

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
    jr c, jr_000_1a9a

    ld a, $03

jr_000_1a9a:
    or c
    ld c, a
    rrc c

RotateRegC:
    rrc c
    ret


Jump_000_1aa1:
jr_000_1aa1:
    xor a
    ld [$c850], a
    ret


; WaitVRAM: Wait for VRAM access window (LCD STAT bit 1 clear)
WaitVRAM:
jr_000_1aa6:
    ldh a, [rSTAT]
    bit 1, a
    ret z

Jump_000_1aab:
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
    jr nz, jr_000_1ace

    pop af
    ret


jr_000_1ace:
    di

jr_000_1acf:
    ldh a, [rSTAT]
    bit 1, a
    jr nz, jr_000_1acf

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
    jr z, jr_000_1b2a

    ld [$de24], a
    cp $27
    jr z, jr_000_1b22

    cp $3a
    jr z, jr_000_1b27

    cp $3f
    jr z, jr_000_1b27

    cp $47
    jr z, jr_000_1b27

    cp $49
    jr z, jr_000_1b27

    cp $4b
    jr z, jr_000_1b27

    cp $4d
    jr z, jr_000_1b27

    cp $4f
    jr z, jr_000_1b27

    cp $5d
    jr z, jr_000_1b27

    cp $9d
    jr z, jr_000_1b27

    call AudioUpdate2x
    ei
    ret


jr_000_1b22:
    call AudioUpdate3x
    ei
    ret


jr_000_1b27:
    call AudioUpdate1x

jr_000_1b2a:
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
    jr z, jr_000_1b9d

    cp $41
    jr z, jr_000_1ba7

    cp $44
    jr z, jr_000_1ba7

    cp $47
    jr z, jr_000_1b9d

    cp $49
    jr z, jr_000_1b9d

    cp $4b
    jr z, jr_000_1b9d

    cp $4d
    jr z, jr_000_1b9d

    cp $4f
    jr z, jr_000_1b9d

    cp $57
    jr z, jr_000_1b9d

    cp $5d
    jr z, jr_000_1b9d

    cp $63
    jr z, jr_000_1b9d

    cp $61
    jr z, jr_000_1ba7

    cp $69
    jr z, jr_000_1b9d

    cp $74
    jr z, jr_000_1b9d

    cp $76
    jr z, jr_000_1b9d

    cp $78
    jr z, jr_000_1b9d

    cp $7c
    jr z, jr_000_1b9d

    cp $86
    jr z, jr_000_1b9d

    cp $8a
    jr z, jr_000_1b9d

    cp $90
    jr z, jr_000_1b9d

    cp $97
    jr z, jr_000_1b9d

    cp $99
    jr z, jr_000_1b9d

    cp $9d
    jr z, jr_000_1b9d

    di
    call AudioProcess
    ei
    pop hl
    pop de
    pop bc
    pop af
    ret


jr_000_1b9d:
    di
    call AudioUpdate1x
    ei
    pop hl
    pop de
    pop bc
    pop af
    ret


jr_000_1ba7:
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
    jr z, jr_000_1bc4

    cp $9d
    jr z, jr_000_1bc4

    call InitBGM
    ld a, $ff
    ld [wBGM], a

jr_000_1bc4:
    ld a, [wSoundEffect]
    cp $ff
    jr z, jr_000_1bd3

    call LoadSE
    ld a, $ff
    ld [wSoundEffect], a

jr_000_1bd3:
    ret


    ret


CheckAnimBusy:
    ld b, a
    ld a, [$c88f]
    or a
    jr nz, jr_000_1c13

    ld a, b
    bit 7, a
    jr nz, jr_000_1c13

    or a
    jr z, jr_000_1c13

    ld [$c894], a
    ld a, [wIsSGB]
    or a
    jr nz, jr_000_1bf5

    ld a, [$c894]
    sra a
    ld [$c894], a

jr_000_1bf5:
    ldh a, [rNR50]
    bit 7, a
    jr nz, jr_000_1c13

    bit 3, a
    jr nz, jr_000_1c13

    or a
    jr z, jr_000_1c13

    ld a, [$c894]
    ld [$c895], a
    ld a, $08
    ld [$c896], a
    ldh a, [rNR50]
    ld [$c897], a
    ret


jr_000_1c13:
    xor a
    ld [$c894], a
    ret


CheckAnimBusyAndProcess:
    ld a, [$c88f]
    or a
    jr nz, jr_000_1c84

    ld a, [$c894]
    bit 7, a
    jr nz, jr_000_1c84

    or a
    ret z

    ld a, [$c895]
    or a
    jr z, jr_000_1c32

    dec a
    ld [$c895], a
    ret


jr_000_1c32:
    ldh a, [rNR50]
    and $88
    cp $88
    jr z, jr_000_1c84

    ld a, [$c897]
    or a
    jr z, jr_000_1c84

    ld b, a
    and $0f
    ld d, a
    ld a, b
    swap a
    and $0f
    ld c, a
    bit 3, c
    jr nz, jr_000_1c53

    ld a, c
    or a
    jr z, jr_000_1c53

    dec c

jr_000_1c53:
    bit 3, d
    jr nz, jr_000_1c5c

    ld a, d
    or a
    jr z, jr_000_1c5c

    dec d

jr_000_1c5c:
    ld a, c
    swap a
    or d
    ldh [rNR50], a
    ld [$c897], a
    or a
    jr z, jr_000_1c79

    ld a, [$c896]
    or a
    jr z, jr_000_1c84

    dec a
    ld [$c896], a
    ld a, [$c894]
    ld [$c895], a
    ret


jr_000_1c79:
    ld a, [$c86c]
    or a
    jr nz, jr_000_1c84

    di
    call InitAudioSystem
    ei

jr_000_1c84:
    xor a
    ld [$c894], a
    ret


SetColorMode:
    ld hl, $c81b
    cp [hl]
    ret z

    ld [hl], a
    cp $00
    jr nz, jr_000_1cb9

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
    jr jr_000_1d37

jr_000_1cb9:
    cp $01
    jr nz, jr_000_1ce3

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
    jr jr_000_1d37

jr_000_1ce3:
    cp $02
    jr nz, jr_000_1d0d

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
    jr jr_000_1d37

jr_000_1d0d:
    cp $03
    jr nz, jr_000_1d37

    ld a, $10
    ld de, $2e24
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
    jr jr_000_1d37

jr_000_1d37:
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
    jr z, jr_000_1d94

    ld a, $08
    call SetInterruptEnable
    ld a, [$c864]
    set 7, a
    res 6, a
    ld [$c864], a
    ld a, [$c863]
    bit 1, a
    jr nz, jr_000_1d69

    ld hl, $6000

jr_000_1d64:
    dec hl
    ld a, h
    or l
    jr nz, jr_000_1d64

jr_000_1d69:
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

jr_000_1d94:
    xor a
    ld [$c866], a
    ld hl, $c842
    ld b, $0e

jr_000_1d9d:
    ld [hl+], a
    dec b
    jr nz, jr_000_1d9d

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

jr_000_1db6:
    ld a, [$c864]
    bit 6, a
    jr z, jr_000_1db6

    ret


; Mul8x8To16: HL = A * C
Mul8x8To16:
    ld b, $00
    ld h, b
    ld l, b
    call CoordSubtract16

CoordSubtract16:
    rrca
    jr nc, jr_000_1dc9

    add hl, bc
jr_000_1dc9:
    sla c
    rl b
    rrca
    jr nc, jr_000_1dd1

    add hl, bc

jr_000_1dd1:
    sla c
    rl b
    rrca
    jr nc, jr_000_1dd9

    add hl, bc

jr_000_1dd9:
    sla c
    rl b
    rrca
    jr nc, jr_000_1de1

    add hl, bc

jr_000_1de1:
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

jr_000_1dff:
    sla b
    rla
    jr c, jr_000_1e07

    cp e
    jr c, jr_000_1e09

jr_000_1e07:
    sub e
    inc b

jr_000_1e09:
    dec d
    jr nz, jr_000_1dff

    ret


; Div16x8To16: HL = HL // A; A = HL % A
Div16x8To16:
    ld d, $10
    ld e, a
    xor a

jr_000_1e11:
    add hl, hl
    rla
    jr c, jr_000_1e18

    cp e
    jr c, jr_000_1e1a

jr_000_1e18:
    sub e
    inc l

jr_000_1e1a:
    dec d
    jr nz, jr_000_1e11

    ret


; Div24x8To16: HL = E:HL // A; A = E:HL % A
Div24x8To16:
    ld d, $18
    ld b, a
    xor a

jr_000_1e22:
    add hl, hl
    rl e
    rla
    jr c, jr_000_1e2b

    cp b
    jr c, jr_000_1e2d

jr_000_1e2b:
    sub b
    inc l

jr_000_1e2d:
    dec d
    jr nz, jr_000_1e22

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
    jr z, jr_000_1ebf

    ld de, $2a63

jr_000_1ebf:
    ld a, [wMapID]
    ld l, a
    ld h, $00
    add hl, hl
    add hl, hl
    add hl, hl
    add hl, de
    ld a, c
    ld b, $ff
    cp [hl]
    jr c, jr_000_1ed1

    ld b, $0f

jr_000_1ed1:
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
    jp nz, Jump_000_1fd6

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
    jr nz, jr_000_1fe7

    call WriteBlankTile
    call PrintDigit

ConvertNumberToText:
    ld a, $00
    ldh [$db], a
    ld e, $10
    ld d, $27
    call ReadHRAM_d5_2012
    or a
    jr nz, jr_000_1ff8

    call WriteBlankTile
    call PrintDigit
    ldh a, [$d5]
    ld c, a
    ldh a, [$d6]
    ld b, a
    jp Jump_000_2060


Jump_000_1fd6:
    ld a, $0f
    ldh [$db], a
    ld e, $40
    ld d, $42
    call GetHRAMPointerB
    call WriteDigitTile
    call PrintDigit

jr_000_1fe7:
    ld a, $01
    ldh [$db], a
    ld e, $a0
    ld d, $86
    call GetHRAMPointerB
    call WriteDigitTile
    call PrintDigit

InitNumberFormat:
jr_000_1ff8:
    ld a, $00
    ldh [$db], a
    ld e, $10
    ld d, $27
    call GetHRAMPointerB

Jump_000_2003:
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
    jp Jump_000_2095


ReadHRAM_d5_2012:
    ldh a, [$d5]
    ld [wDebug_main_menu_option], a
    ldh a, [$d6]
    ld [$c0a1], a
    ldh a, [$d7]
    ld [$c0a2], a
    call GetHRAMPointerB

Jump_000_2024:
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

Jump_000_203a:
    ld h, $ff

AdvancePrintRow:
jr_000_203c:
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
    jr nc, jr_000_203c

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


Jump_000_2060:
    ld de, $03e8
    push bc
    call ExtractDigit16
    pop bc
    or a
    jr nz, jr_000_2095

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
    jr jr_000_20b9

Jump_000_2095:
jr_000_2095:
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

jr_000_20b9:
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

Jump_000_20c3:
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

Jump_000_20d2:
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

Jump_000_2100:
    ld a, $0a
    ld [$0100], a
    pop af
    ld [hl], a

Jump_000_2107:
    ld a, $00
    ld [$0100], a
    ei
    ret


SRAMWriteBlock:
    ld a, $0a
    ld [$0100], a
    ld de, $4638

jr_000_2116:
    ld a, [hl+]
    add e
    ld e, a
    ld a, $00
    adc d
    ld d, a
    dec bc
    ld a, b
    or c
    jr nz, jr_000_2116

    ld a, $00
    ld [$0100], a
    ret


SaveGameState:
    ld hl, $ff8a
    ld de, $a003
    ld bc, $0021
    call CopySRAMBlock
    ld hl, $c8ea

Jump_000_2137:
    ld de, $a024
    ld bc, $1100
    call CopySRAMBlock
    ld hl, $c300
    ld de, $bcc8
    ld bc, $0200
    call CopySRAMBlock
    ld hl, $c200

Jump_000_214f:
    ld de, $bec8
    ld bc, $0100
    call CopySRAMBlock

Jump_000_2158:
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

jr_000_2189:
    ld a, [hl+]
    ld [de], a
    inc de
    dec bc
    ld a, b
    or c
    jr nz, jr_000_2189

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
    jp Jump_000_2158

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

Jump_000_21df:
    ld de, $bcc8
    ld bc, $0200
    call CopyFromSRAM
    ld hl, $c200
    ld de, $bec8
    ld bc, $0100
    call CopyFromSRAM
    ret


CopyFromSRAM:
    ld a, $0a
    ld [$0100], a

jr_000_21fa:
    ld a, [de]
    ld [hl+], a
    inc de
    dec bc

Jump_000_21fe:
    ld a, b
    or c

BranchIfNonZero:
Jump_000_2200:
    jr nz, jr_000_21fa

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
    jr z, jr_000_221a

Jump_000_2210:
    ld a, [wGameMode]
    cp $02

Jump_000_2215:
    jr nz, jr_000_221a

    ld a, b
    pop bc
    ret


jr_000_221a:
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

Jump_000_2242:
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

Jump_000_235b:
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

Jump_000_23ca:
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

Jump_000_246b:
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
    jr c, jr_000_248f

    ld a, l
    sub c
    ld a, h
    sbc b
    jr nc, jr_000_2491

jr_000_248f:
    ld c, l
    ld b, h

jr_000_2491:
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
    jr c, jr_000_24aa

    ld a, l
    sub c
    ld a, h
    sbc b
    jr c, jr_000_24aa

    ld c, l
    ld b, h

jr_000_24aa:
    pop hl
    ld a, c
    ld [hl+], a
    ld [hl], b
    ret


StatAddClamped:
    ld a, [hl]
    add e
    jr c, jr_000_24b6

    cp c
    jr c, jr_000_24b7

jr_000_24b6:
    ld a, c

jr_000_24b7:
    ld [hl], a
    ret


StatSubClamped:
    ld a, [hl]
    sub e
    jr c, jr_000_24c0

    cp c
    jr nc, jr_000_24c1

jr_000_24c0:
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
    jr c, jr_000_24dd

    ld de, $869f

Jump_000_24db:
    ld c, $01

jr_000_24dd:
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

Jump_000_24f2:
    sbc $42
    ld a, c
    sbc $0f
    jr c, jr_000_24dd

    ld de, $423f

StatDivide:
    ld c, $0f
    jr jr_000_24dd

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
    jr nc, jr_000_2511

    ld de, $0000
    ld c, $00

jr_000_2511:
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
    jr nz, jr_000_252a

    ld hl, $c1c0
    ld bc, $0040
    ld a, $dc
    call FillNBytesWithRegA
    ret


jr_000_252a:
    ld hl, $c1c0

SetCountBC64:
    ld bc, $0040

Jump_000_2530:
    ld a, $e0
    call FillNBytesWithRegA

CheckPartyData:
Jump_000_2535:
    ld a, [$ca8d]
    or a
    ret z

    ld hl, $c1c0

Jump_000_253d:
    ld a, $00

Jump_000_253f:
    call SetupStatDisplay

Jump_000_2542:
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
    jr nz, jr_000_25a0

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

Jump_000_2592:
    push hl
    ld hl, $cb15
    ldh a, [$d5]
    call ReadMonsterWord
    pop hl
    call FillMemory
    ret


jr_000_25a0:
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

Jump_000_25c8:
    push hl
    ld hl, $cb0b
    ldh a, [$d5]
    call ReadMonsterByte
    ld b, a
    pop hl
    bit 0, b
    ld a, $e0
    jr z, jr_000_25db

    ld a, $d7

Jump_000_25db:
jr_000_25db:
    ld [hl+], a
    inc hl
    bit 2, b
    ld a, $e0
    jr z, jr_000_25e5

    ld a, $d8

jr_000_25e5:
    ld [hl+], a
    inc hl
    bit 7, b
    ld a, $e0
    jr z, jr_000_25ef

    ld a, $d9

jr_000_25ef:
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

Jump_000_25ff:
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

Jump_000_260e:
    ld a, l

Jump_000_260f:
    add $00
    ld l, a
    ld a, h
    adc $02
    ld h, a
    res 2, h
    ld de, $c1c0
    ld c, $02

jr_000_261d:
    ld b, $14
    push hl

jr_000_2620:
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
    jr nz, jr_000_2620

    pop hl

AdvanceStatOffset12:
    ld a, e
    add $0c
    ld e, a

Jump_000_263e:
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
    jr nz, jr_000_261d

    ret


CheckGateWorldMapType:
    ld a, [wInGateworld]
    or a
    jr nz, jr_000_266c

    ld a, [wMapID]
    cp MAP_BTLDEMO
    jr z, jr_000_266a

    cp MAP_CSLBG
    jr z, jr_000_266a

    ld a, [wMapID]
    cp MAP_OLDWELL
    jr nc, jr_000_266c

jr_000_266a:
    xor a
    ret


jr_000_266c:
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
    ld bc, $0100
    ld d, a
    nop
    ld [$402a], sp

jr_000_26e8:
    ld bc, $0200
    ld d, b
    nop
    inc d
    ld a, [hl+]
    ldh [rSB], a
    nop
    ld bc, $0049
    ld hl, $402a

jr_000_26f8:
    ld bc, $0100
    jr nc, jr_000_26fd

jr_000_26fd:
    ld bc, $e029

jr_000_2700:
    ld bc, $0100
    ld a, [hl-]
    nop
    add hl, bc

Jump_000_2706:
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

Jump_000_2712:
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

Jump_000_271f:
    and b
    nop
    add b
    nop
    and d
    nop
    rra
    add hl, hl
    ld b, b
    ld bc, $0100
    jr jr_000_272d

jr_000_272d:
    inc hl
    add hl, hl
    ld b, b

SetCountBC128:
Jump_000_2730:
jr_000_2730:
    ld bc, $0080
    jr jr_000_2735

TilemapPadding:
jr_000_2735:
    nop

Jump_000_2736:
    ld a, [hl+]
    ld b, b
    ld bc, $0100
    ld d, a
    nop
    ld h, $29
    and b

jr_000_2740:
    nop
    add b
    nop
    jr nc, jr_000_2745

jr_000_2745:
    nop
    jr nc, jr_000_26e8

jr_000_2748:
    nop
    add b
    nop
    ld b, b
    nop
    nop
    ld a, [hl+]
    ld b, b

Jump_000_2750:
jr_000_2750:
    ld bc, $0100
    ld d, a
    nop
    ld [bc], a
    jr nc, jr_000_26f8

jr_000_2758:
    nop
    add b
    nop
    ld d, b
    nop
    inc b
    jr nc, jr_000_2700

jr_000_2760:
    nop
    add b
    nop
    jr c, jr_000_2765

jr_000_2765:
    nop
    ld a, [hl+]
    ld b, b

jr_000_2768:
    ld bc, $0100
    ld d, a
    nop
    rlca
    jr nc, @-$5e

jr_000_2770:
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
    ld bc, $0100
    ld d, a
    nop
    nop
    ld a, [hl+]
    ld b, b
    ld bc, $0100
    ld d, a
    nop
    inc c
    jr nc, jr_000_2730

Jump_000_2790:
    nop
    add b
    nop
    ld b, b
    nop
    nop
    ld a, [hl+]
    ld b, b
    ld bc, $0100
    ld d, a
    nop
    rrca
    jr nc, jr_000_2740

    nop
    nop
    ld bc, $004e
    inc de
    jr nc, jr_000_2748

    nop
    add b
    nop
    ld b, b
    nop
    dec d
    jr nc, jr_000_2750

    nop
    add b
    nop
    ld b, b
    nop
    rla
    jr nc, jr_000_2758

    nop
    add b
    nop
    ld d, b
    nop
    add hl, de
    jr nc, jr_000_2760

    nop
    add b

Jump_000_27c2:
    nop
    ld d, b
    nop
    dec de
    jr nc, jr_000_2768

    nop
    add b
    nop
    jr nc, jr_000_27cd

jr_000_27cd:
    dec e
    jr nc, jr_000_2770

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
    jr nc, jr_000_27dd

jr_000_27dd:
    nop
    ld a, [hl+]
    ld b, b
    ld bc, $0100
    ld d, a
    nop
    nop
    ld a, [hl+]
    ld b, b
    ld bc, $0100
    ld d, a
    nop
    nop
    ld a, [hl+]
    ld b, b
    ld bc, $0100
    ld d, a
    nop
    ld [bc], a
    dec l
    and b
    nop
    add b
    nop
    jr nz, jr_000_27fd

jr_000_27fd:
    inc b

DataTable_27FE:
    dec l
    and b

DataTable_2800:
    nop
    add b
    nop
    jr jr_000_2805

jr_000_2805:
    ld b, $2d
    and b

DataTable_2808:
    nop
    add b
    nop
    jr nz, jr_000_280d

jr_000_280d:
    ld [$a02d], sp

Jump_000_2810:
    nop
    add b

Jump_000_2812:
    nop
    jr nc, jr_000_2815

ReadByteFromBC:
Jump_000_2815:
jr_000_2815:
    ld a, [bc]
    dec l
    and b
    nop
    add b

Jump_000_281a:
    nop
    stop
    inc c
    dec l
    and b
    nop
    add b
    nop
    jr nc, jr_000_2825

jr_000_2825:
    ld c, $2d
    and b
    nop
    add b
    nop
    jr nz, jr_000_282d

jr_000_282d:
    db $10
    dec l

DataTable_282F:
    and b

Jump_000_2830:
    nop
    add b
    nop
    jr nz, jr_000_2835

jr_000_2835:
    ld [de], a
    dec l
    and b
    nop
    add b
    nop
    jr nz, jr_000_283d

jr_000_283d:
    inc d
    dec l
    and b
    nop
    add b
    nop
    jr nz, jr_000_2845

jr_000_2845:
    ld d, $2d
    and b
    nop
    add b
    nop
    jr nc, jr_000_284d

jr_000_284d:
    jr jr_000_287c

    and b
    nop
    add b
    nop

DataTable_2853:
Jump_000_2853:
    jr z, jr_000_2855

jr_000_2855:
    ld a, [de]
    dec l
    ld b, b
    ld bc, $0100
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
    jr nz, jr_000_2875

jr_000_2875:
    ld [de], a

DataTable_2876:
    ld h, $a0
    nop
    add b
    nop
    ld b, b

jr_000_287c:
    nop
    dec d
    ld h, $a0
    nop
    add b
    nop
    ld d, b
    nop
    jr jr_000_28ad

    and b
    nop
    add b
    nop
    jr nz, jr_000_288d

jr_000_288d:
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
    jr nz, jr_000_28ad

jr_000_28ad:
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

Jump_000_28c7:
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

Jump_000_28e4:
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
    jr jr_000_2923

DataTable_28FF:
    and b

Jump_000_2900:
    nop
    add b
    nop
    jr nz, jr_000_2905

jr_000_2905:
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

Jump_000_2915:
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
Jump_000_2920:
    nop
    add b
    nop

jr_000_2923:
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

Jump_000_292f:
    and b

Jump_000_2930:
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

Jump_000_2940:
    nop
    add b
    nop
    ld l, b
    nop

Jump_000_2945:
    ld c, $25
    and b
    nop
    add b
    nop
    ld b, b
    nop
    ld de, $a025

Jump_000_2950:
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

Jump_000_295e:
    ld h, $a0
    nop
    add b
    nop
    jr nz, jr_000_2965

jr_000_2965:
    ld [bc], a
    ld h, $a0
    nop
    add b
    nop
    jr nz, jr_000_296d

jr_000_296d:
    inc b
    ld h, $a0
    nop
    add b
    nop
    dec hl
    nop
    jr jr_000_299a

    and b
    nop
    add b
    nop
    jr nc, jr_000_297d

jr_000_297d:
    nop
    scf

Jump_000_297f:
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

jr_000_299a:
    ld bc, $0030
    jr z, jr_000_29d6

    ldh [rSB], a
    add b
    ld bc, $0030
    ld [hl-], a
    scf
    ldh [rSB], a
    add b
    ld bc, $0030

Jump_000_29ad:
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

jr_000_29d6:
    ld h, $a0
    nop
    add b
    nop
    jr nz, jr_000_29dd

jr_000_29dd:
    ld [de], a

DataTable_29DE:
    inc h
    and b

jr_000_29e0:
    nop
    add b
    nop
    ld d, b
    nop
    jr jr_000_2a0a

    and b
    nop
    add b
    nop
    jr nc, jr_000_29ed

jr_000_29ed:
    jr jr_000_2a12

    and b

jr_000_29f0:
    nop
    add b
    nop
    jr nc, jr_000_29f5

jr_000_29f5:
    jr jr_000_2a1a

    and b

jr_000_29f8:
    nop
    add b
    nop
    jr nc, jr_000_29fd

jr_000_29fd:
    jr jr_000_2a22

    and b

jr_000_2a00:
    nop

Jump_000_2a01:
    add b
    nop
    jr nc, jr_000_2a05

jr_000_2a05:
    ld [de], a
    inc h
    and b

DataTable_2A08:
jr_000_2a08:
    nop
    add b

jr_000_2a0a:
    nop
    ld d, b
    nop
    ld [de], a
    inc h

DataTable_2A0F:
    and b
    nop
    add b

Jump_000_2a12:
jr_000_2a12:
    nop
    ld d, b
    nop

Jump_000_2a15:
    ld [de], a
    inc h
    and b

jr_000_2a18:
    nop
    add b

jr_000_2a1a:
    nop
    ld d, b
    nop
    ld [de], a
    inc h
    and b
    nop
    add b

jr_000_2a22:
    nop
    ld d, b
    nop
    ld [de], a
    inc h
    and b

jr_000_2a28:
    nop
    add b
    nop
    ld d, b
    nop
    ld [de], a
    inc h
    and b

jr_000_2a30:
    nop
    add b
    nop
    ld d, b
    nop
    ld [de], a
    inc h
    and b

jr_000_2a38:
    nop
    add b
    nop
    ld d, b
    nop

DataTable_2A3D:
    ld [de], a
    inc h
    and b

Jump_000_2a40:
jr_000_2a40:
    nop
    add b
    nop
    ld d, b
    nop
    ld [de], a
    inc h
    and b

jr_000_2a48:
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

jr_000_2a58:
    nop

Jump_000_2a59:
    add b
    nop
    ld d, b
    nop
    nop
    jr z, jr_000_29e0

    ld [bc], a
    nop
    ld [bc], a
    jr nc, jr_000_2a65

jr_000_2a65:
    ld bc, $8028
    ld [bc], a
    nop
    ld [bc], a
    jr nc, jr_000_2a6d

jr_000_2a6d:
    ld [bc], a
    jr z, jr_000_29f0

    ld [bc], a
    nop
    ld [bc], a
    jr nc, jr_000_2a75

jr_000_2a75:
    inc bc
    jr z, jr_000_29f8

    ld [bc], a
    nop
    ld [bc], a
    jr nc, jr_000_2a7d

jr_000_2a7d:
    inc b
    jr z, jr_000_2a00

    ld [bc], a
    nop
    ld [bc], a
    jr nc, jr_000_2a85

jr_000_2a85:
    dec b
    jr z, jr_000_2a08

    ld [bc], a
    nop
    ld [bc], a
    jr nc, jr_000_2a8d

jr_000_2a8d:
    ld b, $28
    add b

DataTable_2A90:
    ld [bc], a
    nop
    ld [bc], a
    jr nc, jr_000_2a95

jr_000_2a95:
    rlca
    jr z, jr_000_2a18

    ld [bc], a
    nop
    ld [bc], a
    jr nc, jr_000_2a9d

jr_000_2a9d:
    ld [$8028], sp
    ld [bc], a
    nop
    ld [bc], a
    jr nc, jr_000_2aa5

jr_000_2aa5:
    add hl, bc
    jr z, jr_000_2a28

    ld [bc], a
    nop
    ld [bc], a

DataTable_2AAB:
    jr nc, jr_000_2aad

jr_000_2aad:
    ld a, [bc]
    jr z, jr_000_2a30

    ld [bc], a
    nop
    ld [bc], a
    jr nc, jr_000_2ab5

jr_000_2ab5:
    dec bc
    jr z, jr_000_2a38

    ld [bc], a
    nop
    ld [bc], a
    jr nc, jr_000_2abd

jr_000_2abd:
    inc c
    jr z, jr_000_2a40

    ld [bc], a
    nop
    ld [bc], a
    jr nc, jr_000_2ac5

jr_000_2ac5:
    dec c
    jr z, jr_000_2a48

    ld [bc], a
    nop
    ld [bc], a
    jr nc, jr_000_2acd

jr_000_2acd:
    ld c, $28
    add b
    ld [bc], a
    nop
    ld [bc], a
    jr nc, jr_000_2ad5

jr_000_2ad5:
    rrca
    jr z, jr_000_2a58

    ld [bc], a
    nop
    ld [bc], a
    jr nc, jr_000_2add

jr_000_2add:
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

Jump_000_2b01:
    ld de, $1231
    ld sp, $3113
    inc d

DataTable_2B08:
Jump_000_2b08:
    ld sp, $3115
    ld d, $31
    rla
    ld sp, $3118
    add hl, de
    ld sp, $311a

Jump_000_2b15:
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

    jr c, jr_000_2b91

    jr c, @+$0a

    add hl, sp

Jump_000_2b5d:
    ld e, $39

Jump_000_2b5f:
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
    jr c, jr_000_2b78

jr_000_2b78:
    jr c, jr_000_2bbc

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

jr_000_2b91:
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

jr_000_2bbc:
    cpl
    jr nz, jr_000_2bee

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
    jr z, jr_000_2bfe

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
    jr nc, jr_000_2c0e

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

jr_000_2bee:
    ld [hl], $01

Jump_000_2bf0:
    ld [hl], $02
    ld [hl], $03
    ld [hl], $04
    ld [hl], $05
    ld [hl], $06
    ld [hl], $07

TilemapClearLine:
    ld [hl], $08

jr_000_2bfe:
    ld [hl], $09
    ld [hl], $0a
    ld [hl], $0b

WriteTileSequence:
    ld [hl], $0c
    ld [hl], $0d
    ld [hl], $0e
    ld [hl], $0f
    ld [hl], $10

jr_000_2c0e:
    ld [hl], $11
    ld [hl], $12

Jump_000_2c12:
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

Jump_000_2c67:
    dec d
    dec [hl]
    ld d, $35
    rla
    dec [hl]
    jr jr_000_2ca4

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
    jr nz, jr_000_2cb4

    ld hl, $2235
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

jr_000_2ca4:
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

jr_000_2cb4:
    inc [hl]
    inc d
    inc [hl]
    dec d
    inc [hl]
    ld d, $34
    rla
    inc [hl]
    jr jr_000_2cf3

    add hl, de
    inc [hl]
    ld a, [de]
    inc [hl]

Jump_000_2cc3:
    dec de
    inc [hl]
    inc e
    inc [hl]
    dec e
    inc [hl]
    ld e, $34
    rra
    inc [hl]
    jr nz, jr_000_2d03

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

Jump_000_2ce8:
    inc sp
    ld b, $33
    rlca

Jump_000_2cec:
    inc sp
    ld [$0933], sp
    inc sp
    ld a, [bc]
    inc sp

jr_000_2cf3:
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

jr_000_2d03:
    inc de
    inc sp
    inc d
    inc sp
    dec d
    inc sp
    ld d, $33
    rla
    inc sp
    jr jr_000_2d42

Jump_000_2d0f:
    add hl, de
    inc sp

Jump_000_2d11:
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
    jr nz, jr_000_2d52

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

Jump_000_2d35:
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

jr_000_2d42:
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

jr_000_2d52:
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

jr_000_2da8:
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
    jr jr_000_2e0c

    jr jr_000_2e18

MenuBorderBottom:
    jr jr_000_2e24

MenuBorderCorner:
Jump_000_2e06:
    jr jr_000_2da8

    ld bc, $effa
    rst $28

jr_000_2e0c:
    rst $28
    rst $28
    rst $28
    rst $28

Jump_000_2e10:
    rst $28

MenuBorderFill:
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28
    rst $28

jr_000_2e18:
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

jr_000_2e24:
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

Jump_000_2ec2:
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

Jump_000_2edc:
    reti


Jump_000_2edd:
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


Jump_000_2eea:
    push af
    push bc
    push de
    push hl
    ld a, [$c892]
    rst $00
    ld b, b

Jump_000_2ef3:
    cpl

MenuClearContents:
    ld a, [$082e]
    cpl
    inc h
    cpl

jr_000_2efa:
    ldh a, [rSTAT]
    and $03
    jr nz, jr_000_2efa

    ldh a, [rLCDC]
    res 1, a
    ldh [rLCDC], a
    jr jr_000_2f40

    ldh a, [rLY]
    ld l, a
    ld h, $c1
    ld a, [hl]
    ldh [rSCX], a
    ldh a, [rLYC]
    add $02
    ldh [rLYC], a
    cp $80
    jr c, jr_000_2f40

    ldh a, [$b7]
    ldh [rSCX], a
    ld a, $01
    ldh [rLYC], a
    jr jr_000_2f40

    ldh a, [rLY]
    ld l, a
    ld h, $c1
    ld a, [hl]
    ldh [rSCY], a

Jump_000_2f2c:
    ldh a, [rLYC]
    add $02
    ldh [rLYC], a
    cp $81

Jump_000_2f34:
    jr c, jr_000_2f40

    ldh a, [$bb]
    ldh [rSCY], a
    ld a, $00
    ldh [rLYC], a
    jr jr_000_2f40

jr_000_2f40:
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
    jr z, jr_000_2f5d

jr_000_2f52:
    ld a, l
    sub c
    ld l, a
    ld a, h
    sbc b

Jump_000_2f57:
    ld h, a
    jr c, jr_000_2f66

    inc de
    jr jr_000_2f52

jr_000_2f5d:
    ld a, c
    call Div16x8To16
    ld c, a
    ld b, $00
    jr jr_000_2f6b

jr_000_2f66:
    add hl, bc
    ld b, h

MenuCalcPosition:
    ld c, l
    ld h, d
    ld l, e

jr_000_2f6b:
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
    jr c, jr_000_2fa1

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
    jr nz, jr_000_2fa0

    inc hl
    inc hl
    ld a, [hl+]
    and $3f
    jr nz, jr_000_2fa0

MenuCalcWidth:
    inc hl

Jump_000_2f98:
    ld a, [hl]

MenuCalcHeight:
    and $c0
    jr nz, jr_000_2fa0

    xor a
    jr jr_000_2fa1

jr_000_2fa0:
    scf

jr_000_2fa1:
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
    jr nc, jr_000_2fc0

    ld hl, $dd1b
    add l
    ld l, a
    ld a, $00
    adc h
    ld h, a
    ld a, [hl]
    and a
    jr z, jr_000_2fc4

    cp $ff
    jr z, jr_000_2fc0

    scf
    jr jr_000_2fc8

jr_000_2fc0:
    xor a
    scf
    jr jr_000_2fc8

jr_000_2fc4:
    ld a, $0a
    cp $01

jr_000_2fc8:
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
Jump_000_3001:
    ld a, [$da80]

RetIfZeroA:
Jump_000_3004:
    or a
    ret z

InitBattleState:
    ld a, [$c863]
    and $02
    sla a
    ld b, a
    ld a, [wBattleAttackerIdx]
    xor b

Jump_000_3012:
    cp $04
    jr nc, jr_000_3029

    ld a, [wBattleTargetIdx]
    xor b
    cp $04
    jr nc, jr_000_3029

    ld a, $00

Jump_000_3020:
    ld [$dd60], a
    ld a, $00

StoreBattleDD62:
    ld [$dd62], a

RetNop_3028:
    ret


jr_000_3029:
    ld hl, $5f07
    rst $10
    ld a, [$da81]

Jump_000_3030:
    cp $ff
    ret z

    cp $0e
    jr c, jr_000_3048

    cp $15
    jr z, jr_000_3052

    cp $21
    jr c, jr_000_304d

CheckSaveSlot:
Jump_000_303f:
    cp $2c
    jr z, jr_000_3059

    ld hl, $5e00
    rst $10
    ret


CallBank5CEntry0_3048:
jr_000_3048:
    ld hl, $5c00
    rst $10
    ret


jr_000_304d:
    ld hl, $5d00
    rst $10
    ret


jr_000_3052:
    ld a, [$db8a]
    cp $c5
    jr nz, jr_000_304d

jr_000_3059:
    ld a, [$db75]
    cp $01
    jr z, jr_000_30b4

Jump_000_3060:
    cp $02
    jr z, jr_000_30ce

    ld a, [$dd1f]
    or a
    jr nz, jr_000_307f

    ld a, $20
    ldh [$c3], a
    ld a, [$da81]
    cp $15
    jr nz, jr_000_307b

    ld hl, $5d00

CallBank5EEntry0_3078:
    rst $10
    jr jr_000_307f

jr_000_307b:
    ld hl, $5e00
    rst $10

CheckFieldStateDD20:
jr_000_307f:
    ld a, [$dd20]
    or a
    jr nz, jr_000_309a

    ld a, $50
    ldh [$c3], a
    ld a, [$da81]
    cp $15
    jr nz, jr_000_3096

    ld hl, $5d00
    rst $10
    jr jr_000_309a

jr_000_3096:
    ld hl, $5e00
    rst $10

jr_000_309a:
    ld a, [$dd21]
    or a
    ret nz

    ld a, $80
    ldh [$c3], a
    ld a, [$da81]
    cp $15
    jr nz, jr_000_30af

    ld hl, $5d00
    rst $10
    ret


jr_000_30af:
    ld hl, $5e00
    rst $10
    ret


jr_000_30b4:
    ld a, [$dd1f]
    or a
    ret nz

    ld a, $50
    ldh [$c3], a
    ld a, [$da81]
    cp $15
    jr nz, jr_000_30c9

    ld hl, $5d00
    rst $10
    ret


jr_000_30c9:
    ld hl, $5e00
    rst $10
    ret


jr_000_30ce:
    ld a, [$dd1f]
    or a
    jr nz, jr_000_30e9

    ld a, $38
    ldh [$c3], a
    ld a, [$da81]
    cp $15
    jr nz, jr_000_30e5

Jump_000_30df:
    ld hl, $5d00
    rst $10
    jr jr_000_30e9

jr_000_30e5:
    ld hl, $5e00
    rst $10

jr_000_30e9:
    ld a, [$dd20]
    or a
    ret nz

    ld a, $68

AudioGetTimerHRAM:
    ldh [$c3], a
    ld a, [$da81]
    cp $15
    jr nz, jr_000_30fe

    ld hl, $5d00
    rst $10
    ret


jr_000_30fe:
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

Jump_000_3110:
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
    jr c, jr_000_3137

    cp $21

CallBank5EEntry1_3130:
    jr c, jr_000_313c

    ld hl, $5e01

CrossBankCallAndRet2:
    rst $10
    ret


jr_000_3137:
    ld hl, $5c01
    rst $10
    ret


jr_000_313c:
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

Jump_000_3157:
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
    jp z, Jump_000_3285

    ld de, $0100
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

Jump_000_31c3:
    ld de, $0000
    nop
    nop
    ld de, $ac35
    xor $ff
    rst $38

Jump_000_31ce:
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

Jump_000_320c:
    rst $38
    rst $38

Jump_000_320e:
    nop

Jump_000_320f:
    nop

Jump_000_3210:
    nop
    nop
    xor d
    xor d
    cp e

Jump_000_3215:
    call z, $dddd

Jump_000_3218:
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

Jump_000_3225:
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

Jump_000_3237:
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
    jr nc, jr_000_328d

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

Jump_000_3285:
    ld d, b
    jr nc, jr_000_3298

    ld d, c
    ld b, b
    jr nc, jr_000_32ac

    dec d

jr_000_328d:
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

jr_000_3298:
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

jr_000_32ac:
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

Jump_000_32c3:
    or b
    sub b
    add c
    ld [hl], b
    ld h, b
    ld d, b
    ld b, b
    jr nc, jr_000_32ec

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
    jr nc, jr_000_32fe

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

jr_000_32ec:
    dec b
    dec b
    dec b
    dec b
    pop af
    or b
    ld [hl], b
    ld d, b
    jr nc, jr_000_3316

    jr nz, jr_000_330d

    dec d
    dec d
    dec d
    dec d

AudioWaveData_32FC:
    dec d

AudioWaveData_32FD:
    dec d

jr_000_32fe:
    dec d

Jump_000_32ff:
    dec b

AudioWaveData_3300:
    pop af
    or b
    ld [hl], b

AudioWaveData_3303:
    ld d, b
    jr nc, jr_000_3316

    ld d, c

AudioWaveData_3307:
    ld b, b
    jr nc, jr_000_332a

    dec d
    dec d
    dec d

jr_000_330d:
    dec d
    dec d
    dec b

Jump_000_3310:
    di

Jump_000_3311:
    ret nc

    or b
    sub b
    ld [hl], b
    ld d, b

jr_000_3316:
    jr nc, jr_000_3328

AudioWaveData_3318:
    ld d, c
    ld b, b
    jr nc, jr_000_333c

    dec d
    dec d
    dec d
    dec b

Jump_000_3320:
    add hl, bc
    jr @+$2a

    jr c, jr_000_336d

    ld e, b
    ld l, b
    ld a, b

jr_000_3328:
    adc b
    sbc b

jr_000_332a:
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

jr_000_333c:
    ldh [rNR51], a
    ld [$de1d], a
    ld a, $77

Jump_000_3343:
    ldh [rNR50], a
    ld hl, $dd80
    ld b, $06
    ld a, $ff

jr_000_334c:
    ld [hl], a
    ld de, $0019
    add hl, de
    ld [hl], a
    ld de, $0001
    add hl, de
    dec b
    jr nz, jr_000_334c

    xor a
    ld [$de29], a
    ret


Jump_000_335e:
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

jr_000_3381:
    dec b
    jr z, jr_000_3387

    add a
    jr jr_000_3381

jr_000_3387:
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
    jr nz, jr_000_33c4

    ld hl, $dd84
    ld a, [$de27]
    and $0f
    ld b, a
    ld a, [$de26]

jr_000_33a6:
    srl a
    ld [$de28], a
    jr nc, jr_000_33b2

    ld a, [hl]
    and $f0
    or b
    ld [hl], a

jr_000_33b2:
    ld a, l
    add $1a
    ld l, a
    ld a, h
    adc $00
    ld h, a
    ld a, [$de28]
    and a
    jr nz, jr_000_33a6

    xor a
    ld [$de26], a

jr_000_33c4:
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

jr_000_33db:
    cp [hl]
    jr c, jr_000_33e4

    inc hl

AudioLoadWaveRAM:
    inc hl
    inc hl
    inc hl
    jr jr_000_33db

jr_000_33e4:
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

Jump_000_33f7:
    ld a, [hl-]
    ld e, a
    ld a, [$de24]
    sub [hl]
    ld l, a
    ld h, $00

MultiplyHL_3400:
Jump_000_3400:
    add hl, hl
    add hl, hl

AudioAddHLDE:
Jump_000_3402:
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

Jump_000_340a:
    ld hl, $dd80
    add hl, bc
    ld a, [hl]
    cp $ff
    jr z, jr_000_3430

    inc hl
    ld a, [hl-]

Jump_000_3415:
    ld b, $ee
    and $03
    jr z, jr_000_3429

    ld b, $dd
    cp $01
    jr z, jr_000_3429

    ld b, $bb
    cp $02

Jump_000_3425:
    jr z, jr_000_3429

    ld b, $77

jr_000_3429:
    ld a, [$de1d]
    and b
    ld [$de1d], a

Jump_000_3430:
jr_000_3430:
    xor a
    ld [hl+], a

Jump_000_3432:
    ld a, [de]
    inc de

Jump_000_3434:
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

Jump_000_3440:
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

Jump_000_344f:
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

Jump_000_3488:
    push hl
    ld de, $ffe4
    ld b, $03

jr_000_348e:
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
    jr nz, jr_000_348e

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

jr_000_34bf:
    rlca
    dec b
    jr nz, jr_000_34bf

    ld [$de1f], a
    ld [$de20], a
    ldh a, [$e4]
    ld b, a
    ldh a, [$fd]
    and b
    cp $ff
    jp z, Jump_000_3559

    ldh a, [$e8]
    ld [$2100], a
    swap a
    rra
    and $03
    ld [$4100], a
    ldh a, [$fd]
    or b
    and a
    jp z, Jump_000_357f

    call AudioProcessChannel
    call AudioNoteOn
    ldh a, [$f1]
    ld b, a

AudioGetFrequency:
    ldh a, [$f2]

Jump_000_34f3:
    inc a
    cp b
    jr c, jr_000_34f8

    ld a, b

jr_000_34f8:
    ldh [$f2], a
    ld hl, $ffea
    ldh a, [$e9]

Jump_000_34ff:
    and $0f
    add [hl]
    cp $10

AudioCheckCarry:
    jr c, jr_000_350b

    sub $10
    ld [hl], a
    jr jr_000_3527

jr_000_350b:
    ld [hl], a
    call AudioSetVolume
    ldh a, [$fb]
    and a
    jr z, jr_000_3517

    dec a

AudioSetRegFB:
Jump_000_3515:
    ldh [$fb], a

jr_000_3517:
    ld hl, $ffec
    dec [hl]
    jr nz, jr_000_3527

    call AudioSetupChannel

Jump_000_3520:
    ldh a, [$fa]
    ldh [$fb], a
    call AudioGetEnvelope

jr_000_3527:
    ld a, [$de1f]
    ld b, a
    ld a, [$de1c]
    or b
    ld [$de1c], a

Jump_000_3532:
    pop hl
    push hl
    ld de, $ffe4
    ld b, $03

jr_000_3539:
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

Jump_000_3545:
    ld a, [de]
    ld [hl+], a

Jump_000_3547:
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

Jump_000_3551:
    dec b
    jr nz, jr_000_3539

    ld a, [de]
    ld [hl+], a
    inc e
    ld a, [de]
    ld [hl+], a

Jump_000_3559:
    pop hl
    ld de, $001a
    add hl, de
    ld a, [$de23]
    inc a
    ld [$de23], a
    cp $06
    jp c, Jump_000_3488

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


Jump_000_357f:
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
    jr z, jr_000_35bf

    ld a, [hl+]
    rrca
    rrca
    and $c0
    or d

jr_000_3599:
    ldh [$e9], a
    ld a, [hl+]
    swap a
    ldh [$eb], a
    ld a, [$de1e]
    cp $02
    jr z, jr_000_35c5

    ld a, [hl+]
    ldh [$ed], a

jr_000_35aa:
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
    jp Jump_000_3520


jr_000_35bf:
    ld a, [hl+]
    ldh [$f1], a
    ld a, d
    jr jr_000_3599

jr_000_35c5:
    xor a
    ldh [rNR30], a
    ld d, a
    ldh a, [$ed]
    ld e, a
    cp $ff
    jr nz, jr_000_35d4

Jump_000_35d0:
    ld e, [hl]
    ld a, e
    ldh [$ed], a

jr_000_35d4:
    ld [$de2b], a
    swap e
    ld hl, $316e
    add hl, de

CopyBlock_35DD:
    ld de, $ff30
    ld b, $10

jr_000_35e2:
    ld a, [hl+]
    ld [de], a
    inc de
    dec b
    jr nz, jr_000_35e2

    jr jr_000_35aa

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

Jump_000_35f8:
jr_000_35f8:
    ldh a, [$e4]
    add $01
    ldh [$e4], a
    ldh a, [$fd]

Jump_000_3600:
    adc $00
    ldh [$fd], a
    ld a, [hl+]
    cp $d0
    jr nc, jr_000_3630

    cp $b0
    jr nc, jr_000_366e

AudioProcessNote:
    cp $a0

Jump_000_360f:
    jp nc, Jump_000_36cb

Jump_000_3612:
    jp Jump_000_37ee


jr_000_3615:
    cp $fd
    jr nz, jr_000_3624

    ldh a, [$e4]
    ldh [$f8], a
    ldh a, [$fd]
    ldh [$fe], a

jr_000_3621:
    inc hl
    jr jr_000_35f8

jr_000_3624:
    cp $ff
    jr nz, jr_000_3621

    ldh [$e4], a
    ldh [$fd], a
    call AudioSetSweep
    ret


jr_000_3630:
    cp $f0
    jr nc, jr_000_3615

    cp $e0
    jr nc, jr_000_363c

    and $0f
    jr jr_000_3640

jr_000_363c:
    and $0f

AudioNegate:
    cpl
    inc a

jr_000_3640:
    ld b, a
    ld a, [$de1e]

AudioCheckChannel2:
    cp $02
    jr z, jr_000_3650

    ld a, b
    ldh [$f3], a
    ld a, [hl]
    ldh [$f4], a
    ldh [$f5], a

jr_000_3650:
    inc hl
    jr jr_000_35f8

jr_000_3653:
    and $0f
    ld b, a
    ld a, [$de1e]
    cp $02
    jr z, jr_000_366b

Jump_000_365d:
    ldh a, [$eb]
    and $0f
    jr nz, jr_000_366b

    ld a, [hl]
    ldh [$f1], a
    ld a, b
    swap a
    ldh [$f0], a

jr_000_366b:
    inc hl
    jr jr_000_35f8

jr_000_366e:
    cp $c0
    jr nc, jr_000_3653

    and $0f
    jr z, jr_000_3699

    ld e, a
    ld a, [hl]
    and a
    jr nz, jr_000_368b

    ldh a, [$ee]
    dec a
    ldh [$ee], a
    jr z, jr_000_36b0

    bit 7, a
    jr z, jr_000_3699

    ld a, e
    ldh [$ee], a
    jr jr_000_3699

jr_000_368b:
    ldh a, [$ef]
    dec a
    ldh [$ef], a
    jr z, jr_000_36c2

    bit 7, a
    jr z, jr_000_3699

    ld a, e

ProcessTextCharLoop:
    ldh [$ef], a

jr_000_3699:
    ld a, [hl]
    cp $fc
    jr z, jr_000_36a9

    ldh a, [$f8]
    ldh [$e4], a
    ldh a, [$fe]
    ldh [$fd], a
    jp Jump_000_35ea


jr_000_36a9:
    inc hl
    ld a, [hl+]
    ldh [$e4], a

Jump_000_36ad:
    ld a, [hl]
    ldh [$fd], a

jr_000_36b0:
    jp Jump_000_35ea


    ldh a, [$e4]
    add $01
    ldh [$e4], a
    ldh a, [$fd]
    adc $00
    ldh [$fd], a
    jp Jump_000_35ea


jr_000_36c2:
    ldh a, [$e4]
    add $01
    ldh [$e4], a
    jp Jump_000_35ea


Jump_000_36cb:
    cp $a0
    jr nz, jr_000_36e5

    ld a, [hl+]
    swap a
    ldh [$eb], a
    ld a, [$de1f]
    ld b, a
    ld a, [$de1c]
    and b
    jp nz, Jump_000_35f8

    call AudioCommandHandler
    jp Jump_000_35f8


jr_000_36e5:
    cp $a1
    jr nz, jr_000_3725

    ld a, [$de1e]

Jump_000_36ec:
    cp $02
    jr z, jr_000_36f6

    ld a, [hl+]
    ldh [$ed], a
    jp Jump_000_35f8


jr_000_36f6:
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
    jr z, jr_000_370b

Jump_000_3708:
    jp Jump_000_35f8


jr_000_370b:
    push hl
    ld a, e
    ld [$de2b], a
    swap e
    ld hl, $316e

Jump_000_3715:
    add hl, de
    ld de, $ff30
    ld b, $10

jr_000_371b:
    ld a, [hl+]
    ld [de], a
    inc de
    dec b
    jr nz, jr_000_371b

    pop hl

AudioJumpToFreqCalc:
Jump_000_3722:
    jp Jump_000_35f8


jr_000_3725:
    cp $a2
    jr nz, jr_000_3746

    ld a, [$de1e]
    cp $02

AudioBranchIfZero:
    jr z, jr_000_3740

Jump_000_3730:
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

Jump_000_373d:
    jp Jump_000_35f8


Jump_000_3740:
jr_000_3740:
    ld a, [hl+]
    ldh [$f1], a
    jp Jump_000_35f8


jr_000_3746:
    cp $a3
    jr nz, jr_000_376d

    ld a, [hl+]
    bit 7, a
    jr nz, jr_000_3767

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

jr_000_3762:
    ldh [$e5], a
    jp Jump_000_35f8


jr_000_3767:
    ldh a, [$e5]
    and $0f
    jr jr_000_3762

jr_000_376d:
    cp $a5
    jr nz, jr_000_377f

    ld a, [hl+]
    cp $01
    jr nz, jr_000_377a

    ldh a, [$f9]
    swap a

jr_000_377a:
    ldh [$f9], a
    jp Jump_000_35f8


Jump_000_377f:
jr_000_377f:
    cp $a6
    jr nz, jr_000_3789

    ld a, [hl+]
    ldh [rNR50], a
    jp Jump_000_35f8


jr_000_3789:
    cp $a7
    jr nz, jr_000_3793

    ld a, [hl]
    ldh [$ec], a
    jp Jump_000_38a5


jr_000_3793:
    cp $a8
    jr nz, jr_000_379d

    ld a, [hl+]
    ldh [$fc], a
    jp Jump_000_35f8


jr_000_379d:
    cp $ae
    jr nz, jr_000_37af

    ld a, [hl+]
    and $10
    ld b, a
    ldh a, [$e9]
    and $ef
    or b
    ldh [$e9], a
    jp Jump_000_35f8


jr_000_37af:
    cp $af
    jr nz, jr_000_37c1

    ld a, [hl+]
    and $0f
    ld b, a
    ldh a, [$e9]
    and $f0
    or b
    ldh [$e9], a
    jp Jump_000_35f8


AudioNoteEnd:
Jump_000_37c1:
jr_000_37c1:
    inc hl
    jp Jump_000_35f8


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
jr_000_37d5:
    xor a
    ldh [$f6], a
    ld a, $80
    ldh [$f7], a
    ld a, [$de1e]
    cp $02
    jr z, jr_000_37e7

    call AudioSetDuty
    ret


jr_000_37e7:
    call CheckAudioFlag
    xor a
    ldh [rNR30], a
    ret


Jump_000_37ee:
    ld b, a
    ld a, [hl]
    ldh [$ec], a
    ld a, [$de1e]
    cp $03
    jr nz, jr_000_3815

    ld a, b
    cp $1f

AudioBranchZ_37FC:
Jump_000_37fc:
    jr z, jr_000_37d5

AudioCheckRange16:
    cp $10

AudioBranchNC_3800:
Jump_000_3800:
    jr nc, jr_000_3810

    ld hl, $37c5

Jump_000_3805:
    add l
    ld l, a
    ld a, h

AudioCarryToH:
    adc $00
    ld h, a
    ld l, [hl]
    ld h, $00
    jr jr_000_3848

jr_000_3810:
    ld l, a
    ld h, $00
    jr jr_000_3848

Jump_000_3815:
jr_000_3815:
    ld a, b
    and $0f

AudioCheckRange12:
    cp $0c
    jr nc, jr_000_37d5

    add a
    ld e, a
    ldh a, [$e9]

Jump_000_3820:
    and $10

AudioBranchZ_3822:
    jr z, jr_000_3828

    ld a, e
    add $18
    ld e, a

jr_000_3828:
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
    jr z, jr_000_3840

AudioStoreBfromA:
    ld b, a

jr_000_3839:
    srl h
    rr l
    dec b
    jr nz, jr_000_3839

jr_000_3840:
    ld a, $00
    sub l

AudioSetLength8:
    ld l, a
    ld a, $08
    sbc h
    ld h, a

jr_000_3848:
    xor a
    ldh [$f2], a

AudioSetNoteParams:
    call CheckAudioFlag
    ld a, [$de1e]
    cp $02
    jr nz, jr_000_385c

    call ScreenTransE
    ld a, $80
    ldh [rNR30], a

jr_000_385c:
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
    jr c, jr_000_387f

    cp $fe
    jr c, jr_000_3881

    ld a, $fd
    jr jr_000_3881

jr_000_387f:
    ld a, $02

jr_000_3881:
    ldh [$f6], a
    ld a, [$de1e]
    cp $02
    jr z, jr_000_38b8

    cp $02
    jr nc, jr_000_3899

    ldh a, [$e9]
    and $c0
    or $3f
    ld c, $11
    call WriteAudioRegister

jr_000_3899:
    ld a, h

AudioWriteNR51:
    and $07

AudioSetPanning:
    or $80

jr_000_389e:
    ldh [$f7], a
    ld c, $14
    call WriteAudioRegister

Jump_000_38a5:
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


jr_000_38b8:
    xor a
    ldh [rNR31], a
    ldh a, [rNR52]
    and $04
    jr z, jr_000_3899

    ld a, h
    and $07

AudioWriteNR50:
    jr jr_000_389e

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

Jump_000_38e1:
    ldh [$f5], a
    ld hl, $fff3
    ld a, [hl]
    bit 7, a
    jr nz, jr_000_38f9

    dec [hl]
    ld a, b
    cp $0f
    ret z

    ldh a, [$eb]
    add $10

AudioSetEffect:
    ldh [$eb], a
    jp Jump_000_393c


jr_000_38f9:
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
    jr jr_000_393c

AudioProcessChannel:
Jump_000_3905:
    call CheckAudioFlag

Jump_000_3908:
    ld a, [$de1e]
    cp $03
    ret z

    ldh a, [$fb]
    and a
    ret nz

Jump_000_3912:
    ldh a, [$e5]
    bit 7, a
    ret z

    and $70
    ld b, a
    ld a, [$de22]
    and $0f

Jump_000_391f:
    or b

Jump_000_3920:
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
    jr z, jr_000_395d

AudioGetPanning:
Jump_000_3935:
    ldh a, [$f0]
    and a
    jr nz, jr_000_398e

    ldh a, [$eb]

AudioCommandHandler:
Jump_000_393c:
jr_000_393c:
    ld b, a
    and $07
    jr nz, jr_000_3945

    ld a, b
    or $08
    ld b, a

Jump_000_3945:
jr_000_3945:
    ld a, [$de21]
    add $12
    ld c, a
    ld a, [c]
    cp b
    ret z

    ld a, b

Jump_000_394f:
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


jr_000_395d:
    ldh a, [$eb]
    ld c, $12
    jr jr_000_3954

jr_000_3963:
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
    jr nz, jr_000_3983

    ldh a, [$f7]
    and $7f
    jp z, Jump_000_3a30

jr_000_3983:
    ld a, [$de1e]
    cp $02
    jr z, jr_000_398e

    ldh a, [$f0]
    and a
    ret z

jr_000_398e:
    ldh a, [$f1]
    and a
    ret z

    ld e, $00
    ld c, a
    ldh a, [$f2]
    ld b, $04

jr_000_3999:
    add a
    cp c
    jr c, jr_000_399e

    sub c

jr_000_399e:
    ccf
    rl e
    dec b
    jr nz, jr_000_3999

    ld a, [$de1e]
    cp $02
    jr z, jr_000_3963

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

Jump_000_39c2:
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

Jump_000_39cf:
    swap a
    ld e, a
    ld a, [hl]
    ld h, a
    and $f0
    or e
    ld e, a
    bit 2, h
    jr nz, jr_000_39fc

    inc b

AudioSetTempo:
    ld a, c
    swap a
    and $0f
    jr z, jr_000_39fc

    ld b, a
    bit 3, e
    jr nz, jr_000_39f5

    sla b
    bit 2, e
    jr nz, jr_000_39f5

    sla b
    bit 1, e
    jr z, jr_000_39fa

jr_000_39f5:
    ld a, b

Jump_000_39f6:
    cp $08
    jr c, jr_000_39fc

jr_000_39fa:
    ld b, $00

AudioSetLoop:
jr_000_39fc:
    bit 1, h

Jump_000_39fe:
    jr z, jr_000_3a05

AudioEndLoop:
    ld a, b
    jr z, jr_000_3a05

Jump_000_3a03:
    srl b

jr_000_3a05:
    ld a, h
    and $08

Jump_000_3a08:
    or b
    ld b, a

AudioSetTranspose:
    bit 0, h

Jump_000_3a0c:
    jr z, jr_000_3a17

AudioLookupTable:
    ld hl, $3a83
    add hl, de
    ld a, [hl]
    or b
    jp Jump_000_393c


jr_000_3a17:
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

Jump_000_3a2a:
    add hl, de
    ld a, [hl]
    or b
    jp Jump_000_393c


AudioSetDuty:
Jump_000_3a30:
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

Jump_000_3a44:
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

Jump_000_3a51:
    pop af
    ret


    call nc, $6407
    rlca
    ld sp, hl
    ld b, $95

AudioSetEnvelope2:
    ld b, $37
    ld b, $dd

Jump_000_3a5e:
    dec b
    adc c
    dec b
    ld a, [hl-]
    dec b
    ldh a, [rDIV]
    xor b

Jump_000_3a66:
    inc b
    ld h, l

AudioVibratoSetup:
    inc b
    ld h, $04

Jump_000_3a6b:
    sbc h
    rlca
    ld l, $07
    rst $00
    ld b, $66
    ld b, $0a
    ld b, $b3
    dec b
    ld h, c

Jump_000_3a78:
    dec b
    dec d
    dec b
    call z, $8604
    inc b
    ld b, l
    inc b
    ld [$0004], sp
    nop

Jump_000_3a85:
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
    jr nz, jr_000_3ad1

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

    jr nz, jr_000_3adf

    jr nz, jr_000_3af1

    jr nc, jr_000_3af3

    nop
    nop
    db $10

AudioPortamento:
    db $10
    db $10
    db $10
    jr nz, jr_000_3aeb

    jr nz, jr_000_3aed

    jr nc, jr_000_3aff

    jr nc, jr_000_3b01

jr_000_3ad1:
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

    jr nz, jr_000_3b0c

    jr nc, jr_000_3b0e

    ld b, b

Jump_000_3adf:
jr_000_3adf:
    ld b, b
    ld b, b
    ld d, b
    ld d, b
    nop
    nop
    db $10
    db $10
    jr nz, @+$22

    jr nz, jr_000_3b1b

jr_000_3aeb:
    jr nc, jr_000_3b2d

jr_000_3aed:
    ld b, b

AudioUpdateFreq:
    ld b, b
    ld d, b
    ld d, b

jr_000_3af1:
    ld h, b
    ld h, b

jr_000_3af3:
    nop
    nop
    db $10
    db $10
    jr nz, @+$22

    jr nc, jr_000_3b2b

    ld b, b
    ld b, b
    ld d, b
    ld d, b

jr_000_3aff:
    ld h, b
    ld h, b

jr_000_3b01:
    ld [hl], b
    ld [hl], b

AudioWriteFreqRegs:
    nop
    db $10
    db $10
    jr nz, jr_000_3b28

    jr nc, jr_000_3b3a

    ld b, b
    ld b, b

jr_000_3b0c:
    ld d, b
    ld d, b

jr_000_3b0e:
    ld h, b

Jump_000_3b0f:
    ld h, b
    ld [hl], b
    ld [hl], b
    add b
    nop
    db $10
    db $10
    jr nz, jr_000_3b38

    jr nc, jr_000_3b5a

    ld b, b

jr_000_3b1b:
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

jr_000_3b28:
    jr nc, jr_000_3b6a

    ld d, b

jr_000_3b2b:
    ld d, b
    ld h, b

jr_000_3b2d:
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
    jr nz, jr_000_3b68

jr_000_3b38:
    ld b, b
    ld b, b

jr_000_3b3a:
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
    jr nz, jr_000_3b67

    jr nc, jr_000_3b89

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

jr_000_3b5a:
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
    jr nz, jr_000_3b97

jr_000_3b67:
    ld b, b

jr_000_3b68:
    ld d, b
    ld h, b

jr_000_3b6a:
    ld [hl], b
    ld [hl], b
    add b
    sub b
    and b
    or b
    ret nz

    ret nc

Jump_000_3b72:
    ldh [rP1], a
    db $10
    jr nz, jr_000_3ba7

    ld b, b
    ld d, b
    ld h, b
    ld [hl], b

DataTable_3B7B:
    add b

Jump_000_3b7c:
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

jr_000_3b89:
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

jr_000_3b97:
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

jr_000_3ba7:
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
Jump_000_3c00:
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

Jump_000_3c18:
    add hl, de
    ld de, $ff30

CopyBlock_3C1C:
    ld b, $10

jr_000_3c1e:
    ld a, [hl+]
    ld [de], a
    inc de
    dec b
    jr nz, jr_000_3c1e

    ret


    ld a, [$cdff]
    dec a
    cp $f7
    jr nc, jr_000_3c35

    ld a, [hl]
    or $7f
    cpl
    ld [hl], a
    bit 7, [hl]

RetNop_3C34:
    ret


jr_000_3c35:
    xor a
    ld [hl], a

RetNop_3C37:
    ret


    call DispatchCD90
    ld b, e

ScreenFadeStep:
Jump_000_3c3c:
    inc a
    ld c, d
    inc a
    add e
    inc a
    add $3c
    call $3dab
    ret nz

    jp Jump_000_3ce8


    ld d, $c1
    call $07c1
    ld hl, $53b0

Jump_000_3c52:
    call ReadScreenState
    ld a, [$c9c1]
    cp $03
    call z, CheckAndTriggerEvent
    call $3bf0
    jp Jump_000_3ce8


CheckAndTriggerEvent:
    ld hl, $cda1
    ld a, [hl]
    ld [hl], $01
    or a
    ret z

    ld hl, $53b0
    ld a, $05
    jp $095a


jr_000_3c73:
    ld a, $08
    ld [$c9c0], a
    ld a, $04
    ld [$c993], a
    ld [$cda1], a
    jp Jump_000_3ced


    call DataTable_3B7B
    jp z, Jump_000_3ce8

    ld a, [$c9c1]
    cp $02
    jr nz, jr_000_3ca1

    ld a, [$cd98]
    cp $04
    jr nc, jr_000_3c73

    cp $03
    jr nz, jr_000_3ca1

    ld a, [$cda1]
    or a
    jr nz, jr_000_3c73

jr_000_3ca1:
    call $3dab
    ld hl, $3cbc

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

Jump_000_3cc3:
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


Jump_000_3ce5:
    ld [$cd80], a

PaletteApply:
Jump_000_3ce8:
    ld hl, $cd90
    inc [hl]
    ret


Jump_000_3ced:
    xor a
    ld [$cd90], a
    ret


    call SetSerialByte
    jp $74d0


    call SetSerialByte
    jp $5a3d


    ld h, l

Jump_000_3cff:
    sbc h

Jump_000_3d00:
    ld l, e

Jump_000_3d01:
    sbc h

CheckPartyFlags:
    ld a, [$c98b]
    bit 0, a
    jp nz, Jump_000_1aab

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
    jp Jump_000_3c52


    call DataTable_3B7B
    jp z, Jump_000_3ce8

    call $3dab
    ld hl, $3cbc
    jp Jump_000_3ca7


    ld d, $cc

MenuInputCheck:
    call TilemapRecombineAddr

Jump_000_3d3c:
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
    jp nz, Jump_000_1aab

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
    jr c, jr_000_3de3

    set 5, [hl]

jr_000_3de3:
    xor a
    ret


    call $3dab
    ret nz

    jp Jump_000_3ce8


    call $3dab
    jp $420e


    call DataTable_3B7B
    jp z, Jump_000_3ce8

    call $3dab
    ld hl, $3e01
    jp Jump_000_3ca7


    ld d, b

Jump_000_3e02:
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

    jp Jump_000_3ce8


    ld b, $8d
    call $2043
    ld bc, $0537
    call $1196
    jr jr_000_3e5d

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
    jp Jump_000_3ce8


    ld b, $c9
    call $2043

jr_000_3e58:
    ld a, $5b
    call $0510

Jump_000_3e5d:
jr_000_3e5d:
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
    jr jr_000_3e58

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
    jp Jump_000_3f77


    call PartyMenuSetup
    ret nz

    xor a
    ld [$ccb7], a

Jump_000_3ed3:
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
    jr z, jr_000_3efe

    ld a, [$cd90]
    cp $03
    ld bc, $040f
    jp z, Jump_000_3f77

    ld bc, $0710
    jp Jump_000_3f77


jr_000_3efe:
    ld hl, $c9f5

CheckPartySize:
    ld a, [hl]
    cp $05
    jr c, jr_000_3f18

    ld hl, $cb80
    ld [hl], $f4
    inc l
    ld [hl], $01
    ld a, $08
    ld [$cd90], a
    ld a, $20
    jp Jump_000_0ba1


jr_000_3f18:
    ld bc, $0c0e
    jp Jump_000_3f77

    ld h, [hl]
    sbc h
    ld l, e
    sbc h
    call PartyMenuSetup
    ret nz

    ld bc, $0d0c
    jp Jump_000_3f77


    call CallScriptByType
    ret nz

    jp Jump_000_3ce8


    ld hl, $cb80
    ld a, [hl]
    sub $01
    ld [hl+], a
    ld a, [hl]
    sbc $00
    ld [hl], a
    jr c, jr_000_3f48

    ld a, $01
    ld bc, $9fcb
    jp Jump_000_0c13


jr_000_3f48:
    ld a, $20
    call TextHandler_0BA1
    jp Jump_000_3ce8


    call CallScriptByType
    ret nz

    ld bc, $0b0d
    jp Jump_000_3f77


    call DataTable_3B7B
    ret nz

    ld b, $ec
    call $2043
    jp Jump_000_3e5d


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


Jump_000_3f77:
    ld a, b
    ld [$cd90], a
    ld a, c
    ld hl, $55ce
    call $095a
    jp Jump_000_0b98


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
    jr z, jr_000_3fd5

    ld b, $10

jr_000_3fd5:
    ld e, [hl]
    inc hl
    ld d, $d7

jr_000_3fd9:
    ld a, [hl+]
    cp $ff
    ret z

    cp $fe
    jr z, jr_000_3fd5

    ld [de], a
    ld a, b
    call ReadDEMetadata3B
    jr jr_000_3fd9

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
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
    rst $38
