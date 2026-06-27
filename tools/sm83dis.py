#!/usr/bin/env python3
"""sm83dis.py — disassemble SM83 (Game Boy CPU) code at a given bank:addr.

mgbdis only disassembles code it can reach by following call/jump references;
data-table targets and unreferenced routines are emitted as `db` bytes. This
tool decodes the ROM bytes at an arbitrary address as instructions, which is
needed to read routines mgbdis left as data (e.g. bank-$53 jump-table targets).

Usage:
    python3 tools/sm83dis.py <bank_hex> <addr_hex> [num_instructions]
    python3 tools/sm83dis.py 53 51E8 60
    python3 tools/sm83dis.py 52 41CD 20

Notes:
  - addr is the bank-relative GB address ($4000-$7FFF for ROMX, $0000-$3FFF
    for ROM0/bank 0). File offset = bank*0x4000 + (addr & 0x3FFF).
  - Output shows address, raw bytes, and mnemonic. Branch/call targets are
    shown as absolute GB addresses.
"""
import sys

ROM_PATH = "data/DWM-original.gbc"

# 8-bit register operand names by 3-bit code
R8 = ["b", "c", "d", "e", "h", "l", "[hl]", "a"]
R16_SP = ["bc", "de", "hl", "sp"]
R16_AF = ["bc", "de", "hl", "af"]
CC = ["nz", "z", "nc", "c"]

def u8(b, i):  return b[i]
def s8(b, i):  return b[i] - 256 if b[i] >= 128 else b[i]
def u16(b, i): return b[i] | (b[i+1] << 8)

