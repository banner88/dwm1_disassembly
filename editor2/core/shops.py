"""shops.py — SHOPS and ITEM PRICES as project data (ROADMAP P3.13c, S117;
PROJECT_COMPILER §2.32; DATA_STRUCTURES "Shops (S117)").

What the game stores (ROM-verified + PyBoy-measured S117):
  * a shop is script opcode $04 $0000 <text base $0680> (screen effect type 0,
    bank $09): BUY / SELL / QUIT. Its BUY state 0 fills the list at $C0D8 (20
    B, $FF-terminated) from one of five lists in bank $09, chosen by the ROOM
    the shopkeeper stands in: map $50 (the gate-floor shop) -> the gate list;
    any other map by wScreenIndex: 0 Bazaar, 2 Starry Night shop, 4 Bookstore,
    anything else the Rare item shop. Every vanilla shopkeeper runs the same
    four words: text $0680, $FF04 $0000 $0680, text $0682, end.
  * the BUY PRICE of an item is +1/+2 of its 12-byte record in ItemInfoTable
    ($03:$71DA, 44 records, ids 0-43); the shop PAYS (bank $09 ShopSellPrice)
    the full price in the gate-floor shop, a staff ($18-$1C, $25, $27) / 10,
    anything else price - price/4.

Patched (S117): bank $09 ShopBuyStockFill's choice + copy (64 B) is a
same-size far call to the compiler-owned bank $77 entry 0 ShopFill, which
copies list wShopID - 1 when a script set wShopID ($D240; it lasts the visit —
every BUY re-runs the fill — and entry 1 ShopClose, the same-size tail of the
shop's close in bank $09, clears it), else applies the vanilla rule above to
the lists in bank $77.
List order in ShopPtrTable: the five vanilla shops (VANILLA_SHOPS order), then
the project's custom.shops.

Schema:
  "gamedata": {
    "items": {"1": {"price": 12}},                     # Herb costs 12
    "shops": {"bazaar": [1, 2, 7, 40, 19, 20, 29, 38]} # a vanilla shop's list
  },
  "custom": {
    "shops": [{"id": "pier_shop", "name": "Pier stall", "items": [1, 5, 29]}],
    "scripts": [{"id": "pier_keeper", "shop": {"shop": "pier_shop",
                                               "text": "pier_hello"}}]
  }
A `shop` script = a shopkeeper's talk: its own greeting (a dialogue id; none
= the vanilla "Item shop. May I help you?"), the shop, then the vanilla
"Thank you. Come again!". Lowered to: text, write_ram wShopID n+1,
op $04 0 $0680 (the shop opcode, handler $04:$57A1, 2 params; left unnamed in
scriptgen.OPS — a name there would make Document._migrate rewrite every raw
"0x04" in existing projects), text $0682, end.

Limits (ERROR): an item id outside 1-43; a list empty or longer than 20 (the
$C0D8 buffer the shop clears and counts); a price outside 0-65535; more than
250 lists; a `shop` script naming an unknown shop.
"""

import json
import os

ITEM_COUNT = 44                 # records 0-43 (0 = no item)
LIST_MAX = 20                   # $C0D8 cleared x 20, ShopCountItems stops at 20
VANILLA_SHOPS = [               # (key, label, table, rule)
    ('bazaar', 'Bazaar item shop', 'shop_bazaar', 'any room, screen 0'),
    ('starry', 'Starry Night shop', 'shop_starry', 'any room, screen 2'),
    ('books', 'Bookstore', 'shop_books', 'any room, screen 4'),
    ('rare', 'Rare item shop', 'shop_rare', 'any room, screen 5 (and other screens)'),
    ('gate', 'Gate-floor shop', 'shop_gate', 'map $50 (the shop room inside gates)'),
]
SHOP_TEXT_BASE = 0x0680         # the vanilla shop's texts (+0 hello, +2 bye)
STAFFS = {0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x25, 0x27}


class ShopError(ValueError):
    pass


def _repo():
    return os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))


_VAN = {}


