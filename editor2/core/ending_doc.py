"""ending_doc.py — editing the title screen and the credits (S153, ROADMAP E5).

Headless Document mixin (no Qt): custom.title / custom.credits (editor2/core/
ending.py, PROJECT_COMPILER §2.61). The dialog (editor2/app/ending_dialog.py)
reads and writes only through these; every change is one undo step there
(SnapshotCommand).
"""

import copy

from editor2.core import ending as EN


class EndingMixin:
    # ------------------------------------------------------------ the title
    def title_settings(self):
        """{'lines': [...], 'song': x | None} (a copy; empty when unset)."""
        t = copy.deepcopy(self.custom.get('title') or {})
        t.setdefault('lines', [])
        t.setdefault('song', None)
        return t

    def set_title(self, lines=None, song=None, keep_song=False):
        """Replace the title's lines (a list of {text, row, align|col, colour}) and its
        song (None = the game's $06). Nothing left = no custom.title."""
        t = {}
        out = []
        for ln in lines or []:
            d = {'text': str(ln.get('text', '')), 'row': int(ln.get('row', 13)),
                 'colour': ln.get('colour', 'black')}
            if ln.get('align') == 'center' or ln.get('col') is None:
                d['align'] = 'center'
            else:
                d['col'] = int(ln['col'])
            if d['colour'] not in EN.COLOURS:
                raise ValueError(f"colour {d['colour']!r}: {', '.join(EN.COLOURS)}")
            if d['text']:
                out.append(d)
        if out:
            t['lines'] = out
        if keep_song:
            song = (self.custom.get('title') or {}).get('song')
        if song not in (None, ''):
            t['song'] = song
        if t:
            self.custom['title'] = t
        else:
            self.custom.pop('title', None)
        self.touch()
        return self.title_settings()

    def title_problem(self):
        try:
            EN.title_layout(self.custom)
        except EN.EndingError as ex:
            return str(ex)
        return None

    # ------------------------------------------------------------ the credits
    def credits_settings(self):
        """{'pages': [...] (the game's 27 when unset), 'seconds', 'song',
        'continue_song', 'own': bool (custom.credits.pages exists)}."""
        c = copy.deepcopy(self.custom.get('credits') or {})
        own = isinstance(c.get('pages'), list)
        if not own:
            c['pages'] = EN.vanilla_pages(getattr(self, 'repo_root', None))
        c.setdefault('seconds', EN.SECONDS)
        c.setdefault('song', None)
        c.setdefault('continue_song', None)
        c['own'] = own
        return c

    def set_credits(self, pages=None, seconds=None, song=None, continue_song=None,
                    keep=('song', 'continue_song', 'seconds')):
        """Write custom.credits. pages = the full list ({role, names, monster}) or None
        to keep the game's (no `pages` key). seconds / songs None = the game's. The
        credits texts move here from gamedata.text (an edit there of credits_role /
        credits_name is taken into the pages first). Everything at the game's values
        = no custom.credits."""
        c = {}
        if pages is not None:
            ps = []
            for p in pages:
                ps.append({'role': str(p.get('role', '')), 'names': str(p.get('names', '')),
                           'monster': int(p.get('monster', 0))})
            if not 1 <= len(ps) <= EN.MAX_PAGES:
                raise ValueError(f'{len(ps)} pages — 1-{EN.MAX_PAGES}')
            if ps != EN.vanilla_pages(getattr(self, 'repo_root', None)):
                c['pages'] = ps
        if seconds is not None and int(seconds) != EN.SECONDS:
            c['seconds'] = int(seconds)
        if song not in (None, ''):
            c['song'] = song
        if continue_song not in (None, ''):
            c['continue_song'] = continue_song
        if pages is not None:
            # the pages hold every credits text from now on (the dialog shows the
            # gamedata.text edits in them): the game's pages put back = no edits
            gt = ((self.data.get('gamedata') or {}).get('text') or {})
            for src in EN.CREDITS_TEXT:
                gt.pop(src, None)
        if c:
            self.custom['credits'] = c
        else:
            self.custom.pop('credits', None)
        self.touch()
        return self.credits_settings()

    def credits_pages_from_text(self):
        """The game's pages with the project's gamedata.text credits edits applied
        (what the credits show before custom.credits exists)."""
        ps = EN.vanilla_pages(getattr(self, 'repo_root', None))
        gt = ((self.data.get('gamedata') or {}).get('text') or {})
        for src, key in (('credits_role', 'role'), ('credits_name', 'names')):
            for k, v in (gt.get(src) or {}).items():
                try:
                    i = int(k)
                except (TypeError, ValueError):
                    continue
                if 0 <= i < len(ps):
                    ps[i][key] = v
        return ps

    def credits_problems(self):
        """[(page number 1+, 'error' | 'warning', sentence)]."""
        out = []
        ps = self.credits_settings()['pages']
        for i, p in enumerate(ps):
            e, w = EN.page_problems(p, i == len(ps) - 1)
            out += [(i + 1, 'error', x) for x in e] + [(i + 1, 'warning', x) for x in w]
        return out
