from PIL import Image, ImageDraw
import os

TILE_SIZE = 32

def create_tiles():
    # 8 tiles horizontally = 256 x 32 image
    # 0: Grass
    # 1: Dirt
    # 2: Stone Floor
    # 3: Stone Wall
    # 4: Void
    # 5: Cyan Bridge (Dormant / Normal)
    # 6: Cyan Bridge (Active / Eclipse)
    # 7: Pillar / Ruin Block
    img = Image.new("RGBA", (TILE_SIZE * 8, TILE_SIZE), (0, 0, 0, 0))
    
    # --- 0: GRASS ---
    # Base: deep mossy green with grass blade clusters
    grass = Image.new("RGBA", (32, 32), (34, 62, 36, 255))
    g_draw = ImageDraw.Draw(grass)
    # Mid green patches
    mid_green = (46, 82, 48, 255)
    light_green = (65, 115, 68, 255)
    dark_green = (24, 46, 26, 255)
    for x in range(32):
        for y in range(32):
            if (x * 7 + y * 13) % 5 == 0:
                grass.putpixel((x, y), mid_green)
            elif (x * 11 + y * 17) % 11 == 0:
                grass.putpixel((x, y), dark_green)
    # Distinct grass tufts
    tufts = [(4, 6), (18, 8), (10, 20), (24, 22), (14, 14), (28, 4), (2, 26)]
    for tx, ty in tufts:
        grass.putpixel((tx, ty), light_green)
        grass.putpixel((tx, ty - 1), light_green)
        grass.putpixel((tx + 1, ty), mid_green)
        grass.putpixel((tx - 1, ty + 1), dark_green)
        grass.putpixel((tx + 1, ty + 1), dark_green)
    img.paste(grass, (0 * 32, 0))

    # --- 1: DIRT PATH ---
    dirt = Image.new("RGBA", (32, 32), (92, 70, 52, 255))
    d_draw = ImageDraw.Draw(dirt)
    light_dirt = (118, 92, 70, 255)
    dark_dirt = (68, 50, 36, 255)
    pebble = (145, 130, 115, 255)
    for x in range(32):
        for y in range(32):
            if (x * 9 + y * 19) % 4 == 0:
                dirt.putpixel((x, y), light_dirt)
            elif (x * 13 + y * 7) % 6 == 0:
                dirt.putpixel((x, y), dark_dirt)
    # Little pebbles
    pebbles = [(8, 10), (22, 14), (12, 24), (26, 6)]
    for px, py in pebbles:
        dirt.putpixel((px, py), pebble)
        dirt.putpixel((px + 1, py), pebble)
        dirt.putpixel((px, py + 1), dark_dirt)
    img.paste(dirt, (1 * 32, 0))

    # --- 2: STONE FLOOR ---
    stone = Image.new("RGBA", (32, 32), (72, 74, 82, 255))
    s_light = (98, 100, 112, 255)
    s_dark = (48, 50, 58, 255)
    s_crack = (32, 34, 40, 255)
    # Flagstone borders
    for x in range(32):
        stone.putpixel((x, 0), s_dark)
        stone.putpixel((x, 15), s_dark)
        stone.putpixel((x, 31), s_dark)
    for y in range(0, 16):
        stone.putpixel((15, y), s_dark)
    for y in range(16, 32):
        stone.putpixel((7, y), s_dark)
        stone.putpixel((23, y), s_dark)
    # Highlights & cracks
    for x in range(1, 15):
        stone.putpixel((x, 1), s_light)
    for x in range(16, 31):
        stone.putpixel((x, 1), s_light)
    for x in range(8, 23):
        stone.putpixel((x, 16), s_light)
    # Crack detail
    for i in range(4):
        stone.putpixel((10 + i, 6 + i), s_crack)
    img.paste(stone, (2 * 32, 0))

    # --- 3: STONE WALL ---
    wall = Image.new("RGBA", (32, 32), (40, 42, 50, 255))
    w_top = (110, 115, 128, 255)
    w_face = (60, 64, 76, 255)
    w_shadow = (25, 26, 32, 255)
    w_crack = (16, 17, 22, 255)
    # Top rim highlight
    for x in range(32):
        for y in range(6):
            wall.putpixel((x, y), w_top if y < 2 else w_face)
        wall.putpixel((x, 6), w_shadow)
    # Lower wall blocks
    for x in range(32):
        for y in range(7, 32):
            wall.putpixel((x, y), w_face)
            if (x * 3 + y * 7) % 7 == 0:
                wall.putpixel((x, y), (50, 53, 64, 255))
    # Block seams
    for x in range(32):
        wall.putpixel((x, 19), w_shadow)
        wall.putpixel((x, 31), w_shadow)
    for y in range(7, 19):
        wall.putpixel((16, y), w_shadow)
    for y in range(19, 31):
        wall.putpixel((8, y), w_shadow)
        wall.putpixel((24, y), w_shadow)
    # Outer dark outline
    for x in range(32):
        wall.putpixel((x, 0), (20, 20, 26, 255))
    for y in range(32):
        wall.putpixel((0, y), (20, 20, 26, 255))
        wall.putpixel((31, y), (20, 20, 26, 255))
    img.paste(wall, (3 * 32, 0))

    # --- 4: VOID CHASM ---
    void_tile = Image.new("RGBA", (32, 32), (8, 6, 14, 255))
    for x in range(32):
        for y in range(32):
            dist = abs(x - 15.5) + abs(y - 15.5)
            if (x * 17 + y * 29) % 19 == 0:
                void_tile.putpixel((x, y), (18, 12, 28, 255))
            elif (x * 23 + y * 31) % 29 == 0:
                void_tile.putpixel((x, y), (30, 18, 48, 255)) # tiny starlight spark
    img.paste(void_tile, (4 * 32, 0))

    # --- 5: CYAN BRIDGE (Dormant in normal world) ---
    bridge_norm = void_tile.copy()
    # Faint faint dormant glyph outlines
    for x in range(4, 28):
        for y in range(4, 28):
            if (x == 4 or x == 27 or y == 4 or y == 27) and (x + y) % 3 != 0:
                bridge_norm.putpixel((x, y), (20, 45, 52, 255))
            elif (abs(x - 15.5) + abs(y - 15.5)) <= 5 and (x + y) % 2 == 0:
                bridge_norm.putpixel((x, y), (22, 55, 62, 255))
    img.paste(bridge_norm, (5 * 32, 0))

    # --- 6: CYAN BRIDGE (Active in Eclipse) ---
    bridge_act = Image.new("RGBA", (32, 32), (12, 24, 34, 255))
    c_core = (200, 255, 255, 255)
    c_glow = (50, 235, 230, 255)
    c_rim = (20, 140, 150, 255)
    c_dark = (14, 60, 75, 255)
    for x in range(32):
        for y in range(32):
            if x in (0, 31) or y in (0, 31):
                bridge_act.putpixel((x, y), (8, 30, 42, 255))
            elif x in (2, 29) or y in (2, 29):
                bridge_act.putpixel((x, y), c_rim)
            else:
                bridge_act.putpixel((x, y), c_dark)
    # Luminous runic diamond in center
    for x in range(6, 26):
        for y in range(6, 26):
            d = abs(x - 15.5) + abs(y - 15.5)
            if d == 8 or d == 7:
                bridge_act.putpixel((x, y), c_rim)
            elif d == 6 or d == 5:
                bridge_act.putpixel((x, y), c_glow)
            elif d <= 4:
                bridge_act.putpixel((x, y), c_core if d <= 2 else c_glow)
    img.paste(bridge_act, (6 * 32, 0))

    # --- 7: PILLAR / RUIN BLOCK ---
    pillar = Image.new("RGBA", (32, 32), (52, 54, 64, 255))
    p_highlight = (120, 125, 140, 255)
    p_shadow = (28, 30, 38, 255)
    # Carved border
    for x in range(32):
        pillar.putpixel((x, 0), (20, 20, 26, 255))
        pillar.putpixel((x, 1), p_highlight)
        pillar.putpixel((x, 30), p_shadow)
        pillar.putpixel((x, 31), (20, 20, 26, 255))
    for y in range(32):
        pillar.putpixel((0, y), (20, 20, 26, 255))
        pillar.putpixel((1, y), p_highlight)
        pillar.putpixel((30, y), p_shadow)
        pillar.putpixel((31, y), (20, 20, 26, 255))
    # Carved inset glyph
    for x in range(8, 24):
        for y in range(8, 24):
            if x in (8, 23) or y in (8, 23):
                pillar.putpixel((x, y), p_shadow)
            elif (x + y) % 4 == 0:
                pillar.putpixel((x, y), (42, 44, 52, 255))
    img.paste(pillar, (7 * 32, 0))

    out_path = os.path.join(os.path.dirname(__file__), "tileset.png")
    img.save(out_path, "PNG")
    print(f"Generated {out_path} ({img.size[0]}x{img.size[1]})")

