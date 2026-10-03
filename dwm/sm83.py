"""sm83.py — a complete Game Boy (SM83) CPU interpreter in pure Python (S116).

Written to run the game's OWN sound engine (ROM0 $3331-$3AB2) inside the editor
without an emulator (editor2/core/sound_engine.py): the engine code is executed
from the ROM bytes, instruction by instruction, so what it does is what the game
does by construction. It is a general interpreter (all 256 base opcodes + all 256
CB opcodes, flags per the Pan Docs / SM83 opcode tables), not an audio-specific
model; anything that runs as a call-and-return routine with no interrupts can be
driven by it.

    cpu = CPU(read, write)          # read(addr) -> byte, write(addr, byte)
    cpu.call(0x1AE5, a=0x09)        # run a routine until it returns
    cpu.steps                       # instructions executed so far

What is NOT modelled: cycle timing, interrupts (di / ei / reti only flip
`cpu.ime`), HALT / STOP (they raise CPUHalt), the memory map (the caller's read /
write own it — see sound_engine.Machine).

Validation: tools/census_sound_engine.py runs every vanilla sound + the song
libraries through this interpreter and through PyBoy (the real hardware model) and
requires the engine state ($DD80-$DE2B, HRAM $FFE4-$FFFD) and every sound
register write to agree frame by frame.
"""

__all__ = ['CPU', 'CPUHalt', 'CPUError']


class CPUHalt(Exception):
    pass


class CPUError(Exception):
    pass


# register file indices
A, F, B, C, D, E, H, L, SP, PC = range(10)
R8 = ['B', 'C', 'D', 'E', 'H', 'L', None, 'A']   # 3-bit operand codes (6 = (HL))
RIDX = {'A': A, 'F': F, 'B': B, 'C': C, 'D': D, 'E': E, 'H': H, 'L': L}


