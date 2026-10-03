"""shops_doc.py — the Shops tab's model (ROADMAP P3.13c, S117; compiler:
editor2/core/shops.py, PROJECT_COMPILER §2.32).

Mixed into Document. Every mutation edits project data only:
  * gamedata.items.<id>.price            the buy price of an item (all shops)
  * gamedata.shops.<vanilla key>         a vanilla shop's list
  * custom.shops[]                       the project's own shops
  * custom.scripts[] {"shop": {...}}     a shopkeeper (an NPC's script)
"""

from editor2.core import shops as SH


def _ival(v):
    if isinstance(v, int):
        return v
    s = str(v).strip()
    return int(s[1:], 16) if s.startswith('$') else int(s, 0)


class ShopsMixin:
    # ------------------------------------------------------------ reading
    def shops_resolved(self):
        return SH.resolve(self.data, getattr(self, 'repo_root', None))

    def shop_item_names(self):
        return SH.item_names(getattr(self, 'repo_root', None))

    def shop_list(self):
        """[{key, name, items, vanilla, rule, edited, sellers}] in ShopPtrTable order."""
        r = self.shops_resolved()
        van = SH.vanilla(getattr(self, 'repo_root', None))['shops']
        rules = {k: rule for k, _l, _t, rule in SH.VANILLA_SHOPS}
        out = []
        for key, label, lst, is_v in r['lists']:
            out.append({'key': key, 'name': label, 'items': list(lst), 'vanilla': is_v,
                        'rule': rules.get(key, ''),
                        'edited': is_v and lst != van[key],
                        'sellers': self.shopkeepers(key)})
        return out

    def item_rows(self):
        """[{id, name, price, vanilla_price, sell, sell_gate, shops}] for items 1-43."""
        r = self.shops_resolved()
        van = SH.vanilla(getattr(self, 'repo_root', None))['items']
        names = self.shop_item_names()
        shops = {}
        for key, label, lst, _v in r['lists']:
            for i in lst:
                shops.setdefault(i, []).append(label)
        out = []
        for i in range(1, SH.ITEM_COUNT):
            p = r['prices'][i]
            out.append({'id': i, 'name': names.get(i, f'item {i}'), 'price': p,
                        'vanilla_price': van[i][1] | van[i][2] << 8,
                        'sell': SH.sell_price(i, p), 'sell_gate': SH.sell_price(i, p, True),
                        'shops': shops.get(i, [])})
        return out

    def shopkeepers(self, key):
        """[(room, screen key, state index, npc entry, script id)] whose script
        sells shop `key`."""
        sids = {s['id'] for s in self.custom.get('scripts', [])
                if isinstance(s.get('shop'), dict) and s['shop'].get('shop') == key}
        out = []
        if not sids:
            return out
        for r in self.rooms:
            if r.get('placeholder'):
                continue
            table = r.get('scripts') or {}
            for k in self.screen_keys(r):
                for n, st in enumerate(self.states(r, k)):
                    for e in st.get('npcs') or []:
                        sc = e.get('script')
                        if isinstance(sc, int):
                            sc = table.get(str(sc))
                        if sc in sids:
                            out.append((r, k, n, e, sc))
        return out

    def shop_script(self, sid):
        for s in self.custom.get('scripts', []):
            if s.get('id') == sid and isinstance(s.get('shop'), dict):
                return s
        return None

    # ------------------------------------------------------------ editing
    def set_item_price(self, item, price):
        """price None = the game's own price."""
        item = int(item)
        if not 1 <= item < SH.ITEM_COUNT:
            raise ValueError(f'items are 1-{SH.ITEM_COUNT - 1}')
        gd = self.data.setdefault('gamedata', {})
        items = gd.setdefault('items', {})
        van = SH.vanilla(getattr(self, 'repo_root', None))['items'][item]
        if price is None or int(price) == (van[1] | van[2] << 8):
            items.pop(str(item), None)
        else:
            p = int(price)
            if not 0 <= p <= 0xFFFF:
                raise ValueError('a price is 0-65535 gold')
            items[str(item)] = {'price': p}
        if not items:
            gd.pop('items')
        self.touch()

    def set_shop_items(self, key, items):
        items = [int(i) for i in items]
        SH._check_list(items, f'shop {key}')
        vk = [k for k, *_ in SH.VANILLA_SHOPS]
        if key in vk:
            gd = self.data.setdefault('gamedata', {})
            shops = gd.setdefault('shops', {})
            if items == SH.vanilla(getattr(self, 'repo_root', None))['shops'][key]:
                shops.pop(key, None)
            else:
                shops[key] = items
            if not shops:
                gd.pop('shops')
        else:
            s = self._project_shop(key)
            s['items'] = items
        self.touch()

    def _project_shop(self, key):
        for s in self.custom.get('shops') or []:
            if s.get('id') == key:
                return s
        raise ValueError(f'no project shop {key!r}')

    def new_shop(self, name, items=None):
        lst = self.custom.setdefault('shops', [])
        taken = {s.get('id') for s in lst} | {k for k, *_ in SH.VANILLA_SHOPS}
        sid = self._unique_id(self._slug(name) or 'shop', taken)
        lst.append({'id': sid, 'name': str(name).strip() or sid,
                    'items': [int(i) for i in (items or [1])]})
        self.touch()
        return sid

    def rename_shop(self, key, name):
        self._project_shop(key)['name'] = str(name).strip() or key
        self.touch()

    def delete_shop(self, key):
        """Remove a project shop; its shopkeepers' scripts go and those NPCs
        no longer talk. Returns the number of NPCs that sold it."""
        s = self._project_shop(key)
        n = len(self.shopkeepers(key))
        self.custom['shops'].remove(s)
        if not self.custom['shops']:
            self.custom.pop('shops')
        gone = {x['id'] for x in self.custom.get('scripts', [])
                if isinstance(x.get('shop'), dict) and x['shop'].get('shop') == key}
        self._drop_shop_scripts(gone)
        self.touch()
        return n

    def _drop_shop_scripts(self, sids):
        if not sids:
            return
        for sc in [x for x in self.custom.get('scripts', []) if x.get('id') in sids]:
            did = (sc.get('shop') or {}).get('text')
            if did:
                self.custom['dialogue'] = [d for d in self.custom.get('dialogue', [])
                                           if d.get('id') != did]
            self.custom['scripts'].remove(sc)
        for r in self.rooms:
            table = r.get('scripts') or {}
            idx = {k for k, v in table.items() if v in sids}
            for k in idx:
                table.pop(k)
            for k in self.screen_keys(r):
                for st in self.states(r, k):
                    for e in st.get('npcs') or []:
                        sc = e.get('script')
                        if sc in sids or (isinstance(sc, int) and str(sc) in idx):
                            e['script'] = None

    def make_shopkeeper(self, room, key, state_idx, index, shop, greeting=None):
        """NPC npcs[index] of (room, key, state) sells `shop`; `greeting` =
        boxes (list of [line, line]) shown first, None = the game's "Item
        shop. May I help you?". Returns the script id."""
        r = self.shops_resolved()
        if shop not in r['index']:
            raise ValueError(f'unknown shop {shop!r}')
        lst = self.npc_entries(room, key, state_idx)
        e = lst[index]
        old = e.get('script')
        if isinstance(old, int):
            old = (room.get('scripts') or {}).get(str(old))
        prev = self.shop_script(old) if isinstance(old, str) else None
        scripts = self.custom.setdefault('scripts', [])
        if prev is not None:
            sid = prev['id']
            did = prev['shop'].get('text')
            if did:
                self.custom['dialogue'] = [d for d in self.custom.get('dialogue', [])
                                           if d.get('id') != did]
            spec = {'shop': shop}
            if greeting:
                spec['text'] = self._talk_entry(sid, greeting)
            prev['shop'] = spec
        else:
            sids = {s.get('id') for s in scripts}
            sid = self._unique_id(f"{room['id']}_shop", sids)
            spec = {'shop': shop}
            if greeting:
                spec['text'] = self._talk_entry(sid, greeting)
            scripts.append({'id': sid, 'shop': spec})
            table = room.setdefault('scripts', {})
            if '0' not in table:
                eid = self._unique_id(f"{room['id']}_entry", sids | {sid})
                scripts.append({'id': eid, 'ops': [['end']]})
                table['0'] = eid
            n = 1
            while str(n) in table:
                n += 1
            table[str(n)] = sid
            if e.get('kind') == 'raw':
                v = self.npc_view(room, e)
                v['script'] = sid
                lst[index] = self._npc_entry(v)
            else:
                e['script'] = sid
        self.touch()
        return sid

    def shopkeeper_of(self, room, key, state_idx, index):
        """(shop key, greeting boxes or None) when that NPC is a shopkeeper."""
        e = self.npc_entries(room, key, state_idx)[index]
        sc = e.get('script')
        if isinstance(sc, int):
            sc = (room.get('scripts') or {}).get(str(sc))
        s = self.shop_script(sc) if isinstance(sc, str) else None
        if s is None:
            return None
        did = s['shop'].get('text')
        boxes = None
        if did:
            for d in self.custom.get('dialogue', []):
                if d.get('id') == did:
                    boxes = d.get('boxes')
        return s['shop'].get('shop'), boxes
