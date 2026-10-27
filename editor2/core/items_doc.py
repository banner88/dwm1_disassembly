"""items_doc.py — the Items tab's model (S151, ROADMAP E9; compiler:
editor2/core/items.py, PROJECT_COMPILER §2.59).

Mixed into Document. Every mutation edits project data only:
  * gamedata.items.<1-43>.<field>      the game's items (sparse; a value equal to the
                                       game's own is removed)
  * gamedata.text.item_name / item_description.<1-43>   their name / description
  * gamedata.skills.<176-212>.record   the battle half of the game's items 1-37 (power,
                                       range, usable in battle — the item's battle skill)
  * custom.items[]                     the project's NEW items 44-127 (everything in the
                                       entry: name, description, base, fields, own lines)
"""

from editor2.core import items as IT
from editor2.core import gametext as GT
from editor2.core import textmark as TM

# the editor's fields (the record bytes behind them: items.py)
FIELD_KEYS = ('price', 'consume', 'field_use', 'pick_monster', 'use_message',
              'result_message', 'power', 'sellable', 'keep_on_loss')
BATTLE_ITEMS = range(1, 38)        # items 1-37 = the item_effect skills 176-212
SKILL_OF = lambda i: i + 0xAF      # noqa: E731 — bank $50 / $77 BattleSkillOf


def _skill_records(repo_root=None):
    import json
    import os
    path = os.path.join(IT._repo(repo_root), 'extracted', 'skill_records.json')
    return {r['id']: r for r in json.load(open(path))['records']}