def vanilla(repo_root=None):
    """{'items': [12-byte records] x 44, 'shops': {key: [ids]}} from
    extracted/gamedata_vanilla.json (S117 tables item_info / shop_*)."""
    repo = repo_root or _repo()
    if repo not in _VAN:
        t = json.load(open(os.path.join(repo, 'extracted', 'gamedata_vanilla.json')))['tables']
        items = [bytes.fromhex(r) for r in t['item_info']['rows']]
        shops = {k: [int(r, 16) for r in t[tab]['rows'][:-1]] for k, _l, tab, _r in VANILLA_SHOPS}
        _VAN[repo] = {'items': items, 'shops': shops}
    return _VAN[repo]


def item_names(repo_root=None):
    """{id: display name} from disassembly/items.inc (ITEM_BEEF_JERKY -> BeefJerky)."""
    import re
    repo = repo_root or _repo()
    out = {}
    try:
        for ln in open(os.path.join(repo, 'disassembly', 'items.inc')):
            m = re.match(r'DEF ITEM_(\w+) EQU \$([0-9A-Fa-f]+)', ln)
            if m:
                out[int(m.group(2), 16)] = ''.join(w.capitalize() for w in m.group(1).split('_'))
    except OSError:
        pass
    return out


def sell_price(item, price, gate_shop=False):
    """What a shop pays (bank $09 ShopSellPrice)."""
    if gate_shop:
        return price
    if item in STAFFS:
        return price // 10
    return price - price // 4


def _int(v, what):
    try:
        return int(v, 0) if isinstance(v, str) else int(v)
    except (TypeError, ValueError):
        raise ShopError(f"{what}: {v!r} is not a number")


def _data(prj_or_data):
    return getattr(prj_or_data, 'data', prj_or_data)


def _check_list(lst, what):
    if not isinstance(lst, list) or not lst:
        raise ShopError(f"{what}: a list of 1-{LIST_MAX} item ids")
    if len(lst) > LIST_MAX:
        raise ShopError(f"{what}: {len(lst)} items — a shop shows at most {LIST_MAX} "
                        "(the list buffer at $C0D8)")
    out = []
    for i, v in enumerate(lst):
        n = _int(v, f"{what}[{i}]")
        if not 1 <= n < ITEM_COUNT:
            raise ShopError(f"{what}[{i}]: item {n} — items are 1-{ITEM_COUNT - 1}")
        out.append(n)
    return out


def resolve(prj_or_data, repo_root=None):
    """{'prices': [44], 'lists': [(key, label, [ids], vanilla?)], 'index': {key: n},
    'edited_prices': set} — raises ShopError."""
    d = _data(prj_or_data)
    repo = repo_root or getattr(prj_or_data, 'repo_root', None) or _repo()
    van = vanilla(repo)
    gd = d.get('gamedata') or {}
    prices = [r[1] | r[2] << 8 for r in van['items']]
    edited = set()
    items = gd.get('items') or {}
    if not isinstance(items, dict):
        raise ShopError('gamedata.items: an object keyed by item id ("1"-"43")')
    for k, e in items.items():
        if str(k).startswith('_'):
            continue
        what = f"gamedata.items.{k}"
        i = _int(k, what)
        if not 1 <= i < ITEM_COUNT:
            raise ShopError(f"{what}: items are 1-{ITEM_COUNT - 1}")
        if not isinstance(e, dict):
            raise ShopError(f"{what}: an object ({{\"price\": n}})")
        extra = {x for x in e if not str(x).startswith('_')} - {'price', 'comment'}
        if extra:
            raise ShopError(f"{what}: unknown field(s) {sorted(extra)} (price)")
        if 'price' in e:
            p = _int(e['price'], what + '.price')
            if not 0 <= p <= 0xFFFF:
                raise ShopError(f"{what}.price {p}: 0-65535 gold (a 16-bit word)")
            prices[i] = p
            if p != (van['items'][i][1] | van['items'][i][2] << 8):
                edited.add(i)
    shops = gd.get('shops') or {}
    if not isinstance(shops, dict):
        raise ShopError('gamedata.shops: an object keyed by ' +
                        ', '.join(k for k, *_ in VANILLA_SHOPS))
    lists, index = [], {}
    for key, label, _tab, rule in VANILLA_SHOPS:
        if key in shops:
            lst = _check_list(shops[key], f"gamedata.shops.{key}")
        else:
            lst = list(van['shops'][key])
        index[key] = len(lists)
        lists.append((key, label, lst, True))
    bad = [k for k in shops if not str(k).startswith('_') and k not in index]
    if bad:
        raise ShopError(f"gamedata.shops: unknown shop(s) {bad} — the vanilla shops are "
                        + ', '.join(k for k, *_ in VANILLA_SHOPS) + " (new ones: custom.shops)")
    for i, s in enumerate((d.get('custom') or {}).get('shops') or []):
        what = f"custom.shops[{i}]"
        if not isinstance(s, dict) or not s.get('id'):
            raise ShopError(f"{what}: needs an \"id\"")
        extra = {x for x in s if not str(x).startswith('_')} - {'id', 'name', 'items', 'comment'}
        if extra:
            raise ShopError(f"{what}: unknown field(s) {sorted(extra)} (id, name, items)")
        sid = str(s['id'])
        if sid in index:
            raise ShopError(f"{what}: shop id {sid!r} is used twice (or is a vanilla shop's)")
        index[sid] = len(lists)
        lists.append((sid, s.get('name') or sid, _check_list(s.get('items'), what + '.items'),
                      False))
    if len(lists) > 250:
        raise ShopError(f"{len(lists)} shop lists — at most 250 (wShopID is one byte)")
    return {'prices': prices, 'lists': lists, 'index': index, 'edited_prices': edited}


