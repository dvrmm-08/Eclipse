from PIL import Image, ImageDraw
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

def save_img(img, rel_path):
    path = os.path.join(BASE_DIR, rel_path)
    img.save(path, "PNG")
    print(f"Saved: {rel_path} ({img.size[0]}x{img.size[1]})")

# ==========================================
# 1. GRASS TILES (32x32)
# ==========================================
def make_grass():
    c_base = (38, 72, 42, 255)
    c_mid = (48, 92, 54, 255)
    c_light = (66, 122, 74, 255)
    c_hi = (92, 160, 102, 255)
    c_shadow = (24, 48, 28, 255)

    # Variant 1: Lush base grass
    g1 = Image.new("RGBA", (32, 32), c_base)
    for x in range(32):
        for y in range(32):
            val = (x * 7 + y * 13 + (x ^ y)) % 7
            if val == 0: g1.putpixel((x, y), c_shadow)
            elif val == 1: g1.putpixel((x, y), c_mid)
            elif val == 2 and (x + y) % 3 == 0: g1.putpixel((x, y), c_light)
    # Handcrafted blade clusters
    tufts1 = [(4, 6), (12, 18), (22, 8), (18, 24), (28, 16), (8, 26), (26, 28)]
    for tx, ty in tufts1:
        g1.putpixel((tx, ty), c_hi)
        g1.putpixel((tx, ty - 1), c_light)
        g1.putpixel((tx + 1, ty), c_mid)
        g1.putpixel((tx - 1, ty + 1), c_shadow)
        g1.putpixel((tx, ty + 1), c_shadow)
    save_img(g1, "grass/grass_1.png")

    # Variant 2: Grass with tiny yellow/white florets
    g2 = g1.copy()
    florets = [(10, 8), (20, 20), (6, 22), (25, 6)]
    for fx, fy in florets:
        g2.putpixel((fx, fy), (240, 230, 130, 255))
        g2.putpixel((fx + 1, fy), (255, 255, 210, 255))
        g2.putpixel((fx, fy + 1), c_shadow)
    save_img(g2, "grass/grass_2.png")

    # Variant 3: Overgrown grass with dark moss patches
    g3 = g1.copy()
    moss_col = (20, 42, 24, 255)
    for px, py in [(14, 12), (15, 12), (14, 13), (15, 13), (16, 13), (2, 4), (3, 4), (2, 5)]:
        g3.putpixel((px, py), moss_col)
    save_img(g3, "grass/grass_3.png")

    # Darkened grass for ECLIPSE mode
    g_dark = Image.new("RGBA", (32, 32), (18, 26, 22, 255))
    for x in range(32):
        for y in range(32):
            r, g, b, a = g1.getpixel((x, y))
            # Subdued, dark shadow-realm tone
            g_dark.putpixel((x, y), (int(r * 0.35), int(g * 0.35 + 8), int(b * 0.45 + 10), 255))
    save_img(g_dark, "grass/grass_dark.png")

