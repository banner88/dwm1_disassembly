; ART BANK $7C — new art for ORIGINAL monsters (gamedata.art; generated
; by editor2 `art7c`, S107 P3.10 part 2a — PROJECT_COMPILER §2.23).
; Self-ID byte, pointer table at $4001 (the resolver reads
; $<bank>:$4001 + index*2), the LZ streams. A re-arted species' gfx-ID
; (bank<<8 | index) is written into ROM0 MonsterBattleGfxTable (battle) /
; the eight follower gfx-ID tables (walking). No art = an all-zero bank,
; exactly like the original ROM.

SECTION "Art Bank $7C", ROMX[$4000], BANK[$7C]
    ds $4000, $00
