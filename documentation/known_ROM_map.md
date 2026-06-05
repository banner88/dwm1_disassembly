{{rommap|game=Dragon Warrior Monsters}}

== Bank 00 ==

=== rst $10 ===

This method is used to call functions stored in other banks. It's usually preceded by writes to RAM locations (which act as arguments to the function being called). The function to call is selected via HL, so the rst $10 call is always directly preceded by a write to HL. In this, H is the bank of the function to call, while L is the index of it.

At the start of every bank, besides bank 0, is a byte indicating the bank itself, followed by a list of 2-byte address which address the cross-bank functions stored in that bank. The index is the index into this table (0-based).

For example, the start of bank 1 looks like this:

<pre>
01:4000  01     = Bank index
01:4001  1D 40  = Cross-bank function 0's address (call it with mov hl,$0100; rst $10;)
01:4003  D3 4D  = Cross-bank function 1's address
01:4005  1C 42  = Cross-bank function 2's address
      ...
01:401B  E1 69  = Cross-bank function 13's address
01:40D1  ...    = Cross-bank function 0's code
</pre>

===PRNG===
* <code>0x12D0</code> - Pseudo-Random Number Generator - wC899 × 5 + 0x1357
 ROM0:12D0 E5               push hl
 ROM0:12D1 D5               push de
 ROM0:12D2 FA 99 C8         ld   a,(C899)
 ROM0:12D5 67               ld   h,a
 ROM0:12D6 FA 9A C8         ld   a,(C89A)
 ROM0:12D9 6F               ld   l,a          ;hl = old_prn
 ROM0:12DA 54               ld   d,h
 ROM0:12DB 5D               ld   e,l          ;de = old_prn
 ROM0:12DC 29               add  hl,hl
 ROM0:12DD 29               add  hl,hl
 ROM0:12DE 19               add  hl,de        ;hl = old_prn × 5
 ROM0:12DF 11 57 13         ld   de,1357      ;de = 0x1357
 ROM0:12E2 19               add  hl,de        ;hl = (old_prn × 5) + 0x1357
 ROM0:12E3 7C               ld   a,h
 ROM0:12E4 EA 99 C8         ld   (C899),a     ;write (old_prn × 5) + 0x1357 in wC899
 ROM0:12E7 7D               ld   a,l
 ROM0:12E8 EA 9A C8         ld   (C89A),a
 ROM0:12EB D1               pop  de
 ROM0:12EC E1               pop  hl
 ROM0:12ED C9               ret  

=== Text functions ===

<pre>
00:07AB HandleTextCharacter
00:0D78 ReadNextTextByte
</pre>

===0:1AB9 - Wait for OAM, then write tile in VRAM===
*<code>0x1AB9</code> - Wait for OAM, then write tile in VRAM

===Set BGM===
 ROM0:1AE5 EA B5 C8         ld   (C8B5),a          ;Writes bgm_offset in wC8B5
 ROM0:1AE8 F3               di                     ;disable interrupts
 ROM0:1AE9 CD 31 33         call 3331              ;Audio on, Sound panning 0, Master volume & VIN panning 0x77, and sets various audio related values in 1:DD80+ WRAM area
 ROM0:1AEC FA B5 C8         ld   a,(C8B5)          ;a = bgm_offset
 ROM0:1AEF B7               or   a
 ROM0:1AF0 28 38            jr   z,1B2A            ;if (bgm_offset == 0), jump to 0:1B2A ; fail-safe, as no music should be bgm_offset 0x02 rather than 0x00
 ROM0:1AF2 EA 24 DE         ld   (DE24),a          ;Writes bgm_offset in 1:DE24
 ROM0:1AF5 FE 27            cp   a,27
 ROM0:1AF7 28 29            jr   z,1B22            ;if (bgm_offset == battle), jump to 0:1B22 - Load BGM, 3 parts
 ROM0:1AF9 FE 3A            cp   a,3A
 ROM0:1AFB 28 2A            jr   z,1B27            ;if (bgm_offset == fanfare_b), jump to 0:1B27 - Load BGM, 1 part
 ROM0:1AFD FE 3F            cp   a,3F
 ROM0:1AFF 28 26            jr   z,1B27            ;if (bgm_offset == 0x3F), jump to 0:1B27 - Load BGM, 1 part
 ROM0:1B01 FE 47            cp   a,47
 ROM0:1B03 28 22            jr   z,1B27            ;if (bgm_offset == level_up), jump to 0:1B27 - Load BGM, 1 part
 ROM0:1B05 FE 49            cp   a,49
 ROM0:1B07 28 1E            jr   z,1B27            ;if (bgm_offset == 0x49), jump to 0:1B27 - Load BGM, 1 part
 ROM0:1B09 FE 4B            cp   a,4B
 ROM0:1B0B 28 1A            jr   z,1B27            ;if (bgm_offset == monster_encounter_a), jump to 0:1B27 - Load BGM, 1 part
 ROM0:1B0D FE 4D            cp   a,4D
 ROM0:1B0F 28 16            jr   z,1B27            ;if (bgm_offset == monster_encounter_2), jump to 0:1B27 - Load BGM, 1 part
 ROM0:1B11 FE 4F            cp   a,4F
 ROM0:1B13 28 12            jr   z,1B27            ;if (bgm_offset == game_over), jump to 0:1B27 - Load BGM, 1 part
 ROM0:1B15 FE 5D            cp   a,5D
 ROM0:1B17 28 0E            jr   z,1B27            ;if (bgm_offset == test_bgm_1), jump to 0:1B27 - Load BGM, 1 part
 ROM0:1B19 FE 9D            cp   a,9D
 ROM0:1B1B 28 0A            jr   z,1B27            ;if (bgm_offset == test_bgm_2), jump to 0:1B27 - Load BGM, 1 part
 ROM0:1B1D CD CC 33         call 33CC              ;else: Load BGM, 2 parts
 ROM0:1B20 FB               ei                     ;enable interrupts
 ROM0:1B21 C9               ret

===Call routines to load bgm===
===Call : Load BGM, 3 parts===
 ROM0:1B22 CD C9 33         call 33C9              ;Load BGM, 3 parts
 ROM0:1B25 FB               ei                     ;enable interrupts
 ROM0:1B26 C9               ret  
===Call : Load BGM, 1 part===
 ROM0:1B27 CD CF 33         call 33CF              ;Load BGM, 1 part
 ROM0:1B2A FB               ei                     ;enable interrupts - the fail-safe in case (bgm_offset == 0) jumps here
 ROM0:1B2B C9               ret

===Load SE and non-looping BGM===
 ROM0:1B30 F5               push af
 ROM0:1B31 C5               push bc
 ROM0:1B32 D5               push de
 ROM0:1B33 E5               push hl
 ROM0:1B34 EA 24 DE         ld   (DE24),a
 ROM0:1B37 FE 3F            cp   a,3F
 ROM0:1B39 28 62            jr   z,1B9D
 ROM0:1B3B FE 41            cp   a,41
 ROM0:1B3D 28 68            jr   z,1BA7            ;if (bgm_offset == prayer_heal), jump to 0:1BA7
 ROM0:1B3F FE 44            cp   a,44
 ROM0:1B41 28 64            jr   z,1BA7            ;if (bgm_offset == fanfare_d), jump to 0:1BA7
 ROM0:1B43 FE 47            cp   a,47
 ROM0:1B45 28 56            jr   z,1B9D            ;if (bgm_offset == level_up), jump to 0:1B9D
 ROM0:1B47 FE 49            cp   a,49
 ROM0:1B49 28 52            jr   z,1B9D
 ROM0:1B4B FE 4B            cp   a,4B
 ROM0:1B4D 28 4E            jr   z,1B9D            ;if (bgm_offset == monster_encounter_a), jump to 0:1B9D
 ROM0:1B4F FE 4D            cp   a,4D
 ROM0:1B51 28 4A            jr   z,1B9D            ;if (bgm_offset == monster_encounter_b), jump to 0:1B9D
 ROM0:1B53 FE 4F            cp   a,4F
 ROM0:1B55 28 46            jr   z,1B9D            ;if (bgm_offset == game_over), jump to 0:1B9D
 ROM0:1B57 FE 57            cp   a,57
 ROM0:1B59 28 42            jr   z,1B9D
 ROM0:1B5B FE 5D            cp   a,5D
 ROM0:1B5D 28 3E            jr   z,1B9D            ;if (bgm_offset == test_bgm_1), jump to 0:1B9D
 ROM0:1B5F FE 63            cp   a,63
 ROM0:1B61 28 3A            jr   z,1B9D
 ROM0:1B63 FE 61            cp   a,61
 ROM0:1B65 28 40            jr   z,1BA7
 ROM0:1B67 FE 69            cp   a,69
 ROM0:1B69 28 32            jr   z,1B9D
 ROM0:1B6B FE 74            cp   a,74
 ROM0:1B6D 28 2E            jr   z,1B9D
 ROM0:1B6F FE 76            cp   a,76
 ROM0:1B71 28 2A            jr   z,1B9D
 ROM0:1B73 FE 78            cp   a,78
 ROM0:1B75 28 26            jr   z,1B9D
 ROM0:1B77 FE 7C            cp   a,7C
 ROM0:1B79 28 22            jr   z,1B9D
 ROM0:1B7B FE 86            cp   a,86
 ROM0:1B7D 28 1E            jr   z,1B9D
 ROM0:1B7F FE 8A            cp   a,8A
 ROM0:1B81 28 1A            jr   z,1B9D
 ROM0:1B83 FE 90            cp   a,90
 ROM0:1B85 28 16            jr   z,1B9D
 ROM0:1B87 FE 97            cp   a,97
 ROM0:1B89 28 12            jr   z,1B9D
 ROM0:1B8B FE 99            cp   a,99
 ROM0:1B8D 28 0E            jr   z,1B9D
 ROM0:1B8F FE 9D            cp   a,9D
 ROM0:1B91 28 0A            jr   z,1B9D            ;if (bgm_offset == test_bgm_2), jump to 0:1B9D
 ROM0:1B93 F3               di                     ;disable interrupts
 ROM0:1B94 CD D2 33         call 33D2
 ROM0:1B97 FB               ei                     ;enable interrupts
 ROM0:1B98 E1               pop  hl
 ROM0:1B99 D1               pop  de
 ROM0:1B9A C1               pop  bc
 ROM0:1B9B F1               pop  af
 ROM0:1B9C C9               ret

===0:1BB1 - Related to BGM===
 ROM0:1BB1 FA B7 C8         ld   a,(C8B7)          ;a = bgm_offset
 ROM0:1BB4 FE FF            cp   a,FF
 ROM0:1BB6 28 0C            jr   z,1BC4
 ROM0:1BB8 FE 9D            cp   a,9D
 ROM0:1BBA 28 08            jr   z,1BC4            ;if (bgm_offset == test_bgm_2), jump to 0:1BC4 (will load no BGM at all)
 ROM0:1BBC CD E5 1A         call 1AE5              ;Set BGM
 ROM0:1BBF 3E FF            ld   a,FF
 ROM0:1BC1 EA B7 C8         ld   (C8B7),a
 ROM0:1BC4 FA B8 C8         ld   a,(C8B8)
 ROM0:1BC7 FE FF            cp   a,FF
 ROM0:1BC9 28 08            jr   z,1BD3
 ROM0:1BCB CD 30 1B         call 1B30
 ROM0:1BCE 3E FF            ld   a,FF
 ROM0:1BD0 EA B8 C8         ld   (C8B8),a
 ROM0:1BD3 C9               ret

=== Math functions ===

<pre>
00:1dbe Mul8x8To16   HL = A * C
00:1de6 Mul16x8To24  E:HL = BC * A
00:1e0d Div16x8To16  HL = HL // A; A = HL % A
00:1e1e Div24x8To16  HL = E:HL // A; A = E:HL % A
00:2f45 CmpHLvsBC
00:2f4b Div16x16To16 DE = HL // BC; BC = HL % BC
</pre>

==Bank 01==
===01:55D7 - Copy hFF92-hFF96 to hFFDB-hFFDE; then retrieve next_step_or_next_room_id ===
 ROM1:55D7 F0 92            ld   a,(ff00+92)
 ROM1:55D9 6F               ld   l,a
 ROM1:55DA F0 93            ld   a,(ff00+93)
 ROM1:55DC 67               ld   h,a           ;hl = [FF92]
 ROM1:55DD 7D               ld   a,l
 ROM1:55DE E0 DB            ld   (ff00+DB),a   ;Write hl to hFFDB (basically copy hFF95-hFF96 to hFFDB-hFFDC)
 ROM1:55E0 7C               ld   a,h
 ROM1:55E1 E0 DC            ld   (ff00+DC),a
 ROM1:55E3 F0 95            ld   a,(ff00+95)
 ROM1:55E5 6F               ld   l,a
 ROM1:55E6 F0 96            ld   a,(ff00+96)
 ROM1:55E8 67               ld   h,a           ;hl = [FF95]
 ROM1:55E9 7D               ld   a,l
 ROM1:55EA E0 DD            ld   (ff00+DD),a   ;Write hl to hFFDD (basically copy hFF95-hFF96 to hFFDD-hFFDE)
 ROM1:55EC 7C               ld   a,h
 ROM1:55ED E0 DE            ld   (ff00+DE),a
 ROM1:55EF 21 05 0B         ld   hl,0B05       ;to Bank 0B, function 05
 ROM1:55F2 D7               rst  10
 ROM1:55F3 F0 D5            ld   a,(ff00+D5)   ;a = hFFD5
 ROM1:55F5 FE FF            cp   a,FF
 ROM1:55F7 C8               ret  z             ;if(next_step_or_next_room_id) == 0xFF, exit this function
 ROM1:55F8 EA D4 D8         ld   (D8D4),a      ;Write next_step_or_next_room_id to w1:D8D4
 ROM1:55FB FA 68 C9         ld   a,(C968)      ;a= map_type
 ROM1:55FE EA D3 D8         ld   (D8D3),a      ;Write map_type to w1:D8D3
 ROM1:5601 AF               xor  a
 ROM1:5602 EA D7 D8         ld   (D8D7),a      ;Write 0 to w1:D8D7
 ROM1:5605 21 05 04         ld   hl,0405
 ROM1:5608 D7               rst  10
 ROM1:5609 FA D7 D8         ld   a,(D8D7)      ;a = [1:D8D7]
 ROM1:560C B7               or   a
 ROM1:560D C8               ret  z
 ROM1:560E CB 4F            bit  1,a
 ROM1:5610 C8               ret  z
 ROM1:5611 21 FF FF         ld   hl,FFFF
 ROM1:5614 7D               ld   a,l
 ROM1:5615 EA 17 C9         ld   (C917),a
 ROM1:5618 7C               ld   a,h
 ROM1:5619 EA 18 C9         ld   (C918),a
 ROM1:561C 21 EB C8         ld   hl,C8EB
 ROM1:561F CB C6            set  0,(hl)
 ROM1:5621 AF               xor  a
 ROM1:5622 EA 15 C9         ld   (C915),a
 ROM1:5625 EA 16 C9         ld   (C916),a
 ROM1:5628 C9               ret

===Load next dungeon floor===
 ROM1:69E1 FA 35 C9         ld   a,(C935)      ;a = current_gate
 ROM1:69E4 21 22 6A         ld   hl,6A22
 ROM1:69E7 85               add  l
 ROM1:69E8 6F               ld   l,a
 ROM1:69E9 3E 00            ld   a,00
 ROM1:69EB 8C               adc  h
 ROM1:69EC 67               ld   h,a
 ROM1:69ED 7E               ld   a,(hl)        ;a = offset specific to current gate and current floor
 ROM1:69EE F5               push af
 ROM1:69EF FA 35 C9         ld   a,(C935)      ;a = current_gate
 ROM1:69F2 87               add  a
 ROM1:69F3 21 42 6A         ld   hl,6A42       ;hl points to an array of pointers to Gates floors thresholds
 ROM1:69F6 85               add  l
 ROM1:69F7 6F               ld   l,a
 ROM1:69F8 3E 00            ld   a,00
 ROM1:69FA 8C               adc  h
 ROM1:69FB 67               ld   h,a
 ROM1:69FC 2A               ldi  a,(hl)
 ROM1:69FD 66               ld   h,(hl)
 ROM1:69FE 6F               ld   l,a           ;hl = pointer_to_gate_floor_thresholds
 ROM1:69FF 0E FF            ld   c,FF
 ROM1:6A01 FA 39 C9         ld   a,(C939)      ;a = current_floor
 ROM1:6A04 3C               inc  a             ;current_floor++
 ROM1:6A05 BE               cp   (hl)
 ROM1:6A06 0C               inc  c             ;current_floor_threshold++
 ROM1:6A07 23               inc  hl
 ROM1:6A08 30 F7            jr   nc,6A01
 ROM1:6A0A F1               pop  af           
 ROM1:6A0B 81               add  c             ;a = offset_specific_to_current_gate_and_current_floor + current_floor_threshold
 ROM1:6A0C EA 38 CA         ld   (CA38),a      ;write result of querying 1:6A22 + current_floor_threshold array in wCA38
 ROM1:6A0F 01 1A 00         ld   bc,001A       ;bc = 26
 ROM1:6A12 CD E6 1D         call 1DE6          ;hl = bc × a
 ROM1:6A15 7D               ld   a,l
 ROM1:6A16 C6 AE            add  a,AE
 ROM1:6A18 6F               ld   l,a
 ROM1:6A19 7C               ld   a,h
 ROM1:6A1A CE 6A            adc  a,6A
 ROM1:6A1C 67               ld   h,a           ;hl = 0x6AAE + ((offset_specific_to_current_gate_and_current_floor + current_floor_threshold) × 26)
 ROM1:6A1D 7E               ld   a,(hl)
 ROM1:6A1E EA A9 C8         ld   (C8A9),a      ;store the value pointed to in wC8A9
 ROM1:6A21 C9               ret  

====1:6A22 array (offsets specific to current gate and current floor)====
 00 01 03 05 07 09 0C 0F 12 16 1A 1E 22 27 2C 31
 36 3B 40 45 4A 4F 55 59 5D 61 65 69 6D 71 75 79