# ==========================================
# 2. DIRT TILES (32x32)
# ==========================================
def make_dirt():
    d_base = (94, 68, 48, 255)
    d_dark = (68, 48, 34, 255)
    d_light = (120, 90, 66, 255)
    d_pebble = (148, 135, 120, 255)

    d1 = Image.new("RGBA", (32, 32), d_base)
    for x in range(32):
        for y in range(32):
            v = (x * 11 + y * 17 + (x * 3)) % 8
            if v == 0: d1.putpixel((x, y), d_dark)
            elif v == 1: d1.putpixel((x, y), d_light)
            elif v == 2 and (x + y) % 5 == 0: d1.putpixel((x, y), d_dark)
    # Small pebbles
    for px, py in [(8, 12), (24, 8), (14, 22), (22, 26)]:
        d1.putpixel((px, py), d_pebble)
        d1.putpixel((px + 1, py), (175, 165, 150, 255))
        d1.putpixel((px, py + 1), d_dark)
    save_img(d1, "dirt/dirt_1.png")

    # Dirt 2: Weathered soil with embedded cobbles
    d2 = d1.copy()
    cobble_c = (85, 82, 90, 255)
    for cx, cy in [(6, 6), (18, 14), (10, 24)]:
        for dx in range(3):
            for dy in range(2):
                d2.putpixel((cx + dx, cy + dy), cobble_c)
        d2.putpixel((cx, cy), (115, 112, 122, 255))
        d2.putpixel((cx + 1, cy + 2), d_dark)
    save_img(d2, "dirt/dirt_2.png")

    # Dirt 3: Dirt with mossy edges
    d3 = d1.copy()
    moss_edge = (42, 78, 46, 255)
    for i in range(10):
        d3.putpixel((i * 3 % 32, (i * 7) % 32), moss_edge)
    save_img(d3, "dirt/dirt_3.png")

    # Darkened dirt for ECLIPSE mode
    d_dark_mode = Image.new("RGBA", (32, 32), (0, 0, 0, 255))
    for x in range(32):
        for y in range(32):
            r, g, b, a = d1.getpixel((x, y))
            d_dark_mode.putpixel((x, y), (int(r * 0.38 + 6), int(g * 0.30 + 4), int(b * 0.35 + 8), 255))
    save_img(d_dark_mode, "dirt/dirt_dark.png")

# ==========================================
# 3. TRANSITIONS & STONE (32x32)
# ==========================================
def make_stone_and_transitions():
    # Grass to Dirt transition
    # Top/left grass, bottom/right dirt with fringed pixel clusters
    trans = Image.open(os.path.join(BASE_DIR, "dirt/dirt_1.png")).copy()
    g1 = Image.open(os.path.join(BASE_DIR, "grass/grass_1.png"))
    for x in range(32):
        for y in range(32):
            threshold = (x + y) - 24 + ((x * 5 + y * 7) % 5)
            if threshold < 0:
                trans.putpixel((x, y), g1.getpixel((x, y)))
            elif threshold < 3 and (x * 3 + y * 2) % 3 != 0:
                trans.putpixel((x, y), (44, 82, 48, 255))
    save_img(trans, "stone/grass_dirt_transition.png")

    # Stone Floor 1: Ancient ruin flagstones
    sf1 = Image.new("RGBA", (32, 32), (68, 70, 78, 255))
    s_light = (96, 99, 110, 255)
    s_dark = (36, 38, 44, 255)
    s_crease = (24, 26, 30, 255)
    moss_g = (46, 80, 50, 255)
    
    for x in range(32):
        sf1.putpixel((x, 0), s_crease)
        sf1.putpixel((x, 15), s_crease)
        sf1.putpixel((x, 31), s_crease)
    for y in range(0, 16):
        sf1.putpixel((15, y), s_crease)
    for y in range(16, 32):
        sf1.putpixel((7, y), s_crease)
        sf1.putpixel((23, y), s_crease)
    # Highlights along top edges of flagstones
    for x in range(1, 15): sf1.putpixel((x, 1), s_light)
    for x in range(16, 31): sf1.putpixel((x, 1), s_light)
    for x in range(8, 23): sf1.putpixel((x, 16), s_light)
    # Crevice moss
    sf1.putpixel((14, 2), moss_g)
    sf1.putpixel((16, 14), moss_g)
    sf1.putpixel((6, 17), moss_g)
    save_img(sf1, "stone/stone_floor_1.png")

    # Stone Floor Dark (ECLIPSE)
    sf_dark = Image.new("RGBA", (32, 32), (0, 0, 0, 255))
    for x in range(32):
        for y in range(32):
            r, g, b, a = sf1.getpixel((x, y))
            sf_dark.putpixel((x, y), (int(r * 0.35 + 8), int(g * 0.32 + 4), int(b * 0.42 + 10), 255))
    save_img(sf_dark, "stone/stone_floor_dark.png")

    # Stone Wall: Sturdy mossy masonry
    wall = Image.new("RGBA", (32, 32), (48, 50, 58, 255))
    w_dark = (22, 22, 28, 255)
    w_hi = (112, 116, 130, 255)
    w_mid = (72, 75, 88, 255)
    w_moss = (54, 96, 58, 255)
    w_moss_dark = (28, 52, 32, 255)

    # Dark outlines
    for x in range(32):
        wall.putpixel((x, 0), w_dark)
        wall.putpixel((x, 7), w_dark)
        wall.putpixel((x, 19), w_dark)
        wall.putpixel((x, 31), w_dark)
    for y in range(32):
        wall.putpixel((0, y), w_dark)
        wall.putpixel((31, y), w_dark)
    # Seams
    for y in range(8, 19): wall.putpixel((16, y), w_dark)
    for y in range(20, 31):
        wall.putpixel((8, y), w_dark)
        wall.putpixel((24, y), w_dark)
    # Top highlights
    for x in range(1, 31):
        wall.putpixel((x, 1), w_hi)
        wall.putpixel((x, 8), w_mid)
        wall.putpixel((x, 20), w_mid)
    # Overgrown hanging moss & vines
    for mx in [4, 5, 12, 13, 22, 23, 27]:
        wall.putpixel((mx, 2), w_moss)
        wall.putpixel((mx, 3), w_moss)
        wall.putpixel((mx, 4), w_moss_dark)
    wall.putpixel((12, 9), w_moss)
    wall.putpixel((12, 10), w_moss_dark)
    save_img(wall, "stone/stone_wall.png")

    # Stone Pillar (32x32)
    pil = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    for x in range(4, 28):
        for y in range(2, 30):
            pil.putpixel((x, y), (60, 62, 72, 255))
    for x in range(4, 28):
        pil.putpixel((x, 2), w_hi)
        pil.putpixel((x, 29), w_dark)
        pil.putpixel((x, 8), w_dark)
        pil.putpixel((x, 24), w_dark)
    for y in range(2, 30):
        pil.putpixel((4, y), w_hi if y < 10 else (80, 84, 98, 255))
        pil.putpixel((27, y), w_dark)
    # Runic carving in center
    for y in range(12, 20):
        pil.putpixel((15, y), (30, 32, 38, 255))
        pil.putpixel((16, y), (30, 32, 38, 255))
    pil.putpixel((14, 15), (30, 32, 38, 255))
    pil.putpixel((17, 15), (30, 32, 38, 255))
    save_img(pil, "stone/stone_pillar.png")

