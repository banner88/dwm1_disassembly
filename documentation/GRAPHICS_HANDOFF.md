***
The following is written by an ensemble of LLMs so they MAY be wrong. Do not take it as ground truth, but as useful approximation. 
# DWM1 Graphics & ROM Architecture Handoff

## 1. Core Graphics Architecture (Verified)
*   **Format:** Standard Game Boy 2bpp planar graphics.
*   **Compression:** Custom Enix LZ77 variant.
    *   **Marker Byte:** `0x01`
    *   **Algorithm:** When `0x01` is read, the next two bytes form a 12-bit dictionary offset and a 4-bit length.
    *   **Dictionary:** Uses a 4096-byte circular ring buffer. In-game, this maps exactly to WRAM Bank 0 (`$C000-$CFFF`).
    *   **Length Logic:** `length = (byte2 & 0x0F) + 4`. If the lower nibble is exactly `0x0F`, a 3rd byte is read and added to the length (Extended length).
*   **Asset Storage:** Individual 16-byte tiles **do not have distinct ROM addresses**. They exist only as uncompressed offsets inside larger compressed LZ77 blocks (ZIP folders).

## 2. Character vs. NPC Sprite Structures
*   **Player Character (Terry):** Stored as a large, contiguous compressed block (e.g., `ROM 0x0BC074`). His animation frames are laid out sequentially (Head, Body, Walking 1, Walking 2, etc.).
*   **NPCs (e.g., Milayou):** Highly optimized and fragmented. Copying 320 bytes from an NPC's starting ROM address will often yield 1 frame of the NPC followed by garbage or unrelated sprites. 
*   **Hardware Assembly (OAM):** The game uses Object Attribute Memory to assemble 16x16 characters from 8x8 tiles. Because NPC tiles are fragmented, their OAM tile-index assignments are non-sequential (e.g., Milayou's head might use Tile `$54` and `$5C`, skipping the tiles in between).

## 3. The `tile_inspector.py` GUI (Current State)
We built a Streamlit GUI to bypass the massive headache of editing LZ77 data in hex.
*   **Decompression/Extraction:** It calculates flat ROM offsets, decompresses LZ77 blocks into a virtual 4096-byte buffer, and renders the tiles visually.
*   **VRAM Dumps:** It can accept raw SameBoy `examine` hex dumps to view tiles that are already uncompressed in memory.
*   **Swapper:** It allows visual reordering of tiles within an uncompressed block (to fix jigsaw-puzzle scrambled sprites) and compresses them back into the ROM via `edits.json`.
*   **Asset Library:** It maintains `tile_registry.json`, saving permanent references to tiles and animated composites. 
    *   *Schema tracking:* `rom_source_block` (the LZ77 origin) and `byte_offset_in_block` (where the tile physically lands after decompression).

## 4. Debugging Methodology (Crucial)
*   **SameBoy Watchpoints fail on Graphics:** Because DWM1 uses WRAM delivery buffers (decompressing to `$C000`, then copying to VRAM `$8000`), breaking on VRAM writes only reveals the WRAM buffer, not the ROM origin.
*   **Emulicious is Mandatory:** We rely on the Emulicious emulator's "Tile Viewer -> Pixel Source" feature. It traces pixels backward through the WRAM buffers directly to the `ROM XX:YYYY` address.

## 5. What We DO NOT Know (Open Questions for the New LLM)
1.  **Sprite ID Routing:** How does the game map a logical "Sprite ID" (e.g., ID 1 = Terry, ID 15 = King) to its LZ77 ROM pointer? We found hardcoded `LD DE, $4074` instructions for Terry, but there must be a master pointer table for NPCs and Overworld Monsters.
2.  **OAM Assembly Tables:** Since NPC tiles are fragmented, where are the data tables that tell the game *which* tile indexes to assemble for a specific NPC's animation frame?
3.  **Palette Assignments:** Where are the overworld and battle palettes stored, and how are they assigned to specific Sprite IDs?

## 6. Next Major Milestone: Maps & Environments (The Pivot)
The graphics tool is finished for sprite editing, but it **cannot edit rooms**. To change room layouts, spawn NPCs, or alter collision, we must decode the logical map layer.

**Starting Points for the New LLM:**
*   **Map Pointer Table:** Located in Bank `0B` at `0x2CB43`.
*   **Objective 1:** Write a tool to parse this table and dump the Room Headers.
*   **Objective 2:** Decode the Room Header format to identify the pointers for:
    1.  The 2D Tilemap (Wall/Floor layout).
    2.  The Collision/Passability map.
    3.  The NPC Spawn Table (X/Y coords, Sprite ID, Script Pointer).
*   *Note on Assets:* Environment tilesets (the visual walls/floors) are compressed LZ77 blocks just like the sprites. We can use the existing `tile_inspector.py` logic to extract and view them once we find their ROM addresses via the Map Headers.