"""
ECLIPSE — Environment Pixel Art Generator
Generates handcrafted 32x32 pixel art textures for Level 1:
- Grass (3 natural variants + Eclipse dark)
- Dirt (3 natural variants + Eclipse dark)
- Stone Floor (normal + Eclipse dark)
- Stone Wall & Pillars (mossy ancient masonry with rounded 3D block relief)
- Void (Normal pitch abyss + Eclipse dramatic crimson red)
- Cyan Hidden Bridge (Luminous radiant cyan runic stone)
- Props: Exit Gate (Closed/Open with torches), Lever (Off/On), Tablet, Note, Tree, Bush, Mossy Rock
"""

from PIL import Image, ImageDraw
import os
import math
import random

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

def save_img(img: Image.Image, rel_path: str):
    path = os.path.join(BASE_DIR, rel_path)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path, "PNG")
    print(f"Saved: {rel_path} ({img.size[0]}x{img.size[1]})")

# Pseudo-random deterministic noise generator (smooth 2D value noise)
def make_noise_grid(w, h, seed):
    rng = random.Random(seed)
    return [[rng.random() for _ in range(w)] for _ in range(h)]

def sample_noise(grid, x, y, w, h):
    gx = x % w
    gy = y % h
    x0 = int(gx)
    y0 = int(gy)
    x1 = (x0 + 1) % w
    y1 = (y0 + 1) % h
    fx = gx - x0
    fy = gy - y0
    # Smoothstep
    sx = fx * fx * (3.0 - 2.0 * fx)
    sy = fy * fy * (3.0 - 2.0 * fy)
    top = grid[y0][x0] * (1.0 - sx) + grid[y0][x1] * sx
    bot = grid[y1][x0] * (1.0 - sx) + grid[y1][x1] * sx
    return top * (1.0 - sy) + bot * sy

def fbm(grid4, grid8, grid16, x, y):
    n1 = sample_noise(grid4, x * 0.125, y * 0.125, 4, 4)
    n2 = sample_noise(grid8, x * 0.25, y * 0.25, 8, 8)
    n3 = sample_noise(grid16, x * 0.5, y * 0.5, 16, 16)
    return n1 * 0.55 + n2 * 0.30 + n3 * 0.15

# =============================================================================
# 1. GRASS TILES (32x32)
# =============================================================================
def generate_grass():
    g4 = make_noise_grid(4, 4, 101)
    g8 = make_noise_grid(8, 8, 202)
    g16 = make_noise_grid(16, 16, 303)

    # Base palette
    c_deep = (28, 54, 32, 255)
    c_base = (42, 78, 46, 255)
    c_mid = (56, 104, 60, 255)
    c_light = (74, 134, 78, 255)
    c_tip = (102, 172, 106, 255)

    def color_interp(c1, c2, t):
        t = max(0.0, min(1.0, t))
        return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(4))

    # Variant 1: Lush overgrown meadow
    g1 = Image.new("RGBA", (32, 32))
    for y in range(32):
        for x in range(32):
            val = fbm(g4, g8, g16, x, y)
            if val < 0.35:
                col = color_interp(c_deep, c_base, val / 0.35)
            elif val < 0.65:
                col = color_interp(c_base, c_mid, (val - 0.35) / 0.30)
            elif val < 0.85:
                col = color_interp(c_mid, c_light, (val - 0.65) / 0.20)
            else:
                col = color_interp(c_light, c_tip, (val - 0.85) / 0.15)
            g1.putpixel((x, y), col)

    # Add soft organic blade clusters
    blade_clusters = [
        (6, 8), (14, 20), (22, 10), (18, 26), (27, 18), (9, 28), (25, 29), (12, 6)
    ]
    for bx, by in blade_clusters:
        g1.putpixel((bx, by), c_tip)
        g1.putpixel((bx, by - 1), c_light)
        g1.putpixel((bx + 1, by), c_mid)
        g1.putpixel((bx - 1, by + 1), c_deep)
    save_img(g1, "grass/grass_1.png")

    # Variant 2: Grass with tiny wild buttercups/florets
    g2 = g1.copy()
    florets = [(10, 12), (20, 8), (6, 24), (26, 22), (16, 16)]
    for fx, fy in florets:
        g2.putpixel((fx, fy), (245, 230, 110, 255))
        g2.putpixel((fx + 1, fy), (255, 250, 190, 255))
        g2.putpixel((fx, fy + 1), (190, 150, 40, 255))
        g2.putpixel((fx - 1, fy), c_deep)
    save_img(g2, "grass/grass_2.png")

    # Variant 3: Deep mossy grass with subtle stone clover
    g3 = g1.copy()
    clovers = [(8, 18), (24, 6), (18, 22)]
    moss_deep = (20, 42, 24, 255)
    for cx, cy in clovers:
        for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
            g3.putpixel((cx + dx, cy + dy), c_light)
        g3.putpixel((cx, cy), moss_deep)
    save_img(g3, "grass/grass_3.png")

    # ECLIPSE Mode Grass: Shadow-realm dark desaturated blue-green
    g_dark = Image.new("RGBA", (32, 32))
    for y in range(32):
        for x in range(32):
            r, g, b, _ = g1.getpixel((x, y))
            # Shift towards ominous cold twilight
            nr = int(r * 0.28 + 4)
            ng = int(g * 0.32 + 8)
            nb = int(b * 0.44 + 14)
            g_dark.putpixel((x, y), (nr, ng, nb, 255))
    save_img(g_dark, "grass/grass_dark.png")

