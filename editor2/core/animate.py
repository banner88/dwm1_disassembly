"""Make a tile animated (S99 r3; user: "please make the 'make animatable' tab.
Bonus points if you can make a little tab/edit doodad that lets me re-paint a
second tile in a paint-like manner").

The engine animates SLOTS of a room's sheet, chosen by the room's ONE
animation source (ROOM_DATA_FORMAT "Animated tiles"): a SLIDE source rolls
its slots 1 px sideways (3 right : 1 left per 128 frames; the GreatTree sway
rolls 16 slots in alternating 4-tile groups), a FLIP source swaps each shown
slot with a hidden partner slot every 32 (16/25/64) frames. Making a tile
animated = writing its graphics into free slots of a suitable source (frame B
into the partner slots for a flip), moving tiles that are in the way,
remapping this room's cells that draw the tile, and setting the room's
animation to that source.

Pure document logic (no Qt) — mixed into editor2.core.document.Document.
"""

from editor2.core import animation as A

EFFECTS = ('slide', 'flip')


def _val(v):
    if isinstance(v, int):
        return v
    s = str(v).strip()
    return int(s[1:], 16) if s.startswith('$') else int(s, 0)


def source_units(mid, effect):
    """What a vanilla map's animation offers for `effect`:
    slide -> [slot, ...] (rolled slots); flip -> [(shown, partner), ...]."""
    h = A.handler(mid)
    out = []
    for e in h.get('effects') or []:
        if effect == 'slide' and e['kind'] == 'roll':
            out += list(e['slots'])
        elif effect == 'flip' and e['kind'] == 'swap':
            out += list(zip(e['slots'], e['partners']))
    return out


def units_of(tiles, frames_a, frames_b, effect, cur=None):
    """Group the 4 subtile positions into distinct graphic units:
    [(positions, gfxA, gfxB|None)]. Positions sharing a graphic (same A and,
    for a flip, same B) share one slot. S99 r7: with `cur` (the quarters'
    graphics now), a flip quarter whose frames A and B both equal it does not
    move — it keeps its own slot (and walkability) and needs no pair."""
    out = []
    for k in range(4):
        a = bytes(frames_a[k])
        b = bytes(frames_b[k]) if effect == 'flip' else None
        if effect == 'flip' and cur is not None and a == b == bytes(cur[k]):
            continue
        for u in out:
            if u[1] == a and u[2] == b:
                u[0].append(k)
                break
        else:
            out.append(([k], a, b))
    return out


