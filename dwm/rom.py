"""Minimal ROM accessor for DWM1 GBC ROM."""
from pathlib import Path

BANK_SIZE = 0x4000

class ROM:
    def __init__(self, path: Path):
        self.data = path.read_bytes()

    def addr(self, bank: int, offset: int) -> int:
        """Convert bank:offset to flat file offset."""
        if bank == 0:
            return offset
        return bank * BANK_SIZE + (offset - BANK_SIZE)

    def read(self, bank: int, offset: int, size: int) -> bytes:
        """Read `size` bytes from bank:offset."""
        flat = self.addr(bank, offset)
        return self.data[flat:flat + size]

    def read_until(self, bank: int, offset: int, terminator: int) -> bytes:
        """Read from bank:offset until terminator byte (exclusive)."""
        flat = self.addr(bank, offset)
        end = self.data.index(terminator, flat)
        return self.data[flat:end]