# =============================================================================
# 2. DIRT TILES (32x32)
# =============================================================================
def generate_dirt():
    d4 = make_noise_grid(4, 4, 404)
    d8 = make_noise_grid(8, 8, 505)
    d16 = make_noise_grid(16, 16, 606)

    # Base warm earth palette
    c_deep = (68, 48, 34, 255)
    c_base = (98, 72, 50, 255)
    c_mid = (124, 94, 66, 255)
    c_light = (148, 116, 84, 255)
    c_pebble = (168, 155, 140, 255)

    def color_interp(c1, c2, t):
        t = max(0.0, min(1.0, t))
        return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(4))

    d1 = Image.new("RGBA", (32, 32))
    for y in range(32):
        for x in range(32):
            val = fbm(d4, d8, d16, x, y)
            if val < 0.35:
                col = color_interp(c_deep, c_base, val / 0.35)
            elif val < 0.70:
                col = color_interp(c_base, c_mid, (val - 0.35) / 0.35)
            else:
                col = color_interp(c_mid, c_light, (val - 0.70) / 0.30)
            d1.putpixel((x, y), col)

    # Fine natural pebbles
    pebbles = [(8, 12), (22, 9), (14, 24), (26, 20), (5, 27)]
    for px, py in pebbles:
        d1.putpixel((px, py), c_pebble)
        d1.putpixel((px + 1, py), (195, 185, 172, 255))
        d1.putpixel((px, py + 1), c_deep)
    save_img(d1, "dirt/dirt_1.png")

    # Variant 2: Embedded ancient cobblestones in dirt
    d2 = d1.copy()
    stones = [(6, 7), (18, 14), (11, 23)]
    for sx, sy in stones:
        for dx in range(3):
            for dy in range(2):
                d2.putpixel((sx + dx, sy + dy), (82, 80, 90, 255))
        d2.putpixel((sx, sy), (120, 118, 130, 255))
        d2.putpixel((sx + 1, sy + 2), c_deep)
    save_img(d2, "dirt/dirt_2.png")

    # Variant 3: Dirt with fine mossy edges
    d3 = d1.copy()
    moss_col = (46, 82, 50, 255)
    for px, py in [(2, 3), (3, 3), (4, 4), (28, 15), (29, 15), (15, 30), (16, 30)]:
        d3.putpixel((px, py), moss_col)
    save_img(d3, "dirt/dirt_3.png")

    # ECLIPSE Mode Dirt: Darkened ash loam
    d_dark = Image.new("RGBA", (32, 32))
    for y in range(32):
        for x in range(32):
            r, g, b, _ = d1.getpixel((x, y))
            d_dark.putpixel((x, y), (int(r * 0.32 + 6), int(g * 0.28 + 4), int(b * 0.36 + 8), 255))
    save_img(d_dark, "dirt/dirt_dark.png")