def _gen():
    """Python source for the 256 base + 256 CB handlers. Each handler is a closure
    over R (register list), rd / wr (memory), and returns nothing."""
    src = []
    emit = src.append

    def get8(code):                       # expression reading operand code 0-7
        if code == 6:
            return 'rd((R[6]<<8)|R[7])'
        return f'R[{RIDX[R8[code]]}]'

    def set8(code, expr):                 # statement writing operand code 0-7
        if code == 6:
            return f'wr((R[6]<<8)|R[7], {expr})'
        return f'R[{RIDX[R8[code]]}] = {expr}'

    def imm8():
        return 'rd(R[9]); R[9] = (R[9]+1) & 0xFFFF'

    pairs = {0: ('B', 'C'), 1: ('D', 'E'), 2: ('H', 'L')}

    def fn(name, body):
        emit(f'def {name}():')
        for line in body:
            emit('    ' + line)
        emit('')

    cond = {0: '(R[1] & 0x80) == 0', 1: '(R[1] & 0x80) != 0',
            2: '(R[1] & 0x10) == 0', 3: '(R[1] & 0x10) != 0'}

    # ALU helpers (shared)
    emit('''
def _add(v, carry):
    a = R[0]; c = (R[1] >> 4) & 1 if carry else 0
    r = a + v + c
    R[1] = ((0x80 if (r & 0xFF) == 0 else 0) | (0x20 if ((a & 0xF) + (v & 0xF) + c) > 0xF else 0)
            | (0x10 if r > 0xFF else 0))
    R[0] = r & 0xFF

def _sub(v, carry, store):
    a = R[0]; c = (R[1] >> 4) & 1 if carry else 0
    r = a - v - c
    R[1] = ((0x80 if (r & 0xFF) == 0 else 0) | 0x40 | (0x20 if ((a & 0xF) - (v & 0xF) - c) < 0 else 0)
            | (0x10 if r < 0 else 0))
    if store:
        R[0] = r & 0xFF

def _and(v):
    R[0] &= v; R[1] = 0xA0 if R[0] == 0 else 0x20

def _xor(v):
    R[0] ^= v; R[1] = 0x80 if R[0] == 0 else 0

def _or(v):
    R[0] |= v; R[1] = 0x80 if R[0] == 0 else 0

def _inc(v):
    r = (v + 1) & 0xFF
    R[1] = (R[1] & 0x10) | (0x80 if r == 0 else 0) | (0x20 if (v & 0xF) == 0xF else 0)
    return r

def _dec(v):
    r = (v - 1) & 0xFF
    R[1] = (R[1] & 0x10) | 0x40 | (0x80 if r == 0 else 0) | (0x20 if (v & 0xF) == 0 else 0)
    return r

def _push(v):
    R[8] = (R[8] - 1) & 0xFFFF; wr(R[8], v >> 8)
    R[8] = (R[8] - 1) & 0xFFFF; wr(R[8], v & 0xFF)

def _pop():
    lo = rd(R[8]); R[8] = (R[8] + 1) & 0xFFFF
    hi = rd(R[8]); R[8] = (R[8] + 1) & 0xFFFF
    return (hi << 8) | lo

def _imm16():
    pc = R[9]
    v = rd(pc) | (rd((pc + 1) & 0xFFFF) << 8)
    R[9] = (pc + 2) & 0xFFFF
    return v

def _imm8():
    v = rd(R[9]); R[9] = (R[9] + 1) & 0xFFFF
    return v

def _addhl(v):
    hl = (R[6] << 8) | R[7]
    r = hl + v
    R[1] = (R[1] & 0x80) | (0x20 if ((hl & 0xFFF) + (v & 0xFFF)) > 0xFFF else 0) | (0x10 if r > 0xFFFF else 0)
    r &= 0xFFFF
    R[6] = r >> 8; R[7] = r & 0xFF

def _spe():
    e = _imm8()
    if e >= 0x80:
        e -= 0x100
    sp = R[8]
    r = (sp + e) & 0xFFFF
    R[1] = (0x20 if ((sp & 0xF) + (e & 0xF)) > 0xF else 0) | (0x10 if ((sp & 0xFF) + (e & 0xFF)) > 0xFF else 0)
    return r

def _jr(take):
    e = _imm8()
    if take:
        if e >= 0x80:
            e -= 0x100
        R[9] = (R[9] + e) & 0xFFFF

def _jp(take):
    t = _imm16()
    if take:
        R[9] = t

def _call(take):
    t = _imm16()
    if take:
        _push(R[9]); R[9] = t

def _ret(take):
    if take:
        R[9] = _pop()

def _rst(t):
    _push(R[9]); R[9] = t
''')

    names = [None] * 256
    ALU = ['_add({v}, False)', '_add({v}, True)', '_sub({v}, False, True)',
           '_sub({v}, True, True)', '_and({v})', '_xor({v})', '_or({v})',
           '_sub({v}, False, False)']

    for op in range(256):
        n = f'op_{op:02x}'
        body = None
        x, y, z = op >> 6, (op >> 3) & 7, op & 7
        if op == 0x00:
            body = ['pass']
        elif op in (0x01, 0x11, 0x21):
            hi, lo = pairs[op >> 4]
            body = ['v = _imm16()', f'R[{RIDX[hi]}] = v >> 8; R[{RIDX[lo]}] = v & 0xFF']
        elif op == 0x31:
            body = ['R[8] = _imm16()']
        elif op in (0x02, 0x12):
            hi, lo = pairs[op >> 4]
            body = [f'wr((R[{RIDX[hi]}]<<8)|R[{RIDX[lo]}], R[0])']
        elif op in (0x0A, 0x1A):
            hi, lo = pairs[op >> 4]
            body = [f'R[0] = rd((R[{RIDX[hi]}]<<8)|R[{RIDX[lo]}])']
        elif op == 0x22:
            body = ['hl = (R[6]<<8)|R[7]', 'wr(hl, R[0])', 'hl = (hl+1)&0xFFFF',
                    'R[6] = hl>>8; R[7] = hl&0xFF']
        elif op == 0x32:
            body = ['hl = (R[6]<<8)|R[7]', 'wr(hl, R[0])', 'hl = (hl-1)&0xFFFF',
                    'R[6] = hl>>8; R[7] = hl&0xFF']
        elif op == 0x2A:
            body = ['hl = (R[6]<<8)|R[7]', 'R[0] = rd(hl)', 'hl = (hl+1)&0xFFFF',
                    'R[6] = hl>>8; R[7] = hl&0xFF']
        elif op == 0x3A:
            body = ['hl = (R[6]<<8)|R[7]', 'R[0] = rd(hl)', 'hl = (hl-1)&0xFFFF',
                    'R[6] = hl>>8; R[7] = hl&0xFF']
        elif op in (0x03, 0x13, 0x23, 0x0B, 0x1B, 0x2B):
            hi, lo = pairs[(op >> 4) & 3]
            d = '+1' if (op & 0x0F) == 3 else '-1'
            body = [f'v = (((R[{RIDX[hi]}]<<8)|R[{RIDX[lo]}]){d}) & 0xFFFF',
                    f'R[{RIDX[hi]}] = v >> 8; R[{RIDX[lo]}] = v & 0xFF']
        elif op == 0x33:
            body = ['R[8] = (R[8]+1) & 0xFFFF']
        elif op == 0x3B:
            body = ['R[8] = (R[8]-1) & 0xFFFF']
        elif x == 0 and z == 4:
            body = [set8(y, f'_inc({get8(y)})')] if y != 6 else \
                ['hl = (R[6]<<8)|R[7]', 'wr(hl, _inc(rd(hl)))']
        elif x == 0 and z == 5:
            body = [set8(y, f'_dec({get8(y)})')] if y != 6 else \
                ['hl = (R[6]<<8)|R[7]', 'wr(hl, _dec(rd(hl)))']
        elif x == 0 and z == 6:
            body = ['v = _imm8()', set8(y, 'v')]
        elif op == 0x07:      # RLCA
            body = ['a = R[0]; c = a >> 7', 'R[0] = ((a << 1) | c) & 0xFF', 'R[1] = c << 4']
        elif op == 0x0F:      # RRCA
            body = ['a = R[0]; c = a & 1', 'R[0] = (a >> 1) | (c << 7)', 'R[1] = c << 4']
        elif op == 0x17:      # RLA
            body = ['a = R[0]; c = a >> 7', 'R[0] = ((a << 1) | ((R[1] >> 4) & 1)) & 0xFF',
                    'R[1] = c << 4']
        elif op == 0x1F:      # RRA
            body = ['a = R[0]; c = a & 1', 'R[0] = (a >> 1) | (((R[1] >> 4) & 1) << 7)',
                    'R[1] = c << 4']
        elif op == 0x08:      # ld [a16], sp
            body = ['t = _imm16()', 'wr(t, R[8] & 0xFF)', 'wr((t+1)&0xFFFF, R[8] >> 8)']
        elif op in (0x09, 0x19, 0x29):
            hi, lo = pairs[op >> 4]
            body = [f'_addhl((R[{RIDX[hi]}]<<8)|R[{RIDX[lo]}])']
        elif op == 0x39:
            body = ['_addhl(R[8])']
        elif op == 0x10:
            body = ['raise CPUHalt("STOP")']
        elif op == 0x18:
            body = ['_jr(True)']
        elif op in (0x20, 0x28, 0x30, 0x38):
            body = [f'_jr({cond[(op >> 3) & 3]})']
        elif op == 0x27:      # DAA
            body = ['a = R[0]; f = R[1]; c = f & 0x10',
                    'if f & 0x40:',
                    '    if c: a -= 0x60',
                    '    if f & 0x20: a -= 6',
                    'else:',
                    '    if c or a > 0x99:',
                    '        a += 0x60; c = 0x10',
                    '    if (f & 0x20) or (a & 0x0F) > 9: a += 6',
                    'a &= 0xFF',
                    'R[0] = a; R[1] = (0x80 if a == 0 else 0) | (f & 0x40) | c']
        elif op == 0x2F:
            body = ['R[0] ^= 0xFF; R[1] |= 0x60']
        elif op == 0x37:
            body = ['R[1] = (R[1] & 0x80) | 0x10']
        elif op == 0x3F:
            body = ['R[1] = (R[1] & 0x80) | ((R[1] & 0x10) ^ 0x10)']
        elif op == 0x76:
            body = ['raise CPUHalt("HALT")']
        elif x == 1:
            body = [set8(y, get8(z))]
        elif x == 2:
            body = [ALU[y].format(v=get8(z))]
        elif x == 3:
            if op in (0xC0, 0xC8, 0xD0, 0xD8):
                body = [f'_ret({cond[(op >> 3) & 3]})']
            elif op == 0xC9:
                body = ['R[9] = _pop()']
            elif op == 0xD9:
                body = ['R[9] = _pop(); cpu.ime = 1']
            elif op in (0xC1, 0xD1, 0xE1):
                hi, lo = pairs[(op >> 4) - 0xC]
                body = ['v = _pop()', f'R[{RIDX[hi]}] = v >> 8; R[{RIDX[lo]}] = v & 0xFF']
            elif op == 0xF1:
                body = ['v = _pop()', 'R[0] = v >> 8; R[1] = v & 0xF0']
            elif op in (0xC5, 0xD5, 0xE5):
                hi, lo = pairs[(op >> 4) - 0xC]
                body = [f'_push((R[{RIDX[hi]}]<<8)|R[{RIDX[lo]}])']
            elif op == 0xF5:
                body = ['_push((R[0]<<8)|R[1])']
            elif op in (0xC2, 0xCA, 0xD2, 0xDA):
                body = [f'_jp({cond[(op >> 3) & 3]})']
            elif op == 0xC3:
                body = ['R[9] = _imm16()']
            elif op in (0xC4, 0xCC, 0xD4, 0xDC):
                body = [f'_call({cond[(op >> 3) & 3]})']
            elif op == 0xCD:
                body = ['t = _imm16()', '_push(R[9]); R[9] = t']
            elif z == 6:
                body = ['v = _imm8()', ALU[y].format(v='v')]
            elif z == 7:
                body = [f'_rst({y * 8})']
            elif op == 0xCB:
                body = ['cb = _imm8()', 'CB[cb]()']
            elif op == 0xE0:
                body = ['v = _imm8()', 'wr(0xFF00 | v, R[0])']
            elif op == 0xF0:
                body = ['v = _imm8()', 'R[0] = rd(0xFF00 | v)']
            elif op == 0xE2:
                body = ['wr(0xFF00 | R[3], R[0])']
            elif op == 0xF2:
                body = ['R[0] = rd(0xFF00 | R[3])']
            elif op == 0xEA:
                body = ['wr(_imm16(), R[0])']
            elif op == 0xFA:
                body = ['R[0] = rd(_imm16())']
            elif op == 0xE8:
                body = ['R[8] = _spe()']
            elif op == 0xF8:
                body = ['v = _spe()', 'R[6] = v >> 8; R[7] = v & 0xFF']
            elif op == 0xF9:
                body = ['R[8] = (R[6]<<8)|R[7]']
            elif op == 0xE9:
                body = ['R[9] = (R[6]<<8)|R[7]']
            elif op == 0xF3:
                body = ['cpu.ime = 0']
            elif op == 0xFB:
                body = ['cpu.ime = 1']
        if body is None:
            body = [f'raise CPUError("illegal opcode ${op:02X} at $%04X" % ((R[9]-1)&0xFFFF))']
        fn(n, body)
        names[op] = n

    cbnames = [None] * 256
    for op in range(256):
        n = f'cb_{op:02x}'
        x, y, z = op >> 6, (op >> 3) & 7, op & 7
        v = get8(z)
        if x == 0:
            calc = {
                0: ['c = v >> 7', 'r = ((v << 1) | c) & 0xFF'],             # RLC
                1: ['c = v & 1', 'r = (v >> 1) | (c << 7)'],                # RRC
                2: ['c = v >> 7', 'r = ((v << 1) | ((R[1] >> 4) & 1)) & 0xFF'],   # RL
                3: ['c = v & 1', 'r = (v >> 1) | (((R[1] >> 4) & 1) << 7)'],      # RR
                4: ['c = v >> 7', 'r = (v << 1) & 0xFF'],                    # SLA
                5: ['c = v & 1', 'r = (v >> 1) | (v & 0x80)'],               # SRA
                6: ['c = 0', 'r = ((v << 4) | (v >> 4)) & 0xFF'],            # SWAP
                7: ['c = v & 1', 'r = v >> 1'],                              # SRL
            }[y]
            body = [f'v = {v}'] + calc + ['R[1] = (0x80 if r == 0 else 0) | (c << 4)',
                                          set8(z, 'r')]
        elif x == 1:
            body = [f'v = {v}',
                    f'R[1] = (R[1] & 0x10) | 0x20 | (0 if v & {1 << y} else 0x80)']
        elif x == 2:
            body = [set8(z, f'{v} & {0xFF ^ (1 << y)}')]
        else:
            body = [set8(z, f'{v} | {1 << y}')]
        fn(n, body)
        cbnames[op] = n

    emit('OPS = [' + ', '.join(names) + ']')
    emit('CB = [' + ', '.join(cbnames) + ']')
    return '\n'.join(src)