====1:6A42 array - Pointers to Gates floors thresholds====
 82 6A - Gate of Beginning
 83 6A - Gate of Villager
 83 6A - Gate of Talisman
 83 6A - Gate of Memories
 83 6A - Gate of Bewilder
 83 6A - 
 86 6A - Gate of Peace
 86 6A - Gate of Bravery
 86 6A - 
 8A 6A - 
 8A 6A - 
 8A 6A - 
 8E 6A - 
 83 6A - 
 8E 6A - 
 93 6A - 
 93 6A - 
 86 6A - 
 98 6A - 
 98 6A - 
 98 6A - 
 9D 6A - 
 A3 6A - 
 A3 6A - 
 A3 6A - 
 A3 6A - 
 A3 6A - 
 A3 6A - 
 A3 6A - 
 A3 6A - 
 A3 6A - 
 A7 6A - Unused Gate

====1:6A82 array - Gates floors thresholds====
These numbers are used for monsters encounters, music and other stuff
 FF - No threshold
 03 06 FF - 3; 6
 04 06 09 FF - 4; 6; 9
 04 06 09 FF - 4; 6; 9
 04 06 09 0D FF - 4; 6; 9; 13
 05 09 0D 11 FF - 5; 9; 13; 17
 06 0B 10 15 FF - 6; 11; 16; 21
 06 0B 10 15 1A FF - 6; 11; 16; 21; 26
 06 0B 15 FF - 6; 11; 21
 06 0B 15 29 3D 51 FF - 6; 11; 21; 41; 61; 81

===1:6AAE array - Gates floors thresholds data===
 32 arrays of 26 bytes
 (to document)

== Bank 03 ==

