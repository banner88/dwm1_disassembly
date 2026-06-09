"""Apply edits with optional repointing for over-budget text."""
from pathlib import Path
from dataclasses import dataclass
import json
from dwm.rom import ROM, BANK_SIZE
from dwm.text import encode

MAX_STRING_LEN = 1024  # was 250


@dataclass
class BuildResult:
    bytes_changed: int
    monster_edits: int
    text_inplace: int
    text_repointed: int
    text_rejected: int
    raw_edits: int
    warnings: list[str]


def fix_header_checksum(data: bytearray) -> None:
    cs = 0
    for i in range(0x134, 0x14D):
        cs = (cs - data[i] - 1) & 0xFF
    data[0x14D] = cs


def fix_global_checksum(data: bytearray) -> None:
    cs = 0
    for i, b in enumerate(data):
        if i in (0x14E, 0x14F): continue
        cs = (cs + b) & 0xFFFF
    data[0x14E] = (cs >> 8) & 0xFF
    data[0x14F] = cs & 0xFF


def _flat(bank: int, local: int) -> int:
    return bank * BANK_SIZE + (local - 0x4000 if bank else local)


def apply_monster_edits(data, edits, warnings) -> int:
    n = 0
    BANK, OFFSET, SIZE = 0x03, 0x4461, 43
    for mid_str, fields in edits.items():
        mid = int(mid_str)
        flat = _flat(BANK, OFFSET) + mid * SIZE
        block = bytearray(data[flat:flat + SIZE])
        if "family" in fields: block[0] = fields["family"]
        if "level_cap" in fields: block[1] = fields["level_cap"]
        if "exp_table" in fields: block[2] = fields["exp_table"]
        if "female_ratio" in fields: block[3] = fields["female_ratio"]
        if "base_skills" in fields:
            assert len(fields["base_skills"]) == 3
            block[6:9] = bytes(fields["base_skills"])
        if "resistances" in fields:
            assert len(fields["resistances"]) == 27
            block[0x0F:0x2A] = bytes(fields["resistances"])
        data[flat:flat + SIZE] = block
        n += 1
    return n


class FreeSpaceAllocator:
    def __init__(self, free_space: dict):
        self.banks: dict[int, list[list[int]]] = {}
        for bank_str, regions in free_space.items():
            bank = int(bank_str, 16)
            self.banks[bank] = [
                [int(r["bank_local_offset"], 16), r["length"]] for r in regions
            ]

    def alloc(self, bank: int, n_bytes: int) -> int | None:
        for region in self.banks.get(bank, []):
            local_off, remaining = region
            if remaining >= n_bytes:
                region[0] = local_off + n_bytes
                region[1] = remaining - n_bytes
                return local_off
        return None


def apply_text_edits(data, edits, free_space, warnings):
    n_inplace = 0
    n_repointed = 0
    n_rejected = 0
    alloc = FreeSpaceAllocator(free_space)

    for loc_str, spec in edits.items():
        if isinstance(spec, str):
            new_text, ptr_loc, allow_repoint = spec, None, False
        else:
            new_text = spec["text"]
            ptr_loc = spec.get("ptr_location")
            allow_repoint = spec.get("allow_repoint", False)

        bank_s, off_s = loc_str.split(":")
        bank, off = int(bank_s, 16), int(off_s, 16)
        flat = _flat(bank, off)

        # Find original length — scan up to MAX_STRING_LEN bytes
        orig_len = 0
        found_term = False
        while flat + orig_len < len(data) and orig_len < MAX_STRING_LEN:
            if data[flat + orig_len] == 0xF0:
                found_term = True
                break
            orig_len += 1
        if not found_term:
            warnings.append(
                f"{loc_str}: NO TERMINATOR within {MAX_STRING_LEN}B (started at 0x{flat:06X}); REJECTED"
            )
            n_rejected += 1
            continue
        orig_len += 1  # include terminator

        try:
            new_bytes = encode(new_text)
        except Exception as e:
            warnings.append(f"{loc_str}: encode error: {e}; REJECTED")
            n_rejected += 1
            continue

        if len(new_bytes) <= orig_len:
            data[flat:flat + len(new_bytes)] = new_bytes
            for i in range(len(new_bytes), orig_len):
                data[flat + i] = 0xF0
            n_inplace += 1
            continue

        if not (allow_repoint and ptr_loc):
            warnings.append(
                f"{loc_str}: new {len(new_bytes)}B > orig {orig_len}B; "
                f"repointing disabled; REJECTED"
            )
            n_rejected += 1
            continue

        new_local = alloc.alloc(bank, len(new_bytes))
        if new_local is None:
            warnings.append(
                f"{loc_str}: no free space ({len(new_bytes)}B) in bank {bank:02X}; REJECTED"
            )
            n_rejected += 1
            continue
        new_flat = _flat(bank, new_local)
        data[new_flat:new_flat + len(new_bytes)] = new_bytes
        pb_s, po_s = ptr_loc.split(":")
        pflat = _flat(int(pb_s, 16), int(po_s, 16))
        data[pflat]     = new_local & 0xFF
        data[pflat + 1] = (new_local >> 8) & 0xFF
        n_repointed += 1

    return n_inplace, n_repointed, n_rejected


def apply_raw_edits(data, edits, warnings) -> int:
    n = 0
    for off_str, hex_str in edits.items():
        flat = int(off_str, 16)
        b = bytes.fromhex(hex_str.replace(" ", ""))
        data[flat:flat + len(b)] = b
        n += 1
    return n


def build(src: Path, edits_path: Path, dst: Path) -> BuildResult:
    rom = ROM(src)
    data = rom.data
    before = bytes(data)
    edits = json.loads(edits_path.read_text()) if edits_path.exists() else {}
    free_space = {}
    fs_path = Path("extracted/free_space.json")
    if fs_path.exists():
        free_space = json.loads(fs_path.read_text())

    warnings: list[str] = []
    n_mon = apply_monster_edits(data, edits.get("monster_stats", {}), warnings)
    n_in, n_rp, n_rj = apply_text_edits(data, edits.get("text", {}), free_space, warnings)
    n_raw = apply_raw_edits(data, edits.get("raw_bytes", {}), warnings)

    fix_header_checksum(data)
    fix_global_checksum(data)
    Path(dst).write_bytes(data)

    changed = sum(1 for a, b in zip(before, data) if a != b)
    return BuildResult(
        bytes_changed=changed,
        monster_edits=n_mon,
        text_inplace=n_in,
        text_repointed=n_rp,
        text_rejected=n_rj,
        raw_edits=n_raw,
        warnings=warnings,
    )