class AnimateMixin:
    # ------------------------------------------------------------ queries
    def anim_of_metatile(self, room, mt):
        """How the room's current animation treats this metatile:
        {'map', 'effect' ('slide'|'flip'|None), 'partners' {pos: slot}}."""
        info = self.room_animation(room)
        mid = info['map']
        if mid is None:
            return {'map': None, 'effect': None, 'partners': {}}
        detail = A.handler(mid).get('slot_detail') or {}
        eff, partners = None, {}
        for k, t in enumerate(mt['tiles']):
            d = detail.get(str(t & 0x7F))
            if not d:
                continue
            if d['kind'] == 'swap' and d.get('partner') is not None:
                eff = 'flip'
                partners[k] = d['partner']
            elif d['kind'] == 'roll':
                eff = eff or 'slide'
        return {'map': mid, 'effect': eff, 'partners': partners}

    def _room_layout_ids(self, room):
        out = []
        for scr in (room.get('screens') or {}).values():
            for ref in [scr.get('layout')] + [st.get('layout') for st in scr.get('states') or []]:
                if ref and 'id' in ref and self.has_layout(ref['id']) and ref['id'] not in out:
                    out.append(ref['id'])
        return out

    def _cells_of(self, room, mt):
        """[(layout id, cx, cy)] of this room's cells drawing metatile `mt`
        (same 4 subtiles; same palettes when the layout carries attrs)."""
        want = [t & 0x7F for t in mt['tiles']]
        pals = mt.get('pal')
        out = []
        for lid in self._room_layout_ids(room):
            L = self.layout(lid)
            tiles, attr = L['tiles'], L.get('attr')
            for cy in range(len(tiles) // 2):
                for cx in range(len(tiles[0]) // 2):
                    r, c = cy * 2, cx * 2
                    cur = [tiles[r][c] & 0x7F, tiles[r][c + 1] & 0x7F,
                           tiles[r + 1][c] & 0x7F, tiles[r + 1][c + 1] & 0x7F]
                    if cur != want:
                        continue
                    if attr and pals is not None:
                        ap = [attr[r][c] & 7, attr[r][c + 1] & 7,
                              attr[r + 1][c] & 7, attr[r + 1][c + 1] & 7]
                        mp = pals if isinstance(pals, list) else [pals] * 4
                        if ap != [p & 7 for p in mp]:
                            continue
                    out.append((lid, cx, cy))
        return out

    def _cells_touching(self, room, slots, skip=None):
        """Cells (2x2) of this room drawing a subtile in `slots`, except
        cells that draw metatile `skip` (its 4 subtiles)."""
        skip = [t & 0x7F for t in skip['tiles']] if skip else None
        n = 0
        for lid in self._room_layout_ids(room):
            T = self.layout(lid)['tiles']
            for r in range(0, len(T) - 1, 2):
                for c in range(0, len(T[0]) - 1, 2):
                    cur = [T[r][c] & 0x7F, T[r][c + 1] & 0x7F,
                           T[r + 1][c] & 0x7F, T[r + 1][c + 1] & 0x7F]
                    if cur != skip and any(t in slots for t in cur):
                        n += 1
        return n

    def anim_budget(self, room):
        """How full this room's animation is (S99 r6; user: "I'm still very
        unclear how many tiles per room are allowed to be animated. Would be
        good to have a count"). {'map', 'units': [{'effect', 'total', 'used',
        'unit'}], 'tiles': [(name, [4 slots], cells)]}: `total` slots (slide)
        or pairs (flip) the animation moves, `used` = those this room draws;
        `tiles` = this room's metatiles that move."""
        info = self.room_animation(room)
        mid = info['map']
        out = {'map': mid, 'units': [], 'tiles': []}
        if mid is None or not room.get('record'):
            return out
        tid = self.tileset_key(room)
        usage = self.tile_usage(tid)

        def here(sl):
            return any(w[0] == room['id'] for w in usage[sl]['placed'])
        for eff in EFFECTS:
            offer = source_units(mid, eff)
            if not offer:
                continue
            used = [x for x in offer if (here(x) if eff == 'slide' else here(x[0]) or here(x[1]))]
            out['units'].append({'effect': eff, 'total': len(offer), 'used': len(used),
                                 'unit': 'slot' if eff == 'slide' else 'pair'})
        anim = info['slots']
        names = {}
        try:
            for m in self.metatiles(tid):
                names.setdefault(tuple(t & 0x7F for t in m['tiles']), m.get('name'))
        except Exception:
            pass
        count = {}
        for lid in self._room_layout_ids(room):
            T = self.layout(lid)['tiles']
            for r in range(0, len(T) - 1, 2):
                for c in range(0, len(T[0]) - 1, 2):
                    cur = (T[r][c] & 0x7F, T[r][c + 1] & 0x7F,
                           T[r + 1][c] & 0x7F, T[r + 1][c + 1] & 0x7F)
                    if any(t in anim for t in cur):
                        count[cur] = count.get(cur, 0) + 1
        out['tiles'] = [(names.get(k) or '', list(k), n) for k, n in
                        sorted(count.items(), key=lambda kv: -kv[1])]
        return out

    def _released_by(self, room, mt, usage):
        """Slots of `mt` that no longer draw anything once its cells here are
        remapped (S99 r6): placed only in this room, only by these cells,
        and not in My metatiles — they count as free for tiles in the way."""
        cells = self._cells_of(room, mt)
        mine = [t & 0x7F for t in mt['tiles']]
        occ = {}
        for lid in self._room_layout_ids(room):
            for row in self.layout(lid)['tiles']:
                for t in row:
                    occ[t & 0x7F] = occ.get(t & 0x7F, 0) + 1
        out = set()
        for t in set(mine):
            u = usage[t]
            if u['mine'] or any(w[0] != room['id'] for w in u['placed']):
                continue
            if occ.get(t, 0) == len(cells) * mine.count(t) and cells:
                out.add(t)
        return out

    def _room_art(self, room, mt):
        """The 4 quarters' graphics as the room draws them now."""
        rec = room['record']
        if 'tileset' in rec:
            sh = self.read_sheet(rec['tileset'])
        else:
            sh = bytes(self.vanilla.room_gfx(room).sheet)
        return [bytes(sh[(t & 0x7F) * 16:(t & 0x7F) * 16 + 16]) for t in mt['tiles']]

    @staticmethod
    def _rewritten(mt, need):
        """Slots of `mt` that ONLY moving quarters use (they get new slots);
        slots of still quarters stay as they are."""
        pos = {k for u in need for k in u[0]}
        return ({mt['tiles'][k] & 0x7F for k in pos}
                - {mt['tiles'][k] & 0x7F for k in range(4) if k not in pos})

    def animate_candidates(self, room, mt, effect, frames_a, frames_b=None):
        """Every vanilla animation that can host this tile, best first:
        [{'map', 'label', 'units', 'free', 'fits', 'walk_ok', 'current',
          'stops'}] — `free` = its slots not drawn by other tiles of this
        room's sheet; `stops` = animated cells of this room that a switch
        would freeze."""
        tid = self.tileset_key(room)
        thr = _val(room['record']['collision_threshold'])
        usage = self.tile_usage(tid)
        cur = self.room_animation(room)
        need = units_of(mt['tiles'], frames_a, frames_b or frames_a, effect,
                        self._room_art(room, mt))
        mine = self._rewritten(mt, need)
        still_q = {mt['tiles'][k] & 0x7F for k in range(4)
                   if not any(k in u[0] for u in need)}
        br_unit = next((i for i, u in enumerate(need) if 3 in u[0]), None)
        br_wall = (mt['tiles'][3] & 0x7F) < thr
        # animated cells of this room that another source would stop
        stop_cells = self._cells_touching(room, cur['slots'], mt) if cur['slots'] else 0
        released = self._released_by(room, mt, usage) & mine
        if not need:
            return []
        lib_only = sum(1 for u in usage if not u['placed'] and u['mine'] and not u['animated'])
        # slots other rooms on this tileset animate (they stay animated
        # whatever this room does)
        other_anim = set()
        for r2 in self.rooms_using_tileset(tid):
            if r2 is not room and r2.get('id') != room.get('id'):
                other_anim |= self.room_animation(r2)['slots']
        out = []
        names = {}
        try:
            names = {m: n for m, n, _s in self.vanilla.vanilla_rooms()}
        except Exception:
            pass
        seen = set()
        for mid, _label in A.sources(names):
            h = A.map_entry(mid).get('handler')
            if h in seen:
                continue
            seen.add(h)
            offer = source_units(mid, effect)
            if not offer:
                continue

            current = cur['map'] == mid

            def taken(s):
                # the room's CURRENT animation: a slot drawn by another tile
                # is another animated tile. S99 r6 (user: "Surely it should
                # allow me to shift animation to tile I'm editing??"): it can
                # be TAKEN OVER — that tile moves to a still slot and stands
                # still with its current look — but only when no free unit is
                # left. Any other source: tiles in its slots are still ones.
                return current and bool(usage[s]['placed']) and s not in mine

            def cost(x):
                xs = (x,) if effect == 'slide' else x
                return (sum(1 for y in xs if taken(y)),
                        sum(1 for y in xs if usage[y]['placed'] and y not in mine))
            free = sorted(offer, key=cost)          # free first, take-overs last
            use = free[:len(need)]
            flat = [x for f in use for x in ((f,) if effect == 'slide' else f)]
            takes = sorted({x for x in flat if taken(x)})
            taken_slots = sorted({x for f in offer
                                  for x in ((f,) if effect == 'slide' else f) if taken(x)})
            # can the tiles in the way go somewhere on their own side?
            # EVERY slot the animation moves (both kinds: Zoma also rolls 49-50
            # while this tile flips) — a switch sets them all moving
            offer_flat = {x for f in offer for x in ((f,) if effect == 'slide' else f)} \
                | set(A.slots(mid))
            spare = {True: 0, False: 0}
            for f in range(128):
                u = usage[f]
                # this room's OLD animation stops on a switch: its slots are
                # ordinary ones then (only other rooms' animated slots stay off)
                if f in offer_flat or f in other_anim or (u['animated'] and current):
                    continue
                if (not u['placed'] and not u['mine']) or f in released:
                    spare[f < thr] += 1
            # a SWITCH makes every slot of the new animation move: tiles in
            # use there (other than this one) must leave — count them all
            want = {True: 0, False: 0}
            for x in (flat if current else offer_flat):
                # a slot only this tile's cells draw is rewritten in place;
                # anything else in use there (incl. a quarter this tile SHARES
                # with other cells) moves out, or those cells would animate
                if (usage[x]['placed'] or usage[x]['mine'] or x in still_q) \
                        and x not in released:
                    want[x < thr] += 1
            moves = sum(want.values())
            room_ok = all(want[k] <= spare[k] for k in (True, False))
            short = {'wall': max(0, want[True] - spare[True]),
                     'walkable': max(0, want[False] - spare[False])}
            # S99 r7 (user: "this tileset needs 2 more free wall slots … removing
            # walkability from like 10 tiles doesnt make the button not greyed
            # out"): one side short, the other with room to spare -> move the
            # wall/walkable split (tiles there move to their own side; no
            # tile's walkability or look changes)
            shift = 0
            if not room_ok and bool(short['wall']) != bool(short['walkable']):
                up = bool(short['wall'])
                n = short['wall'] or short['walkable']
                surplus = (spare[False] - want[False]) if up else (spare[True] - want[True])
                # slots of the new animation inside the band change side too
                # (their tiles are moved out first) but free no slot
                band, gain, x = [], 0, (thr if up else thr - 1)
                while gain < n and 0 < x < 128 and x not in other_anim and not (
                        current and usage[x]['animated']):
                    band.append(x)
                    gain += x not in offer_flat
                    x += 1 if up else -1
                if gain >= n and surplus >= gain:
                    shift = len(band) if up else -len(band)
            # the whole tileset is short: how many more free slots (any side —
            # the split moves as needed), and how many unused My-metatile
            # graphics a purge would free
            short_any = max(0, sum(want.values()) - sum(spare.values())) if not room_ok \
                and not shift else 0
            fits = len(free) >= len(need) and (room_ok or bool(shift))
            first = [x if effect == 'slide' else x[0] for x in free]
            walk_ok = br_unit is None or any((s < thr) == br_wall for s in first)
            if mid == 0x01 and effect == 'slide':
                what = 'sway (16 tiles, groups of 4 alternate)'
            elif effect == 'slide':
                what = f'slide ({len(offer)} slot{"s" if len(offer) > 1 else ""})'
            else:
                what = f'flip ({len(offer)} pair{"s" if len(offer) > 1 else ""})'
            out.append({'map': mid, 'label': f'${mid:02X} {names.get(mid, A.map_entry(mid).get("name", ""))}'
                                              f' — {what}',
                        'units': len(need), 'free': free, 'fits': fits, 'moves': moves,
                        'room_ok': room_ok, 'offer': len(offer),
                        'walk_ok': walk_ok, 'current': cur['map'] == mid,
                        'takes': takes, 'taken_slots': taken_slots,
                        'released': sorted(released - offer_flat),
                        'short': short, 'shift': shift, 'thr': thr, 'short_any': short_any,
                        'lib_only': lib_only,
                        'stops': (self._cells_touching(room, set(takes), mt) if current
                                  else stop_cells),
                        'br_unit': br_unit})
        # stopping fewer animated cells beats keeping the room's animation
        out.sort(key=lambda c: (not c['fits'], c['stops'], not c['current'],
                                not c['walk_ok'], bool(c['shift']), c['moves'], c['map']))
        return out

    def _vacate(self, tid, sheet, slots, keep, thr, avoid, release=()):
        """Move every tile in use in `slots` (except `keep`) to a free slot
        on the same side of the threshold (layouts + metatiles remapped), so
        switching a room's animation never sets unrelated tiles moving.
        Returns [(old, new)]; raises RuntimeError when a side is full."""
        usage = self.tile_usage(tid)
        # `release`: slots the caller frees right after (the tile being
        # animated leaves them) — usable targets; the caller rewrites the
        # cells that still point there
        busy = {i for i, u in enumerate(usage) if u['placed'] or u['mine']} - set(release)
        moved = []
        for s in sorted(slots):
            if s in keep or s not in busy:
                continue
            side = [f for f in range(128) if f not in busy and f not in avoid
                    and f not in slots and (f < thr) == (s < thr)]
            if not side:
                raise RuntimeError(
                    f'slot {s} holds a tile in use and there is no free '
                    f"{'wall' if s < thr else 'walkable'} slot to move it to — free one "
                    '(Tileset tab: purge / release, or an own tileset copy) and try again')
            f = side[-1] if s < thr else side[0]
            sheet[f * 16:f * 16 + 16] = sheet[s * 16:s * 16 + 16]
            self._remap_tile(tid, s, f)
            busy.add(f)
            moved.append((s, f))
        return moved

    def _shift_split(self, tid, delta, avoid):
        """Move the wall/walkable split (collision threshold) of every room
        on tileset `tid` by `delta` slots (>0: more wall slots). Tiles in the
        slots that change side move to free slots on their OWN side first
        (every layout / metatile follows), so nothing on screen changes and
        every tile keeps its walkability (S99 r7). Returns ({old: new}, thr)."""
        from editor2.core.document import hexs
        rooms = self.rooms_using_tileset(tid)
        thr = _val(rooms[0]['record']['collision_threshold'])
        new = thr + delta
        band = range(thr, new) if delta > 0 else range(new, thr)
        anim = self.animated_slots(tid)       # AFTER the room switched (caller)
        if any(x in anim and x not in avoid for x in band) or not (0 < new < 128):
            raise RuntimeError('cannot move the wall/walkable split across animated slots')
        usage = self.tile_usage(tid)
        busy = {i for i, u in enumerate(usage) if u['placed'] or u['mine']}
        sheet = self.read_sheet(tid)
        if delta > 0:                         # band becomes wall: its tiles stay walkable
            targets = [f for f in range(new, 128) if f not in busy and f not in anim
                       and f not in avoid]
        else:                                 # band becomes walkable: its tiles stay walls
            targets = [f for f in range(new - 1, -1, -1) if f not in busy and f not in anim
                       and f not in avoid]
        moved = {}
        for x in band:
            if x not in busy:
                continue
            if not targets:
                raise RuntimeError('no free slot to move the tiles at the wall/walkable split to')
            f = targets.pop(0)
            sheet[f * 16:f * 16 + 16] = sheet[x * 16:x * 16 + 16]
            self._remap_tile(tid, x, f)
            moved[x] = f
        self.write_sheet(tid, sheet)
        for r in rooms:
            r['record']['collision_threshold'] = hexs(new)
        return moved, new

    # ------------------------------------------------ strays / make still (S99 r4)
    def _source_sheet(self, mid):
        try:
            return bytes(self.vanilla.vanilla_gfx(mid).sheet)
        except Exception:
            return None

    def stray_animated(self, room):
        """Slots this room PLACES that its 'source' animation moves although
        they do not hold the source room's own art there — art that ended up
        in an animated slot by accident (pre-S99 imports took the source's
        hidden-frame slots as free; user S99: "Why is the mirror in $6b
        moving? I never wanted it to move"). Only 'source' rooms: a borrowed
        or Make-animated id is deliberate."""
        info = self.room_animation(room)
        if info['kind'] != 'source' or info['map'] is None or not room.get('record'):
            return []
        ref = self._source_sheet(info['map'])
        if ref is None:
            return []
        tid = self.tileset_key(room)
        sheet = self.read_sheet(tid) if 'tileset' in room['record'] else bytearray(ref)
        usage = self.tile_usage(tid)
        out = []
        for sl in sorted(info['slots']):
            here = [w for w in usage[sl]['placed'] if w[0] == room['id']]
            if here and bytes(sheet[sl * 16:sl * 16 + 16]) != ref[sl * 16:sl * 16 + 16]:
                out.append(sl)
        return out

    def stray_report(self):
        """[(room id, room name, slots, source map)] for every room with strays."""
        out = []
        for r in self.rooms:
            if r.get('placeholder'):
                continue
            st = self.stray_animated(r)
            if st:
                out.append((r['id'], self.room_name(r), st, self.room_animation(r)['map']))
        return out

    def repair_animation(self, room_ids=None):
        """Move every stray (see stray_animated) out to a free still slot on
        the same side (all its placements follow) and put the source room's
        own art back into the animated slot, so the room's real animation
        keeps working and the stray stands still. Returns notes."""
        notes = []
        for rid, name, slots, mid in self.stray_report():
            if room_ids is not None and rid not in room_ids:
                continue
            room = self.room(rid)
            tid = room['record']['tileset']
            thr = _val(room['record']['collision_threshold'])
            sheet = self.read_sheet(tid)
            ref = self._source_sheet(mid)
            moved = self._vacate(tid, sheet, set(slots), set(), thr,
                                 self.animated_slots(tid))
            for sl in slots:
                sheet[sl * 16:sl * 16 + 16] = ref[sl * 16:sl * 16 + 16]
            self.write_sheet(tid, sheet)
            notes.append(f"{name}: tiles in ${mid:02X}'s animated slots moved to still slots ("
                         + ', '.join(f'{a}->{b}' for a, b in moved) + ')')
        self.last_import_note = '; '.join(notes)
        return notes

    def make_still(self, room_id, mt, own_sheet=None):
        """Stop metatile `mt` moving in this room: each subtile that sits in a
        slot the room animates gets a copy of its CURRENT graphic in a free
        still slot on the same side; this room's cells of the metatile are
        remapped (other tiles using those slots keep animating). Returns the
        new metatile (added to My metatiles)."""
        room = self.room(room_id)
        rec = room['record']
        if 'tileset' not in rec:
            if own_sheet is None:
                raise RuntimeError('room borrows a vanilla tileset — pass own_sheet')
            self.localize_tileset(room, own_sheet)
        tid = rec['tileset']
        thr = _val(rec['collision_threshold'])
        anim = self.room_animation(room)['slots']
        hot = sorted({t & 0x7F for t in mt['tiles'] if (t & 0x7F) in anim})
        if not hot:
            raise RuntimeError('this tile does not move in this room')
        cells = self._cells_of(room, mt)
        sheet = self.read_sheet(tid)
        used = self.used_tiles(tid)
        avoid = self.animated_slots(tid)
        new_of = {}
        for sl in hot:
            g = bytes(sheet[sl * 16:sl * 16 + 16])
            same = next((f for f in range(128) if f not in avoid and (f < thr) == (sl < thr)
                         and bytes(sheet[f * 16:f * 16 + 16]) == g), None)
            if same is None:
                side = [f for f in range(128) if f not in used and f not in avoid
                        and (f < thr) == (sl < thr)]
                if not side:
                    raise RuntimeError(
                        f"no free {'wall' if sl < thr else 'walkable'} slot for a still copy of "
                        f'slot {sl} — free one (Tileset tab: purge / release) and try again')
                same = side[-1] if sl < thr else side[0]
                sheet[same * 16:same * 16 + 16] = g
                used.add(same)
            new_of[sl] = same
        self.write_sheet(tid, sheet)
        new_tiles = [(t & 0x80) | new_of.get(t & 0x7F, t & 0x7F) for t in mt['tiles']]
        for lid, cx, cy in cells:
            T = self.layout(lid)['tiles']
            r, c = cy * 2, cx * 2
            T[r][c], T[r][c + 1], T[r + 1][c], T[r + 1][c + 1] = new_tiles
        nm = f"still {mt.get('name') or 'tile'}"
        self.add_metatile(tid, nm, [t & 0x7F for t in new_tiles], mt.get('pal', 0))
        self.last_import_note = (f"{len(cells)} cell(s) now still: "
                                 + ', '.join(f'{a}->{b}' for a, b in new_of.items()))
        self.touch()
        return {'name': nm, 'tiles': [t & 0x7F for t in new_tiles], 'pal': mt.get('pal', 0)}

    # ------------------------------------------------------------ the op
    def make_animated(self, room_id, mt, effect, mid, frames_a, frames_b=None,
                      name=None, own_sheet=None):
        """Put metatile `mt` (in room `room_id`) into animation `mid`:
        frames_a / frames_b = 4 x 16-byte 2bpp graphics per subtile position
        (TL, TR, BL, BR; frame B only for a flip). Returns the new metatile
        (added to My metatiles); `self.last_import_note` says what happened."""
        assert effect in EFFECTS
        room = self.room(room_id)
        rec = room['record']
        if 'tileset' not in rec:
            if own_sheet is None:
                raise RuntimeError('room borrows a vanilla tileset — pass own_sheet')
            self.localize_tileset(room, own_sheet)
        tid = rec['tileset']
        thr = _val(rec['collision_threshold'])
        cand = next((c for c in self.animate_candidates(room, mt, effect, frames_a, frames_b)
                     if c['map'] == mid), None)
        if cand is None:
            raise RuntimeError(f'${mid:02X} has no {effect} animation')
        split_note = None
        if cand['fits'] and not cand['room_ok'] and cand.get('shift'):
            old_anim = room.get('animation')
            room['animation'] = f'0x{mid:02X}'      # the split may cross the old slots
            offer = {x for f in source_units(mid, effect)
                     for x in ((f,) if effect == 'slide' else f)}
            moved_s, new_thr = self._shift_split(tid, cand['shift'], offer)
            mt = dict(mt, tiles=[(t & 0x80) | moved_s.get(t & 0x7F, t & 0x7F)
                                 for t in mt['tiles']])
            split_note = (f"wall/walkable split moved ${thr:02X} -> ${new_thr:02X} to make room"
                          + (' (' + ', '.join(f'{a}->{b}' for a, b in moved_s.items()) + ')'
                             if moved_s else ''))
            thr = new_thr
            room['animation'] = old_anim            # candidates judge the switch as before
            cand = next((c for c in self.animate_candidates(room, mt, effect, frames_a,
                                                            frames_b) if c['map'] == mid), None)
            if cand is None or not cand['room_ok']:
                raise RuntimeError('moving the wall/walkable split did not make enough room')
        need = units_of(mt['tiles'], frames_a, frames_b or frames_a, effect,
                        self._room_art(room, mt))
        if not cand['fits']:
            raise RuntimeError(
                f"${mid:02X} offers {len(cand['free'])} "
                f"{'slot' if effect == 'slide' else 'pair'}(s); this tile needs "
                f"{len(need)} (one per different 8x8 graphic)")
        cells = self._cells_of(room, mt)
        # assign units -> slots; the unit holding the bottom-right subtile
        # prefers a slot on its current side of the threshold (walkability)
        br_wall = (mt['tiles'][3] & 0x7F) < thr
        free = list(cand['free'])

        def first(x):
            return x if effect == 'slide' else x[0]
        order = sorted(range(len(need)), key=lambda i: 3 not in need[i][0])
        taken = set(cand['taken_slots'])

        def tcost(x):
            return sum(1 for y in ((x,) if effect == 'slide' else x) if y in taken)
        assign = {}
        for i in order:
            if 3 in need[i][0]:
                # never take over a moving tile just for walkability
                pick = min(free, key=lambda x: (tcost(x), (first(x) < thr) != br_wall,
                                                free.index(x)))
            else:
                pick = free[0]
            free.remove(pick)
            assign[i] = pick
        took = sorted({y for x in assign.values()
                       for y in ((x,) if effect == 'slide' else x) if y in taken})
        took_cells = self._cells_touching(room, set(took), mt) if took else 0
        slots_needed = set()
        for x in assign.values():
            slots_needed |= {x} if effect == 'slide' else set(x)
        # switch the room's animation; tiles in use in the slots we write —
        # and, on a SWITCH, in every slot the new animation moves — leave
        switching = self.room_animation(room)['map'] != mid
        # always the explicit id (never 'source'): art made animated on
        # purpose must not look like a stray in a 'source' room (S99 r4)
        room['animation'] = f'0x{mid:02X}'
        anim_after = self.animated_slots(tid)
        sheet = self.read_sheet(tid)
        vac = set(slots_needed) | (set(A.slots(mid)) if switching else set())
        released = self._released_by(room, mt, self.tile_usage(tid)) & self._rewritten(mt, need)
        moved = self._vacate(tid, sheet, vac, released & vac, thr,
                             anim_after | slots_needed, release=released - vac)
        # still quarters keep their graphic; follow it if it had to leave an
        # animated slot
        mv = dict(moved)
        new_tiles = [(t & 0x80) | mv.get(t & 0x7F, t & 0x7F) for t in mt['tiles']]
        for i, (pos, ga, gb) in enumerate(need):
            x = assign[i]
            if effect == 'slide':
                sheet[x * 16:x * 16 + 16] = ga
                slot = x
            else:
                s, p = x
                sheet[s * 16:s * 16 + 16] = ga
                sheet[p * 16:p * 16 + 16] = gb
                slot = s
            for k in pos:
                new_tiles[k] = (mt['tiles'][k] & 0x80) | slot
        self.write_sheet(tid, sheet)
        # this room's cells drawing the tile now draw the animated one
        for lid, cx, cy in cells:
            T = self.layout(lid)['tiles']
            r, c = cy * 2, cx * 2
            T[r][c], T[r][c + 1], T[r + 1][c], T[r + 1][c + 1] = new_tiles
        nm = name or f"animated {effect} (${mid:02X})"
        self.add_metatile(tid, nm, [t & 0x7F for t in new_tiles], mt.get('pal', 0))
        new = {'name': nm, 'tiles': [t & 0x7F for t in new_tiles], 'pal': mt.get('pal', 0)}
        note = ([split_note] if split_note else []) + [f"{effect} with ${mid:02X}'s animation: slots "
                + A.rng([first(x) for x in assign.values()])
                + ('' if effect == 'slide' else
                   f" (second frames in {A.rng([x[1] for x in assign.values()])})")]
        if cells:
            note.append(f'{len(cells)} cell(s) of this room updated')
        if moved:
            note.append('moved ' + ', '.join(f'{a}->{b}' for a, b in moved))
        br = new_tiles[3] & 0x7F
        if (br < thr) != br_wall:
            note.append(f"the tile is now {'a WALL' if br < thr else 'WALKABLE'} "
                        f"(slot {br} sits on that side here)")
        if took:
            note.append(f"took over slot(s) {A.rng(took)}: in {took_cells} cell(s) the quarters "
                        'that moved there now stand still (same look)')
        elif cand['stops'] and switching:
            note.append(f"{cand['stops']} cell(s) animated by the old animation stop moving")
        self.last_import_note = '; '.join(note)
        self.touch()
        return new
