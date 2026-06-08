from pathlib import Path

BANK_SIZE = 0x4000

class ROM:
    def __init__(self, path: Path):
        self.path = Path(path)
        self.data = bytearray(self.path.read_bytes())

    @staticmethod
    def addr(bank: int, offset: int) -> int:
        """Convert bank:offset (e.g., 41:5B1F) to flat ROM file offset."""
        if bank == 0:
            return offset
        # Banks > 0 use $4000-$7FFF window; flat = bank*0x4000 + (offset - 0x4000)
        assert 0x4000 <= offset <= 0x7FFF, f"bad offset {offset:X}"
        return bank * BANK_SIZE + (offset - 0x4000)

    def read(self, bank: int, offset: int, length: int) -> bytes:
        start = self.addr(bank, offset)
        return bytes(self.data[start:start + length])

    def write(self, bank: int, offset: int, data: bytes) -> None:
        start = self.addr(bank, offset)
        self.data[start:start + len(data)] = data

    def read_until(self, bank: int, offset: int, terminator: int, max_len: int = 256) -> bytes:
        start = self.addr(bank, offset)
        end = self.data.index(terminator, start, start + max_len) + 1
        return bytes(self.data[start:end])

    def save(self, path: Path) -> None:
        # TODO: recompute header checksums (rgbfix-style)
        Path(path).write_bytes(self.data)