# ==========================================
# 4. VOID & ECLIPSE TILES (32x32)
# ==========================================
def make_void_and_eclipse():
    # Void Normal: Near-black starry cosmic abyss
    v_norm = Image.new("RGBA", (32, 32), (8, 7, 12, 255))
    for x in range(32):
        for y in range(32):
            if (x * 13 + y * 29) % 23 == 0:
                v_norm.putpixel((x, y), (18, 14, 28, 255))
            elif (x * 19 + y * 37) % 47 == 0:
                v_norm.putpixel((x, y), (38, 28, 58, 255)) # cosmic dust spark
    save_img(v_norm, "void/void_normal.png")

    # Void ECLIPSE: Deep ominous crimson-red void
    v_ecl = Image.new("RGBA", (32, 32), (42, 6, 12, 255))
    for x in range(32):
        for y in range(32):
            val = (x * 11 + y * 19 + (x ^ y)) % 17
            if val == 0: v_ecl.putpixel((x, y), (28, 3, 8, 255)) # deep shadow
            elif val in (1, 2): v_ecl.putpixel((x, y), (68, 10, 20, 255)) # red cloud
            elif val == 3: v_ecl.putpixel((x, y), (98, 16, 32, 255)) # crimson glow
            elif (x * 23 + y * 31) % 41 == 0:
                v_ecl.putpixel((x, y), (180, 32, 54, 255)) # burning ember
    save_img(v_ecl, "eclipse/void_eclipse.png")

    # Cyan Hidden Path (ECLIPSE)
    # Radiant, bright cyan runic bridge that strongly contrasts with red void!
    cyan = Image.new("RGBA", (32, 32), (10, 36, 44, 255))
    c_border = (8, 70, 78, 255)
    c_bright = (48, 230, 220, 255)
    c_core = (210, 255, 255, 255)
    c_dark = (16, 60, 68, 255)

    for x in range(32):
        for y in range(32):
            if x in (0, 31) or y in (0, 31):
                cyan.putpixel((x, y), c_border)
            elif x in (1, 30) or y in (1, 30):
                cyan.putpixel((x, y), c_dark)
            else:
                cyan.putpixel((x, y), (14, 48, 56, 255))

    # Glowing runic diamond sigil in center
    for x in range(4, 28):
        for y in range(4, 28):
            d = abs(x - 15.5) + abs(y - 15.5)
            if d in (9, 10):
                cyan.putpixel((x, y), c_border)
            elif d in (7, 8):
                cyan.putpixel((x, y), c_bright)
            elif d in (5, 6):
                cyan.putpixel((x, y), c_core if d == 5 else c_bright)
            elif d <= 4:
                cyan.putpixel((x, y), c_core if d <= 2 else c_bright)
    save_img(cyan, "eclipse/cyan_path.png")