def decode(b, i, pc):
    """Return (text, length). b=bytes, i=index, pc=GB address of this instr."""
    op = b[i]
    def imm8():  return f"${u8(b,i+1):02x}"
    def imm16(): return f"${u16(b,i+1):04x}"
    def rel():
        d = s8(b, i+1); return f"${(pc+2+d)&0xffff:04x}"

    # --- single-byte / patterned opcodes ---
    if op == 0x00: return "nop", 1
    if op == 0x10: return "stop", 2
    if op == 0x76: return "halt", 1
    if op == 0xF3: return "di", 1
    if op == 0xFB: return "ei", 1
    if op == 0x07: return "rlca", 1
    if op == 0x0F: return "rrca", 1
    if op == 0x17: return "rla", 1
    if op == 0x1F: return "rra", 1
    if op == 0x27: return "daa", 1
    if op == 0x2F: return "cpl", 1
    if op == 0x37: return "scf", 1
    if op == 0x3F: return "ccf", 1

    # ld r16, imm16
    if op in (0x01,0x11,0x21,0x31): return f"ld {R16_SP[op>>4]}, {imm16()}", 3
    # ld [r16], a / ld a, [r16]
    if op == 0x02: return "ld [bc], a", 1
    if op == 0x12: return "ld [de], a", 1
    if op == 0x22: return "ld [hl+], a", 1
    if op == 0x32: return "ld [hl-], a", 1
    if op == 0x0A: return "ld a, [bc]", 1
    if op == 0x1A: return "ld a, [de]", 1
    if op == 0x2A: return "ld a, [hl+]", 1
    if op == 0x3A: return "ld a, [hl-]", 1
    # inc/dec r16
    if op in (0x03,0x13,0x23,0x33): return f"inc {R16_SP[op>>4]}", 1
    if op in (0x0B,0x1B,0x2B,0x3B): return f"dec {R16_SP[op>>4]}", 1
    # inc/dec r8
    if op & 0xC7 == 0x04: return f"inc {R8[(op>>3)&7]}", 1
    if op & 0xC7 == 0x05: return f"dec {R8[(op>>3)&7]}", 1
    # ld r8, imm8
    if op & 0xC7 == 0x06: return f"ld {R8[(op>>3)&7]}, {imm8()}", 2
    # add hl, r16
    if op in (0x09,0x19,0x29,0x39): return f"add hl, {R16_SP[op>>4]}", 1
    # jr
    if op == 0x18: return f"jr {rel()}", 2
    if op in (0x20,0x28,0x30,0x38): return f"jr {CC[(op>>3)&3]}, {rel()}", 2
    # ld [a16], sp
    if op == 0x08: return f"ld [{imm16()}], sp", 3
    # rlc/etc handled by CB
    # ld r8, r8 (0x40-0x7F except 0x76 halt)
    if 0x40 <= op <= 0x7F:
        return f"ld {R8[(op>>3)&7]}, {R8[op&7]}", 1
    # alu a, r8 (0x80-0xBF)
    if 0x80 <= op <= 0xBF:
        ops = ["add a,","adc a,","sub","sbc a,","and","xor","or","cp"]
        return f"{ops[(op>>3)&7]} {R8[op&7]}", 1
    # alu a, imm8
    if op in (0xC6,0xCE,0xD6,0xDE,0xE6,0xEE,0xF6,0xFE):
        ops = {0xC6:"add a,",0xCE:"adc a,",0xD6:"sub",0xDE:"sbc a,",
               0xE6:"and",0xEE:"xor",0xF6:"or",0xFE:"cp"}
        return f"{ops[op]} {imm8()}", 2
    # push/pop
    if op in (0xC1,0xD1,0xE1,0xF1): return f"pop {R16_AF[(op>>4)&3]}", 1
    if op in (0xC5,0xD5,0xE5,0xF5): return f"push {R16_AF[(op>>4)&3]}", 1
    # ret / reti / ret cc
    if op == 0xC9: return "ret", 1
    if op == 0xD9: return "reti", 1
    if op in (0xC0,0xC8,0xD0,0xD8): return f"ret {CC[(op>>3)&3]}", 1
    # jp
    if op == 0xC3: return f"jp {imm16()}", 3
    if op == 0xE9: return "jp hl", 1
    if op in (0xC2,0xCA,0xD2,0xDA): return f"jp {CC[(op>>3)&3]}, {imm16()}", 3
    # call
    if op == 0xCD: return f"call {imm16()}", 3
    if op in (0xC4,0xCC,0xD4,0xDC): return f"call {CC[(op>>3)&3]}, {imm16()}", 3
    # rst
    if op & 0xC7 == 0xC7: return f"rst ${op & 0x38:02x}", 1
    # ldh
    if op == 0xE0: return f"ldh [${0xff00+u8(b,i+1):04x}], a", 2
    if op == 0xF0: return f"ldh a, [${0xff00+u8(b,i+1):04x}]", 2
    if op == 0xE2: return "ldh [$ff00+c], a", 1
    if op == 0xF2: return "ldh a, [$ff00+c]", 1
    # ld [a16],a / ld a,[a16]
    if op == 0xEA: return f"ld [{imm16()}], a", 3
    if op == 0xFA: return f"ld a, [{imm16()}]", 3
    # add sp,e / ld hl,sp+e / ld sp,hl / ld hl... etc
    if op == 0xE8: return f"add sp, {imm8()}", 2
    if op == 0xF8: return f"ld hl, sp+{imm8()}", 2
    if op == 0xF9: return "ld sp, hl", 1
    # CB prefix
    if op == 0xCB:
        cb = b[i+1]; reg = R8[cb&7]
        if cb < 0x40:
            names = ["rlc","rrc","rl","rr","sla","sra","swap","srl"]
            return f"{names[(cb>>3)&7]} {reg}", 2
        bit = (cb>>3)&7
        if cb < 0x80: return f"bit {bit}, {reg}", 2
        if cb < 0xC0: return f"res {bit}, {reg}", 2
        return f"set {bit}, {reg}", 2
    return f"db ${op:02x}", 1

def main():
    if len(sys.argv) < 3:
        print(__doc__); sys.exit(1)
    bank = int(sys.argv[1], 16)
    addr = int(sys.argv[2], 16)
    n = int(sys.argv[3]) if len(sys.argv) > 3 else 32
    rom = open(ROM_PATH, "rb").read()
    base_off = bank*0x4000 + (addr & 0x3FFF)
    pc = addr
    off = base_off
    for _ in range(n):
        i = off
        text, length = decode(rom, i, pc)
        raw = " ".join(f"{rom[i+k]:02x}" for k in range(length))
        print(f"  ${pc:04x}: {raw:<12} {text}")
        pc += length
        off += length

if __name__ == "__main__":
    main()