def shop_id_byte(prj, key, ctx=''):
    """wShopID value a `shop` script writes (list index + 1)."""
    r = resolve(prj)
    if key not in r['index']:
        raise ShopError(f"{ctx}: unknown shop {key!r} — " +
                        ', '.join(r['index']))
    return r['index'][key] + 1


def check(prj):
    resolve(prj)
    return []


# ---------------------------------------------------------------------------
# emitters
# ---------------------------------------------------------------------------

def emit_item_info(prj, warnings):
    r = resolve(prj)
    van = vanilla(getattr(prj, 'repo_root', None))
    names = item_names(getattr(prj, 'repo_root', None))
    out = ["ItemInfoTable:  ; 44 x 12 B; +1/+2 = buy price (gamedata.items.<id>.price)"]
    for i, rec in enumerate(van['items']):
        b = bytearray(rec)
        if i:
            b[1], b[2] = r['prices'][i] & 0xFF, r['prices'][i] >> 8
        what = f"[{i:2d}] {names.get(i, 'none')}" + (f", price {r['prices'][i]}" if i else '')
        out.append("    db " + ", ".join(f"${x:02x}" for x in b) + f"   ; {what}"
                   + ("   ; (edited)" if i in r['edited_prices'] else ''))
    return "\n".join(out) + "\n"


def emit_bank_077(prj, warnings, head):
    r = resolve(prj)
    names = item_names(getattr(prj, 'repo_root', None))
    nv = len(VANILLA_SHOPS)
    out = [head.rstrip('\n'), "",
           "; " + "=" * 77,
           "; SHOP LISTS (generated by editor2 `shops77` from gamedata.shops + custom.shops,",
           "; PROJECT_COMPILER §2.32). Order: the five vanilla shops, then the project's.",
           "; " + "=" * 77, "",
           f"SHOP_COUNT EQU {len(r['lists'])}",
           "ShopPtrTable:"]
    for n, (key, label, lst, is_v) in enumerate(r['lists']):
        out.append(f"    dw ShopList_{n}   ; {n}: {label}" + ("" if is_v else f" (custom.shops '{key}')"))
    out.append("")
    for n, (key, label, lst, is_v) in enumerate(r['lists']):
        out.append(f"ShopList_{n}:  ; {label} — " + ", ".join(names.get(i, str(i)) for i in lst))
        out.append("    db " + ", ".join(f"${i:02x}" for i in lst) + ", $ff")
    out.append("")
    if nv != 5:
        raise ShopError('internal: the template assumes five vanilla shops')
    return "\n".join(out) + "\n"


REGIONS = [('gd_item_info', 'patches/bank_003.asm', emit_item_info, 0x03)]