# =============================================================================
# 3. STONE TILES & MASONRY (32x32)
# =============================================================================
def generate_stone():
    # Ancient Stone Wall: Hand-carved 3D block masonry with mossy crevices
    # Each tile shows 2 rows of weathered stone blocks with rounded bevels
    wall = Image.new("RGBA", (32, 32), (54, 56, 66, 255))
    s_dark_mortar = (22, 24, 30, 255)
    s_shadow = (36, 38, 46, 255)
    s_body = (64, 68, 80, 255)
    s_mid = (84, 88, 102, 255)
    s_hi = (118, 124, 142, 255)
    s_top_cap = (136, 142, 160, 255)
    moss_bright = (56, 110, 62, 255)
    moss_shadow = (28, 56, 32, 255)

    # 1. Fill base block rows
    # Row 1: y = 2 to 15 (block width 30)
    # Row 2: y = 17 to 30 (offset block seam at x = 16)
    for y in range(32):
        for x in range(32):
            # Outer dark mortar lines
            if y in (0, 1, 16, 31) or x in (0, 31):
                wall.putpixel((x, y), s_dark_mortar)
            elif y == 16 or (y >= 17 and x in (15, 16)):
                wall.putpixel((x, y), s_dark_mortar)
            else:
                # Stone body with subtle organic texture
                noise_val = ((x * 7 + y * 13 + (x ^ y)) % 5)
                if noise_val == 0:
                    wall.putpixel((x, y), s_shadow)
                elif noise_val == 1:
                    wall.putpixel((x, y), s_mid)
                else:
                    wall.putpixel((x, y), s_body)

    # 2. Add top bevel highlights for 3D block relief
    for x in range(1, 31):
        wall.putpixel((x, 2), s_top_cap)
        wall.putpixel((x, 3), s_hi)
        if x != 15 and x != 16:
            wall.putpixel((x, 17), s_hi)
            wall.putpixel((x, 18), s_mid)

    # 3. Add bottom shadows under blocks
    for x in range(1, 31):
        wall.putpixel((x, 15), s_shadow)
        wall.putpixel((x, 30), s_shadow)

    # 4. Creeping moss and vines in crevices
    for mx, my in [(4, 2), (5, 2), (5, 3), (6, 3), (12, 16), (13, 16), (13, 17), (24, 2), (25, 2), (25, 3)]:
        wall.putpixel((mx, my), moss_bright)
        wall.putpixel((mx, my + 1), moss_shadow)
    save_img(wall, "stone/stone_wall.png")

    # Stone Floor: Ancient flagstones with rounded beveled edges
    floor = Image.new("RGBA", (32, 32), (68, 72, 84, 255))
    for y in range(32):
        for x in range(32):
            if x in (0, 15, 31) or y in (0, 15, 31):
                floor.putpixel((x, y), s_dark_mortar)
            elif (x in (1, 16) and y not in (0, 15, 31)) or (y in (1, 16) and x not in (0, 15, 31)):
                floor.putpixel((x, y), s_hi)
            elif x in (14, 30) or y in (14, 30):
                floor.putpixel((x, y), s_shadow)
            else:
                v = (x * 5 + y * 11) % 4
                floor.putpixel((x, y), s_body if v != 0 else s_mid)
    # Moss in flagstone crevices
    for mx, my in [(15, 6), (15, 7), (8, 15), (9, 15), (22, 15)]:
        floor.putpixel((mx, my), moss_bright)
    save_img(floor, "stone/stone_floor_1.png")

    # Stone Floor Dark (ECLIPSE Mode)
    floor_dark = Image.new("RGBA", (32, 32))
    for y in range(32):
        for x in range(32):
            r, g, b, _ = floor.getpixel((x, y))
            floor_dark.putpixel((x, y), (int(r * 0.32 + 6), int(g * 0.28 + 4), int(b * 0.38 + 10), 255))
    save_img(floor_dark, "stone/stone_floor_dark.png")

    # Stone Pillar (32x32)
    pil = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    for y in range(2, 30):
        for x in range(5, 27):
            pil.putpixel((x, y), s_body)
    for x in range(5, 27):
        pil.putpixel((x, 2), s_top_cap)
        pil.putpixel((x, 3), s_hi)
        pil.putpixel((x, 8), s_dark_mortar)
        pil.putpixel((x, 24), s_dark_mortar)
        pil.putpixel((x, 29), s_dark_mortar)
    for y in range(2, 30):
        pil.putpixel((5, y), s_hi)
        pil.putpixel((26, y), s_dark_mortar)
    save_img(pil, "stone/stone_pillar.png")

    # Grass-to-Dirt Transition tile
    trans = Image.open(os.path.join(BASE_DIR, "dirt/dirt_1.png")).copy()
    g1 = Image.open(os.path.join(BASE_DIR, "grass/grass_1.png"))
    for y in range(32):
        for x in range(32):
            cutoff = (x + y) - 24 + ((x * 7 + y * 11) % 5)
            if cutoff < 0:
                trans.putpixel((x, y), g1.getpixel((x, y)))
            elif cutoff < 3 and (x + y) % 2 == 0:
                trans.putpixel((x, y), (48, 88, 52, 255))
    save_img(trans, "stone/grass_dirt_transition.png")