_SOURCE = _gen()


class CPU:
    """SM83 core. read / write are the memory map (ints in, ints out)."""

    def __init__(self, read, write):
        self.R = [0] * 10
        self.ime = 0
        self.steps = 0
        self.read = read
        self.write = write
        ns = {'R': self.R, 'rd': read, 'wr': write, 'cpu': self,
              'CPUHalt': CPUHalt, 'CPUError': CPUError}
        exec(compile(_SOURCE, 'sm83_ops', 'exec'), ns)
        self._ops = ns['OPS']
        self._push = ns['_push']

    # register conveniences
    def __getattr__(self, name):
        if name in ('a', 'f', 'b', 'c', 'd', 'e', 'h', 'l'):
            return self.R[RIDX[name.upper()]]
        if name == 'sp':
            return self.R[SP]
        if name == 'pc':
            return self.R[PC]
        if name == 'hl':
            return (self.R[H] << 8) | self.R[L]
        if name == 'de':
            return (self.R[D] << 8) | self.R[E]
        if name == 'bc':
            return (self.R[B] << 8) | self.R[C]
        raise AttributeError(name)

    def call(self, addr, a=None, hl=None, de=None, bc=None, sp=0xFFFE,
             max_steps=2_000_000, sentinel=0x0000):
        """Run the routine at `addr` until it returns to `sentinel` (pushed as the
        return address). Registers given are loaded first."""
        R = self.R
        if a is not None:
            R[A] = a & 0xFF
        for v, (hi, lo) in ((hl, (H, L)), (de, (D, E)), (bc, (B, C))):
            if v is not None:
                R[hi] = (v >> 8) & 0xFF
                R[lo] = v & 0xFF
        R[SP] = sp
        self._push(sentinel)
        R[PC] = addr
        ops = self._ops
        rd = self.read
        n = 0
        while R[PC] != sentinel:
            pc = R[PC]
            op = rd(pc)
            R[PC] = (pc + 1) & 0xFFFF
            ops[op]()
            n += 1
            if n > max_steps:
                raise CPUError(f'routine ${addr:04X} did not return in {max_steps} steps '
                               f'(PC ${R[PC]:04X})')
        self.steps += n
        return n