# ==========================================
# 5. PROPS & VEGETATION
# ==========================================
def make_props():
    # Tree (48 x 64): Ancient mossy ruin tree
    tree = Image.new("RGBA", (48, 64), (0, 0, 0, 0))
    t_draw = ImageDraw.Draw(tree)
    # Trunk
    trunk_c = (56, 38, 24, 255)
    trunk_dark = (36, 24, 15, 255)
    trunk_hi = (82, 58, 38, 255)
    moss_trunk = (44, 78, 40, 255)
    for y in range(34, 60):
        w = 5 + int((y - 34) * 0.3)
        for x in range(24 - w, 24 + w):
            tree.putpixel((x, y), trunk_c)
        tree.putpixel((24 - w, y), trunk_hi)
        tree.putpixel((24 + w - 1, y), trunk_dark)
    # Roots spreading
    for rx, ry in [(16, 59), (15, 60), (14, 61), (31, 59), (32, 60), (33, 61)]:
        tree.putpixel((rx, ry), trunk_dark)
    # Moss on roots
    for mx, my in [(18, 56), (19, 56), (20, 55), (28, 56)]:
        tree.putpixel((mx, my), moss_trunk)

    # Leaf canopy (rounded pixel clusters)
    canopy_dark = (22, 50, 26, 255)
    canopy_mid = (36, 84, 42, 255)
    canopy_light = (58, 126, 66, 255)
    canopy_hi = (92, 172, 104, 255)

    clusters = [
        (24, 20, 18), (14, 26, 12), (34, 26, 12),
        (20, 32, 14), (28, 32, 14), (24, 12, 14)
    ]
    for cx, cy, rad in clusters:
        for x in range(cx - rad, cx + rad + 1):
            for y in range(cy - rad, cy + rad + 1):
                if 0 <= x < 48 and 0 <= y < 64:
                    dist = ((x - cx)**2 + (y - cy)**2)**0.5
                    if dist <= rad:
                        # Cluster lighting from top-left
                        if y > cy + rad * 0.4: col = canopy_dark
                        elif dist > rad * 0.75: col = canopy_dark
                        elif x < cx and y < cy: col = canopy_hi if dist < rad * 0.4 else canopy_light
                        else: col = canopy_mid
                        tree.putpixel((x, y), col)
    save_img(tree, "vegetation/tree.png")

    # Bush (32x32)
    bush = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    for x in range(32):
        for y in range(32):
            d = ((x - 16)**2 + (y - 18)**2)**0.5
            if d <= 12:
                if y > 24 or d > 11: bush.putpixel((x, y), (20, 46, 24, 255))
                elif x < 14 and y < 16: bush.putpixel((x, y), (82, 162, 94, 255))
                elif d < 9: bush.putpixel((x, y), (46, 108, 54, 255))
                else: bush.putpixel((x, y), (30, 74, 36, 255))
    # Red berries
    for bx, by in [(12, 14), (20, 16), (15, 20), (22, 21)]:
        bush.putpixel((bx, by), (220, 40, 50, 255))
        bush.putpixel((bx + 1, by), (255, 120, 130, 255))
    save_img(bush, "vegetation/bush.png")

    # Mossy Rock (32x32)
    rock = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    r_body = (72, 74, 84, 255)
    r_dark = (32, 34, 40, 255)
    r_hi = (120, 124, 138, 255)
    r_moss = (62, 114, 68, 255)
    for x in range(32):
        for y in range(32):
            d = ((x - 16)**2 + (y - 18)**2 * 1.3)**0.5
            if d <= 12:
                if y > 23 or d > 11: rock.putpixel((x, y), r_dark)
                elif x < 13 and y < 16: rock.putpixel((x, y), r_hi)
                else: rock.putpixel((x, y), r_body)
    # Top moss cap
    for x in range(8, 24):
        for y in range(8, 14):
            if rock.getpixel((x, y))[3] > 0:
                rock.putpixel((x, y), r_moss)
    save_img(rock, "props/rock_moss.png")

    # Stone Tablet (32x32)
    tab = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    t_stone = (58, 60, 70, 255)
    t_hi = (108, 112, 128, 255)
    t_dark = (24, 26, 32, 255)
    t_cyan = (60, 235, 225, 255)
    t_core = (220, 255, 255, 255)
    # Monolith
    for x in range(7, 25):
        for y in range(4, 28):
            tab.putpixel((x, y), t_stone)
            if x == 7 or y == 4: tab.putpixel((x, y), t_hi)
            elif x == 24 or y == 27: tab.putpixel((x, y), t_dark)
    # Base slab
    for x in range(5, 27):
        for y in range(27, 31):
            tab.putpixel((x, y), (42, 44, 52, 255))
            if y == 30: tab.putpixel((x, y), t_dark)
    # Glowing cyan runes
    for ry in [8, 12, 16, 20]:
        for rx in range(10, 22):
            if (rx + ry) % 3 != 0:
                tab.putpixel((rx, ry), t_cyan)
    tab.putpixel((15, 6), t_core)
    tab.putpixel((16, 6), t_core)
    save_img(tab, "props/tablet.png")

    # Lever Off (32x32)
    lev_off = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    # Pedestal
    for x in range(8, 24):
        for y in range(20, 28):
            lev_off.putpixel((x, y), (56, 58, 68, 255))
        lev_off.putpixel((x, 28), (22, 24, 28, 255))
    for x in range(9, 23): lev_off.putpixel((x, 20), (98, 102, 116, 255))
    # Iron lever arm up-left
    for idx, (lx, ly) in enumerate([(16, 20), (15, 18), (14, 16), (13, 14), (12, 12), (11, 10)]):
        lev_off.putpixel((lx, ly), (170, 165, 150, 255))
        lev_off.putpixel((lx + 1, ly), (90, 85, 75, 255))
    # Knob
    for kx in range(9, 13):
        for ky in range(7, 11):
            lev_off.putpixel((kx, ky), (190, 40, 50, 255))
    lev_off.putpixel((10, 8), (255, 140, 140, 255))
    save_img(lev_off, "props/lever_off.png")

    # Lever On (32x32)
    lev_on = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    for x in range(8, 24):
        for y in range(20, 28):
            lev_on.putpixel((x, y), (56, 58, 68, 255))
        lev_on.putpixel((x, 28), (22, 24, 28, 255))
    for x in range(9, 23): lev_on.putpixel((x, 20), (98, 102, 116, 255))
    # Lever arm down-right
    for lx, ly in [(16, 20), (17, 19), (18, 18), (19, 17), (20, 16)]:
        lev_on.putpixel((lx, ly), (170, 165, 150, 255))
        lev_on.putpixel((lx, ly + 1), (90, 85, 75, 255))
    # Glowing cyan knob
    for kx in range(20, 24):
        for ky in range(15, 19):
            lev_on.putpixel((kx, ky), (45, 230, 220, 255))
    lev_on.putpixel((21, 16), (220, 255, 255, 255))
    save_img(lev_on, "props/lever_on.png")

    # Ancient Stone Exit Gate Closed (32 x 48)
    gate_c = Image.new("RGBA", (32, 48), (0, 0, 0, 0))
    # Arch pillars
    g_stone = (64, 66, 76, 255)
    g_hi = (112, 116, 130, 255)
    g_dark = (26, 28, 34, 255)
    g_moss = (48, 92, 54, 255)

    # Top arch
    for x in range(32):
        for y in range(10):
            gate_c.putpixel((x, y), g_stone)
            if y < 2: gate_c.putpixel((x, y), g_hi)
        gate_c.putpixel((x, 10), g_dark)
        gate_c.putpixel((x, 0), g_dark)
    # Side pillars
    for y in range(10, 48):
        for x in (0, 1, 2, 3, 4, 27, 28, 29, 30, 31):
            gate_c.putpixel((x, y), g_stone)
            if x in (0, 31): gate_c.putpixel((x, y), g_dark)
            elif x in (1, 28): gate_c.putpixel((x, y), g_hi)
    # Hanging moss on arch
    for mx in [5, 6, 15, 16, 25]:
        gate_c.putpixel((mx, 4), g_moss)
        gate_c.putpixel((mx, 5), g_moss)
        gate_c.putpixel((mx, 6), (28, 52, 32, 255))
    # Portcullis iron bars
    for bx in [9, 13, 17, 21]:
        for by in range(11, 48):
            gate_c.putpixel((bx, by), (150, 155, 165, 255))
            gate_c.putpixel((bx + 1, by), (70, 75, 85, 255))
    for hx in range(5, 27):
        for hy in (20, 34):
            gate_c.putpixel((hx, hy), (130, 135, 145, 255))
            gate_c.putpixel((hx, hy + 1), (40, 42, 50, 255))
    # Heavy golden padlock in center
    for lx in range(14, 19):
        for ly in range(24, 30):
            gate_c.putpixel((lx, ly), (210, 170, 50, 255))
    gate_c.putpixel((16, 26), (40, 30, 10, 255))
    save_img(gate_c, "props/gate_closed.png")

    # Ancient Stone Exit Gate Open (32 x 48)
    gate_o = gate_c.copy()
    # Remove bars and lock, draw deep mystical portal passage
    for x in range(5, 27):
        for y in range(11, 48):
            # Glowing portal depth
            dist_top = y - 11
            if dist_top < 10: col = (14, 38, 32, 255)
            elif dist_top < 24: col = (24, 62, 52, 255)
            else: col = (38, 92, 78, 255)
            gate_o.putpixel((x, y), col)
            if (x * 7 + y * 13) % 11 == 0:
                gate_o.putpixel((x, y), (90, 240, 200, 255)) # mystical emerald specks
    save_img(gate_o, "props/gate_open.png")

    # Note / Parchment Scroll (32x32)
    note = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    for x in range(9, 23):
        for y in range(13, 23):
            note.putpixel((x, y), (230, 215, 180, 255))
    for x in range(10, 22):
        note.putpixel((x, 13), (255, 245, 215, 255))
        note.putpixel((x, 22), (170, 150, 115, 255))
    for y in range(14, 22):
        note.putpixel((9, y), (250, 240, 205, 255))
        note.putpixel((22, y), (160, 140, 105, 255))
    for ly in [15, 17, 19]:
        for lx in range(11, 21):
            if lx % 2 == 0: note.putpixel((lx, ly), (80, 60, 45, 255))
    # Wax seal
    note.putpixel((20, 20), (195, 35, 35, 255))
    note.putpixel((21, 20), (195, 35, 35, 255))
    save_img(note, "props/note.png")

if __name__ == "__main__":
    make_grass()
    make_dirt()
    make_stone_and_transitions()
    make_void_and_eclipse()
    make_props()
    print("\nAll environment pixel-art assets generated successfully!")