class ItemsMixin:
    # ------------------------------------------------------------ reading
    def items_resolved(self):
        return IT.resolve(self.data, getattr(self, 'repo_root', None))

    def new_item_entry(self, i):
        for e in self.custom.get('items') or []:
            if isinstance(e, dict) and e.get('id') == i:
                return e
        return None

    def item_names_all(self):
        """{id: name} of every item (the game's 43 — edited names included — + the new)."""
        out = dict(IT.names(self.data, getattr(self, 'repo_root', None)))
        rows = ((self.data.get('gamedata') or {}).get('text') or {}).get('item_name') or {}
        for k, v in rows.items():
            try:
                out[int(k)] = TM.plain(v) if hasattr(TM, 'plain') else v
            except (TypeError, ValueError):
                pass
        return out

    def item_list(self):
        """[{id, name, base, new, edited}] — the game's items 1-43, then the project's."""
        r = self.items_resolved()
        names = self.item_names_all()
        out = []
        for i in range(1, IT.GAME_ITEMS):
            out.append({'id': i, 'name': names.get(i, f'item {i}'), 'base': i, 'new': False,
                        'edited': self._game_item_edited(i, r)})
        for i in sorted(r['new']):
            out.append({'id': i, 'name': names.get(i, f'item {i}'), 'base': r['base'][i],
                        'new': True, 'edited': True})
        return out

    def _game_item_edited(self, i, r=None):
        r = r or self.items_resolved()
        gd = self.data.get('gamedata') or {}
        txt = (gd.get('text') or {})
        if i in r['edited']:
            return True
        for src in ('item_name', 'item_description'):
            if str(i) in (txt.get(src) or {}):
                return True
        if i in BATTLE_ITEMS and str(SKILL_OF(i)) in (gd.get('skills') or {}):
            return 'record' in (gd['skills'][str(SKILL_OF(i))] or {})
        return False

    def item_info(self, i):
        """Everything the Items tab shows of item i."""
        r = self.items_resolved()
        repo = getattr(self, 'repo_root', None)
        if i not in r['new'] and not 1 <= i < IT.GAME_ITEMS:
            raise KeyError(f'item {i}')
        rec = r['records'][i]
        f = IT.decode(rec)
        base = r['base'][i]
        new = i in r['new']
        names = self.item_names_all()
        ix = GT.index(repo)
        if new:
            e = self.new_item_entry(i)
            name, desc = e.get('name', ''), e.get('description') or ''
            van = IT.decode(IT.vanilla_records(repo)[base])
        else:
            name = self.game_text('item_name', str(i))['markup']
            desc = self.game_text('item_description', str(i))['markup']
            van = IT.decode(IT.vanilla_records(repo)[i])
            e = None
        out = {'id': i, 'new': new, 'base': base, 'base_name': names.get(base, str(base)),
               'name': name, 'description': desc, 'fields': f, 'vanilla': van,
               'effect': IT.describe_effect(base, f['power']),
               'effect_kind': IT.EFFECTS.get(base, ('?', ''))[0],
               'sell': self._sell_price(base, f['price']),
               'use_text': (e or {}).get('use_text'), 'result_text': (e or {}).get('result_text'),
               'use_line': self._use_line(f['use_message'], r),
               'result_line': self._use_line(f['result_message'], r) if f['result_message'] else '',
               'battle': self._battle_info(i, base),
               # S157 (ROADMAP E9): used-up chance 0 = ONE-ONLY (items.one_only, loot.py)
               'one_only': i in r.get('one_only', ()),
               'loot_notes': self._loot_notes(i) if i in r.get('one_only', ()) else []}
        return out

    def _loot_notes(self, i):
        """S157: where item i (one-only) no longer appears in the random gates."""
        from . import loot as LT
        nm = self.item_names_all().get(i, str(i))
        return [n for n in LT.notes(self, getattr(self, 'repo_root', None))
                if n.startswith(nm + ':')]

    # ---- S157: the one-only rule's line (gamedata.item_rules)
    def item_rule(self, key):
        """The markup of a one-only rule line ('already_has'): the project's or the default."""
        if key != 'already_has':
            raise KeyError(key)
        return IT.already_has_markup(self)

    def set_item_rule(self, key, markup):
        """Set (or, empty / the default, remove) gamedata.item_rules[key]."""
        if key not in IT.RULES_KEYS:
            raise KeyError(key)
        txt = (markup or '').rstrip('\n')
        if txt:
            TM.encode(txt, 'box')                                   # validates
        gd = self.data.setdefault('gamedata', {})
        rules = gd.setdefault('item_rules', {})
        if not txt or txt == IT.DEFAULT_ALREADY_HAS:
            rules.pop(key, None)
        else:
            rules[key] = txt
        if not rules:
            gd.pop('item_rules', None)
        self.touch()

    def one_only_names(self):
        """[(id, name)] of the project's one-only items."""
        names = self.item_names_all()
        return [(i, names.get(i, str(i))) for i in sorted(self.items_resolved().get('one_only', ()))]

    @staticmethod
    def _sell_price(base, price):
        from editor2.core import shops as SH
        return SH.sell_price(base, price)

    def _use_line(self, n, r=None):
        """The words of item use line n (the game's 0-47 or a project item's own)."""
        if n < IT.USE_MESSAGES:
            try:
                return self.game_text('item_use_message', str(n))['markup']
            except KeyError:
                return ''
        r = r or self.items_resolved()
        for (i, kind), m in r['messages'].items():
            if m == n:
                e = self.new_item_entry(i) or {}
                return e.get('use_text' if kind == 'use' else 'result_text') or ''
        return f'(line {n}: none)'

    def use_lines(self):
        """[(n, words)] of the game's 48 item use lines."""
        return [(n, self._use_line(n)) for n in range(IT.USE_MESSAGES)]

    def _battle_record(self, sid):
        """The item skill's 19-byte record with the project's gamedata.skills overrides."""
        from editor2.core.gamedata import RECORD_FIELDS
        rec = bytearray.fromhex(_skill_records(getattr(self, 'repo_root', None))[sid]
                                ['battle_record']['raw'])
        o = (((self.data.get('gamedata') or {}).get('skills') or {}).get(str(sid)) or {})
        for n, off, size in RECORD_FIELDS:
            v = (o.get('record') or {}).get(n)
            if v is None:
                continue
            v = int(v, 0) if isinstance(v, str) else int(v)
            rec[off] = v & 0xFF
            if size == 2:
                rec[off + 1] = v >> 8
        return bytes(rec)

    def _battle_info(self, i, base):
        """{'skill', 'usable', 'power', 'range', 'own', 'item_effect'} — the battle half:
        the item's (a project item: its base's) item skill record."""
        sid = SKILL_OF(base)
        rec = self._battle_record(sid)
        return {'skill': sid, 'usable': rec[10] != 1,
                'power': rec[11] | rec[12] << 8, 'range': rec[13] | rec[14] << 8,
                'own': i < IT.GAME_ITEMS and base in BATTLE_ITEMS,
                'item_effect': base in BATTLE_ITEMS}

    def item_uses(self, i):
        """[words] — where item i is sold / given / checked (shops, item sets, story checks
        and commands, scripts, cutscenes, quests)."""
        out = []
        try:
            for sh in self.shop_list():
                if i in sh['items']:
                    out.append(f"sold by {sh['name']}")
        except Exception:                                    # noqa: BLE001
            pass
        for st in self.custom.get('shop_sets') or []:
            if i in (st.get('items') or []):
                out.append(f"sold in the item set {st.get('name') or st.get('shop')}")
        for c in self.custom.get('checks') or []:
            if c.get('kind') == 'item' and _int(c.get('item')) == i:
                out.append(f"story check {c.get('name')}")

        def walk(node, where):
            if isinstance(node, dict):
                for k, v in node.items():
                    if k in ('give_item', 'take_item') and isinstance(v, dict) and \
                            _int(v.get('item')) == i:
                        out.append(f"{k.replace('_', ' ')} in {where}")
                    else:
                        walk(v, where)
            elif isinstance(node, list):
                if len(node) >= 3 and node[0] == 'op' and node[1] == 'give_item' and \
                        _int(node[2]) == i:
                    out.append(f"give item op in {where}")
                for v in node:
                    walk(v, where)
        for s in self.custom.get('scripts') or []:
            walk(s, f"script {s.get('id')}")
        for r in self.custom.get('rooms') or []:
            walk(r.get('cutscenes') or [], f"the cutscenes of {r.get('name') or r.get('id')}")
        for q in self.custom.get('quests') or []:
            walk(q, f"quest {q.get('name') or q.get('id')}")
        return out

    # ------------------------------------------------------------ editing
    def _gd_items(self):
        return self.data.setdefault('gamedata', {}).setdefault('items', {})

    def _tidy_gd_items(self):
        gd = self.data.get('gamedata') or {}
        if 'items' in gd and not gd['items']:
            gd.pop('items')

    def set_item_field(self, i, field, value):
        """One field of item i (FIELD_KEYS). A game item's field equal to the game's own
        value is removed (sparse); a new item keeps every field it sets."""
        if field not in FIELD_KEYS:
            raise ValueError(f'no item field {field!r}')
        if i >= IT.GAME_ITEMS:
            e = self.new_item_entry(i)
            if e is None:
                raise KeyError(f'item {i}')
            trial = dict(e)
            trial[field] = value
            if field in ('use_message', 'result_message'):
                trial.pop('use_text' if field == 'use_message' else 'result_text', None)
            self._check_new(trial)
            e[field] = value
            if field == 'use_message':
                e.pop('use_text', None)
            if field == 'result_message':
                e.pop('result_text', None)
            self.touch()
            return
        if not 1 <= i < IT.GAME_ITEMS:
            raise KeyError(f'item {i}')
        van = IT.decode(IT.vanilla_records(getattr(self, 'repo_root', None))[i])
        rec = bytearray(IT.vanilla_records(getattr(self, 'repo_root', None))[i])
        IT.apply_fields(rec, {field: value}, f'item {i}')          # validates
        items = self._gd_items()
        ent = items.setdefault(str(i), {})
        if value == van[field]:
            ent.pop(field, None)
        else:
            ent[field] = value
        if not ent:
            items.pop(str(i), None)
        self._tidy_gd_items()
        self.touch()

    def set_item_name(self, i, markup):
        if i >= IT.GAME_ITEMS:
            e = self.new_item_entry(i)
            if e is None:
                raise KeyError(f'item {i}')
            self._check_new(dict(e, name=markup))
            e['name'] = markup
            self.touch()
        else:
            self.set_game_text('item_name', str(i), markup, only_this=True)

    def set_item_description(self, i, markup):
        if i >= IT.GAME_ITEMS:
            e = self.new_item_entry(i)
            if e is None:
                raise KeyError(f'item {i}')
            if markup:
                self._check_new(dict(e, description=markup))
                e['description'] = markup
            else:
                e.pop('description', None)
            self.touch()
        else:
            self.set_game_text('item_description', str(i), markup, only_this=True)

    def set_item_own_line(self, i, which, markup):
        """A new item's OWN use / result line (which = 'use' | 'result'); markup None =
        back to a game line (the base's)."""
        e = self.new_item_entry(i)
        if e is None:
            raise ValueError('only the project\'s items have lines of their own — the game\'s '
                             'items pick one of the 48 lines (or edit it on the Text tab)')
        key = 'use_text' if which == 'use' else 'result_text'
        num = 'use_message' if which == 'use' else 'result_message'
        if markup:
            trial = dict(e)
            trial[key] = markup
            trial.pop(num, None)
            self._check_new(trial)
            e[key] = markup
            e.pop(num, None)
        else:
            e.pop(key, None)
        self.touch()

    def set_item_battle(self, i, power=None, range_=None, usable=None):
        """The battle half of the game's items 1-37 = their item skill's record (power =
        party_min / enemy_min, range = party_range / enemy_range, usable = field10)."""
        if i not in BATTLE_ITEMS:
            raise ValueError('only the game\'s items 1-37 have a battle record of their own '
                             '(a project item uses its base\'s)')
        sid = SKILL_OF(i)
        from editor2.core.gamedata import RECORD_FIELDS
        raw = bytes.fromhex(_skill_records(getattr(self, 'repo_root', None))[sid]
                            ['battle_record']['raw'])
        off = {n: o for n, o, _s in RECORD_FIELDS}

        def van16(n):
            return raw[off[n]] | raw[off[n] + 1] << 8
        sk = self.data.setdefault('gamedata', {}).setdefault('skills', {})
        ent = sk.setdefault(str(sid), {})
        rec = ent.setdefault('record', {})
        if power is not None:
            if not 0 <= int(power) <= 999:
                raise ValueError('a battle power is 0-999')
            for n in ('party_min', 'enemy_min'):
                if int(power) == van16(n):
                    rec.pop(n, None)
                else:
                    rec[n] = int(power)
        if range_ is not None:
            if not 0 <= int(range_) <= 999:
                raise ValueError('a range is 0-999')
            for n in ('party_range', 'enemy_range'):
                if int(range_) == van16(n):
                    rec.pop(n, None)
                else:
                    rec[n] = int(range_)
        if usable is not None:
            if usable:
                if raw[off['field10']] == 1:
                    raise ValueError('this item cannot be used in battle in the game (its '
                                     'battle skill does nothing there)')
                rec.pop('field10', None)
            else:
                rec['field10'] = 1                       # 1 = not usable in battle
        if not rec:
            ent.pop('record', None)
        if not ent:
            sk.pop(str(sid), None)
        if not sk:
            self.data['gamedata'].pop('skills', None)
        self.touch()

    def _check_new(self, e):
        rows = [x if x.get('id') != e.get('id') else e for x in (self.custom.get('items') or [])]
        trial = {'custom': {'items': rows}}
        IT.resolve(trial, getattr(self, 'repo_root', None))

    def new_item(self, base, name=None, copy_of=None):
        """A new item working like `base` (1-43); copy_of = an item whose fields it starts
        with (default: the base). -> the new id."""
        base = int(base)
        if not 1 <= base < IT.GAME_ITEMS:
            raise ValueError('an item works like one of the game\'s items 1-43')
        i = IT.free_id(self.data)
        if i is None:
            raise ValueError(f'the project has {IT.ID_MAX + 1 - IT.FIRST_NEW} items — the most '
                             'there can be (ids 44-127)')
        src = copy_of if copy_of is not None else base
        info = self.item_info(src)
        names = set(self.item_names_all().values())
        nm = name or info['base_name'][:7] + '+'
        k = 2
        while nm in names:
            nm = (name or info['base_name'])[:7] + str(k)
            k += 1
        e = {'id': i, 'name': nm, 'base': base}
        for k2 in FIELD_KEYS:
            e[k2] = info['fields'][k2]
        if info['description']:
            e['description'] = info['description']
        if copy_of is not None and copy_of >= IT.GAME_ITEMS:
            src_e = self.new_item_entry(copy_of) or {}
            for k3 in ('use_text', 'result_text'):
                if src_e.get(k3):
                    e[k3] = src_e[k3]
                    e.pop('use_message' if k3 == 'use_text' else 'result_message', None)
        self._check_new(e)
        self.custom.setdefault('items', []).append(e)
        self.touch()
        return i

    def set_item_base(self, i, base):
        e = self.new_item_entry(i)
        if e is None:
            raise ValueError('the game\'s items keep their own code')
        self._check_new(dict(e, base=int(base)))
        e['base'] = int(base)
        self.touch()

    def delete_item(self, i, force=False):
        e = self.new_item_entry(i)
        if e is None:
            raise ValueError('only the project\'s items can be deleted')
        uses = self.item_uses(i)
        if uses and not force:
            raise ValueError(f"{e.get('name')} is still used: " + '; '.join(uses[:6]))
        self.custom['items'] = [x for x in self.custom['items'] if x is not e]
        if not self.custom['items']:
            self.custom.pop('items')
        self.touch()

    def reset_item(self, i):
        """A game item back to the game's: fields, name, description, battle record."""
        if not 1 <= i < IT.GAME_ITEMS:
            raise ValueError('only the game\'s items have an original')
        items = (self.data.get('gamedata') or {}).get('items') or {}
        items.pop(str(i), None)
        self._tidy_gd_items()
        for src in ('item_name', 'item_description'):
            GT.set_edit(self.data, src, str(i), None)
        if i in BATTLE_ITEMS:
            sk = (self.data.get('gamedata') or {}).get('skills') or {}
            ent = sk.get(str(SKILL_OF(i)))
            if ent is not None:
                ent.pop('record', None)
                if not ent:
                    sk.pop(str(SKILL_OF(i)))
                if not sk:
                    self.data['gamedata'].pop('skills', None)
        self.touch()


def _int(v):
    try:
        return int(v, 0) if isinstance(v, str) else int(v)
    except (TypeError, ValueError):
        return None
