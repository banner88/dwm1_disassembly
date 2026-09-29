// dwmcheck — SameBoy-core harness for DWM1 tile-animation checks (S102).
// Boots a ROM with a battery save (CGB-E), continues the game, warps to a
// map (the same RAM mailbox tools/pyboy_harness.py warp() writes), then
// for N frames compares the VRAM of every animated slot against its
// authored frames (expect file) and writes two screenshots (PPM).
//
// usage: dwmcheck boot.bin rom.gbc rom.sav expect.bin map x y frames outprefix
// expect.bin: u8 nslots; per slot: u8 slot, u8 nframes, nframes*16 bytes.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <Core/gb.h>

static GB_gameboy_t gb;
static uint32_t pixels[256 * 224];
static volatile bool vbl;
static void vblank(GB_gameboy_t *g, GB_vblank_type_t t) { (void)g; (void)t; vbl = true; }
static uint32_t rgb(GB_gameboy_t *g, uint8_t r, uint8_t gg, uint8_t b) { (void)g; return (r << 16) | (gg << 8) | b; }

static void frame(void) { vbl = false; while (!vbl) GB_run(&gb); }
static void adv(int n) { while (n--) frame(); }
static uint8_t rd(uint16_t a) { return GB_safe_read_memory(&gb, a); }
static void wr(uint16_t a, uint8_t v) { GB_write_memory(&gb, a, v); }
static void tap(GB_key_t k, int wait) { GB_set_key_state(&gb, k, true); adv(3); GB_set_key_state(&gb, k, false); adv(wait); }

static void snap(const char *path) {
    FILE *f = fopen(path, "wb");
    fprintf(f, "P6 160 144 255\n");
    for (int i = 0; i < 160 * 144; i++) {
        uint8_t c[3] = { pixels[i] >> 16, pixels[i] >> 8, pixels[i] };
        fwrite(c, 1, 3, f);
    }
    fclose(f);
}

int main(int argc, char **argv) {
    if (argc < 10) { fprintf(stderr, "usage\n"); return 2; }
    GB_init(&gb, GB_MODEL_CGB_E);
    if (GB_load_boot_rom(&gb, argv[1])) { fprintf(stderr, "boot rom\n"); return 1; }
    GB_set_vblank_callback(&gb, vblank);
    GB_set_pixels_output(&gb, pixels);
    GB_set_rgb_encode_callback(&gb, rgb);
    GB_set_color_correction_mode(&gb, GB_COLOR_CORRECTION_DISABLED);
    GB_set_turbo_mode(&gb, true, true);
    if (GB_load_rom(&gb, argv[2])) { fprintf(stderr, "rom\n"); return 1; }
    GB_load_battery(&gb, argv[3]);
    int map = strtol(argv[5], 0, 16), x = atoi(argv[6]), y = atoi(argv[7]), nf = atoi(argv[8]);
    // expected frames
    FILE *e = fopen(argv[4], "rb");
    int ns = fgetc(e);
    int slot[128], nfr[128]; uint8_t *fr[128];
    for (int i = 0; i < ns; i++) {
        slot[i] = fgetc(e); nfr[i] = fgetc(e);
        fr[i] = malloc(nfr[i] * 16); fread(fr[i], 16, nfr[i], e);
    }
    fclose(e);
    // continue the game
    adv(400);
    for (int i = 0; i < 30; i++) {
        if (rd(0xC88A) == 1 && rd(0xC968) != 0) break;
        tap(GB_KEY_A, 30);
    }
    for (int i = 0; i < 4; i++) tap(GB_KEY_B, 30);
    adv(60); tap(GB_KEY_DOWN, 30);
    // warp (pyboy_harness.warp)
    wr(0xD8D7, 0); wr(0xC96D, map); wr(0xC96E, 0);
    int px = x * 16 + 8, py = y * 16 + 8;
    wr(0xC96F, px & 0xFF); wr(0xC970, px >> 8); wr(0xC971, py & 0xFF); wr(0xC972, py >> 8);
    wr(0xC96C, 1); wr(0xC88F, 1);
    adv(240);
    printf("map %02X\n", rd(0xC968));
    size_t vsize; uint16_t vbank;
    uint8_t *vram = GB_get_direct_access(&gb, GB_DIRECT_ACCESS_VRAM, &vsize, &vbank);
    int bad = 0, changes[128] = {0}, last[128];
    for (int i = 0; i < ns; i++) last[i] = -2;
    char path[512];
    for (int f = 0; f < nf; f++) {
        frame();
        for (int i = 0; i < ns; i++) {
            uint8_t *v = vram + slot[i] * 16 + 0x1000;   // $9000 + slot*16 in bank 0
            int k = -1;
            for (int j = 0; j < nfr[i]; j++) if (!memcmp(v, fr[i] + j * 16, 16)) { k = j; break; }
            if (k < 0) {
                if (bad < 10) {
                    printf("MISMATCH frame %d slot %d:", f, slot[i]);
                    for (int b = 0; b < 16; b++) printf(" %02X", v[b]);
                    printf("\n");
                }
                bad++;
            }
            if (k != last[i]) { changes[i]++; last[i] = k; }
        }
        if (f == 20 || f == 60) { snprintf(path, sizeof path, "%s_%d.ppm", argv[9], f); snap(path); }
    }
    printf("frames not matching any authored frame: %d\n", bad);
    for (int i = 0; i < ns; i++) printf("slot %d changes %d\n", slot[i], changes[i]);
    return bad ? 3 : 0;
}