# =============================================================================
# 4. VOID & ECLIPSE TILES (32x32)
# =============================================================================
def generate_void_and_eclipse():
    # Normal Void: Pitch black abyssal chasm with faint cosmic depth
    v_norm = Image.new("RGBA", (32, 32), (7, 6, 11, 255))
    for y in range(32):
        for x in range(32):
            if (x * 13 + y * 29) % 31 == 0:
                v_norm.putpixel((x, y), (14, 12, 22, 255))
            elif (x * 17 + y * 37) % 67 == 0:
                v_norm.putpixel((x, y), (32, 24, 48, 255))
    save_img(v_norm, "void/void_normal.png")

    # ECLIPSE Void: Dramatic glowing crimson red chasm with dark fissures
    v_ecl = Image.new("RGBA", (32, 32), (38, 6, 12, 255))
    c_red_deep = (24, 3, 7, 255)
    c_red_mid = (54, 8, 16, 255)
    c_red_bright = (95, 14, 26, 255)
    c_red_ember = (175, 28, 48, 255)

    for y in range(32):
        for x in range(32):
            val = (x * 11 + y * 19 + (x ^ y)) % 19
            if val < 4:
                v_ecl.putpixel((x, y), c_red_deep)
            elif val < 13:
                v_ecl.putpixel((x, y), c_red_mid)
            elif val < 17:
                v_ecl.putpixel((x, y), c_red_bright)
            else:
                v_ecl.putpixel((x, y), c_red_ember)
    save_img(v_ecl, "eclipse/void_eclipse.png")

    # Cyan Hidden Path: Radiant glowing cyan runic stone (striking contrast against red!)
    cyan = Image.new("RGBA", (32, 32), (12, 42, 52, 255))
    c_rim = (6, 68, 76, 255)
    c_cyan_dark = (18, 92, 106, 255)
    c_cyan_bright = (45, 220, 228, 255)
    c_cyan_core = (220, 255, 255, 255)

    for y in range(32):
        for x in range(32):
            if x in (0, 31) or y in (0, 31):
                cyan.putpixel((x, y), c_rim)
            elif x in (1, 30) or y in (1, 30):
                cyan.putpixel((x, y), c_cyan_dark)
            elif x in (2, 29) or y in (2, 29):
                cyan.putpixel((x, y), c_cyan_bright)
            else:
                # Glowing ancient runic pattern in center
                dist = abs(x - 15.5) + abs(y - 15.5)
                if dist in (8, 9):
                    cyan.putpixel((x, y), c_cyan_bright)
                elif dist in (5, 6):
                    cyan.putpixel((x, y), c_cyan_core)
                elif dist <= 4:
                    cyan.putpixel((x, y), c_cyan_bright if dist != 0 else c_cyan_core)
                else:
                    cyan.putpixel((x, y), (14, 52, 64, 255))
    save_img(cyan, "eclipse/cyan_path.png")

