; -----------------------------------------------------------------------------
; PlaceNum{X} (S140, ROADMAP ARC CAP3a — regions) — the PLACE NUMBER of a custom
; map id in the current region. A custom place is (wMapRegion, wMapID); its
; place number indexes every per-place table the compiler emits (P order:
; region 0's places, then region 1's, ... — each region from id $6B up). This
; block is pasted into every bank whose code indexes such a table (banks $60,
; $6C, $71, $76; suffix = the bank), each with its own copy of the two small
; tables below (emitted by the compiler next to the bank's data):
;   RegionTable{X}:    db n_regions, then per region: db count (ids $6B .. $6B
;                      + count - 1 are its places, holes = placeholders), dw base
;                      (the place number of its id $6B)
;   GlobalPlaceIds{X}: db (id - $6B) ... db $FF — the GLOBAL places (the arena
;                      copies, which ROM0 ArenaAlias knows by bare id): region 0's
;                      places wherever the player stands; no other region uses
;                      those ids.
; One region (every project up to 128 places): count = the place count, base 0
; — the place number is id - $6B, as the tables were indexed before S140.
;
; PlaceNum{X}: A = a map id / script type, region = wMapRegion.
; PlaceNumIn{X}: E = a map id / script type, D = the region.
; Out: CF clear = a place, HL = its place number; CF set = none — a vanilla id
; ($00-$6A), a link id or anything >= $EB (REGION_IDS), a region the build
; lacks (a stale save), an id past its region's last place. Keeps BC.
; Clobbers A, DE.
; -----------------------------------------------------------------------------
PlaceNum{X}:
    ld e, a
    ld a, [wMapRegion]
    ld d, a
PlaceNumIn{X}:
    ld a, e
    sub CUSTOM_ROOM_START
    ret c                               ; a vanilla id
    cp REGION_IDS
    ccf
    ret c                               ; $EB+: a link id / not a place
    ld e, a                             ; E = id - $6B
    ld hl, GlobalPlaceIds{X}
.global:
    ld a, [hl+]
    cp $FF
    jr z, .region
    cp e
    jr nz, .global
    ld d, $00                           ; a global place: region 0's
.region:
    ld hl, RegionTable{X}
    ld a, d
    cp [hl]
    ccf
    ret c                               ; a region this build does not have
    inc hl
    ld d, a
    add a
    add d                               ; region * 3
    add l
    ld l, a
    adc h
    sub l
    ld h, a                             ; HL -> [count, base lo, base hi]
    ld a, e
    cp [hl]
    ccf
    ret c                               ; past the region's last place
    inc hl
    ld a, [hl+]
    ld h, [hl]
    ld l, a                             ; HL = the region's first place number
    ld d, $00
    add hl, de                          ; + (id - $6B); CF clear (no overflow)
    ret
