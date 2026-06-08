"""Search every text blob (tabled and orphan) by case-insensitive substring."""
import json
import sys
from pathlib import Path

def main():
    if len(sys.argv) < 2:
        print("Usage: search_text.py <keyword> [keyword2 ...]")
        sys.exit(1)
    keywords = [k.lower() for k in sys.argv[1:]]

    blobs = json.loads(Path("extracted/text_blobs.json").read_text())
    matches = []
    for b in blobs:
        t = b["text"].lower()
        if any(k in t for k in keywords):
            matches.append(b)

    print(f"Found {len(matches)} matches for {keywords}\n")
    for m in matches:
        print(f"  {m['flat']}  bank={m['bank']}:{m['offset']}  len={m['length']}")
        print(f"    {m['text']!r}")
        print()

if __name__ == "__main__":
    main()
