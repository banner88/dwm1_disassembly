from pathlib import Path
from dwm.build import build

SRC = Path("data/DWM-original.gbc")
EDITS = Path("extracted/edits.json")
DST = Path("data/DWM-hacked.gbc")

def verify_boot(rom_path: Path, screenshot: Path):
    from pyboy import PyBoy
    pyboy = PyBoy(str(rom_path), window="null")
    for _ in range(600): pyboy.tick()
    pyboy.screen.image.save(screenshot)
    pyboy.stop()

def main():
    r = build(SRC, EDITS, DST)
    print(f"Built {DST}")
    print(f"  monster edits:      {r.monster_edits}")
    print(f"  text edits (inpl.): {r.text_inplace}")
    print(f"  text edits (repnt): {r.text_repointed}")
    print(f"  text REJECTED:      {r.text_rejected}")
    print(f"  raw edits:          {r.raw_edits}")
    print(f"  total bytes changed: {r.bytes_changed}")
    if r.warnings:
        print(f"\n⚠️  {len(r.warnings)} WARNING(S):")
        for w in r.warnings:
            print(f"    {w}")
    if r.text_rejected > 0:
        print("\n❌ Some text edits were REJECTED. They did NOT make it into the ROM.")
    verify_boot(DST, Path("data/title_after_build.png"))
    print(f"\n✓ Boot OK. Screenshot saved.")

if __name__ == "__main__":
    main()