=== Monster info table ===
Base info for monsters starts at ROM03:4461. This table has 221 entries at 43 bytes each. See the names [[#Monster name tables|here]]

Format:

<pre>
00: Family:
  00 = Slime
  01 = Dragon
  02 = Beast
  03 = Flying
  04 = Plant
  05 = Bug
  06 = Devil
  07 = Zombie
  08 = Material
  09 = ???  (Boss)
01: Base level cap
02: [[#Experience table|Experience table]] index
03: Percentage of females:
  v  = raw val (F:M ratio)
  00 =   0/256 (0:100)
  01 =  26/256 (13:115 ~ 10:90)
  02 = 128/256 (50:50)
  03 = 214/256 (107:21 ~ 84:16)
04: ?
06: Base skills (3 skills, 1 byte per)
09: ?
0F: Resistances (27 bytes)
2A: ?
</pre>

==Bank 04==
===4:5B1B - Arena (non-Starry Night Tournament): Generate Battles, handle current consecutive battle===

===4:6D93 - Coliseum in Gates, generate a prize, etc.===
* Initializes Coliseum in Gates and its prize, among other things

===rst $10 depending on Map type===
 ROM4:71EF FA D3 D8         ld   a,(D8D3)     ;a = map_type
 ROM4:71F2 FE 06            cp   a,06
 ROM4:71F4 30 05            jr   nc,71FB      ;if(map_type > 0x6), jump to 4:71FB
 ROM4:71F6 21 00 0C         ld   hl,0C00      ;to Bank C
 ROM4:71F9 D7               rst  10
 ROM4:71FA C9               ret  
 ROM4:71FB FE 20            cp   a,20
 ROM4:71FD 30 05            jr   nc,7204      ;if(map_type > 0x20), jump to 4:7204
 ROM4:71FF 21 00 0D         ld   hl,0D00      ;to Bank D
 ROM4:7202 D7               rst  10
 ROM4:7203 C9               ret  
 ROM4:7204 FE 40            cp   a,40
 ROM4:7206 30 05            jr   nc,720D      ;if(map_type > 0x40), jump to 4:720D
 ROM4:7208 21 00 0E         ld   hl,0E00      ;to Bank E
 ROM4:720B D7               rst  10
 ROM4:720C C9               ret  
 ROM4:720D 21 00 0F         ld   hl,0F00      ;to Bank F
 ROM4:7210 D7               rst  10
 ROM4:7211 C9               ret

==Bank 0B==
===B:4274 - Loading next room stuff, to document===
 ROMB:4274 FA 69 C9         ld   a,(C969)      ;a = flag_in_gate
 ROMB:4277 B7               or   a
 ROMB:4278 20 32            jr   nz,42AC       ;if(flag_in_gate), jump to B:42AC
 ROMB:427A 21 43 4B         ld   hl,4B43       ;hl = 0x4B43
 ROMB:427D FA 68 C9         ld   a,(C968)      ;a= map_type
 ROMB:4280 87               add  a
 ROMB:4281 85               add  l
 ROMB:4282 6F               ld   l,a
 ROMB:4283 3E 00            ld   a,00
 ROMB:4285 8C               adc  h
 ROMB:4286 67               ld   h,a           ;hl = 0x4B43 + (map_type × 2)
 ROMB:4287 2A               ldi  a,(hl)
 ROMB:4288 66               ld   h,(hl)
 ROMB:4289 6F               ld   l,a
 ROMB:428A FA 25 C9         ld   a,(C925)
 ROMB:428D 87               add  a
 ROMB:428E 85               add  l
 ROMB:428F 6F               ld   l,a
 ROMB:4290 3E 00            ld   a,00
 ROMB:4292 8C               adc  h
 ROMB:4293 67               ld   h,a           ;hl = map_type_pointer + ([wC925] × 2)
 ROMB:4294 2A               ldi  a,(hl)
 ROMB:4295 66               ld   h,(hl)
 ROMB:4296 6F               ld   l,a           ;hl = [hl]
 ROMB:4297 5E               ld   e,(hl)
 ROMB:4298 23               inc  hl
 ROMB:4299 56               ld   d,(hl)        ;de = [hl]; pointer to WRAM location of either current step, current room or current consecutive battle in current map
 ROMB:429A 23               inc  hl            ;hl++
 ROMB:429B 1A               ld   a,(de)        ;a = [de]; current step, current room or current consecutive battle in current map
 ROMB:429C 5F               ld   e,a           ;e = current_step_room_or_consecutive_battle
 ROMB:429D 87               add  a
 ROMB:429E 83               add  e
 ROMB:429F 87               add  a             ;a ×= 6
 ROMB:42A0 85               add  l             ;a += l
 ROMB:42A1 6F               ld   l,a
 ROMB:42A2 3E 00            ld   a,00
 ROMB:42A4 8C               adc  h
 ROMB:42A5 67               ld   h,a           ;hl += (current_step_room_or_consecutive_battle × 6)
 ROMB:42A6 23               inc  hl
 ROMB:42A7 23               inc  hl            ;hl += 2
 ROMB:42A8 2A               ldi  a,(hl)
 ROMB:42A9 66               ld   h,(hl)
 ROMB:42AA 6F               ld   l,a           ;hl = [hl]
 ROMB:42AB C9               ret

===B:42AC===
 ROMB:42AC FA 26 C9         ld   a,(C926)      ;a = [wC926]
 ROMB:42AF FE FF            cp   a,FF
 ROMB:42B1 20 04            jr   nz,42B7
 ROMB:42B3 21 08 43         ld   hl,4308
 ROMB:42B6 C9               ret  

===B:43A4===
 ROMB:43A4 3E FF            ld   a,FF
 ROMB:43A6 E0 D5            ld   (ff00+D5),a   ;next_step_or_next_room_id = 0xFF
 ROMB:43A8 F0 90            ld   a,(ff00+90)
 ROMB:43AA CB 77            bit  6,a
 ROMB:43AC C0               ret  nz
 ROMB:43AD FA D7 D8         ld   a,(D8D7)
 ROMB:43B0 B7               or   a
 ROMB:43B1 C0               ret  nz
 ROMB:43B2 CD B8 43         call 43B8
 ROMB:43B5 E0 D5            ld   (ff00+D5),a
 ROMB:43B7 C9               ret  

===B:43B8===
 ROMB:43B8 CD 74 42         call 4274
 ROMB:43BB 7E               ld   a,(hl)     ;a = value_pointed_by_result_of_func_B_4274
 ROMB:43BC FE FF            cp   a,FF
 ROMB:43BE C8               ret  z          ;if(a == 0xFF), exit this function
 ROMB:43BF CB 7F            bit  7,a
 ROMB:43C1 28 1F            jr   z,43E2     ;if(bit 7 of a is set), jump to B:43C1
 ROMB:43C3 E6 F0            and  a,F0
 ROMB:43C5 FE 90            cp   a,90
 ROMB:43C7 20 0F            jr   nz,43D8    ;if(a ≠ 0x90), jump to B:43D8
 ROMB:43C9 CD 52 44         call 4452       ;retrieve coordinates of exit, retrieve current step, check if they match coordinates for current step, then load next step
 ROMB:43CC 20 0A            jr   nz,43D8
 ROMB:43CE 7D               ld   a,l
 ROMB:43CF C6 04            add  a,04
 ROMB:43D1 6F               ld   l,a
 ROMB:43D2 7C               ld   a,h
 ROMB:43D3 CE 00            adc  a,00
 ROMB:43D5 67               ld   h,a       ;hl +=4
 ROMB:43D6 7E               ld   a,(hl)    ;a = next_step_or_next_room_id
 ROMB:43D7 C9               ret

===B:4452===
* <code>0x2C3C7</code> - Retrieve coordinates of exit, retrieve current step, check if they match coordinates for current step, then load next step

===Enter Gate or Map===
 ROMB:4452 E5               push hl
 ROMB:4453 C5               push bc
 ROMB:4454 D5               push de
 ROMB:4455 23               inc  hl
 ROMB:4456 23               inc  hl
 ROMB:4457 F0 DB            ld   a,(ff00+DB)   ;a = current_column and ?
 ROMB:4459 CB 37            swap a
 ROMB:445B E6 0F            and  a,0F
 ROMB:445D 47               ld   b,a
 ROMB:445E F0 DC            ld   a,(ff00+DC)
 ROMB:4460 CB 37            swap a
 ROMB:4462 E6 F0            and  a,F0
 ROMB:4464 B0               or   b
 ROMB:4465 47               ld   b,a
 ROMB:4466 3E 0A            ld   a,0A
 ROMB:4468 CD FB 1D         call 1DFB
 ROMB:446B BE               cp   (hl)
 ROMB:446C 20 DE            jr   nz,444C
 ROMB:446E 23               inc  hl
 ROMB:446F F0 DD            ld   a,(ff00+DD)   ;a = current_row and ?
 ROMB:4471 CB 37            swap a
 ROMB:4473 E6 0F            and  a,0F
 ROMB:4475 47               ld   b,a
 ROMB:4476 F0 DE            ld   a,(ff00+DE)
 ROMB:4478 CB 37            swap a
 ROMB:447A E6 F0            and  a,F0
 ROMB:447C B0               or   b
 ROMB:447D 47               ld   b,a
 ROMB:447E 3E 08            ld   a,08
 ROMB:4480 CD FB 1D         call 1DFB
 ROMB:4483 BE               cp   (hl)
 ROMB:4484 20 C6            jr   nz,444C
 ROMB:4486 18 BF            jr   4447
 ROMB:4488 FA 50 C8         ld   a,(C850)
 ROMB:448B B7               or   a
 ROMB:448C C0               ret  nz
 ROMB:448D FA 8E C8         ld   a,(C88E)
 ROMB:4490 B7               or   a
 ROMB:4491 C0               ret  nz
 ROMB:4492 FA 8F C8         ld   a,(C88F)
 ROMB:4495 B7               or   a
 ROMB:4496 C0               ret  nz
 ROMB:4497 FA EB C8         ld   a,(C8EB)
 ROMB:449A CB 47            bit  0,a
 ROMB:449C C0               ret  nz
 ROMB:449D F0 90            ld   a,(ff00+90)
 ROMB:449F CB 47            bit  0,a
 ROMB:44A1 C0               ret  nz
 ROMB:44A2 FA 69 C9         ld   a,(C969)      ;a = flag_in_gate
 ROMB:44A5 B7               or   a
 ROMB:44A6 C0               ret  nz
 ROMB:44A7 21 43 4B         ld   hl,4B43       ;hl = pointer_to_pointers_to_gate_ids
 ROMB:44AA FA 68 C9         ld   a,(C968)      ;a = map_type
 ROMB:44AD 87               add  a
 ROMB:44AE 85               add  l
 ROMB:44AF 6F               ld   l,a
 ROMB:44B0 3E 00            ld   a,00
 ROMB:44B2 8C               adc  h
 ROMB:44B3 67               ld   h,a
 ROMB:44B4 2A               ldi  a,(hl)
 ROMB:44B5 66               ld   h,(hl)
 ROMB:44B6 6F               ld   l,a
 ROMB:44B7 FA 25 C9         ld   a,(C925)
 ROMB:44BA 87               add  a
 ROMB:44BB 85               add  l
 ROMB:44BC 6F               ld   l,a
 ROMB:44BD 3E 00            ld   a,00
 ROMB:44BF 8C               adc  h
 ROMB:44C0 67               ld   h,a
 ROMB:44C1 2A               ldi  a,(hl)
 ROMB:44C2 66               ld   h,(hl)
 ROMB:44C3 6F               ld   l,a
 ROMB:44C4 5E               ld   e,(hl)
 ROMB:44C5 23               inc  hl
 ROMB:44C6 56               ld   d,(hl)
 ROMB:44C7 23               inc  hl
 ROMB:44C8 1A               ld   a,(de)
 ROMB:44C9 5F               ld   e,a
 ROMB:44CA 87               add  a
 ROMB:44CB 83               add  e
 ROMB:44CC 87               add  a
 ROMB:44CD 85               add  l
 ROMB:44CE 6F               ld   l,a
 ROMB:44CF 3E 00            ld   a,00
 ROMB:44D1 8C               adc  h
 ROMB:44D2 67               ld   h,a
 ROMB:44D3 23               inc  hl
 ROMB:44D4 23               inc  hl
 ROMB:44D5 23               inc  hl
 ROMB:44D6 23               inc  hl
 ROMB:44D7 2A               ldi  a,(hl)
 ROMB:44D8 66               ld   h,(hl)
 ROMB:44D9 6F               ld   l,a
 ROMB:44DA 01 E7 2D         ld   bc,2DE7
 ROMB:44DD FA 25 C9         ld   a,(C925)
 ROMB:44E0 87               add  a
 ROMB:44E1 81               add  c
 ROMB:44E2 4F               ld   c,a
 ROMB:44E3 3E 00            ld   a,00
 ROMB:44E5 88               adc  b
 ROMB:44E6 47               ld   b,a
 ROMB:44E7 0A               ld   a,(bc)
 ROMB:44E8 5F               ld   e,a
 ROMB:44E9 03               inc  bc
 ROMB:44EA 0A               ld   a,(bc)
 ROMB:44EB 57               ld   d,a
 ROMB:44EC 7E               ld   a,(hl)
 ROMB:44ED FE FF            cp   a,FF
 ROMB:44EF C8               ret  z
 ROMB:44F0 7E               ld   a,(hl)
 ROMB:44F1 B7               or   a
 ROMB:44F2 28 10            jr   z,4504
 ROMB:44F4 FE 09            cp   a,09
 ROMB:44F6 28 0C            jr   z,4504
 ROMB:44F8 23               inc  hl
 ROMB:44F9 7E               ld   a,(hl)
 ROMB:44FA 2B               dec  hl
 ROMB:44FB B7               or   a
 ROMB:44FC 28 06            jr   z,4504
 ROMB:44FE FE 07            cp   a,07
 ROMB:4500 28 02            jr   z,4504
 ROMB:4502 18 0F            jr   4513
 ROMB:4504 F0 97            ld   a,(ff00+97)
 ROMB:4506 93               sub  e
 ROMB:4507 BE               cp   (hl)
 ROMB:4508 20 09            jr   nz,4513
 ROMB:450A 23               inc  hl
 ROMB:450B F0 98            ld   a,(ff00+98)
 ROMB:450D 92               sub  d
 ROMB:450E BE               cp   (hl)
 ROMB:450F 2B               dec  hl
 ROMB:4510 CA A8 45         jp   z,45A8
 ROMB:4513 7D               ld   a,l
 ROMB:4514 C6 07            add  a,07
 ROMB:4516 6F               ld   l,a
 ROMB:4517 7C               ld   a,h
 ROMB:4518 CE 00            adc  a,00
 ROMB:451A 67               ld   h,a
 ROMB:451B 18 CF            jr   44EC
 ROMB:451D FA EB C8         ld   a,(C8EB)
 ROMB:4520 CB 47            bit  0,a
 ROMB:4522 C2 74 46         jp   nz,4674
 ROMB:4525 F0 90            ld   a,(ff00+90)
 ROMB:4527 CB 47            bit  0,a
 ROMB:4529 C2 74 46         jp   nz,4674
 ROMB:452C FA 69 C9         ld   a,(C969)      ;a = flag_in_gate
 ROMB:452F B7               or   a
 ROMB:4530 C2 A7 46         jp   nz,46A7
 ROMB:4533 21 43 4B         ld   hl,4B43
 ROMB:4536 FA 68 C9         ld   a,(C968)
 ROMB:4539 87               add  a
 ROMB:453A 85               add  l
 ROMB:453B 6F               ld   l,a
 ROMB:453C 3E 00            ld   a,00
 ROMB:453E 8C               adc  h
 ROMB:453F 67               ld   h,a
 ROMB:4540 2A               ldi  a,(hl)
 ROMB:4541 66               ld   h,(hl)
 ROMB:4542 6F               ld   l,a
 ROMB:4543 FA 25 C9         ld   a,(C925)
 ROMB:4546 87               add  a
 ROMB:4547 85               add  l
 ROMB:4548 6F               ld   l,a
 ROMB:4549 3E 00            ld   a,00
 ROMB:454B 8C               adc  h
 ROMB:454C 67               ld   h,a
 ROMB:454D 2A               ldi  a,(hl)
 ROMB:454E 66               ld   h,(hl)
 ROMB:454F 6F               ld   l,a
 ROMB:4550 5E               ld   e,(hl)
 ROMB:4551 23               inc  hl
 ROMB:4552 56               ld   d,(hl)
 ROMB:4553 23               inc  hl
 ROMB:4554 1A               ld   a,(de)
 ROMB:4555 5F               ld   e,a
 ROMB:4556 87               add  a
 ROMB:4557 83               add  e
 ROMB:4558 87               add  a
 ROMB:4559 85               add  l
 ROMB:455A 6F               ld   l,a
 ROMB:455B 3E 00            ld   a,00
 ROMB:455D 8C               adc  h
 ROMB:455E 67               ld   h,a
 ROMB:455F 23               inc  hl
 ROMB:4560 23               inc  hl
 ROMB:4561 23               inc  hl
 ROMB:4562 23               inc  hl
 ROMB:4563 2A               ldi  a,(hl)
 ROMB:4564 66               ld   h,(hl)
 ROMB:4565 6F               ld   l,a
 ROMB:4566 01 E7 2D         ld   bc,2DE7
 ROMB:4569 FA 25 C9         ld   a,(C925)
 ROMB:456C 87               add  a
 ROMB:456D 81               add  c
 ROMB:456E 4F               ld   c,a
 ROMB:456F 3E 00            ld   a,00
 ROMB:4571 88               adc  b
 ROMB:4572 47               ld   b,a
 ROMB:4573 0A               ld   a,(bc)
 ROMB:4574 5F               ld   e,a
 ROMB:4575 03               inc  bc
 ROMB:4576 0A               ld   a,(bc)
 ROMB:4577 57               ld   d,a
 ROMB:4578 7E               ld   a,(hl)
 ROMB:4579 FE FF            cp   a,FF
 ROMB:457B CA 74 46         jp   z,4674
 ROMB:457E 7E               ld   a,(hl)
 ROMB:457F B7               or   a
 ROMB:4580 28 1C            jr   z,459E
 ROMB:4582 FE 09            cp   a,09
 ROMB:4584 28 18            jr   z,459E
 ROMB:4586 F0 97            ld   a,(ff00+97)
 ROMB:4588 93               sub  e
 ROMB:4589 BE               cp   (hl)
 ROMB:458A 20 12            jr   nz,459E
 ROMB:458C 23               inc  hl
 ROMB:458D 7E               ld   a,(hl)
 ROMB:458E 2B               dec  hl
 ROMB:458F B7               or   a
 ROMB:4590 28 0C            jr   z,459E
 ROMB:4592 FE 07            cp   a,07
 ROMB:4594 28 08            jr   z,459E
 ROMB:4596 23               inc  hl
 ROMB:4597 F0 98            ld   a,(ff00+98)
 ROMB:4599 92               sub  d
 ROMB:459A BE               cp   (hl)
 ROMB:459B 2B               dec  hl
 ROMB:459C 28 0A            jr   z,45A8
 ROMB:459E 7D               ld   a,l
 ROMB:459F C6 07            add  a,07
 ROMB:45A1 6F               ld   l,a
 ROMB:45A2 7C               ld   a,h
 ROMB:45A3 CE 00            adc  a,00
 ROMB:45A5 67               ld   h,a
 ROMB:45A6 18 D0            jr   4578
 ROMB:45A8 23               inc  hl
 ROMB:45A9 23               inc  hl
 ROMB:45AA 2A               ldi  a,(hl)
 ROMB:45AB EA 6D C9         ld   (C96D),a      ;Write gate_id in wC96D
 ROMB:45AE 2A               ldi  a,(hl)
 ROMB:45AF EA 6E C9         ld   (C96E),a
 ROMB:45B2 11 E7 2D         ld   de,2DE7
 ROMB:45B5 2A               ldi  a,(hl)
 ROMB:45B6 F5               push af
 ROMB:45B7 E6 0F            and  a,0F
 ROMB:45B9 87               add  a
 ROMB:45BA 83               add  e
 ROMB:45BB 5F               ld   e,a
 ROMB:45BC 3E 00            ld   a,00
 ROMB:45BE 8A               adc  d
 ROMB:45BF 57               ld   d,a
 ROMB:45C0 1A               ld   a,(de)
 ROMB:45C1 86               add  (hl)
 ROMB:45C2 13               inc  de
 ROMB:45C3 23               inc  hl
 ROMB:45C4 CB 37            swap a
 ROMB:45C6 47               ld   b,a
 ROMB:45C7 E6 F0            and  a,F0
 ROMB:45C9 4F               ld   c,a
 ROMB:45CA 78               ld   a,b
 ROMB:45CB E6 0F            and  a,0F
 ROMB:45CD 47               ld   b,a
 ROMB:45CE 79               ld   a,c
 ROMB:45CF C6 08            add  a,08
 ROMB:45D1 4F               ld   c,a
 ROMB:45D2 78               ld   a,b
 ROMB:45D3 CE 00            adc  a,00
 ROMB:45D5 47               ld   b,a
 ROMB:45D6 79               ld   a,c
 ROMB:45D7 EA 6F C9         ld   (C96F),a
 ROMB:45DA 78               ld   a,b
 ROMB:45DB EA 70 C9         ld   (C970),a
 ROMB:45DE 1A               ld   a,(de)
 ROMB:45DF 86               add  (hl)
 ROMB:45E0 13               inc  de
 ROMB:45E1 23               inc  hl
 ROMB:45E2 CB 37            swap a
 ROMB:45E4 47               ld   b,a
 ROMB:45E5 E6 F0            and  a,F0
 ROMB:45E7 4F               ld   c,a
 ROMB:45E8 78               ld   a,b
 ROMB:45E9 E6 0F            and  a,0F
 ROMB:45EB 47               ld   b,a
 ROMB:45EC 79               ld   a,c
 ROMB:45ED C6 08            add  a,08
 ROMB:45EF 4F               ld   c,a
 ROMB:45F0 78               ld   a,b
 ROMB:45F1 CE 00            adc  a,00
 ROMB:45F3 47               ld   b,a
 ROMB:45F4 F1               pop  af
 ROMB:45F5 CB 7F            bit  7,a
 ROMB:45F7 28 08            jr   z,4601
 ROMB:45F9 79               ld   a,c
 ROMB:45FA C6 08            add  a,08
 ROMB:45FC 4F               ld   c,a
 ROMB:45FD 78               ld   a,b
 ROMB:45FE CE 00            adc  a,00
 ROMB:4600 47               ld   b,a
 ROMB:4601 79               ld   a,c
 ROMB:4602 EA 71 C9         ld   (C971),a
 ROMB:4605 78               ld   a,b
 ROMB:4606 EA 72 C9         ld   (C972),a
 ROMB:4609 3E 01            ld   a,01
 ROMB:460B EA 6C C9         ld   (C96C),a
 ROMB:460E FA 6E C9         ld   a,(C96E)
 ROMB:4611 B7               or   a
 ROMB:4612 20 57            jr   nz,466B
 ROMB:4614 FA 69 C9         ld   a,(C969)      ;a = flag_in_gate
 ROMB:4617 B7               or   a
 ROMB:4618 20 0D            jr   nz,4627
 ROMB:461A FA 68 C9         ld   a,(C968)      ;a =  map_type
 ROMB:461D FE 10            cp   a,10
 ROMB:461F 20 06            jr   nz,4627
 ROMB:4621 F0 95            ld   a,(ff00+95)
 ROMB:4623 FE 68            cp   a,68
 ROMB:4625 28 05            jr   z,462C
 ROMB:4627 CD 52 26         call 2652
 ROMB:462A 28 2F            jr   z,465B
 ROMB:462C FA 68 C9         ld   a,(C968)      ;a =  map_type
 ROMB:462F 6F               ld   l,a
 ROMB:4630 FA 69 C9         ld   a,(C969)      ;a = flag_in_gate
 ROMB:4633 67               ld   h,a
 ROMB:4634 E5               push hl
 ROMB:4635 FA 6D C9         ld   a,(C96D)      ;a = gate_to_warp_to
 ROMB:4638 6F               ld   l,a
 ROMB:4639 FA 6E C9         ld   a,(C96E)
 ROMB:463C 67               ld   h,a
 ROMB:463D 7D               ld   a,l
 ROMB:463E EA 68 C9         ld   (C968),a      ;Write map_type in wC968
 ROMB:4641 7C               ld   a,h
 ROMB:4642 EA 69 C9         ld   (C969),a      ;Write flag_in_gate in wC969
 ROMB:4645 CD 52 26         call 2652
 ROMB:4648 E1               pop  hl
 ROMB:4649 F5               push af
 ROMB:464A 7D               ld   a,l
 ROMB:464B EA 68 C9         ld   (C968),a      ;Write map_type in wC968
 ROMB:464E 7C               ld   a,h
 ROMB:464F EA 69 C9         ld   (C969),a      ;Write flag_in_gate in wC969
 ROMB:4652 F1               pop  af
 ROMB:4653 20 06            jr   nz,465B
 ROMB:4655 21 09 01         ld   hl,0109
 ROMB:4658 D7               rst  10
 ROMB:4659 18 10            jr   466B
 ROMB:465B 3E 03            ld   a,03
 ROMB:465D CD 88 16         call 1688
 ROMB:4660 21 8F C8         ld   hl,C88F
 ROMB:4663 34               inc  (hl)
 ROMB:4664 3E 51            ld   a,51
 ROMB:4666 CD 2C 1B         call 1B2C
 ROMB:4669 18 09            jr   4674
 ROMB:466B 21 EB C8         ld   hl,C8EB
 ROMB:466E CB EE            set  5,(hl)
 ROMB:4670 AF               xor  a
 ROMB:4671 EA 05 C9         ld   (C905),a
 ROMB:4674 FA 68 C9         ld   a,(C968)      ;a =  map_type
 ROMB:4677 FA 68 C9         ld   a,(C968)      ;a =  map_type
 ROMB:467A FE 53            cp   a,53
 ROMB:467C 28 57            jr   z,46D5        ;if(special_room_forst_maze), jump to B:46D5
 ROMB:467E FE 61            cp   a,61
 ROMB:4680 28 53            jr   z,46D5
 ROMB:4682 FE 62            cp   a,62
 ROMB:4684 28 4F            jr   z,46D5
 ROMB:4686 FE 63            cp   a,63
 ROMB:4688 28 4B            jr   z,46D5
 ROMB:468A FE 64            cp   a,64
 ROMB:468C 28 47            jr   z,46D5
 ROMB:468E FE 54            cp   a,54
 ROMB:4690 28 43            jr   z,46D5
 ROMB:4692 FE 55            cp   a,55
 ROMB:4694 28 3F            jr   z,46D5
 ROMB:4696 FE 56            cp   a,56
 ROMB:4698 28 3B            jr   z,46D5        ;if(special_room_conveyor_belt_maze_3), jump to B:46D5
 ROMB:469A FE 57            cp   a,57
 ROMB:469C 28 37            jr   z,46D5
 ROMB:469E FE 58            cp   a,58
 ROMB:46A0 28 33            jr   z,46D5
 ROMB:46A2 FE 59            cp   a,59
 ROMB:46A4 28 2F            jr   z,46D5        ;if(special_room_maze_3), jump to B:46D5
 ROMB:46A6 C9               ret

===B:4B43 - Pointers to WRAM address to current step/map/battle and to pointers to exits coordinates and next steps/next rooms array===
 B:4B43
 13 4C - Castle
 23 4E - 
 5D 50 - 
 F2 52 - 
 AE 55 - 
 3A 58 - 
 9E 59 - Arena lobby
 2B 5A - Arena rooms
 86 5C - 
 45 5D - 
 6A 5E - 
 13 4C - 
 94 5E - 
 C0 5E - 
 13 4C - 
 4A 5F - 
 71 5F - 
 13 4C - 
 DB 5F - 
 7D 60 - 
 13 4C - 
 13 4C - 
 39 61 - 
 71 5F - 
 F8 61 - 
 BB 62 - 
 E2 62 - 
 13 63 - 
 5E 63 - 
 C5 63 - 
 F6 63 - 
 38 64 - 
 13 4C - 
 13 4C - 
 13 4C - 
 A4 64 - 
 DB 64 - 
 39 65 - 
 97 65 - 
 F5 65 - 
 58 66 - 
 B6 66 - 
 14 67 - 
 72 67 - 
 A9 67 - 
 07 68 - 
 65 68 - 
 CA 68 - 
 AF 6A - Boss Room - Gate of Beginning
 D4 6A - Boss Room - Gate of Villager
 12 6B - Boss Room - Gate of Talisman
 41 6B - Boss Room - Gate of Memories
 66 6B - Boss Room - Gate of Bewilder
 C2 6B - 
 FB 6B - Boss Room - Gate of Peace
 84 6C - Boss Room - Gate of Bravery
 17 6D - 
 FA 6D - 
 33 6E - 
 3E 6F - 
 63 6F - 
 E3 6F - 
 23 70 - 
 52 70 - 
 77 70 - 
 E4 70 - 
 42 71 - Labyrinth
 DB 74 - 
 1E 75 - 
 61 75 - 
 C9 75 - 
 F8 75 - 
 43 76 - 
 72 76 - 
 A1 76 - 
 D0 76 - 
 FF 76 - 
 2E 77 - 
 5D 77 - 
 A9 77 - Boss Room - Unused Gate
 DD 77 - 
 FA 77 - 
 17 78 - 
 4B 78 - 
 08 79 - 
 78 79 - 
 E8 79 - 
 58 7A - 
 C8 7A - 
 38 7B - 
 A8 7B - 
 D9 7B - 
 0A 7C - 
 45 7C - Arena battle
 E2 7C - 
 DD 77 - 
 44 71 - Labyrinth final room
 4D 78 - 
 4F 78 - 
 51 78 - 
 53 78 - 
 44 71 - 
 44 71 - 
 44 71 - 
 23 4C - 
 3D 4C -

===B:7192 - Labyrinth exits coordinates and steps array===
* <code>0x2F192</code> - Array of coordinates and corresponding steps within Labyrinth
 B:7192
 (bb) aa bb cc dd ee
 aa - 90, test value; pointed by an array of pointer depending on current step
 bb - FF, test value, can be duplicated at start of array; pointed by an array of pointer depending on current step
 cc - Column
 dd - Row
 ee - Step; 0F means wrong step, which resets current step to 0.
      Correct last step of an exit sequence has the same step as previous step (which ends the exit sequence, and resets current step to 0)
 
 From the initial room:
  RIGHT (north one): Mimic
  DOWN DOWN DOWN RIGHT (south one): Watabou doll
  UP UP LEFT (south one): Empty spot
  UP UP UP LEFT DOWN DOWN LEFT (north one): Boss

==Bank 0F==
===Load next room in map ?===
 ROMF:4007 FA D3 D8         ld   a,(D8D3)      ;a = map_type
 ROMF:400A 6F               ld   l,a
 ROMF:400B 26 00            ld   h,00
 ROMF:400D 29               add  hl,hl
 ROMF:400E 11 BA 41         ld   de,41BA
 ROMF:4011 19               add  hl,de         ;hl = 0x41BA + map_type × 2
 ROMF:4012 5E               ld   e,(hl)
 ROMF:4013 23               inc  hl
 ROMF:4014 56               ld   d,(hl)
 ROMF:4015 FA D4 D8         ld   a,(D8D4)      ;next_step or next_room_id ?
 ROMF:4018 6F               ld   l,a
 ROMF:4019 26 00            ld   h,00
 ROMF:401B 29               add  hl,hl
 ROMF:401C 19               add  hl,de
 ROMF:401D 5E               ld   e,(hl)
 ROMF:401E 23               inc  hl
 ROMF:401F 56               ld   d,(hl)
 ROMF:4020 FA D5 D8         ld   a,(D8D5)
 ROMF:4023 6F               ld   l,a
 ROMF:4024 FA D6 D8         ld   a,(D8D6)
 ROMF:4027 67               ld   h,a
 ROMF:4028 29               add  hl,hl
 ROMF:4029 19               add  hl,de
 ROMF:402A 4E               ld   c,(hl)
 ROMF:402B 23               inc  hl
 ROMF:402C 46               ld   b,(hl)
 ROMF:402D 2B               dec  hl
 ROMF:402E C9               ret

== Bank 13 ==
=== Experience table ===
At ROM13:41E6, there are 32 entries of 297 bytes each. Those 297 bytes are an array of 99 3-byte records. Each 3-byte record is an integer representing the total experience points required to achieve that level (1-based index into the array).

To use this, find the row associate with the ID mentioned in the [[#Monster info table|monster info table]] then use the column as the level. Level 1 is always 0 exp because all monsters start at level 1 when hatched.

<div style="overflow-x:scroll; width:100%">
{| class="prettytable"
! id || 1 || 2 || 3 || 4 || 5 || 6 || 7 || 8 || 9 || 10 || 11 || 12 || 13 || 14 || 15 || 16 || 17 || 18 || 19 || 20 || 21 || 22 || 23 || 24 || 25 || 26 || 27 || 28 || 29 || 30 || 31 || 32 || 33 || 34 || 35 || 36 || 37 || 38 || 39 || 40 || 41 || 42 || 43 || 44 || 45 || 46 || 47 || 48 || 49 || 50 || 51 || 52 || 53 || 54 || 55 || 56 || 57 || 58 || 59 || 60 || 61 || 62 || 63 || 64 || 65 || 66 || 67 || 68 || 69 || 70 || 71 || 72 || 73 || 74 || 75 || 76 || 77 || 78 || 79 || 80 || 81 || 82 || 83 || 84 || 85 || 86 || 87 || 88 || 89 || 90 || 91 || 92 || 93 || 94 || 95 || 96 || 97 || 98 || 99
|-
| 0 || 0 || 2 || 7 || 15 || 30 || 50 || 90 || 140 || 215 || 330 || 500 || 760 || 1080 || 1480 || 1980 || 2600 || 3380 || 4360 || 5580 || 6950 || 8500 || 10500 || 12900 || 15700 || 18900 || 22500 || 26500 || 30900 || 35700 || 40900 || 46500 || 52500 || 58900 || 65700 || 72900 || 80500 || 88500 || 96900 || 105700 || 114900 || 124500 || 134500 || 145500 || 157500 || 170500 || 184500 || 199500 || 215500 || 232500 || 250500 || 269500 || 289500 || 310500 || 332500 || 355500 || 379500 || 404500 || 429500 || 454500 || 479500 || 504500 || 529500 || 554500 || 579500 || 604500 || 629500 || 654500 || 679500 || 704500 || 729500 || 754500 || 779500 || 804500 || 829500 || 854500 || 879500 || 904500 || 929500 || 954500 || 979500 || 1004500 || 1029500 || 1054500 || 1079500 || 1104500 || 1129500 || 1154500 || 1179500 || 1204500 || 1229500 || 1254500 || 1279500 || 1304500 || 1329500 || 1354500 || 1379500 || 1404500 || 1429500 || 1454500
|-
| 1 || 0 || 2 || 7 || 15 || 30 || 50 || 90 || 140 || 215 || 330 || 500 || 760 || 1080 || 1480 || 1980 || 2600 || 3380 || 4360 || 5580 || 6950 || 8500 || 10500 || 12900 || 15700 || 18900 || 22500 || 26500 || 30900 || 35700 || 40900 || 46500 || 52500 || 58900 || 65700 || 72900 || 80500 || 88500 || 96900 || 105700 || 114900 || 124500 || 134500 || 146500 || 160500 || 176500 || 194500 || 214500 || 236500 || 260500 || 286500 || 314500 || 344500 || 374500 || 404500 || 434500 || 464500 || 494500 || 524500 || 554500 || 584500 || 614500 || 644500 || 674500 || 704500 || 734500 || 764500 || 794500 || 824500 || 854500 || 884500 || 914500 || 944500 || 974500 || 1004500 || 1034500 || 1064500 || 1094500 || 1124500 || 1154500 || 1184500 || 1214500 || 1244500 || 1274500 || 1304500 || 1334500 || 1364500 || 1394500 || 1424500 || 1454500 || 1484500 || 1514500 || 1544500 || 1574500 || 1604500 || 1634500 || 1664500 || 1694500 || 1724500 || 1754500
|-
| 2 || 0 || 2 || 7 || 15 || 30 || 50 || 90 || 140 || 215 || 330 || 500 || 760 || 1080 || 1480 || 1980 || 2600 || 3380 || 4360 || 5580 || 6950 || 8500 || 10500 || 13100 || 16300 || 20100 || 24500 || 29500 || 35100 || 41300 || 48100 || 55500 || 63500 || 72100 || 81300 || 91100 || 101500 || 112500 || 124100 || 136300 || 149100 || 162500 || 176500 || 191500 || 207500 || 224500 || 242500 || 261500 || 281500 || 302500 || 324500 || 347500 || 371500 || 396500 || 421500 || 446500 || 471500 || 496500 || 521500 || 546500 || 571500 || 596500 || 621500 || 646500 || 671500 || 696500 || 721500 || 746500 || 771500 || 796500 || 821500 || 846500 || 871500 || 896500 || 921500 || 946500 || 971500 || 996500 || 1021500 || 1046500 || 1071500 || 1096500 || 1121500 || 1146500 || 1171500 || 1196500 || 1221500 || 1246500 || 1271500 || 1296500 || 1321500 || 1346500 || 1371500 || 1396500 || 1421500 || 1446500 || 1471500 || 1496500 || 1521500 || 1546500
|-
| 3 || 0 || 2 || 7 || 15 || 30 || 50 || 90 || 140 || 215 || 330 || 500 || 760 || 1080 || 1480 || 1980 || 2600 || 3380 || 4360 || 5580 || 6950 || 8500 || 10500 || 13100 || 16300 || 20100 || 24500 || 29500 || 35100 || 41300 || 48100 || 55500 || 63500 || 72100 || 81300 || 91100 || 101500 || 112500 || 124100 || 136300 || 149100 || 162500 || 176500 || 192500 || 210500 || 230500 || 252500 || 276500 || 302500 || 330500 || 360500 || 390500 || 420500 || 450500 || 480500 || 510500 || 540500 || 570500 || 600500 || 630500 || 660500 || 690500 || 720500 || 750500 || 780500 || 810500 || 840500 || 870500 || 900500 || 930500 || 960500 || 990500 || 1020500 || 1050500 || 1080500 || 1110500 || 1140500 || 1170500 || 1200500 || 1230500 || 1260500 || 1290500 || 1320500 || 1350500 || 1380500 || 1410500 || 1440500 || 1470500 || 1500500 || 1530500 || 1560500 || 1590500 || 1620500 || 1650500 || 1680500 || 1710500 || 1740500 || 1770500 || 1800500 || 1830500
|-
| 4 || 0 || 2 || 7 || 15 || 30 || 50 || 90 || 140 || 215 || 330 || 500 || 760 || 1080 || 1480 || 1980 || 2600 || 3380 || 4360 || 5580 || 6950 || 8500 || 10500 || 13300 || 16900 || 21300 || 26500 || 32500 || 39300 || 46900 || 55300 || 64500 || 74500 || 85300 || 96900 || 109300 || 122500 || 136500 || 151300 || 166900 || 183300 || 200500 || 218500 || 237500 || 257500 || 278500 || 300500 || 323500 || 347500 || 372500 || 397500 || 422500 || 447500 || 472500 || 497500 || 522500 || 547500 || 572500 || 597500 || 622500 || 647500 || 672500 || 697500 || 722500 || 747500 || 772500 || 797500 || 822500 || 847500 || 872500 || 897500 || 922500 || 947500 || 972500 || 997500 || 1022500 || 1047500 || 1072500 || 1097500 || 1122500 || 1147500 || 1172500 || 1197500 || 1222500 || 1247500 || 1272500 || 1297500 || 1322500 || 1347500 || 1372500 || 1397500 || 1422500 || 1447500 || 1472500 || 1497500 || 1522500 || 1547500 || 1572500 || 1597500 || 1622500
|-
| 5 || 0 || 2 || 7 || 15 || 30 || 50 || 90 || 140 || 215 || 330 || 500 || 760 || 1080 || 1480 || 1980 || 2600 || 3380 || 4360 || 5580 || 6950 || 8500 || 10500 || 13300 || 16900 || 21300 || 26500 || 32500 || 39300 || 46900 || 55300 || 64500 || 74500 || 85300 || 96900 || 109300 || 122500 || 136500 || 151300 || 166900 || 183300 || 200500 || 218500 || 238500 || 260500 || 284500 || 310500 || 338500 || 368500 || 398500 || 428500 || 458500 || 488500 || 518500 || 548500 || 578500 || 608500 || 638500 || 668500 || 698500 || 728500 || 758500 || 788500 || 818500 || 848500 || 878500 || 908500 || 938500 || 968500 || 998500 || 1028500 || 1058500 || 1088500 || 1118500 || 1148500 || 1178500 || 1208500 || 1238500 || 1268500 || 1298500 || 1328500 || 1358500 || 1388500 || 1418500 || 1448500 || 1478500 || 1508500 || 1538500 || 1568500 || 1598500 || 1628500 || 1658500 || 1688500 || 1718500 || 1748500 || 1778500 || 1808500 || 1838500 || 1868500 || 1898500
|-
| 6 || 0 || 2 || 7 || 15 || 30 || 50 || 90 || 140 || 215 || 330 || 500 || 760 || 1080 || 1480 || 1980 || 2600 || 3380 || 4360 || 5580 || 6950 || 8500 || 10500 || 13500 || 17500 || 22500 || 28500 || 35500 || 43500 || 52500 || 62500 || 73500 || 85500 || 98500 || 112500 || 127500 || 143500 || 160500 || 178500 || 197500 || 217500 || 238500 || 260500 || 283500 || 307500 || 332500 || 357500 || 382500 || 407500 || 432500 || 457500 || 482500 || 507500 || 532500 || 557500 || 582500 || 607500 || 632500 || 657500 || 682500 || 707500 || 732500 || 757500 || 782500 || 807500 || 832500 || 857500 || 882500 || 907500 || 932500 || 957500 || 982500 || 1007500 || 1032500 || 1057500 || 1082500 || 1107500 || 1132500 || 1157500 || 1182500 || 1207500 || 1232500 || 1257500 || 1282500 || 1207500 || 1332500 || 1357500 || 1382500 || 1407500 || 1432500 || 1457500 || 1482500 || 1507500 || 1532500 || 1557500 || 1582500 || 1607500 || 1632500 || 1657500 || 1682500
|-
| 7 || 0 || 2 || 7 || 15 || 30 || 50 || 90 || 140 || 215 || 330 || 500 || 760 || 1080 || 1480 || 1980 || 2600 || 3380 || 4360 || 5580 || 6950 || 8500 || 10500 || 13500 || 17500 || 22500 || 28500 || 35500 || 43500 || 52500 || 62500 || 73500 || 85500 || 98500 || 112500 || 127500 || 143500 || 160500 || 178500 || 197500 || 217500 || 238500 || 260500 || 284500 || 310500 || 338500 || 368500 || 398500 || 428500 || 458500 || 488500 || 518500 || 548500 || 578500 || 608500 || 638500 || 668500 || 698500 || 728500 || 758500 || 788500 || 818500 || 848500 || 878500 || 908500 || 938500 || 968500 || 998500 || 1028500 || 1058500 || 1088500 || 1118500 || 1148500 || 1178500 || 1208500 || 1238500 || 1268500 || 1298500 || 1328500 || 1358500 || 1388500 || 1418500 || 1448500 || 1478500 || 1508500 || 1538500 || 1568500 || 1598500 || 1628500 || 1658500 || 1688500 || 1718500 || 1748500 || 1778500 || 1808500 || 1838500 || 1868500 || 1898500 || 1928500 || 1958500
|-
| 8 || 0 || 5 || 15 || 30 || 60 || 100 || 180 || 280 || 430 || 660 || 1000 || 1520 || 2160 || 2960 || 3960 || 5200 || 6760 || 8760 || 11160 || 13900 || 17000 || 21000 || 25800 || 31400 || 37800 || 45000 || 53000 || 61800 || 71400 || 81800 || 93000 || 105000 || 117800 || 131400 || 145800 || 161000 || 177000 || 193800 || 211400 || 229800 || 249000 || 269000 || 290250 || 312750 || 336500 || 361500 || 387750 || 415250 || 444000 || 474000 || 506000 || 540000 || 576000 || 614000 || 654000 || 695000 || 737000 || 780000 || 824000 || 869000 || 915000 || 962000 || 1010000 || 1059000 || 1109000 || 1159000 || 1209000 || 1259000 || 1309000 || 1338520 || 1409000 || 1459000 || 1509000 || 1559000 || 1609000 || 1659000 || 1709000 || 1759000 || 1809000 || 1859000 || 1909000 || 1959000 || 2009000 || 2059000 || 2109000 || 2159000 || 2209000 || 2259000 || 2309000 || 2359000 || 2409000 || 2459000 || 2509000 || 2559000 || 2609000 || 2659000 || 2709000 || 2759000 || 2809000
|-
| 9 || 0 || 5 || 15 || 30 || 60 || 100 || 180 || 280 || 430 || 660 || 1000 || 1520 || 2160 || 2960 || 3960 || 5200 || 6760 || 8760 || 11160 || 13900 || 17000 || 21000 || 25800 || 31400 || 37800 || 45000 || 53000 || 61800 || 71400 || 81800 || 93000 || 105000 || 117800 || 131400 || 145800 || 161000 || 177000 || 193800 || 211400 || 229800 || 249000 || 269000 || 292100 || 318300 || 347600 || 380000 || 415500 || 454100 || 495900 || 540900 || 586900 || 633900 || 681900 || 730900 || 780900 || 831900 || 883900 || 936900 || 990900 || 1045900 || 1101900 || 1158900 || 1216900 || 1275900 || 1335900 || 1395900 || 1455900 || 1515900 || 1575900 || 1635900 || 1695900 || 1755900 || 1815900 || 1875900 || 1935900 || 1995900 || 2055900 || 2115900 || 2175900 || 2235900 || 2295900 || 2355900 || 2415900 || 2475900 || 2535900 || 2595900 || 2655900 || 2715900 || 2775900 || 2835900 || 2895900 || 2955900 || 3015900 || 3075900 || 3135900 || 3195900 || 3255900 || 3315900 || 3375900
|-
| 10 || 0 || 5 || 15 || 30 || 60 || 100 || 180 || 280 || 430 || 660 || 1000 || 1520 || 2160 || 2960 || 3960 || 5200 || 6760 || 8760 || 11160 || 13900 || 17000 || 21000 || 26200 || 32600 || 40200 || 49000 || 59000 || 70200 || 82600 || 96200 || 111000 || 127000 || 144200 || 162600 || 182200 || 203000 || 225000 || 248200 || 272600 || 298200 || 325000 || 353000 || 382500 || 413500 || 446256 || 480000 || 515500 || 552500 || 591000 || 631000 || 671600 || 712800 || 754600 || 797000 || 840000 || 883600 || 927800 || 972600 || 1018000 || 1064000 || 1110800 || 1158400 || 1206800 || 1256000 || 1306000 || 1356000 || 1406000 || 1456000 || 1506000 || 1556000 || 1606000 || 1656000 || 1706000 || 1756000 || 1806000 || 1856000 || 1906000 || 1956000 || 2006000 || 2056000 || 2106000 || 2156000 || 2206000 || 2256000 || 2306000 || 2356000 || 2406000 || 2456000 || 2506000 || 2556000 || 2606000 || 2656000 || 2706000 || 2756000 || 2806000 || 2856000 || 2906000 || 2956000 || 3006000
|-
| 11 || 0 || 5 || 15 || 30 || 60 || 100 || 180 || 280 || 430 || 660 || 1000 || 1520 || 2160 || 2960 || 3960 || 5200 || 6760 || 8760 || 11160 || 13900 || 17000 || 21000 || 26200 || 32600 || 40200 || 49000 || 59000 || 70200 || 82600 || 96200 || 111000 || 127000 || 144200 || 162600 || 182200 || 203000 || 225000 || 248200 || 272600 || 298200 || 325000 || 353000 || 383750 || 417250 || 453500 || 492500 || 534250 || 578750 || 626000 || 676000 || 726600 || 777800 || 829600 || 882000 || 935000 || 988600 || 1042800 || 1097600 || 1153000 || 1209000 || 1265800 || 1323400 || 1381800 || 1441000 || 1501000 || 1561000 || 1621000 || 1681000 || 1741000 || 1801000 || 1861000 || 1921000 || 1981000 || 2041000 || 2101000 || 2161000 || 2221000 || 2281000 || 2341000 || 2401000 || 2461000 || 2521000 || 2581000 || 2641000 || 2701000 || 2761000 || 2821000 || 2881000 || 2941000 || 3001000 || 3061000 || 3121000 || 3181000 || 3241000 || 3301000 || 3361000 || 3421000 || 3481000 || 3541000
|-
| 12 || 0 || 5 || 15 || 30 || 60 || 100 || 180 || 280 || 430 || 660 || 1000 || 1520 || 2160 || 2960 || 3960 || 5200 || 6760 || 8760 || 11160 || 13900 || 17000 || 21000 || 26600 || 33800 || 42600 || 53000 || 65000 || 78600 || 93800 || 110600 || 129000 || 149000 || 170600 || 193800 || 218600 || 245000 || 273000 || 302600 || 333800 || 366600 || 401000 || 435550 || 470250 || 505100 || 540100 || 575600 || 611600 || 648100 || 685100 || 722600 || 760600 || 799100 || 838100 || 877600 || 917600 || 957600 || 997600 || 1037600 || 1077600 || 1117600 || 1157600 || 1197600 || 1237600 || 1277600 || 1317600 || 1357600 || 1397600 || 1437600 || 1477600 || 1517600 || 1557600 || 1597600 || 1637600 || 1677600 || 1717600 || 1757600 || 1797600 || 1837600 || 1877600 || 1917600 || 1957600 || 1997600 || 2037600 || 2077600 || 2117600 || 2157600 || 2197600 || 2237600 || 2277600 || 2317600 || 2357600 || 2397600 || 2437600 || 2477600 || 2517600 || 2557600 || 2597600 || 2637600 || 2677600
|-
| 13 || 0 || 5 || 15 || 30 || 60 || 100 || 180 || 280 || 430 || 660 || 1000 || 1520 || 2160 || 2960 || 3960 || 5200 || 6760 || 8760 || 11160 || 13900 || 17000 || 21000 || 26600 || 33800 || 42600 || 53000 || 65000 || 78600 || 93800 || 110600 || 129000 || 149000 || 170600 || 193800 || 218600 || 245000 || 273000 || 302600 || 333800 || 366600 || 401000 || 436800 || 474000 || 512600 || 552600 || 593600 || 635600 || 678600 || 722600 || 767600 || 813600 || 860600 || 908600 || 957600 || 1007600 || 1057600 || 1107600 || 1157600 || 1207600 || 1257600 || 1307600 || 1357600 || 1407600 || 1457600 || 1507600 || 1557600 || 1607600 || 1657600 || 1707600 || 1757600 || 1807600 || 1857600 || 1907600 || 1957600 || 2007600 || 2057600 || 2107600 || 2157600 || 2207600 || 2257600 || 2307600 || 2357600 || 2407600 || 2457600 || 2507600 || 2557600 || 2607600 || 2657600 || 2707600 || 2757600 || 2807600 || 2857600 || 2907605 || 2957600 || 3007600 || 3057600 || 3107600 || 3157600 || 3207600
|-
| 14 || 0 || 5 || 15 || 30 || 60 || 100 || 180 || 280 || 430 || 660 || 1000 || 1520 || 2160 || 2960 || 3960 || 5200 || 6760 || 8760 || 11160 || 13900 || 17000 || 21000 || 27000 || 35000 || 45000 || 57000 || 71000 || 87000 || 105000 || 125000 || 147000 || 171000 || 197000 || 225000 || 255000 || 287000 || 321000 || 357000 || 395000 || 435000 || 477000 || 519750 || 563250 || 607500 || 652500 || 697000 || 741000 || 784500 || 827500 || 870000 || 912000 || 953500 || 994500 || 1035000 || 1075000 || 1115000 || 1155000 || 1195000 || 1235000 || 1275000 || 1315000 || 1355000 || 1395000 || 1435000 || 1475000 || 1515000 || 1555000 || 1595000 || 1635000 || 1675000 || 1715000 || 1755000 || 1795000 || 1835000 || 1875000 || 1915000 || 1955000 || 1995000 || 2035000 || 2075000 || 2115000 || 2155000 || 2195000 || 2235000 || 2275000 || 2315000 || 2355000 || 2395000 || 2435000 || 2475000 || 2515000 || 2555000 || 2595000 || 2635000 || 2675000 || 2715000 || 2755000 || 2795000 || 2835000
|-
| 15 || 0 || 5 || 15 || 30 || 60 || 100 || 180 || 280 || 430 || 660 || 1000 || 1520 || 2160 || 2960 || 3960 || 5200 || 6760 || 8760 || 11160 || 13900 || 17000 || 21000 || 27000 || 35000 || 45000 || 57000 || 71000 || 87000 || 105000 || 125000 || 147000 || 171000 || 197000 || 225000 || 255000 || 285500 || 316500 || 348000 || 380000 || 412500 || 445500 || 479000 || 513000 || 547500 || 582500 || 619000 || 657000 || 696500 || 737500 || 780000 || 824000 || 869500 || 916500 || 965000 || 1015000 || 1066000 || 1118000 || 1171000 || 1225000 || 1280000 || 1336000 || 1393000 || 1451000 || 1510000 || 1570000 || 1630000 || 1690000 || 1750000 || 1809744 || 1870000 || 1930000 || 1990000 || 2050000 || 2110000 || 2170000 || 2230000 || 2290000 || 2350000 || 2410000 || 2470000 || 2530000 || 2590000 || 2650000 || 2710000 || 2770000 || 2830000 || 2890000 || 2950000 || 3010000 || 3070000 || 3130000 || 3190000 || 3250000 || 3310000 || 3370000 || 3430000 || 3490000 || 3550000 || 3610000
|-
| 16 || 0 || 10 || 30 || 60 || 120 || 220 || 360 || 560 || 860 || 1320 || 2000 || 3040 || 4320 || 5920 || 7920 || 10400 || 13520 || 17520 || 22320 || 27800 || 34000 || 42000 || 51000 || 61000 || 72000 || 84000 || 97000 || 111000 || 126000 || 142000 || 159800 || 179400 || 200800 || 224000 || 249000 || 275000 || 302000 || 330000 || 359000 || 389000 || 420000 || 452000 || 485000 || 519000 || 554000 || 590500 || 628500 || 668000 || 709000 || 751500 || 795500 || 841000 || 888000 || 936500 || 986500 || 1038500 || 1092500 || 1148500 || 1206500 || 1266500 || 1328500 || 1392500 || 1458500 || 1526500 || 1596500 || 1666500 || 1736500 || 1806500 || 1876500 || 1946500 || 2016500 || 2086500 || 2156500 || 2226500 || 2296500 || 2366500 || 2436500 || 2506500 || 2576500 || 2646500 || 2716500 || 2786500 || 2856500 || 2926500 || 2996500 || 3066500 || 3136500 || 3206500 || 3276500 || 3346500 || 3416500 || 3486500 || 3556500 || 3626500 || 3696500 || 3766500 || 3836500 || 3906500 || 3976500
|-
| 17 || 0 || 10 || 30 || 60 || 120 || 220 || 360 || 560 || 860 || 1320 || 2000 || 3040 || 4320 || 5920 || 7920 || 10400 || 13520 || 17520 || 22320 || 27800 || 34000 || 42000 || 51000 || 61000 || 72000 || 84000 || 97000 || 111000 || 126000 || 142000 || 159800 || 179400 || 200800 || 224000 || 249000 || 275500 || 303500 || 333000 || 364000 || 396500 || 430500 || 466000 || 503000 || 541500 || 581500 || 623500 || 667500 || 713500 || 761500 || 811500 || 863500 || 917500 || 973500 || 1031500 || 1091500 || 1152500 || 1214500 || 1277500 || 1341500 || 1406500 || 1472500 || 1539500 || 1607500 || 1676500 || 1746500 || 1816500 || 1886500 || 1956500 || 2026500 || 2096500 || 2166516 || 2236500 || 2306500 || 2376500 || 2446500 || 2516500 || 2586500 || 2656500 || 2726500 || 2796500 || 2866500 || 2936500 || 3006500 || 3076500 || 3146500 || 3216500 || 3286500 || 3356500 || 3426500 || 3496500 || 3566500 || 3636500 || 3706500 || 3776500 || 3846500 || 3916500 || 3986500 || 4056500 || 4126500
|-
| 18 || 0 || 10 || 30 || 60 || 120 || 220 || 360 || 560 || 860 || 1320 || 2000 || 3040 || 4320 || 5920 || 7920 || 10400 || 13520 || 17520 || 22320 || 27800 || 34000 || 42000 || 52400 || 65200 || 80400 || 98000 || 118000 || 140400 || 165200 || 192400 || 222000 || 254000 || 288400 || 325200 || 364400 || 405600 || 448400 || 492400 || 537200 || 582800 || 629200 || 676400 || 724400 || 773400 || 823400 || 874400 || 926400 || 979400 || 1033400 || 1088400 || 1144400 || 1201400 || 1259400 || 1318400 || 1378400 || 1439400 || 1501400 || 1564400 || 1628400 || 1693400 || 1759400 || 1826400 || 1894400 || 1963400 || 2033400 || 2103400 || 2173400 || 2243400 || 2313400 || 2383400 || 2453400 || 2523400 || 2593400 || 2663400 || 2733400 || 2803400 || 2873400 || 2943400 || 3013400 || 3083400 || 3153400 || 3223400 || 3293400 || 3363400 || 3433400 || 3503400 || 3573400 || 3643400 || 3713400 || 3783400 || 3853400 || 3923400 || 3993400 || 4063400 || 4133400 || 4203400 || 4273400 || 4343400 || 4413400
|-
| 19 || 0 || 10 || 30 || 60 || 120 || 220 || 360 || 560 || 860 || 1320 || 2000 || 3040 || 4320 || 5920 || 7920 || 10400 || 13520 || 17520 || 22320 || 27800 || 34000 || 42000 || 52400 || 65200 || 80400 || 98000 || 118000 || 140400 || 165200 || 192400 || 222000 || 254000 || 288400 || 325200 || 364400 || 406000 || 450000 || 496400 || 545200 || 596400 || 650000 || 706000 || 770000 || 842000 || 922000 || 1010000 || 1106000 || 1210000 || 1322000 || 1442000 || 1562000 || 1682000 || 1802000 || 1922000 || 2042000 || 2162000 || 2282000 || 2402000 || 2522000 || 2642000 || 2762000 || 2882000 || 3002000 || 3122000 || 3242000 || 3362000 || 3482000 || 3602000 || 3722000 || 3842000 || 3962000 || 4082000 || 4202000 || 4322000 || 4442000 || 4562000 || 4682000 || 4802000 || 4922000 || 5042000 || 5162000 || 5282000 || 5402000 || 5522000 || 5642000 || 5762000 || 5882000 || 6002000 || 6122000 || 6242000 || 6362000 || 6482000 || 6602000 || 6722000 || 6842000 || 6962000 || 7082000 || 7202000 || 7322000
|-
| 20 || 0 || 10 || 30 || 60 || 120 || 220 || 360 || 560 || 860 || 1320 || 2000 || 3040 || 4320 || 5920 || 7920 || 10400 || 13520 || 17520 || 22320 || 27800 || 34000 || 42000 || 52500 || 65500 || 81000 || 99000 || 120000 || 144000 || 171000 || 201000 || 233000 || 267000 || 303000 || 341000 || 381000 || 422000 || 464000 || 507000 || 551000 || 596000 || 642000 || 689000 || 737000 || 786000 || 836000 || 887000 || 939000 || 992000 || 1046000 || 1101000 || 1157000 || 1214000 || 1272000 || 1331000 || 1391000 || 1452000 || 1514000 || 1577000 || 1641000 || 1706000 || 1772000 || 1839000 || 1907000 || 1976000 || 2046000 || 2116000 || 2186000 || 2256000 || 2326000 || 2396000 || 2466000 || 2536000 || 2606000 || 2676000 || 2746000 || 2816000 || 2886000 || 2956000 || 3026000 || 3096000 || 3166000 || 3236000 || 3306000 || 3376000 || 3446000 || 3516000 || 3586000 || 3656000 || 3726000 || 3796000 || 3866000 || 3936000 || 4006000 || 4076000 || 4146000 || 4216000 || 4286000 || 4356000 || 4426000
|-
| 21 || 0 || 10 || 30 || 60 || 120 || 220 || 360 || 560 || 860 || 1320 || 2000 || 3040 || 4320 || 5920 || 7920 || 10400 || 13520 || 17520 || 22320 || 27800 || 34000 || 42000 || 53200 || 67600 || 85200 || 106000 || 130000 || 156000 || 184000 || 214000 || 246000 || 280000 || 316000 || 354000 || 394000 || 436000 || 480000 || 526000 || 574000 || 624000 || 676000 || 730000 || 786000 || 844000 || 904000 || 965000 || 1027000 || 1090000 || 1154000 || 1219000 || 1285000 || 1352000 || 1420000 || 1489000 || 1559000 || 1630000 || 1702000 || 1775000 || 1849000 || 1924000 || 2000000 || 2077000 || 2155000 || 2234000 || 2314000 || 2394000 || 2474000 || 2554000 || 2634000 || 2714000 || 2794000 || 2874000 || 2954000 || 3034000 || 3114000 || 3194000 || 3274000 || 3354000 || 3434000 || 3514000 || 3594000 || 3674000 || 3754000 || 3834000 || 3914000 || 3994000 || 4074000 || 4154000 || 4234000 || 4314000 || 4394000 || 4474000 || 4554000 || 4634000 || 4714000 || 4794000 || 4874000 || 4954000 || 5034000
|-
| 22 || 0 || 10 || 30 || 60 || 120 || 220 || 360 || 560 || 860 || 1320 || 2000 || 3040 || 4320 || 5920 || 7920 || 10400 || 13520 || 17520 || 22320 || 27800 || 34000 || 42000 || 54000 || 70000 || 90000 || 112000 || 136000 || 162000 || 190000 || 220000 || 252000 || 286000 || 322000 || 360000 || 400000 || 441000 || 483000 || 526000 || 570000 || 615000 || 661000 || 708000 || 756000 || 805000 || 855000 || 906000 || 958000 || 1011000 || 1065000 || 1120000 || 1176000 || 1233000 || 1291000 || 1350000 || 1410000 || 1470000 || 1530000 || 1590000 || 1650000 || 1710000 || 1770000 || 1830000 || 1890000 || 1950000 || 2010000 || 2070000 || 2130000 || 2190000 || 2250000 || 2310000 || 2370000 || 2430000 || 2490000 || 2550000 || 2610000 || 2670000 || 2730000 || 2790000 || 2850000 || 2910000 || 2970000 || 3030000 || 3090000 || 3150000 || 3210000 || 3270000 || 3330000 || 3390000 || 3450000 || 3510000 || 3570000 || 3630000 || 3690000 || 3750000 || 3810000 || 3870000 || 3930000 || 3990000 || 4050000
|-
| 23 || 0 || 10 || 30 || 60 || 120 || 220 || 360 || 560 || 860 || 1320 || 2000 || 3040 || 4320 || 5920 || 7920 || 10400 || 13520 || 17520 || 22320 || 27800 || 34000 || 42000 || 54000 || 70000 || 90000 || 113000 || 139000 || 168000 || 200000 || 235000 || 273000 || 314000 || 358000 || 405000 || 455000 || 506000 || 558000 || 611000 || 665000 || 720000 || 776000 || 833000 || 891000 || 950000 || 1010000 || 1070000 || 1130000 || 1190000 || 1250000 || 1310000 || 1370000 || 1430000 || 1490000 || 1550000 || 1610000 || 1671000 || 1733000 || 1796000 || 1860000 || 1925000 || 1991000 || 2058000 || 2126000 || 2195000 || 2265000 || 2335000 || 2405000 || 2475000 || 2545000 || 2615000 || 2685000 || 2755000 || 2825000 || 2895000 || 2965000 || 3035000 || 3105000 || 3175000 || 3245000 || 3315000 || 3385000 || 3455000 || 3525000 || 3595000 || 3665000 || 3735000 || 3805000 || 3875000 || 3945000 || 4015000 || 4085000 || 4155000 || 4225000 || 4295000 || 4365000 || 4435000 || 4505000 || 4575000 || 4645000
|-
| 24 || 0 || 100 || 300 || 600 || 1200 || 2200 || 3600 || 5600 || 8600 || 13200 || 20000 || 30400 || 43200 || 59200 || 79200 || 101700 || 126700 || 152700 || 180700 || 210700 || 242700 || 276700 || 312700 || 350700 || 390700 || 431700 || 473700 || 516700 || 560700 || 605700 || 651700 || 698700 || 746700 || 795700 || 845700 || 895700 || 945700 || 995700 || 1045700 || 1095700 || 1145700 || 1195700 || 1245700 || 1295700 || 1345700 || 1396200 || 1447200 || 1498700 || 1550700 || 1603200 || 1656200 || 1709700 || 1763700 || 1818200 || 1873200 || 1929700 || 1987700 || 2047200 || 2108200 || 2170700 || 2234700 || 2300200 || 2367200 || 2435700 || 2505700 || 2575700 || 2645700 || 2715700 || 2785700 || 2855700 || 2925700 || 2995700 || 3065700 || 3135700 || 3205700 || 3275700 || 3345700 || 3415700 || 3485700 || 3555700 || 3625700 || 3695700 || 3776992 || 3835700 || 3905700 || 3975700 || 4045700 || 4115700 || 4185700 || 4255700 || 4325700 || 4395700 || 4465700 || 4535700 || 4605700 || 4675700 || 4745700 || 4815700 || 4885700
|-
| 25 || 0 || 100 || 300 || 600 || 1200 || 2200 || 3600 || 5600 || 8600 || 13200 || 20000 || 30400 || 43200 || 59200 || 79200 || 104200 || 134200 || 168200 || 205200 || 245200 || 287200 || 330200 || 374200 || 418700 || 463700 || 509200 || 555200 || 601700 || 648700 || 696200 || 744200 || 792700 || 841700 || 891200 || 941200 || 991700 || 1042700 || 1094200 || 1146200 || 1198700 || 1251700 || 1305200 || 1359200 || 1413700 || 1468700 || 1524200 || 1580200 || 1636700 || 1693700 || 1751200 || 1809200 || 1867700 || 1926700 || 1986200 || 2046200 || 2108200 || 2172200 || 2238200 || 2306200 || 2376200 || 2448200 || 2522200 || 2598200 || 2676200 || 2756200 || 2836200 || 2916200 || 2996200 || 3076200 || 3156200 || 3236200 || 3316200 || 3396200 || 3476200 || 3556200 || 3636200 || 3716200 || 3796200 || 3876200 || 3956200 || 4036200 || 4116200 || 4196200 || 4276200 || 4356200 || 4436200 || 4516200 || 4596200 || 4676200 || 4756200 || 4836200 || 4916200 || 4996200 || 5076200 || 5156200 || 5236200 || 5316200 || 5396200 || 5476200
|-
| 26 || 0 || 100 || 300 || 600 || 1200 || 2200 || 3600 || 5600 || 8600 || 13200 || 20000 || 30400 || 43200 || 59200 || 79200 || 104200 || 134200 || 168200 || 205200 || 245200 || 288200 || 333200 || 380200 || 429200 || 479200 || 529700 || 580700 || 632200 || 684200 || 736700 || 789700 || 843200 || 897200 || 951700 || 1006700 || 1062200 || 1118200 || 1174700 || 1231700 || 1289200 || 1347200 || 1405700 || 1464700 || 1524200 || 1584200 || 1644200 || 1704200 || 1764200 || 1824200 || 1884200 || 1944200 || 2004200 || 2064200 || 2124200 || 2184200 || 2245200 || 2307200 || 2370200 || 2434200 || 2499200 || 2565200 || 2632200 || 2700200 || 2769200 || 2839200 || 2909200 || 2979200 || 3049200 || 3119200 || 3189200 || 3259200 || 3329200 || 3399200 || 3469200 || 3539200 || 3609208 || 3679200 || 3749200 || 3819200 || 3889200 || 3959200 || 4029200 || 4099200 || 4169200 || 4239200 || 4309200 || 4379200 || 4449200 || 4519200 || 4589200 || 4659200 || 4729200 || 4799200 || 4869200 || 4939200 || 5009200 || 5079200 || 5149200 || 5219200
|-
| 27 || 0 || 100 || 300 || 600 || 1200 || 2200 || 3600 || 5600 || 8600 || 13200 || 20000 || 30400 || 44400 || 62400 || 84400 || 111400 || 143400 || 181400 || 225400 || 275400 || 325400 || 375400 || 425400 || 475400 || 525400 || 575900 || 626900 || 678400 || 730400 || 782900 || 835900 || 889400 || 943400 || 997900 || 1052900 || 1108400 || 1164400 || 1220900 || 1277900 || 1335400 || 1393400 || 1451900 || 1510900 || 1570400 || 1630400 || 1690900 || 1751900 || 1813400 || 1875400 || 1937900 || 2000900 || 2064400 || 2128400 || 2192900 || 2257900 || 2324400 || 2392400 || 2461900 || 2532900 || 2605400 || 2679400 || 2754900 || 2831900 || 2910400 || 2990400 || 3070400 || 3150400 || 3230400 || 3310400 || 3390400 || 3470400 || 3550400 || 3630400 || 3710400 || 3790400 || 3870400 || 3950400 || 4030400 || 4110400 || 4190400 || 4270400 || 4350400 || 4430400 || 4510400 || 4590400 || 4670400 || 4750400 || 4830400 || 4910400 || 4990400 || 5070400 || 5150400 || 5230400 || 5310400 || 5390400 || 5470400 || 5550400 || 5630400 || 5710400
|-
| 28 || 0 || 100 || 300 || 600 || 1200 || 2200 || 3600 || 5600 || 8600 || 13200 || 20000 || 30400 || 44400 || 62400 || 84400 || 111400 || 143400 || 181400 || 225400 || 275400 || 325400 || 375400 || 425400 || 475400 || 525400 || 575900 || 626900 || 678400 || 730400 || 782900 || 835900 || 889400 || 943400 || 997900 || 1052900 || 1108400 || 1164400 || 1220900 || 1277900 || 1335400 || 1393400 || 1451900 || 1510900 || 1570400 || 1630400 || 1691400 || 1753400 || 1816400 || 1880400 || 1945400 || 2011400 || 2078400 || 2146400 || 2215400 || 2285400 || 2356400 || 2428400 || 2501400 || 2575400 || 2650400 || 2726400 || 2803400 || 2881400 || 2960400 || 3040400 || 3120400 || 3200400 || 3280400 || 3360400 || 3440400 || 3520400 || 3600400 || 3680400 || 3760400 || 3840400 || 3920400 || 4000400 || 4080400 || 4160400 || 4240400 || 4320400 || 4400400 || 4480400 || 4560400 || 4640400 || 4720400 || 4800400 || 4880400 || 4960400 || 5040400 || 5120400 || 5200400 || 5280400 || 5360400 || 5440400 || 5520400 || 5600400 || 5680400 || 5760400
|-
| 29 || 0 || 100 || 300 || 600 || 1200 || 2200 || 3600 || 5600 || 8600 || 13200 || 20000 || 30400 || 44400 || 62400 || 84400 || 111400 || 143400 || 181400 || 225400 || 275400 || 325400 || 375400 || 425400 || 475400 || 525400 || 575900 || 626900 || 678400 || 730400 || 782900 || 835900 || 889400 || 943400 || 997900 || 1052900 || 1108400 || 1164400 || 1220900 || 1277900 || 1335400 || 1393400 || 1451900 || 1510900 || 1570400 || 1630400 || 1692400 || 1756400 || 1822400 || 1890400 || 1960400 || 2032400 || 2106400 || 2182400 || 2260400 || 2340400 || 2422400 || 2506400 || 2592400 || 2680400 || 2770400 || 2862400 || 2956400 || 3052400 || 3150400 || 3250400 || 3350400 || 3450400 || 3550400 || 3650400 || 3750400 || 3850400 || 3950400 || 4050400 || 4150400 || 4250400 || 4350400 || 4450400 || 4550400 || 4650400 || 4750400 || 4850400 || 4950400 || 5050400 || 5150400 || 5250400 || 5350400 || 5450400 || 5550400 || 5650400 || 5750400 || 5850400 || 5950400 || 6050400 || 6150400 || 6250400 || 6350400 || 6450400 || 6550400 || 6650400
|-
| 30 || 0 || 100 || 300 || 600 || 1200 || 2200 || 3600 || 5600 || 8600 || 13200 || 20000 || 30400 || 44400 || 62400 || 84400 || 111400 || 143400 || 181400 || 225400 || 275400 || 325400 || 375400 || 425400 || 475400 || 525400 || 576400 || 628400 || 681400 || 735392 || 790400 || 846400 || 903400 || 961400 || 1020400 || 1080400 || 1141400 || 1203400 || 1266400 || 1330400 || 1395400 || 1461400 || 1528400 || 1596400 || 1665400 || 1735400 || 1806400 || 1878400 || 1951400 || 2025400 || 2100400 || 2176400 || 2253400 || 2331400 || 2410400 || 2490400 || 2572400 || 2656400 || 2742400 || 2830400 || 2920400 || 3012400 || 3106400 || 3202400 || 3300400 || 3400400 || 3500400 || 3600400 || 3700400 || 3800400 || 3900400 || 4000400 || 4100400 || 4200400 || 4300400 || 4400400 || 4500400 || 4600400 || 4700400 || 4800400 || 4900400 || 5000400 || 5100400 || 5200400 || 5300400 || 5400400 || 5500400 || 5600400 || 5700400 || 5800400 || 5900400 || 6000400 || 6100400 || 6200400 || 6300400 || 6400400 || 6500400 || 6600400 || 6700400 || 6800400
|-
| 31 || 0 || 100 || 300 || 600 || 1200 || 2200 || 3600 || 5600 || 8600 || 13200 || 20000 || 30400 || 44400 || 62400 || 84400 || 111400 || 143400 || 181400 || 225400 || 275400 || 327400 || 381400 || 437400 || 495400 || 555400 || 616400 || 678400 || 741400 || 805400 || 870400 || 936400 || 1003400 || 1071400 || 1140400 || 1210400 || 1281400 || 1353400 || 1426400 || 1500400 || 1575400 || 1651400 || 1728400 || 1806400 || 1885400 || 1965400 || 2046400 || 2128400 || 2211400 || 2295400 || 2380400 || 2466400 || 2553400 || 2641400 || 2730400 || 2820400 || 2911400 || 3003400 || 3096400 || 3190400 || 3285400 || 3381400 || 3478400 || 3576400 || 3675400 || 3775400 || 3875400 || 3975400 || 4075400 || 4175400 || 4275400 || 4375400 || 4475400 || 4575400 || 4675400 || 4775400 || 4875400 || 4975400 || 5075400 || 5175400 || 5275400 || 5375400 || 5475400 || 5575400 || 5675400 || 5775400 || 5875400 || 5975400 || 6075400 || 6175400 || 6275400 || 6375400 || 6475400 || 6575400 || 6675400 || 6775400 || 6875400 || 6975400 || 7075400 || 7175400
|}
</div>

==Bank 14==
===Load Enemy stats===
 RO14:4849 D5               push de
 RO14:484A FA 12 DA         ld   a,(DA12)
 RO14:484D 4F               ld   c,a
 RO14:484E FA 13 DA         ld   a,(DA13)
 RO14:4851 47               ld   b,a        ;bc = enemy_stats_id
 RO14:4852 3E 19            ld   a,19
 RO14:4854 CD E6 1D         call 1DE6
 RO14:4857 7D               ld   a,l        ;hl = enemy_stats_id × 25
 RO14:4858 C6 1D            add  a,1D
 RO14:485A 6F               ld   l,a
 RO14:485B 7C               ld   a,h
 RO14:485C CE 4C            adc  a,4C       ;0x4C1D + (enemy_stats_id × 25)
 RO14:485E 67               ld   h,a        ;hl = pointer_to_enemy_stats
 RO14:485F D1               pop  de
 RO14:4860 06 19            ld   b,19       ;b = 25
 RO14:4862 2A               ldi  a,(hl)     ;a = current_enemy_stat_byte
 RO14:4863 12               ld   (de),a     ;Write current_enemy_stat_byte in [de]
 RO14:4864 13               inc  de
 RO14:4865 05               dec  b
 RO14:4866 20 FA            jr   nz,4862    ;loop 25 times
 RO14:4868 C9               ret

===Retrieve next Monster stats ID in scripted battles with multiple Monsters===
*<code>0x50869</code> - Retrieve the next Monster stats ID in scripted battles with multiple Monsters
====Retrieve current Monster stats ID, and first value of the array====
 RO14:4869 FA 12 DA         ld   a,(DA12)
 RO14:486C 4F               ld   c,a
 RO14:486D FA 13 DA         ld   a,(DA13)
 RO14:4870 47               ld   b,a        ;bc = enemy_stats_id
 RO14:4871 21 93 48         ld   hl,4893
 RO14:4874 2A               ldi  a,(hl)     ;loop_start
 RO14:4875 5F               ld   e,a
 RO14:4876 2A               ldi  a,(hl)
 RO14:4877 57               ld   d,a        ;de 
 RO14:4878 A3               and  e
 RO14:4879 FE FF            cp   a,FF
 RO14:487B 20 01            jr   nz,487E    ;if it's not the last entry of the array, jump to next subroutine
 RO14:487D C9               ret  

====Check if Monster stat ID in array is equal to the current one, if yes retrieve next Monster stats ID====
 RO14:487E 7B               ld   a,e
 RO14:487F B9               cp   c
 RO14:4880 20 0D            jr   nz,488F
 RO14:4882 7A               ld   a,d
 RO14:4883 B8               cp   b
 RO14:4884 20 09            jr   nz,488F    ;if(current_enemy_stats_id
 RO14:4886 2A               ldi  a,(hl)
 RO14:4887 EA 12 DA         ld   (DA12),a   ;Write next enemy_stats_id in wDA12
 RO14:488A 2A               ldi  a,(hl)
 RO14:488B EA 13 DA         ld   (DA13),a
 RO14:488E C9               ret  

====Goes to the next value in array, loop back to first subroutine====
 RO14:488F 23               inc  hl
 RO14:4890 23               inc  hl
 RO14:4891 18 E1            jr   4874       ;loop to 14:4874

====Array of Monster stats IDs for scripted battles with multiple Monsters====
 RO14:4893
 68 Monster stats IDs on 2 bytes
 
===Enemy stats array===
*<code>0x501CD</code> - Enemy stats array, 25 bytes per Enemy stat. Note that it is different from Monster IDs, a same Monster can have different statistics for different encounters.
 RO14:4C1D
 aa bb cc dd ee ff ff gg gg hh hh ii ii jj jj kk kk ll mm nn oo pp qq rr ss
 aa - Monster ID
 bb - 
 cc - 
 dd - 
 ee - Level
 ff - HPs
 gg - MPs
 hh - ATK
 ii - DEF
 jj - AGL
 kk - INT
 ll - 
 mm - 
 nn - 
 oo - 
 pp - Skill 1
 qq - Skill 2
 rr - Skill 3
 ss - FF delimiter
 
 Example for Enemy stats ID 293, Metabble from 3rd battle of S Rank Arena:
 14:68BA
 11 00 00 07 26 0A 00 EA 01 6E 00 9E 02 FF 01 FF 00 FA FA FA 00 05 08 FF FF
 Monster ID: Metabble
 Level: 38
 HPs: 10
 MPs: 490
 ATK: 110
 DEF: 670
 AGL: 511
 INT: 255
 Skill 1: Firebolt
 Skill 2: Explodet
 Skill 3: -

== Bank 16 ==
=== Unevolved skill map ===
At ROM16:4874, an array of 256 bytes mapping a skill ID (as the array index) to the base skill ID in its evolution chain. Such as Blazemost mapping to Blaze. If an entry cannot be inherited, it maps to FF (this is only used for fake skills).

=== Breeding table ===
At ROM16:4b30, not entirely sure the purpose yet but it's involved in breeding. One purpose is that it can add additional pluses during the breeding, but all those fields are 0s, so this is an unused feature.

===Set counter before next random encounter===
 RO16:6E14 CD D0 12         call 12D0         ;PRNG: wC899 × 5 + 0x1357
 RO16:6E17 FA 99 C8         ld   a,(C899)
 RO16:6E1A 6F               ld   l,a
 RO16:6E1B FA 9A C8         ld   a,(C89A)
 RO16:6E1E 67               ld   h,a          ;hl = PRN
 RO16:6E1F 3E 65            ld   a,65
 RO16:6E21 CD 0D 1E         call 1E0D         ;a = hl % 101
 RO16:6E24 21 3D 6E         ld   hl,6E3D      ;hl = 6E3D
 RO16:6E27 BE               cp   (hl)         ;loop start
 RO16:6E28 28 08            jr   z,6E32
 RO16:6E2A 38 06            jr   c,6E32       ;if(a ≤ [hl]), skip to 16:6E32
 RO16:6E2C 23               inc  hl
 RO16:6E2D 23               inc  hl
 RO16:6E2E 23               inc  hl
 RO16:6E2F 23               inc  hl           ;hl += 4
 RO16:6E30 18 F5            jr   6E27         ;loop to 16:6E27
 RO16:6E32 23               inc  hl
 RO16:6E33 23               inc  hl           ;hl += 2
 RO16:6E34 2A               ldi  a,(hl)
 RO16:6E35 EA 39 CA         ld   (CA39),a     ;Write counter_before_random_encounter in wCA39
 RO16:6E38 2A               ldi  a,(hl)
 RO16:6E39 EA 3A CA         ld   (CA3A),a
 RO16:6E3C C9               ret

====counter_before_random_encounter array====
* <code>0x5AE3D</code> - array of counters before next random encounter
 RO16:6E3D
 aa 00 bb bb
 aa - PRN range to select this counter
 bb - counter_before_random_encounter
 
 02 00 4C 04 - 3/101 - 1,100
 04 00 B0 04 - 2/101 - 1,200
 06 00 14 05 - 2/101 - 1,300
 08 00 78 05 - 2/101 - 1,400
 0A 00 DC 05 - 2/101 - 1,500
 0C 00 40 06 - 2/101 - 1,600
 0E 00 A4 06 - 2/101 - 1,700
 10 00 08 07 - 2/101 - 1,800
 12 00 6C 07 - 2/101 - 1,900
 14 00 D0 07 - 2/101 - 2,000
 16 00 34 08 - 2/101 - 2,100
 18 00 98 08 - 2/101 - 2,200
 1A 00 FC 08 - 2/101 - 2,300
 1C 00 60 09 - 2/101 - 2,400
 1E 00 C4 09 - 2/101 - 2,500
 20 00 28 0A - 2/101 - 2,600
 22 00 8C 0A - 2/101 - 2,700
 24 00 F0 0A - 2/101 - 2,800
 26 00 54 0B - 2/101 - 2,900
 28 00 B8 0B - 2/101 - 3,000
 2A 00 1C 0C - 2/101 - 3,100
 2C 00 80 0C - 2/101 - 3,200
 2E 00 E4 0C - 2/101 - 3,300
 30 00 48 0D - 2/101 - 3,400
 32 00 AC 0D - 2/101 - 3,500
 34 00 10 0E - 2/101 - 3,600
 36 00 74 0E - 2/101 - 3,700
 38 00 D8 0E - 2/101 - 3,800
 3A 00 3C 0F - 2/101 - 3,900
 3C 00 A0 0F - 2/101 - 4,000
 3E 00 04 10 - 2/101 - 4,100
 40 00 68 10 - 2/101 - 4,200
 42 00 CC 10 - 2/101 - 4,300
 44 00 30 11 - 2/101 - 4,400
 46 00 94 11 - 2/101 - 4,500
 48 00 F8 11 - 2/101 - 4,600
 4A 00 5C 12 - 2/101 - 4,700
 4C 00 C0 12 - 2/101 - 4,800
 4E 00 24 13 - 2/101 - 4,900
 50 00 88 13 - 2/101 - 5,000
 52 00 EC 13 - 2/101 - 5,100
 54 00 50 14 - 2/101 - 5,200
 56 00 B4 14 - 2/101 - 5,300
 58 00 18 15 - 2/101 - 5,400
 5A 00 7C 15 - 2/101 - 5,500
 5C 00 E0 15 - 2/101 - 5,600
 5E 00 44 16 - 2/101 - 5,700
 60 00 A8 16 - 2/101 - 5,800
 62 00 0C 17 - 2/101 - 5,900
 FF 00 70 17 - 2/101 - 6,000

===Determine if there's a random encounter===
 RO16:6F5F 2A               ldi  a,(hl)
 RO16:6F60 46               ld   b,(hl)
 RO16:6F61 4F               ld   c,a
 RO16:6F62 C5               push bc
 RO16:6F63 21 0D 01         ld   hl,010D
 RO16:6F66 D7               rst  10
 RO16:6F67 21 2B 70         ld   hl,702B
 RO16:6F6A FA A9 C8         ld   a,(C8A9)
 RO16:6F6D 85               add  l
 RO16:6F6E 6F               ld   l,a
 RO16:6F6F 3E 00            ld   a,00
 RO16:6F71 8C               adc  h
 RO16:6F72 67               ld   h,a
 RO16:6F73 7E               ld   a,(hl)
 RO16:6F74 C1               pop  bc
 RO16:6F75 CD E6 1D         call 1DE6       ;hl = bc × a
 RO16:6F78 3E 40            ld   a,40       ;a = 64
 RO16:6F7A CD 1E 1E         call 1E1E       ;
 RO16:6F7D 5D               ld   e,l
 RO16:6F7E 54               ld   d,h        ;de = random_encounter_rate
 RO16:6F7F FA 39 CA         ld   a,(CA39)
 RO16:6F82 6F               ld   l,a
 RO16:6F83 FA 3A CA         ld   a,(CA3A)
 RO16:6F86 67               ld   h,a        ;hl = counter_before_random_encounter
 RO16:6F87 7D               ld   a,l
 RO16:6F88 93               sub  e
 RO16:6F89 6F               ld   l,a
 RO16:6F8A 7C               ld   a,h
 RO16:6F8B 9A               sbc  d          ;counter_before_random_encounter - random_encounter_rate
 RO16:6F8C 67               ld   h,a
 RO16:6F8D 30 13            jr   nc,6FA2    ;if there's no carry after counter_before_random_encounter - random_encounter_rate, skip to 16:6FA2
 RO16:6F8F 21 0B 01         ld   hl,010B
 RO16:6F92 D7               rst  10         ;generate a random encounter
 RO16:6F93 21 EB C8         ld   hl,C8EB
 RO16:6F96 CB F6            set  6,(hl)
 RO16:6F98 AF               xor  a
 RO16:6F99 EA 05 C9         ld   (C905),a
 RO16:6F9C 3E 00            ld   a,00
 RO16:6F9E EA 09 DA         ld   (DA09),a
 RO16:6FA1 C9               ret

==Load floor data for current gate?==
 RO16:5B76 FA 35 C9         ld   a,(C935)
 RO16:5B79 87               add  a
 RO16:5B7A 87               add  a
 RO16:5B7B 87               add  a
 RO16:5B7C 21 A6 70         ld   hl,70A6     ;hl = pointer to gate floor data?
 RO16:5B7F 85               add  l
 RO16:5B80 6F               ld   l,a
 RO16:5B81 3E 00            ld   a,00
 RO16:5B83 8C               adc  h
 RO16:5B84 67               ld   h,a
 RO16:5B85 2A               ldi  a,(hl)
 RO16:5B86 EA 36 C9         ld   (C936),a
 RO16:5B89 2A               ldi  a,(hl)
 RO16:5B8A EA 37 C9         ld   (C937),a
 RO16:5B8D 2A               ldi  a,(hl)
 RO16:5B8E EA 38 C9         ld   (C938),a
 RO16:5B91 E5               push hl
 RO16:5B92 2A               ldi  a,(hl)
 RO16:5B93 EA 3A C9         ld   (C93A),a
 RO16:5B96 2A               ldi  a,(hl)
 RO16:5B97 EA 3B C9         ld   (C93B),a
 RO16:5B9A 23               inc  hl
 RO16:5B9B 23               inc  hl
 RO16:5B9C 7E               ld   a,(hl)
 RO16:5B9D EA 3C C9         ld   (C93C),a
 RO16:5BA0 E1               pop  hl
 RO16:5BA1 FA 39 C9         ld   a,(C939)     ;a = current_floor
 RO16:5BA4 47               ld   b,a
 RO16:5BA5 3C               inc  a
 RO16:5BA6 BE               cp   (hl)
 RO16:5BA7 28 38            jr   z,5BE1       ;if(current_floor == last_floor), jump to 16:5BE1 - Load Gate's Boss floor
 RO16:5BA9 FA 35 C9         ld   a,(C935)
 RO16:5BAC B7               or   a
 RO16:5BAD 28 10            jr   z,5BBF
 RO16:5BAF FA 99 C8         ld   a,(C899)
 RO16:5BB2 CB 67            bit  4,a
 RO16:5BB4 28 09            jr   z,5BBF
 RO16:5BB6 3E 03            ld   a,03
 RO16:5BB8 CD FB 1D         call 1DFB
 RO16:5BBB FE 02            cp   a,02
 RO16:5BBD 28 5D            jr   z,5C1C
 RO16:5BBF FA 36 C9         ld   a,(C936)
 RO16:5BC2 87               add  a
 RO16:5BC3 87               add  a
 RO16:5BC4 87               add  a
 RO16:5BC5 87               add  a
 RO16:5BC6 21 A6 71         ld   hl,71A6
 RO16:5BC9 85               add  l
 RO16:5BCA 6F               ld   l,a
 RO16:5BCB 3E 00            ld   a,00
 RO16:5BCD 8C               adc  h
 RO16:5BCE 67               ld   h,a
 RO16:5BCF CD C0 5F         call 5FC0
 RO16:5BD2 EA 36 C9         ld   (C936),a
 RO16:5BD5 FA 36 C9         ld   a,(C936)
 RO16:5BD8 EA 68 C9         ld   (C968),a
 RO16:5BDB 3E 01            ld   a,01
 RO16:5BDD EA 69 C9         ld   (C969),a
 RO16:5BE0 C9               ret

===Load Gate's Boss floor===
 RO16:5BE1 FA 35 C9         ld   a,(C935)     ;a = current_gate
 RO16:5BE4 87               add  a
 RO16:5BE5 87               add  a
 RO16:5BE6 87               add  a            ;a = current_gate × 8
 RO16:5BE7 21 AA 70         ld   hl,70AA
 RO16:5BEA 85               add  l
 RO16:5BEB 6F               ld   l,a
 RO16:5BEC 3E 00            ld   a,00
 RO16:5BEE 8C               adc  h
 RO16:5BEF 67               ld   h,a          ;hl = 0x70AA + (current_gate × 8)
 RO16:5BF0 2A               ldi  a,(hl)
 RO16:5BF1 EA 68 C9         ld   (C968),a     ;Writes the 5th byte of the array to wC968
 RO16:5BF4 3E 00            ld   a,00
 RO16:5BF6 EA 69 C9         ld   (C969),a     ;Writes 0 to wC969
 RO16:5BF9 2A               ldi  a,(hl)       ;a = 6th byte of the array
 RO16:5BFA CB 37            swap a
 RO16:5BFC 47               ld   b,a
 RO16:5BFD E6 F0            and  a,F0
 RO16:5BFF F6 08            or   a,08
 RO16:5C01 EA 6F C9         ld   (C96F),a
 RO16:5C04 78               ld   a,b
 RO16:5C05 E6 0F            and  a,0F
 RO16:5C07 EA 70 C9         ld   (C970),a
 RO16:5C0A 2A               ldi  a,(hl)
 RO16:5C0B CB 37            swap a
 RO16:5C0D 47               ld   b,a
 RO16:5C0E E6 F0            and  a,F0
 RO16:5C10 F6 08            or   a,08
 RO16:5C12 EA 71 C9         ld   (C971),a
 RO16:5C15 78               ld   a,b
 RO16:5C16 E6 0F            and  a,0F
 RO16:5C18 EA 72 C9         ld   (C972),a
 RO16:5C1B C9               ret

===16:70A6 - Gate's Boss floor array===
 aa bb cc dd ee ff gg hh
 ee - Gate's last floor
 
 00 00 00 05 30 07 02 01 - Gate of Beginning
 01 01 01 05 31 01 06 01 - Gate of Villager
 01 01 02 06 32 05 01 01 - Gate of Talisman
 02 01 02 05 33 04 06 01 - Gate of Memories
 02 02 03 06 34 00 07 01 - Gate of Bewilder
 03 02 03 09 35 01 06 01
 03 02 04 08 36 05 01 02 - Gate of Peace
 03 03 04 09 37 05 07 02 - Gate of Bravery
 04 03 05 0C 38 08 03 02
 04 04 05 0B 39 02 01 02
 04 04 05 0B 3C 02 06 02
 04 04 06 0C 10 08 05 02
 05 06 06 0E 3B 04 01 02
 05 06 06 0F 3A 01 07 02
 05 06 07 10 3D 04 07 02
 06 07 07 12 3E 04 01 03
 07 07 08 14 3F 06 03 03
 07 05 08 13 40 04 06 03
 08 08 09 17 42 04 06 03 - Gate of Labyrinth (0x42 is Labyrinth room; actual Boss room is 0x60)
 08 09 09 19 43 05 05 03
 08 05 09 19 44 00 03 03
 09 0A 0A 1D 45 04 07 03
 0A 0B 0B 1E 46 05 06 03 - Gate of Ambition
 0A 0B 0B 1D 47 05 06 03
 0A 0B 0B 1B 48 04 07 03
 0B 0C 0C 1E 49 04 07 03
 0B 0C 0C 1E 4A 09 07 03
 0B 0D 0D 1E 4B 04 07 03
 0C 0D 0D 1E 4C 05 05 03
 0D 0E 0E 1B 4D 05 07 03 - Arena Right Gate
 0E 0E 0E 1E 4E 08 0C 03
 0F 0F 0F 63 4F 05 06 03 - Unused Gate, last floor 99

== Bank 41 ==
There's a table at ROM41:4007 which points to the various string tables stored in this bank.

=== Monster name tables ===
The monster name pointers start at ROM41:4339, size of 2x256, all pointing to within this bank. The monster names start at ROM41:5B1F and are back-to-back, each terminated by F0.

<pre>
00: DrakSlime
01: SpotSlime
02: WingSlime
03: TreeSlime
04: Snaily
05: SlimeNite
06: Babble
07: BoxSlime
08: Slime
09: Healer
0A: FangSlime
0B: RockSlime
0C: SlimeBorg
0D: Slabbit
0E: SpotKing
0F: KingSlime
10: Metaly
11: Metabble
12: MetalKing
13: GoldSlime
14: DragonKid
15: Tortragon
16: Pteranod
17: Gasgon
18: FairyDrak
19: LizardMan
1A: Poisongon
1B: Swordgon
1C: Dragon
1D: MiniDrak
1E: MadDragon
1F: Rayburn
20: Chamelgon
21: LizardFly
22: Andreal
23: KingCobra
24: Spikerous
25: GreatDrak
26: Crestpent
27: WingSnake
28: Coatol
29: Orochi
2A: BattleRex
2B: SkyDragon
2C: Divinegon
2D: Tonguella
2E: Almiraj
2F: CatFly
30: PillowRat
31: Saccer
32: GulpBeast
33: Skullroo
34: WindBeast
35: Anteater
36: SuperTen
37: IronTurt
38: Mommonja
39: HammerMan
3A: Grizzly
3B: Yeti
3C: MadGopher
3D: FairyRat
3E: Unicorn
3F: Goategon
40: WildApe
41: Trumpeter
42: KingLeo
43: DarkHorn
44: MadCat
45: BigEye
46: Picky
47: Wyvern
48: BullBird
49: Florajay
4A: DuckKite
4B: MadPecker
4C: MadRaven
4D: MistyWing
4E: Dracky
4F: BigRoost
50: StubBird
51: LandOwl
52: MadGoose
53: MadCondor
54: Blizzardy
55: Phoenix
56: ZapBird
57: WhipBird
58: FunkyBird
59: RainHawk
5A: MadPlant
5B: FireWeed
5C: FloraMan
5D: WingTree
5E: CactiBall
5F: Gulpple
60: Toadstool
61: AmberWeed
62: Stubsuck
63: Oniono
64: DanceVegi
65: TreeBoy
66: FaceTree
67: HerbMan
68: BeanMan
69: EvilSeed
6A: ManEater
6B: Snapper
6C: Rosevine
6D: Watabou
6E: GiantSlug
6F: Catapila
70: Gophecada
71: Butterfly
72: WeedBug
73: GiantWorm
74: Lipsy
75: StagBug
76: ArmyAnt
77: GoHopper
78: TailEater
79: ArmorPede
7A: Eyeder
7B: GiantMoth
7C: Droll
7D: ArmyCrab
7E: MadHornet
7F: HornBeet
80: Armorpion
81: Digster
82: Pixy
83: ArcDemon
84: AgDevil
85: Demonite
86: DarkEye
87: EyeBall
88: SkulRider
89: EvilBeast
8A: 1EyeClown
8B: Gremlin
8C: MedusaEye
8D: Lionex
8E: GoatHorn
8F: Orc
90: Ogre
91: GateGuard
92: ChopClown
93: Grendal
94: Akubar
95: MadKnight
96: Gigantes
97: Centasaur
98: EvilArmor
99: Jamirus
9A: Durran
9B: Spooky
9C: Skullgon
9D: Putrepup
9E: RotRaven
9F: Mummy
A0: DarkCrab
A1: DeadNite
A2: Shadow
A3: Hork
A4: Mudron
A5: NiteWhip
A6: MadSpirit
A7: WindMerge
A8: Reaper
A9: DeadNoble
AA: WhiteKing
AB: BoneSlave
AC: Skeletor
AD: Servant
AE: Copycat
AF: JewelBag
B0: EvilWand
B1: MadCandle
B2: CoilBird
B3: Facer
B4: SpikyBoy
B5: MadMirror
B6: RogueNite
B7: Goopi
B8: Voodoll
B9: MetalDrak
BA: Balzak
BB: SabreMan
BC: CurseLamp
BD: Roboster
BE: EvilPot
BF: Gismo
C0: LavaMan
C1: IceMan
C2: Mimic
C3: MudDoll
C4: Golem
C5: StoneMan
C6: BombCrag
C7: GoldGolem
C8: DracoLord
C9: DracoLord
CA: Hargon
CB: Sidoh
CC: Baramos
CD: Zoma
CE: Pizzaro
CF: Esterk
D0: Mirudraas
D1: Mirudraas
D2: Mudou
D3: DeathMore
D4: DeathMore
D5: DeathMore
D6: Darkdrium
D7: TERRY?
D8: Tatsu
D9: Diago
DA: Samsi
DB: Bazoo
DC-E0: 
E1-FF: ?????
</pre>

=== Skill name tables ===
The combat skill names start at ROM41:628E and are back-to-back, each terminated by F0.

<pre>
00: Blaze
01: Blazemore
02: Blazemost
03: Firebal
04: Firebane
05: Firebolt
06: Bang
07: Boom
08: Explodet
09: Infernos
0A: Infermore
0B: Infermost
0C: IceBolt
0D: SnowStorm
0E: Blizzard
0F: Bolt
10: Zap
11: Thordain
12: Beat
13: Defeat
14: Sacrifice
15: Sleep
16: SleepAll
17: StopSpell
18: Surround
19: PanicAll
1A: RobMagic
1B: TakeMagic
1C: Sap
1D: Defence
1E: Upper
1F: Increase
20: Slow
21: SlowAll
22: Speed
23: SpeedUp
24: Barrier
25: TwinHits
26: MagicWall
27: MagicBack
28: Bounce
29: Transform
2A: Ironize
2B: Heal
2C: HealMore
2D: HealAll
2E: HealUs
2F: HealUsAll
30: Vivify
31: Revive
32: Farewell
33: Antidote
34: NumbOff
35: DeChaos
36: CurseOff
37: StepGuard
38: MapMagic
39: Chance
3A: Attack
3B: TwinSlash
3C: Ramming
3D: Beserker
3E: Kamikaze
3F: Massacre
40: EvilSlash
41: ChargeUP
42: HighJump
43: SuckAir
44: FireSlash
45: BoltSlash
46: VacuSlash
47: IceSlash
48: MetalCut
49: DrakSlash
4A: BeastCut
4B: BirdBlow
4C: DevilCut
4D: ZombieCut
4E: CleanCut
4F: MultiCut
50: BiAttack
51: QuadHits
52: CallHelp
53: YellHelp
54: Focus
55: SquallHit
56: PsycheUp
57: RainSlash
58: WindBeast
59: Vacuum
5A: Lightning
5B: RockThrow
5C: FireAir
5D: BlazeAir
5E: Scorching
5F: WhiteFire
60: FrigidAir
61: IceAir
62: IceStorm
63: WhiteAir
64: Hellblast
65: BigBang
66: MegaMagic
67: PoisonHit
68: NapAttack
69: Paralyze
6A: SleepAir
6B: PalsyAir
6C: PoisonGas
6D: PoisonAir
6E: PaniDance
6F: Curse
70: Ahhh
71: K.O.Dance
72: SandStorm
73: Radiant
74: EerieLite
75: OddDance
76: RobDance
77: SideStep
78: LureDance
79: LushLicks
7A: SickLick
7B: LegSweep
7C: BigTrip
7D: WarCry
7E: Whistle
7F: Imitate
80: DeMagic
81: Surge
82: UltraDown
83: ThickFog
84: TatsuCall
85: DiagoCall
86: SamsiCall
87: BazooCall
88: Cover
89: Guardian
8A: TailWind
8B: StormWind
8C: Dodge
8D: Defence
8E: StrongD
8F: SuckAll
90: BladeD
91: DanceShut
92: MouthShut
93: Meditate
94: Hustle
95: LifeSong
96: LifeDance
</pre>

=== Personality name tables ===
 ROM41:4997 personality name pointer table, size of 2x27, all pointing to within this bank.
    These are indexed by (idx(Charge) * 9 + idx(Cautious) * 3 + idx(Mixed)) where idx(x) is:
     * 0 if x >= 0xC0
     * 1 if 0x40 <= x < 0xC0
     * 2 if x < 0x40
    Effectively this means the indexes are best to worst, worsening Mixed first, then carrying from Cautious, etc.
 
 ROM41:7159 personality names start here, each terminated by F0, in the order specified by the pointer table.
 
 00: HOTBLOOD
 01: DARING
 02: DAREDEVIL
 03: LONE WOLF
 04: VAIN
 05: EZ GOING
 06: SMUG
 07: SNOBBY
 08: RECKLESS
 09: COOL/CALM
 0a: WHIMSY
 0b: NOSY
 0c: WHIZ KID
 0d: ORDINARY
 0e: HASTY
 0f: STUBBORN
 10: REBEL
 11: SPOILED
 12: HUMANE
 13: UNCERTAIN
 14: CARELESS
 15: SHREWED
 16: CAREFREE
 17: GULLIBLE
 18: SLY
 19: COWARD
 1a: LAZY

==Bank 50==
=== Personality adjustment tables ===
These tables are 4x8, each row containing 1 byte each of the adjustments for Charge, Mixed, Cautious, and Motivation respectively. Each table represents what happens when you select a certain Plan in battle. The row corresponds to a combination of the monster's current Motivation and level. Note that selecting Fight makes no adjustments to personality stats.

==== Run ====
 ROM50:59B6
    -4, 0, 0, -10  # Motivation < 151  &&       Level <  10
    -3, 0, 0, -5   # Motivation < 151  && 10 <= Level <  20
    -2, 0, 0, -3   # Motivation < 151  && 20 <= Level <  30
    -1, 0, 0, -2   # Motivation < 151  &&       Level >= 30
    -8, 0, 0, -15  # Motivation >= 151 &&       Level <  10
    -6, 0, 0, -10  # Motivation >= 151 && 10 <= Level <  20
    -4, 0, 0, -5   # Motivation >= 151 && 20 <= Level <  30
    -2, 0, 0, -3   # Motivation >= 151 &&       Level >= 30

==== Charge ====
 ROM57:70A9
    7, -1, 0, 3   # Motivation < 151  &&       Level <  10
    5, -1, 0, 2   # Motivation < 151  && 10 <= Level <  20
    3, -1, 0, 1   # Motivation < 151  && 20 <= Level <  30
    2, -1, 0, 1   # Motivation < 151  &&       Level >= 30
    10, -1, 0, 4  # Motivation >= 151 &&       Level <  10
    7, -1, 0, 3   # Motivation >= 151 && 10 <= Level <  20
    5, -1, 0, 2   # Motivation >= 151 && 20 <= Level <  30
    5, 0, 0, 1    # Motivation >= 151 &&       Level >= 30

==== Mixed ====
 ROM57:70C9
    0, 7, -2, 3   # Motivation < 151  &&       Level <  10
    0, 5, -2, 2   # Motivation < 151  && 10 <= Level <  20
    0, 4, -1, 1   # Motivation < 151  && 20 <= Level <  30
    0, 3, -1, 1   # Motivation < 151  &&       Level >= 30
    0, 10, -3, 4  # Motivation >= 151 &&       Level <  10
    0, 7, -2, 3   # Motivation >= 151 && 10 <= Level <  20
    0, 5, -1, 2   # Motivation >= 151 && 20 <= Level <  30
    0, 5, 0, 1    # Motivation >= 151 &&       Level >= 30

==== Cautious ====
 ROM57:70E9
    -2, 0, 7, 3   # Motivation < 151  &&       Level <  10
    -2, 0, 5, 2   # Motivation < 151  && 10 <= Level <  20
    -1, 0, 4, 1   # Motivation < 151  && 20 <= Level <  30
    -1, 0, 3, 1   # Motivation < 151  &&       Level >= 30
    -2, 0, 10, 4  # Motivation >= 151 &&       Level <  10
    -2, 0, 7, 3   # Motivation >= 151 && 10 <= Level <  20
    -1, 0, 5, 2   # Motivation >= 151 && 20 <= Level <  30
    0, 0, 5, 1    # Motivation >= 151 &&       Level >= 30

==== Command ====
 ROM57:7109
    0, 0, 0, -1  # Motivation < 151  &&       Level <  10
    0, 0, 0, -2  # Motivation < 151  && 10 <= Level <  20
    0, 0, 0, -2  # Motivation < 151  && 20 <= Level <  30
    0, 0, 0, -1  # Motivation < 151  &&       Level >= 30
    0, 0, 0, -1  # Motivation >= 151 &&       Level <  10
    0, 0, 0, -2  # Motivation >= 151 && 10 <= Level <  20
    0, 0, 0, -2  # Motivation >= 151 && 20 <= Level <  30
    0, 0, 0, -1  # Motivation >= 151 &&       Level >= 30

===Load next Monster stats IDs in Arena and Coliseum===
 RO50:66D3 FA CD D9         ld   a,(D9CD)      ;a = current_consecutive_battle
 RO50:66D6 FE 03            cp   a,03
 RO50:66D8 C8               ret  z             ;if(current_consecutive_battle == 3), exit this function; it was the last battle
 RO50:66D9 FA CE D9         ld   a,(D9CE)
 RO50:66DC 47               ld   b,a
 RO50:66DD 87               add  a
 RO50:66DE 80               add  b
 RO50:66DF 47               ld   b,a
 RO50:66E0 FA CD D9         ld   a,(D9CD)      ;a = current_consecutive_battle
 RO50:66E3 80               add  b
 RO50:66E4 47               ld   b,a
 RO50:66E5 87               add  a
 RO50:66E6 80               add  b
 RO50:66E7 21 E0 00         ld   hl,00E0
 RO50:66EA 85               add  l
 RO50:66EB 6F               ld   l,a
 RO50:66EC 3E 00            ld   a,00
 RO50:66EE 8C               adc  h
 RO50:66EF 67               ld   h,a
 RO50:66F0 7D               ld   a,l
 RO50:66F1 EA 03 DA         ld   (DA03),a      ;Write enemy_stats_id_1 to wDA03
 RO50:66F4 7C               ld   a,h
 RO50:66F5 EA 04 DA         ld   (DA04),a
 RO50:66F8 23               inc  hl            ;enemy_stats_id_2 = enemy_stats_id_1 + 1
 RO50:66F9 7D               ld   a,l
 RO50:66FA EA 05 DA         ld   (DA05),a      ;Write enemy_stats_id_2 to wDA05
 RO50:66FD 7C               ld   a,h
 RO50:66FE EA 06 DA         ld   (DA06),a
 RO50:6701 23               inc  hl            ;enemy_stats_id_3 = enemy_stats_id_2 + 1
 RO50:6702 7D               ld   a,l
 RO50:6703 EA 07 DA         ld   (DA07),a      ;Write enemy_stats_id_3 to wDA07
 RO50:6706 7C               ld   a,h
 RO50:6707 EA 08 DA         ld   (DA08),a
 RO50:670A 3E 02            ld   a,02
 RO50:670C EA 02 DA         ld   (DA02),a      ;Write 2 to wDA02
 RO50:670F FA CE D9         ld   a,(D9CE)      ;a = [wD9CE]
 RO50:6712 47               ld   b,a
 RO50:6713 87               add  a
 RO50:6714 80               add  b
 RO50:6715 47               ld   b,a
 RO50:6716 FA CD D9         ld   a,(D9CD)
 RO50:6719 80               add  b
 RO50:671A 87               add  a
 RO50:671B 21 78 67         ld   hl,6778
 RO50:671E 85               add  l
 RO50:671F 6F               ld   l,a
 RO50:6720 3E 00            ld   a,00
 RO50:6722 8C               adc  h
 RO50:6723 67               ld   h,a
 RO50:6724 2A               ldi  a,(hl)
 RO50:6725 EA CA D7         ld   (D7CA),a
 RO50:6728 7E               ld   a,(hl)
 RO50:6729 EA CB D7         ld   (D7CB),a
 RO50:672C FA 03 DA         ld   a,(DA03)
 RO50:672F 6F               ld   l,a
 RO50:6730 FA 04 DA         ld   a,(DA04)
 RO50:6733 67               ld   h,a
 RO50:6734 CD 66 67         call 6766
 RO50:6737 EA CE D7         ld   (D7CE),a
 RO50:673A 3E 01            ld   a,01
 RO50:673C EA CF D7         ld   (D7CF),a
 RO50:673F FA 05 DA         ld   a,(DA05)
 RO50:6742 6F               ld   l,a
 RO50:6743 FA 06 DA         ld   a,(DA06)
 RO50:6746 67               ld   h,a
 RO50:6747 CD 66 67         call 6766
 RO50:674A EA CC D7         ld   (D7CC),a
 RO50:674D 3E 01            ld   a,01
 RO50:674F EA CD D7         ld   (D7CD),a
 RO50:6752 FA 07 DA         ld   a,(DA07)
 RO50:6755 6F               ld   l,a
 RO50:6756 FA 08 DA         ld   a,(DA08)
 RO50:6759 67               ld   h,a
 RO50:675A CD 66 67         call 6766
 RO50:675D EA D0 D7         ld   (D7D0),a
 RO50:6760 3E 01            ld   a,01
 RO50:6762 EA D1 D7         ld   (D7D1),a
 RO50:6765 C9               ret

==Bank 51==
===Load Battle===
 RO51:4027 21 17 C8         ld   hl,C817
 RO51:402A 36 00            ld   (hl),00
 RO51:402C 23               inc  hl
 RO51:402D 36 00            ld   (hl),00
 RO51:402F 21 01 08         ld   hl,0801
 RO51:4032 D7               rst  10
 RO51:4033 3E FC            ld   a,FC
 RO51:4035 CD 88 16         call 1688
 RO51:4038 11 00 5B         ld   de,5B00
 RO51:403B 21 00 96         ld   hl,9600
 RO51:403E CD CF 14         call 14CF
 RO51:4041 11 01 5B         ld   de,5B01
 RO51:4044 21 00 88         ld   hl,8800
 RO51:4047 CD CF 14         call 14CF
 RO51:404A 11 00 2E         ld   de,2E00
 RO51:404D 21 00 8D         ld   hl,8D00
 RO51:4050 CD CF 14         call 14CF
 RO51:4053 21 00 8B         ld   hl,8B00
 RO51:4056 11 02 12         ld   de,1202
 RO51:4059 CD 8F 09         call 098F
 RO51:405C CD 07 41         call 4107
 RO51:405F CD D1 40         call 40D1
 RO51:4062 FA 6C C8         ld   a,(C86C)
 RO51:4065 B7               or   a
 RO51:4066 28 0B            jr   z,4073
 RO51:4068 3E FF            ld   a,FF
 RO51:406A EA B7 C8         ld   (C8B7),a
 RO51:406D EA B8 C8         ld   (C8B8),a
 RO51:4070 CD 31 33         call 3331
 RO51:4073 06 27            ld   b,27               ;bmg_offset = battle
 RO51:4075 FA 68 C9         ld   a,(C968)
 RO51:4078 FE 5D            cp   a,5D
 RO51:407A C2 8B 40         jp   nz,408B            ;if (map_type ≠ arena_battle), jump to 51:408B
 RO51:407D 21 EA C8         ld   hl,C8EA
 RO51:4080 CB BE            res  7,(hl)
 RO51:4082 FA 99 D9         ld   a,(D999)
 RO51:4085 FE 02            cp   a,02
 RO51:4087 20 02            jr   nz,408B            ;if ([w1:D999] ≠ 0x02), jump to 51:408B
 RO51:4089 06 2B            ld   b,2B
 RO51:408B 78               ld   a,b                ;bmg_offset = battle_against_mireille
 RO51:408C CD E1 1A         call 1AE1               ;Call: Set BGM offset to load
 RO51:408F 3E 07            ld   a,07
 RO51:4091 E0 B5            ld   (ff00+B5),a
 RO51:4093 3E FF            ld   a,FF
 RO51:4095 E0 B6            ld   (ff00+B6),a
 RO51:4097 3E 00            ld   a,00
 RO51:4099 E0 BB            ld   (ff00+BB),a
 RO51:409B 3E 00            ld   a,00
 RO51:409D E0 B7            ld   (ff00+B7),a
 RO51:409F CD 2F 12         call 122F
 RO51:40A2 CD 17 14         call 1417
 RO51:40A5 AF               xor  a
 RO51:40A6 EA A4 C8         ld   (C8A4),a
 RO51:40A9 EA A5 C8         ld   (C8A5),a
 RO51:40AC AF               xor  a
 RO51:40AD EA 92 C8         ld   (C892),a
 RO51:40B0 AF               xor  a
 RO51:40B1 EA 62 DD         ld   (DD62),a
 RO51:40B4 AF               xor  a
 RO51:40B5 EA 73 C8         ld   (C873),a
 RO51:40B8 AF               xor  a
 RO51:40B9 EA 6E C8         ld   (C86E),a
 RO51:40BC 21 0A 17         ld   hl,170A
 RO51:40BF D7               rst  10
 RO51:40C0 21 10 51         ld   hl,5110
 RO51:40C3 D7               rst  10
 RO51:40C4 3E 03            ld   a,03
 RO51:40C6 EA A1 C8         ld   (C8A1),a
 RO51:40C9 CD 5D 12         call 125D
 RO51:40CC 3E 0B            ld   a,0B
 RO51:40CE C3 CB 11         jp   11CB
 RO51:40D1 FA 8D CA         ld   a,(CA8D)
 RO51:40D4 B7               or   a
 RO51:40D5 C8               ret  z
 RO51:40D6 FA 8E CA         ld   a,(CA8E)
 RO51:40D9 57               ld   d,a
 RO51:40DA 21 07 01         ld   hl,0107
 RO51:40DD D7               rst  10
 RO51:40DE 7A               ld   a,d
 RO51:40DF EA 15 DA         ld   (DA15),a
 RO51:40E2 FA 8D CA         ld   a,(CA8D)
 RO51:40E5 FE 01            cp   a,01
 RO51:40E7 C8               ret  z
 RO51:40E8 FA 8F CA         ld   a,(CA8F)
 RO51:40EB 57               ld   d,a
 RO51:40EC 21 07 01         ld   hl,0107
 RO51:40EF D7               rst  10
 RO51:40F0 7A               ld   a,d
 RO51:40F1 EA 16 DA         ld   (DA16),a
 RO51:40F4 FA 8D CA         ld   a,(CA8D)
 RO51:40F7 FE 02            cp   a,02
 RO51:40F9 C8               ret  z
 RO51:40FA FA 90 CA         ld   a,(CA90)
 RO51:40FD 57               ld   d,a
 RO51:40FE 21 07 01         ld   hl,0107
 RO51:4101 D7               rst  10
 RO51:4102 7A               ld   a,d
 RO51:4103 EA 17 DA         ld   (DA17),a
 RO51:4106 C9               ret

===Load requested Monster stats ID in wDA12-wDA13, and another value in wDA31===
 RO51:4627 C5               push bc
 RO51:4628 79               ld   a,c
 RO51:4629 D6 04            sub  a,04
 RO51:462B 4F               ld   c,a
 RO51:462C C5               push bc
 RO51:462D 21 03 DA         ld   hl,DA03
 RO51:4630 79               ld   a,c
 RO51:4631 87               add  a
 RO51:4632 85               add  l
 RO51:4633 6F               ld   l,a
 RO51:4634 3E 00            ld   a,00
 RO51:4636 8C               adc  h
 RO51:4637 67               ld   h,a           ;hl = 0xDA03 + (a × 2); pointer_to_monster_stats_id
 RO51:4638 2A               ldi  a,(hl)
 RO51:4639 66               ld   h,(hl)
 RO51:463A 6F               ld   l,a           ;hl = monster_stats_id 
 RO51:463B 7D               ld   a,l
 RO51:463C EA 12 DA         ld   (DA12),a      ;Write monster_stats_id in wDA12
 RO51:463F 7C               ld   a,h
 RO51:4640 EA 13 DA         ld   (DA13),a
 RO51:4643 21 01 14         ld   hl,1401       ;to Bank 0x14, function 0x01
 RO51:4646 D7               rst  10
 RO51:4647 C1               pop  bc
 RO51:4648 CD E0 47         call 47E0
 RO51:464B 79               ld   a,c
 RO51:464C C6 04            add  a,04
 RO51:464E 21 3C DC         ld   hl,DC3C
 RO51:4651 85               add  l
 RO51:4652 6F               ld   l,a
 RO51:4653 3E 00            ld   a,00
 RO51:4655 8C               adc  h
 RO51:4656 67               ld   h,a
 RO51:4657 CD 88 46         call 4688
 RO51:465A 7E               ld   a,(hl)
 RO51:465B EA 31 DA         ld   (DA31),a
 RO51:465E C5               push bc
 RO51:465F 21 01 03         ld   hl,0301
 RO51:4662 D7               rst  10
 RO51:4663 C1               pop  bc
 RO51:4664 CD 4C 49         call 494C
 RO51:4667 C1               pop  bc
 RO51:4668 C9               ret

== Bank 52 ==
=== Skill functions ===
<pre>
52:4011 SkillFunctionTable
52:41CD SkillBlaze
52:41D4 SkillFirebal
52:41DB SkillBang
52:41E2 SkillInfernos
52:41E9 SkillIceBolt
52:41F0 SkillBolt
52:41F7 SkillBeat
52:422B SkillSacrifice
52:4235 SkillSleep
52:427C SkillStopSpell
52:42AA SkillSurround
52:42D8 SkillPanicAll
52:4308 SkillRobMagic
52:4330 SkillTakeMagic
52:434A SkillSap
52:436D SkillUpper
52:4385 SkillSlow
52:43A8 SkillSpeed
52:43C0 SkillBarrier
52:43FB SkillTwinHits
52:4415 SkillMagicWall
52:4434 SkillMagicBack
52:446C SkillTransform
52:4479 SkillIRONIZE
52:447F SkillIronize
52:44C4 SkillHeal
52:44F8 SkillVivify
52:457E SkillFarewell
52:458F SkillAntidote
52:45A7 SkillNumbOff
52:45D8 SkillDeChaos
52:45FE SkillCurseOff
52:4616 SkillChance
52:4625 SkillPoisonHit_StepGuard_Whistle_Attack_Run
52:462F SkillPsycheUp_TwinSlash
52:464C SkillRamming
52:4653 SkillBeserker
52:467C SkillKamikaze
52:4683 SkillMassacre
52:46BE SkillChargeUP
52:46CF SkillHighJump
52:470F SkillSuckAir
52:4720 SkillFireSlash
52:472A SkillBoltSlash
52:4734 SkillVacuSlash
52:473E SkillIceSlash
52:4748 SkillMetalCut
52:4752 SkillDrakSlash
52:475C SkillBeastCut
52:4766 SkillBirdBlow
52:4770 SkillDevilCut
52:477A SkillZombieCut
52:4784 SkillCleanCut
52:478E SkillMultiCut
52:4798 SkillBiAttack
52:480C SkillCallHelp
52:4888 SkillFocus
52:4897 SkillSquallHit
52:48B4 SkillRainSlash
52:4918 SkillWindBeast
52:492B SkillRockThrow
52:4932 SkillFireAir
52:493C SkillFrigidAir
52:4946 SkillBigBang
52:494D SkillMegaMagic
52:4954 SkillPalsyAir
52:497B SkillPoisonGas
52:49D2 SkillCurse
52:4A00 SkillAhhh
52:4A22 SkillSandStorm
52:4A57 SkillEerieLite
52:4A7B SkillOddDance
52:4AA3 SkillSideStep
52:4AC5 SkillLureDance
52:4AE7 SkillLushLicks
52:4B34 SkillLegSweep
52:4B68 SkillWarCry
52:4B92 SkillImitate
52:4BA1 SkillDeMagic_ThickFog
52:4BAB SkillSurge
52:4BB6 SkillUltraDown
52:4BD0 SkillTatsuCall
52:4C31 SkillCover
52:4C3B SkillTailWind
52:4C72 SkillDodge
52:4C81 SkillBladeD_Defense
52:4CA5 SkillSuckAll
52:4CDC SkillDanceShut
52:4D0A SkillMouthShut
52:4D38 SkillMeditate
52:4D92 SkillLifeSong
52:4DE9 SkillLifeDance
52:4E0A SkillDaze
52:4E0E SkillBeDragon
52:4E15 SkillSmashlime
52:4E1F SkillSheldodge
52:4E29 SkillBranching
52:4E33 SkillGigaSlash
52:4E3A SkillRUN
52:4E6D SkillAhhh
52:4E8A SkillHitAlly
52:4EA4 SkillHitEnemy
52:4EBE SkillHitRandom
52:4ED8 SkillTrip
52:4EE3 SkillScared
52:4EE7 SkillParalyze
52:4EF9 SkillSmashed
52:4F2C SkillHealUsAll
52:4F35 SkillALLCHANGE
52:4F54 SkillBIGSLEEP
52:4F7F SkillMP0
52:4FA1 SkillCALLEVIL
52:4FCC SkillFREEZY
52:4FFC SkillRESTOREMP
52:501F SkillMETEOR
</pre>

=== Family check functions ===
<pre>
52:6304 CheckIsSlime
52:6311 CheckIsDragon
52:631f CheckIsBeast
52:632d CheckIsFlying
52:633b CheckIsPlant
52:6349 CheckIsBug
52:6357 CheckIsDevil
52:6365 CheckIsZombie
52:6373 CheckIsMaterial
</pre>

=== Math functions ===
These are used commonly in the skill functions to calculate damage and such

<pre>
52:6b2a BCsrl3  BC >>= 3
52:6b2e BCsrl2  BC >>= 2
52:6b32 BCsrl1  BC >>= 1
52:6b37 HLsrl4  HL >>= 4
52:6b3b HLsrl3  HL >>= 3
52:6b3f HLsrl2  HL >>= 2
52:6b43 HLsrl1  HL >>= 1
</pre>

{{Internal Data|game=Dragon Warrior Monsters}}