# =============================================================================
# 5. PROPS & ENVIRONMENT SPRITES
# =============================================================================
def generate_props():
    # ── Ancient Exit Gate Closed (32 x 48) ──
    # Majestic arched stone portal with heavy iron-banded wooden door & burning torches!
    gate_c = Image.new("RGBA", (32, 48), (0, 0, 0, 0))
    s_arch = (64, 68, 80, 255)
    s_hi = (120, 126, 144, 255)
    s_dark = (24, 26, 32, 255)
    wood_base = (78, 52, 34, 255)
    wood_shadow = (46, 30, 18, 255)
    iron_band = (140, 144, 155, 255)
    iron_dark = (60, 64, 72, 255)
    torch_gold = (255, 205, 50, 255)
    torch_orange = (235, 110, 25, 255)
    torch_red = (185, 45, 20, 255)

    # 1. Stone arch top (y = 0 to 12)
    for y in range(12):
        for x in range(32):
            gate_c.putpixel((x, y), s_arch)
            if y < 2: gate_c.putpixel((x, y), s_hi)
        gate_c.putpixel((0, y), s_dark)
        gate_c.putpixel((31, y), s_dark)
    for x in range(32):
        gate_c.putpixel((x, 0), s_dark)
        gate_c.putpixel((x, 12), s_dark)

    # 2. Side stone pillars (x = 0..4 and 27..31, y = 12..47)
    for y in range(12, 48):
        for x in (0, 1, 2, 3, 4, 27, 28, 29, 30, 31):
            gate_c.putpixel((x, y), s_arch)
            if x in (0, 31): gate_c.putpixel((x, y), s_dark)
            elif x in (1, 28): gate_c.putpixel((x, y), s_hi)

    # 3. Wooden heavy door (x = 5..26, y = 13..47)
    for y in range(13, 48):
        for x in range(5, 27):
            gate_c.putpixel((x, y), wood_base)
            if x in (5, 15, 16, 26) or y == 47:
                gate_c.putpixel((x, y), wood_shadow)

    # 4. Iron cross-bands and studs
    for hy in (20, 34):
        for x in range(5, 27):
            gate_c.putpixel((x, hy), iron_band)
            gate_c.putpixel((x, hy + 1), iron_dark)
    # Iron ring handles
    for rx, ry in [(12, 28), (19, 28)]:
        gate_c.putpixel((rx, ry), iron_band)
        gate_c.putpixel((rx, ry + 1), iron_band)

    # 5. Glowing wall torches flanking the arch at (2, 22) and (29, 22)
    for tx in (2, 29):
        # Iron bracket
        gate_c.putpixel((tx, 26), iron_dark)
        gate_c.putpixel((tx, 25), iron_band)
        # Flame
        gate_c.putpixel((tx, 24), torch_red)
        gate_c.putpixel((tx, 23), torch_orange)
        gate_c.putpixel((tx, 22), torch_gold)
        gate_c.putpixel((tx + 1 if tx == 2 else tx - 1, 23), torch_gold)
    save_img(gate_c, "props/gate_closed.png")

    # ── Ancient Exit Gate Open (32 x 48) ──
    # Arch remains, wooden doors are ajar, revealing a warm golden-lit passage!
    gate_o = gate_c.copy()
    passage_lit = (42, 32, 24, 255)
    passage_glow = (180, 135, 60, 255)
    passage_deep = (20, 16, 14, 255)

    for y in range(13, 48):
        for x in range(5, 27):
            dist_from_center = abs(x - 15.5)
            if dist_from_center < 7:
                gate_o.putpixel((x, y), passage_lit if y > 30 else passage_deep)
            else:
                gate_o.putpixel((x, y), wood_shadow)
    # Bright warm exit threshold glow
    for x in range(9, 23):
        gate_o.putpixel((x, 44), passage_glow)
        gate_o.putpixel((x, 45), (230, 190, 90, 255))
        gate_o.putpixel((x, 46), passage_glow)
    save_img(gate_o, "props/gate_open.png")

    # ── Lever Off (32x32) ──
    # Mounted on an ancient stone pedestal with brass mechanical armature
    lev_off = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    s_pedestal = (62, 66, 78, 255)
    s_hi_ped = (110, 116, 132, 255)
    # Stone plinth
    for y in range(20, 29):
        for x in range(8, 24):
            lev_off.putpixel((x, y), s_pedestal)
    for x in range(8, 24):
        lev_off.putpixel((x, 20), s_hi_ped)
        lev_off.putpixel((x, 28), s_dark)
    # Lever armature (angled back-left)
    for lx, ly in [(16, 20), (15, 18), (14, 16), (13, 14), (12, 12), (11, 10)]:
        lev_off.putpixel((lx, ly), (180, 155, 110, 255))
        lev_off.putpixel((lx + 1, ly), (95, 75, 45, 255))
    # Knob (dormant dark crimson)
    for kx in range(9, 13):
        for ky in range(7, 11):
            lev_off.putpixel((kx, ky), (180, 42, 50, 255))
    lev_off.putpixel((10, 8), (245, 120, 120, 255))
    save_img(lev_off, "props/lever_off.png")

    # ── Lever On (32x32) ──
    # Lever thrown forward-right, glowing with radiant cyan energy!
    lev_on = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    for y in range(20, 29):
        for x in range(8, 24):
            lev_on.putpixel((x, y), s_pedestal)
    for x in range(8, 24):
        lev_on.putpixel((x, 20), s_hi_ped)
        lev_on.putpixel((x, 28), s_dark)
    # Lever armature (angled forward-right)
    for lx, ly in [(16, 20), (17, 19), (18, 18), (19, 17), (20, 16), (21, 15)]:
        lev_on.putpixel((lx, ly), (180, 155, 110, 255))
        lev_on.putpixel((lx, ly + 1), (95, 75, 45, 255))
    # Luminous cyan knob
    for kx in range(20, 24):
        for ky in range(13, 17):
            lev_on.putpixel((kx, ky), (45, 230, 228, 255))
    lev_on.putpixel((21, 14), (220, 255, 255, 255))
    save_img(lev_on, "props/lever_on.png")

    # ── Ancient Carved Stone Tablet (32x32) ──
    # Standing megalith etched with ancient glowing cyan glyphs
    tab = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    t_body = (60, 64, 76, 255)
    t_hi = (112, 118, 136, 255)
    t_dark = (26, 28, 34, 255)
    t_cyan = (50, 230, 225, 255)
    t_cyan_core = (220, 255, 255, 255)

    # Monolith stele (x = 7..24, y = 4..27)
    for y in range(4, 28):
        for x in range(7, 25):
            tab.putpixel((x, y), t_body)
            if x == 7 or y == 4: tab.putpixel((x, y), t_hi)
            elif x == 24 or y == 27: tab.putpixel((x, y), t_dark)
    # Base plinth
    for y in range(27, 31):
        for x in range(5, 27):
            tab.putpixel((x, y), (44, 46, 56, 255))
            if y == 30: tab.putpixel((x, y), t_dark)
    # Circular cyan mystic eye / spiral glyph
    for ry in [8, 11, 14, 17, 20]:
        for rx in range(11, 21):
            if (rx + ry) % 3 != 0:
                tab.putpixel((rx, ry), t_cyan)
    tab.putpixel((15, 6), t_cyan_core)
    tab.putpixel((16, 6), t_cyan_core)
    save_img(tab, "props/tablet.png")

    # ── Ancient Parchment Note (32x32) ──
    # Crumpled ancient parchment scroll resting on the grass
    note = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    p_body = (220, 198, 150, 255)
    p_shadow = (170, 145, 95, 255)
    p_crease = (130, 105, 65, 255)
    p_ink = (75, 50, 30, 255)

    for y in range(8, 25):
        for x in range(9, 23):
            note.putpixel((x, y), p_body)
    # Curled corners and shadows
    for x in range(9, 23):
        note.putpixel((x, 8), (240, 220, 175, 255))
        note.putpixel((x, 24), p_shadow)
        note.putpixel((x, 25), (40, 30, 20, 120)) # drop shadow on grass
    for y in range(8, 25):
        note.putpixel((9, y), (240, 220, 175, 255))
        note.putpixel((22, y), p_shadow)
        note.putpixel((23, y), (40, 30, 20, 120))
    # Handwritten ink text lines
    for iy in (11, 14, 17, 20):
        for ix in range(11, 21):
            if (ix + iy * 2) % 3 != 0:
                note.putpixel((ix, iy), p_ink)
    save_img(note, "props/note.png")

    # ── Ancient Ruin Tree (48 x 64) ──
    tree = Image.new("RGBA", (48, 64), (0, 0, 0, 0))
    # Trunk
    trunk_c = (58, 40, 26, 255)
    trunk_dark = (36, 24, 15, 255)
    trunk_hi = (88, 62, 42, 255)
    moss_t = (48, 86, 44, 255)
    for y in range(32, 60):
        w = 4 + int((y - 32) * 0.35)
        for x in range(24 - w, 24 + w):
            tree.putpixel((x, y), trunk_c)
        tree.putpixel((24 - w, y), trunk_hi)
        tree.putpixel((24 + w - 1, y), trunk_dark)
    # Deep spreading roots
    for rx, ry in [(16, 59), (15, 60), (14, 61), (31, 59), (32, 60), (33, 61)]:
        tree.putpixel((rx, ry), trunk_dark)
    for mx, my in [(18, 56), (19, 56), (28, 56)]:
        tree.putpixel((mx, my), moss_t)

    # Voluminous leafy crown
    c_dark = (22, 52, 28, 255)
    c_mid = (38, 88, 44, 255)
    c_light = (62, 134, 70, 255)
    c_hi = (98, 180, 108, 255)

    clusters = [
        (24, 18, 18), (14, 25, 13), (34, 25, 13),
        (20, 32, 14), (28, 32, 14), (24, 10, 13)
    ]
    for cx, cy, rad in clusters:
        for y in range(cy - rad, cy + rad + 1):
            for x in range(cx - rad, cx + rad + 1):
                if 0 <= x < 48 and 0 <= y < 64:
                    dist = ((x - cx)**2 + (y - cy)**2)**0.5
                    if dist <= rad:
                        if y > cy + rad * 0.45 or dist > rad * 0.8:
                            col = c_dark
                        elif x < cx and y < cy:
                            col = c_hi if dist < rad * 0.4 else c_light
                        else:
                            col = c_mid
                        tree.putpixel((x, y), col)
    save_img(tree, "vegetation/tree.png")

    # ── Bush (32x32) ──
    bush = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    for y in range(32):
        for x in range(32):
            dist = ((x - 16)**2 + (y - 18)**2)**0.5
            if dist <= 12:
                if y > 24 or dist > 11:
                    bush.putpixel((x, y), (20, 48, 24, 255))
                elif x < 14 and y < 16:
                    bush.putpixel((x, y), (85, 170, 96, 255))
                elif dist < 8:
                    bush.putpixel((x, y), (48, 115, 58, 255))
                else:
                    bush.putpixel((x, y), (32, 80, 38, 255))
    # Wild red berries
    for bx, by in [(11, 14), (20, 16), (15, 21), (23, 20)]:
        bush.putpixel((bx, by), (225, 38, 48, 255))
        bush.putpixel((bx + 1, by), (255, 125, 135, 255))
    save_img(bush, "vegetation/bush.png")

    # ── Mossy Boulder Rock (32x32) ──
    rock = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    r_body = (74, 76, 88, 255)
    r_dark = (32, 34, 42, 255)
    r_hi = (122, 126, 142, 255)
    r_moss = (64, 120, 70, 255)

    for y in range(32):
        for x in range(32):
            dist = ((x - 16)**2 + (y - 18)**2 * 1.35)**0.5
            if dist <= 12:
                if y > 23 or dist > 11:
                    rock.putpixel((x, y), r_dark)
                elif x < 13 and y < 16:
                    rock.putpixel((x, y), r_hi)
                else:
                    rock.putpixel((x, y), r_body)
    # Overgrown moss patch on boulder crown
    for y in range(8, 14):
        for x in range(9, 23):
            if rock.getpixel((x, y))[3] > 0:
                rock.putpixel((x, y), r_moss)
    save_img(rock, "props/rock_moss.png")

def main():
    print("Generating environment pixel art...")
    generate_grass()
    generate_dirt()
    generate_stone()
    generate_void_and_eclipse()
    generate_props()
    print("Environment generation complete!")

if __name__ == "__main__":
    main()