def create_objects():
    # 32x32 sprite sheet for objects:
    # 0: Lever Off (up)
    # 1: Lever On (pulled down, glowing)
    # 2: Gate Closed (iron bars)
    # 3: Gate Open (gateway opening)
    # 4: Tablet / Inscription Stone
    # 5: Optional Note / Scroll
    # 6: Eye Statue (Gargoyle / Laser idol)
    img = Image.new("RGBA", (32 * 7, 32), (0, 0, 0, 0))

    # --- 0: LEVER OFF ---
    lever_off = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    # Base stand
    for x in range(8, 24):
        for y in range(22, 28):
            lever_off.putpixel((x, y), (50, 52, 60, 255))
        lever_off.putpixel((x, 28), (24, 25, 30, 255))
    for x in range(9, 23):
        lever_off.putpixel((x, 22), (90, 94, 105, 255))
    # Lever stick pointing up-left
    stick_pts = [(16, 22), (15, 20), (14, 18), (13, 16), (12, 14), (11, 12), (10, 10)]
    for sx, sy in stick_pts:
        lever_off.putpixel((sx, sy), (170, 160, 140, 255))
        lever_off.putpixel((sx + 1, sy), (100, 95, 80, 255))
    # Lever knob (dormant red / brass)
    for kx in range(8, 12):
        for ky in range(7, 11):
            lever_off.putpixel((kx, ky), (180, 50, 50, 255))
    lever_off.putpixel((9, 8), (250, 120, 120, 255))
    img.paste(lever_off, (0 * 32, 0))

    # --- 1: LEVER ON (Pulled) ---
    lever_on = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    # Base stand
    for x in range(8, 24):
        for y in range(22, 28):
            lever_on.putpixel((x, y), (50, 52, 60, 255))
        lever_on.putpixel((x, 28), (24, 25, 30, 255))
    for x in range(9, 23):
        lever_on.putpixel((x, 22), (90, 94, 105, 255))
    # Lever stick pointing down-right
    stick_pts_on = [(16, 22), (17, 21), (18, 20), (19, 19), (20, 18), (21, 17)]
    for sx, sy in stick_pts_on:
        lever_on.putpixel((sx, sy), (170, 160, 140, 255))
        lever_on.putpixel((sx, sy + 1), (100, 95, 80, 255))
    # Lever knob glowing cyan!
    for kx in range(21, 25):
        for ky in range(16, 20):
            lever_on.putpixel((kx, ky), (50, 230, 220, 255))
    lever_on.putpixel((22, 17), (220, 255, 255, 255))
    img.paste(lever_on, (1 * 32, 0))

    # --- 2: GATE CLOSED ---
    gate_c = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    # Stone arch frame
    for x in range(32):
        for y in range(6):
            gate_c.putpixel((x, y), (70, 72, 82, 255))
            if y < 2: gate_c.putpixel((x, y), (110, 114, 126, 255))
    for y in range(6, 32):
        for x in (0, 1, 2, 3, 4, 27, 28, 29, 30, 31):
            gate_c.putpixel((x, y), (60, 62, 70, 255))
    # Iron bars & lock
    bars_x = [8, 12, 16, 20, 24]
    for bx in bars_x:
        for by in range(6, 32):
            gate_c.putpixel((bx, by), (160, 165, 175, 255))
            gate_c.putpixel((bx + 1, by), (90, 95, 105, 255))
    # Horizontal crossbars
    for hx in range(5, 27):
        for hy in (12, 22):
            gate_c.putpixel((hx, hy), (130, 135, 145, 255))
            gate_c.putpixel((hx, hy + 1), (50, 52, 60, 255))
    # Large heavy iron lock
    for lx in range(14, 19):
        for ly in range(15, 20):
            gate_c.putpixel((lx, ly), (200, 160, 60, 255))
    gate_c.putpixel((16, 17), (40, 30, 10, 255))
    img.paste(gate_c, (2 * 32, 0))

    # --- 3: GATE OPEN ---
    gate_o = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    # Stone arch frame
    for x in range(32):
        for y in range(6):
            gate_o.putpixel((x, y), (70, 72, 82, 255))
            if y < 2: gate_o.putpixel((x, y), (110, 114, 126, 255))
    for y in range(6, 32):
        for x in (0, 1, 2, 3, 4, 27, 28, 29, 30, 31):
            gate_o.putpixel((x, y), (60, 62, 70, 255))
    # Open glowing portal path inside
    for x in range(5, 27):
        for y in range(6, 32):
            gate_o.putpixel((x, y), (20, 45, 40, 255) if y < 14 else (35, 75, 65, 255))
            if (x * 7 + y * 11) % 9 == 0:
                gate_o.putpixel((x, y), (80, 220, 180, 200)) # mystical light specks
    img.paste(gate_o, (3 * 32, 0))

    # --- 4: TABLET / STELE ---
    tablet = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    # Carved monolith
    for x in range(8, 24):
        for y in range(4, 28):
            tablet.putpixel((x, y), (68, 70, 80, 255))
            if x == 8 or y == 4:
                tablet.putpixel((x, y), (115, 120, 135, 255)) # highlight rim
            elif x == 23 or y == 27:
                tablet.putpixel((x, y), (30, 32, 38, 255)) # shadow rim
    # Plinth base
    for x in range(6, 26):
        for y in range(27, 31):
            tablet.putpixel((x, y), (48, 50, 58, 255))
    # Inscribed glowing cyan text/glyphs
    for r, gy in enumerate([8, 12, 16, 20]):
        for gx in range(11, 21):
            if (gx + r) % 3 != 0:
                tablet.putpixel((gx, gy), (60, 230, 220, 255))
    tablet.putpixel((15, 7), (200, 255, 255, 255)) # radiant sigil on tablet top
    img.paste(tablet, (4 * 32, 0))

    # --- 5: NOTE / SCROLL ---
    note = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    # Ancient parchment lying flat on ground with curled corners
    for x in range(10, 23):
        for y in range(14, 24):
            note.putpixel((x, y), (220, 205, 170, 255))
    for x in range(11, 22):
        note.putpixel((x, 14), (245, 235, 205, 255))
        note.putpixel((x, 23), (160, 140, 105, 255))
    for y in range(15, 23):
        note.putpixel((10, y), (240, 230, 195, 255))
        note.putpixel((22, y), (150, 130, 95, 255))
    # Ink lines
    for ly in [16, 18, 20]:
        for lx in range(12, 21):
            if lx % 2 == 0:
                note.putpixel((lx, ly), (80, 60, 45, 255))
    # Blood-red wax seal / red mark
    note.putpixel((20, 21), (190, 40, 40, 255))
    note.putpixel((21, 21), (190, 40, 40, 255))
    img.paste(note, (5 * 32, 0))

    # --- 6: EYE STATUE (Laser emitter) ---
    statue = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    # Heavy stone idol / gargoyle
    # Base
    for x in range(4, 28):
        for y in range(24, 31):
            statue.putpixel((x, y), (50, 52, 62, 255))
    # Pillar body
    for x in range(8, 24):
        for y in range(10, 24):
            statue.putpixel((x, y), (64, 66, 76, 255))
            if x in (8, 9): statue.putpixel((x, y), (95, 100, 115, 255))
            elif x in (22, 23): statue.putpixel((x, y), (35, 36, 44, 255))
    # Horned head / hood
    for x in range(6, 26):
        for y in range(2, 12):
            statue.putpixel((x, y), (45, 46, 56, 255))
    # Horns
    statue.putpixel((6, 1), (30, 31, 38, 255))
    statue.putpixel((7, 2), (30, 31, 38, 255))
    statue.putpixel((25, 1), (30, 31, 38, 255))
    statue.putpixel((24, 2), (30, 31, 38, 255))
    # Giant ominous glowing RED EYE in the center (Laser emitter aperture)
    for ex in range(13, 19):
        for ey in range(6, 12):
            statue.putpixel((ex, ey), (180, 20, 30, 255))
    for ex in range(14, 18):
        for ey in range(7, 11):
            statue.putpixel((ex, ey), (255, 50, 60, 255))
    statue.putpixel((15, 8), (255, 220, 220, 255))
    statue.putpixel((16, 8), (255, 220, 220, 255))
    img.paste(statue, (6 * 32, 0))

    out_path = os.path.join(os.path.dirname(__file__), "interactables.png")
    img.save(out_path, "PNG")
    print(f"Generated {out_path} ({img.size[0]}x{img.size[1]})")

if __name__ == "__main__":
    create_tiles()
    create_objects()
