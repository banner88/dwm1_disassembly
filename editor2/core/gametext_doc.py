"""gametext_doc.py — the Text tab's model (S150, ROADMAP P3.6 / Phase F
T-author; compiler: editor2/core/gametext.py, PROJECT_COMPILER §2.58).

Mixed into Document. Every mutation edits `gamedata.text` only. A text the
original game shows through several slots with the SAME string (the 382 text
ids that share a line, a table's repeated rows) is edited as ONE: the edit is
written to every member of its group unless `only_this` is asked for.
"""

from editor2.core import gametext as GT
from editor2.core import textmark as TM


class GameTextMixin:
    def game_text_index(self):
        return GT.index(getattr(self, 'repo_root', None))

    def _gt_rows(self):
        return ((self.data.get('gamedata') or {}).get('text') or {})

    def game_text(self, source, key):
        """{'markup', 'original', 'edited', 'same', 'style', 'entry', 'error',
        'warnings', 'bytes'} of one text (key = '$0123' / a row number)."""
        x = self.game_text_index().get(source, key)
        if x is None:
            raise KeyError(f'{source} {key}')
        orig = x.markup()
        rows = self._gt_rows().get(source) or {}
        cur = rows.get(GT._norm_key(source, key))
        out = {'entry': x, 'original': orig, 'markup': orig if cur is None else cur,
               'edited': cur is not None, 'same': list(x.same), 'style': x.style,
               'error': None, 'warnings': [], 'bytes': None}
        try:
            raw = TM.encode(out['markup'], x.style)
            out['bytes'] = raw
            cap = GT.MAX_GLYPHS.get(source)
            if cap is not None and GT.glyph_count(raw) > cap:
                out['error'] = f'{GT.glyph_count(raw)} letters — at most {cap}'
            out['warnings'] = GT.warnings_for(x, raw + b'\xf0')
        except TM.MarkupError as e:
            out['error'] = str(e)
        return out

    def game_text_edited(self, group=None):
        """[(source, key)] of the edited texts (in the index's order)."""
        ix = self.game_text_index()
        rows = self._gt_rows()
        out = []
        for k in ix.order:
            x = ix.entries[k]
            if group is not None and x.group != group:
                continue
            if GT._norm_key(x.source, x.key) in (rows.get(x.source) or {}):
                out.append(k)
        return out

    def check_game_text(self, source, markup):
        """Raise ValueError when `markup` is no text of `source`'s kind."""
        ix = self.game_text_index()
        style = 'box' if source == GT.DIALOGUE else (ix.tables[source].get('style', 'rows'))
        try:
            raw = TM.encode(markup, style)
        except TM.MarkupError as e:
            raise ValueError(str(e)) from None
        cap = GT.MAX_GLYPHS.get(source)
        if cap is not None:
            if GT.glyph_count(raw) > cap:
                raise ValueError(f'{GT.glyph_count(raw)} letters — at most {cap} '
                                 f'(the game draws it in a {cap}-cell field)')
            if any(k == 'c' for k, _b in TM._units(raw)):
                raise ValueError('a name takes letters only (no codes)')
        return raw

    def set_game_text(self, source, key, markup, only_this=False):
        """Edit one text (and, unless only_this, every text that showed the same
        line in the original game). markup None / == the original = back to
        the original."""
        ix = self.game_text_index()
        x = ix.get(source, key)
        if x is None:
            raise KeyError(f'{source} {key}')
        if x.owner:
            raise ValueError(f'edit this text on the {x.owner} tab')
        if markup is not None:
            self.check_game_text(source, markup)
        keys = [(x.source, x.key)] + ([] if only_this else list(x.same))
        for src, k in keys:
            y = ix.get(src, k)
            if markup is None or markup == y.markup():
                GT.set_edit(self.data, src, k, None)
            else:
                GT.set_edit(self.data, src, k, markup)
        self.touch()

    def reset_game_text(self, source, key, only_this=False):
        self.set_game_text(source, key, None, only_this=only_this)

    def reset_game_text_group(self, group):
        """Every edit of one Text sub-tab back to the original."""
        for src, k in self.game_text_edited(group):
            GT.set_edit(self.data, src, k, None)
        self.touch()

    # ---- [S165] the words drawn in the windows as tiles (editor2/core/window_words.py)
    # ---- [S166] + the words a window cuts out of a text (key "T:<table>:<row>/<offset>")
    def window_words(self):
        """{slot key: the project's word}: gamedata.window_words, and (S166) every text slot whose
        word in the row as edited (gamedata.text) differs from the game's."""
        v = (self.data.get('gamedata') or {}).get('window_words')
        out = dict(v) if isinstance(v, dict) else {}
        from editor2.core import window_words as WW
        rows = self._gt_rows()
        for key, s_ in WW.slots(getattr(self, 'repo_root', None)).items():
            if s_['kind'] != 'text':
                continue
            cur = (rows.get(s_['source']) or {}).get(GT._norm_key(s_['source'], s_['index']))
            if cur is None:
                continue
            w = WW.text_word(cur, s_)
            if w != s_['text']:
                out[key] = w
        return out

    def set_window_word(self, key, word):
        """One window word: `word` None / '' / == the original = back to the original. Refused
        (WindowWordsError) when longer than the slot or using a letter the screen's font lacks.
        S166: a text slot rewrites its row in gamedata.text (the slot's cells; the other cells of
        the row as they are)."""
        from editor2.core import window_words as WW
        sl = WW.slots(getattr(self, 'repo_root', None))
        if key not in sl:
            raise WW.WindowWordsError(f'no window word {key!r}')
        s_ = sl[key]
        if s_['kind'] == 'text':
            x = self.game_text(s_['source'], s_['index'])
            want = s_['text'] if word in (None, '') else word
            markup = WW.compose_text(x['markup'], s_, want)
            self.set_game_text(s_['source'], s_['index'], markup, only_this=True)
            return
        gd = self.data.setdefault('gamedata', {})
        ww = gd.setdefault('window_words', {})
        if word in (None, '') or word == s_['text']:
            ww.pop(key, None)
        else:
            errs = []
            WW.validate({'window_words': {key: word}}, errs, getattr(self, 'repo_root', None))
            if errs:
                if not ww:
                    gd.pop('window_words')
                if not gd:
                    self.data.pop('gamedata')
                raise WW.WindowWordsError(errs[0].split(': ', 1)[1])
            ww[key] = word
        if not ww:
            gd.pop('window_words')
        if not gd:
            self.data.pop('gamedata')
        self.touch()
