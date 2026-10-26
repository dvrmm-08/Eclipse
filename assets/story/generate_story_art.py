#!/usr/bin/env python3
"""
ECLIPSE — Retro Fantasy Pixel-Art Story Illustrations Generator
Generates 6 bespoke 8-bit/16-bit pixel-art illustrations for the introduction and ending:
  1. intro_page1.png: Ruined kingdom beneath an eclipsed moon.
  2. intro_page2.png: Fractured world / shattered mirror between normal & shadow realms.
  3. intro_page3.png: The Wanderer standing before ancient monolithic ruins.
  4. intro_page4.png: The Wanderer with mysterious towering Shadow silhouette behind.
  5. ending_illustration.png: Wanderer and Shadow facing each other amidst silent Watchers.
  6. eclipse_disc.png: Pixel-art solar/lunar eclipse with corona radiance for ending card.
"""

from PIL import Image, ImageDraw
import math
import os

WIDTH = 240
HEIGHT = 120

PALETTE = {
    "sky_dark": (5, 7, 17, 255),
    "sky_mid": (10, 14, 32, 255),
    "sky_light": (18, 25, 54, 255),
    "star_white": (255, 255, 255, 255),
    "star_cyan": (130, 220, 255, 255),
    "star_gold": (255, 215, 110, 255),
    
    "gold_bright": (250, 225, 140, 255),
    "gold_mid": (212, 175, 55, 255),
    "gold_dark": (140, 105, 25, 255),
    "gold_shadow": (65, 48, 12, 255),
    
    "stone_highlight": (139, 151, 188, 255),
    "stone_light": (98, 108, 142, 255),
    "stone_mid": (66, 73, 98, 255),
    "stone_dark": (42, 46, 64, 255),
    "stone_shadow": (24, 26, 38, 255),
    "stone_black": (14, 15, 22, 255),
    
    "cloak_white": (251, 250, 245, 255),
    "cloak_light": (224, 218, 204, 255),
    "cloak_mid": (175, 168, 152, 255),
    "cloak_shadow": (95, 90, 80, 255),
    "cloak_dark": (35, 32, 38, 255),
    
    "cyan_bright": (210, 255, 255, 255),
    "cyan_mid": (45, 230, 222, 255),
    "cyan_dark": (22, 130, 135, 255),
    
    "crimson_bright": (255, 90, 110, 255),
    "crimson_mid": (210, 35, 60, 255),
    "crimson_dark": (110, 15, 30, 255),
    
    "shadow_body": (10, 11, 18, 255),
    "shadow_glow": (30, 18, 32, 255),
}

def draw_starfield(draw, width, height, density=35, seed=42):
    # Deterministic pseudo-random stars
    import random
    rng = random.Random(seed)
    for _ in range(density):
        x = rng.randint(4, width - 5)
        y = rng.randint(4, height - 35)
        c = rng.choice([PALETTE["star_white"], PALETTE["star_cyan"], PALETTE["star_gold"]])
        draw.point((x, y), fill=c)
        if rng.random() > 0.75:
            # Twinkle cross
            draw.point((x+1, y), fill=PALETTE["sky_light"])
            draw.point((x-1, y), fill=PALETTE["sky_light"])
            draw.point((x, y+1), fill=PALETTE["sky_light"])
            draw.point((x, y-1), fill=PALETTE["sky_light"])

def draw_inner_pixel_border(draw, width, height):
    # Ornate inner frame for the illustration
    gold = PALETTE["gold_mid"]
    dark_gold = PALETTE["gold_shadow"]
    bright_gold = PALETTE["gold_bright"]
    
    # Single pixel bounding line
    draw.rectangle([0, 0, width - 1, height - 1], outline=dark_gold)
    draw.rectangle([1, 1, width - 2, height - 2], outline=gold)
    
    # Stepped corners
    for cx, cy in [(1, 1), (width - 5, 1), (1, height - 5), (width - 5, height - 5)]:
        draw.rectangle([cx, cy, cx + 3, cy + 3], fill=bright_gold)
        draw.point((cx + 1, cy + 1), fill=PALETTE["stone_black"])

def create_page1_illustration():
    """Page 1: A distant ruined kingdom beneath an eclipsed moon."""
    img = Image.new("RGBA", (WIDTH, HEIGHT), PALETTE["sky_dark"])
    draw = ImageDraw.Draw(img)
    
    # Sky gradient bands
    for y in range(HEIGHT):
        if y < 40:
            c = PALETTE["sky_dark"]
        elif y < 75:
            c = PALETTE["sky_mid"]
        else:
            c = PALETTE["sky_light"]
        draw.line([(0, y), (WIDTH, y)], fill=c)
        
    draw_starfield(draw, WIDTH, HEIGHT, 45, seed=101)
    
    # Eclipsed Moon (center-right, x=160, y=36, radius=16)
    mx, my, r = 155, 36, 17
    # Corona aura
    for dr in range(r + 6, r, -1):
        alpha = int(70 * (r + 7 - dr) / 7.0)
        draw.ellipse([mx - dr, my - dr, mx + dr, my + dr], outline=(212, 175, 55, alpha))
        draw.ellipse([mx - dr - 1, my - dr, mx + dr + 1, my + dr], outline=(255, 75, 90, alpha // 2))
    # Outer ring
    draw.ellipse([mx - r, my - r, mx + r, my + r], fill=PALETTE["gold_bright"], outline=PALETTE["gold_mid"])
    # Inner dark shadow disc
    draw.ellipse([mx - r + 2, my - r + 1, mx + r - 1, my + r - 1], fill=PALETTE["sky_dark"])
    # Golden crescent rim on left edge
    draw.arc([mx - r, my - r, mx + r, my + r], start=100, end=260, fill=PALETTE["gold_bright"], width=2)
    
    # Distant mountains silhouette
    pts = [
        (0, 85), (20, 72), (45, 80), (70, 65), (95, 78), 
        (120, 68), (145, 75), (170, 62), (195, 74), (220, 66), (WIDTH, 75),
        (WIDTH, HEIGHT), (0, HEIGHT)
    ]
    draw.polygon(pts, fill=PALETTE["stone_dark"])
    
    # Middle ruins & towers
    tower_pts = [
        # Left castle ruined spires
        (18, 50), (24, 45), (30, 50), (30, 88), (18, 88)
    ]
    draw.polygon(tower_pts, fill=PALETTE["stone_mid"])
    draw.polygon([(40, 56), (46, 52), (52, 56), (52, 90), (40, 90)], fill=PALETTE["stone_mid"])
    
    # Crumbling stone pillars
    for px, ph in [(65, 35), (80, 28), (105, 40), (125, 32), (185, 38), (205, 26), (222, 34)]:
        py = 88 - ph
        draw.rectangle([px, py, px + 7, 88], fill=PALETTE["stone_light"])
        # Shadow side of pillar
        draw.rectangle([px + 4, py, px + 7, 88], fill=PALETTE["stone_mid"])
        # Broken jagged top
        draw.point((px + 1, py - 1), fill=PALETTE["stone_light"])
        draw.point((px + 5, py + 1), fill=PALETTE["sky_mid"])
        
    # Foreground cliff and ground flagstones
    ground_pts = [
        (0, 88), (35, 86), (75, 90), (120, 87), (165, 89), (210, 87), (WIDTH, 90),
        (WIDTH, HEIGHT), (0, HEIGHT)
    ]
    draw.polygon(ground_pts, fill=PALETTE["stone_shadow"])
    
    # Foreground stone bricks detailing
    for y in range(92, HEIGHT - 3, 6):
        draw.line([(0, y), (WIDTH, y)], fill=PALETTE["stone_black"])
        offset = (y // 6) % 2 * 12
        for x in range(offset, WIDTH, 24):
            draw.line([(x, y), (x, y + 6)], fill=PALETTE["stone_black"])
            draw.point((x + 1, y + 1), fill=PALETTE["stone_mid"])
            
    # Lone watcher statue silhouette in foreground
    wx = 55
    draw.rectangle([wx, 78, wx + 8, 92], fill=PALETTE["stone_black"])
    draw.rectangle([wx + 1, 70, wx + 7, 78], fill=PALETTE["stone_black"])
    draw.point((wx + 3, 73), fill=PALETTE["crimson_mid"])
    
    draw_inner_pixel_border(draw, WIDTH, HEIGHT)
    return img

def create_page2_illustration():
    """Page 2: A shattered mirror / two overlapping worlds."""
    img = Image.new("RGBA", (WIDTH, HEIGHT), PALETTE["sky_dark"])
    draw = ImageDraw.Draw(img)
    
    # Left Half: Normal World (Ruins with starlight)
    draw.rectangle([0, 0, WIDTH // 2, HEIGHT], fill=PALETTE["sky_mid"])
    draw_starfield(draw, WIDTH // 2 - 10, HEIGHT, 25, seed=202)
    # Normal ground & pillar
    draw.polygon([(0, 85), (WIDTH // 2, 85), (WIDTH // 2, HEIGHT), (0, HEIGHT)], fill=PALETTE["stone_mid"])
    draw.rectangle([30, 48, 42, 85], fill=PALETTE["stone_light"])
    draw.rectangle([36, 48, 42, 85], fill=PALETTE["stone_shadow"])
    
    # Right Half: Eclipse Shadow Realm (Crimson void and cyan glow)
    draw.rectangle([WIDTH // 2, 0, WIDTH, HEIGHT], fill=(16, 8, 18, 255))
    # Crimson void gradient
    for y in range(HEIGHT):
        glow = int(45 * (y / HEIGHT))
        draw.line([(WIDTH // 2, y), (WIDTH, y)], fill=(28 + glow, 10, 24 + glow // 2, 255))
        
    # Floating Cyan bridge stepping stone in right realm
    draw.rectangle([140, 80, 185, 90], fill=PALETTE["cyan_dark"])
    draw.rectangle([142, 80, 183, 83], fill=PALETTE["cyan_mid"])
    draw.line([(144, 81), (181, 81)], fill=PALETTE["cyan_bright"])
    
    draw.rectangle([195, 72, 230, 82], fill=PALETTE["cyan_dark"])
    draw.rectangle([197, 72, 228, 75], fill=PALETTE["cyan_mid"])
    
    # Shattered Mirror Fracture (Jagged center fissure)
    fissure = [
        (120, 0), (124, 18), (116, 34), (126, 52), (114, 70), (128, 88), (118, 105), (122, HEIGHT)
    ]
    # Draw fissure glow
    for i in range(len(fissure) - 1):
        p1 = fissure[i]
        p2 = fissure[i+1]
        draw.line([p1, p2], fill=PALETTE["cyan_bright"], width=3)
        draw.line([p1, p2], fill=PALETTE["star_white"], width=1)
        
    # Floating mirror shards
    shards = [
        [(95, 30), (105, 26), (102, 38)],
        [(135, 45), (145, 42), (140, 55)],
        [(110, 80), (118, 74), (114, 88)],
        [(130, 92), (138, 88), (134, 100)]
    ]
    for s in shards:
        draw.polygon(s, fill=PALETTE["gold_bright"], outline=PALETTE["cyan_bright"])
        
    # Moon split in two across the fissure
    # Left moon half (Normal, golden)
    draw.chord([100, 15, 140, 55], start=90, end=270, fill=PALETTE["gold_bright"])
    draw.arc([100, 15, 140, 55], start=90, end=270, fill=PALETTE["gold_mid"], width=1)
    # Right moon half (Eclipse, black with crimson rim)
    draw.chord([102, 17, 142, 57], start=270, end=90, fill=PALETTE["shadow_body"])
    draw.arc([102, 17, 142, 57], start=270, end=90, fill=PALETTE["crimson_mid"], width=2)
    
    draw_inner_pixel_border(draw, WIDTH, HEIGHT)
    return img

def create_page3_illustration():
    """Page 3: The Wanderer standing before ancient ruins."""
    img = Image.new("RGBA", (WIDTH, HEIGHT), PALETTE["sky_dark"])
    draw = ImageDraw.Draw(img)
    
    # Sky with faint dawn/twilight glow
    for y in range(HEIGHT):
        draw.line([(0, y), (WIDTH, y)], fill=PALETTE["sky_mid"] if y < 70 else PALETTE["sky_light"])
    draw_starfield(draw, WIDTH, HEIGHT, 30, seed=303)
    
    # Giant monolithic ruin archway in background (centered at x=150)
    arch_left = 110
    arch_right = 190
    arch_top = 22
    # Arch pillars
    draw.rectangle([arch_left, arch_top, arch_left + 16, 92], fill=PALETTE["stone_dark"])
    draw.rectangle([arch_left + 2, arch_top, arch_left + 8, 92], fill=PALETTE["stone_light"])
    draw.rectangle([arch_right - 16, arch_top, arch_right, 92], fill=PALETTE["stone_dark"])
    draw.rectangle([arch_right - 14, arch_top, arch_right - 8, 92], fill=PALETTE["stone_light"])
    # Arch lintel
    draw.rectangle([arch_left - 8, arch_top - 10, arch_right + 8, arch_top], fill=PALETTE["stone_mid"])
    draw.rectangle([arch_left - 8, arch_top - 10, arch_right + 8, arch_top - 6], fill=PALETTE["stone_highlight"])
    # Mysterious portal void inside arch
    draw.rectangle([arch_left + 16, arch_top, arch_right - 16, 92], fill=(12, 16, 32, 255))
    draw.ellipse([arch_left + 22, arch_top + 15, arch_right - 22, 85], fill=(18, 30, 48, 255))
    # Glowing ancient runes on arch
    for ry in [30, 45, 60, 75]:
        draw.point((arch_left + 10, ry), fill=PALETTE["cyan_mid"])
        draw.point((arch_right - 10, ry), fill=PALETTE["cyan_mid"])
        
    # Stone ground
    draw.rectangle([0, 90, WIDTH, HEIGHT], fill=PALETTE["stone_shadow"])
    for y in range(94, HEIGHT, 6):
        draw.line([(0, y), (WIDTH, y)], fill=PALETTE["stone_black"])
        
    # Foreground White Wanderer (x=55, y=56, height=36)
    wx, wy = 55, 56
    # Hood & cloak
    draw.polygon([(wx + 8, wy), (wx + 2, wy + 8), (wx + 14, wy + 8)], fill=PALETTE["cloak_white"])
    # Face void
    draw.rectangle([wx + 5, wy + 7, wx + 11, wy + 11], fill=PALETTE["cloak_dark"])
    # Cyan eye
    draw.point((wx + 9, wy + 8), fill=PALETTE["cyan_bright"])
    # Cloak body
    draw.polygon([(wx + 2, wy + 9), (wx + 14, wy + 9), (wx + 17, wy + 32), (wx - 1, wy + 32)], fill=PALETTE["cloak_light"])
    draw.polygon([(wx + 4, wy + 10), (wx + 12, wy + 10), (wx + 14, wy + 31), (wx + 2, wy + 31)], fill=PALETTE["cloak_white"])
    # Shadow side of cloak
    draw.line([(wx + 15, wy + 12), (wx + 17, wy + 32)], fill=PALETTE["cloak_shadow"], width=2)
    # Cyan chest jewel/sigil
    draw.point((wx + 8, wy + 16), fill=PALETTE["cyan_bright"])
    draw.point((wx + 7, wy + 16), fill=PALETTE["cyan_mid"])
    draw.point((wx + 9, wy + 16), fill=PALETTE["cyan_mid"])
    # Boots
    draw.rectangle([wx + 3, wy + 32, wx + 7, wy + 36], fill=PALETTE["cloak_dark"])
    draw.rectangle([wx + 9, wy + 32, wx + 13, wy + 36], fill=PALETTE["cloak_dark"])
    
    # Ground shadow beneath Wanderer
    draw.ellipse([wx - 4, wy + 34, wx + 20, wy + 38], fill=PALETTE["stone_black"])
    
    draw_inner_pixel_border(draw, WIDTH, HEIGHT)
    return img

def create_page4_illustration():
    """Page 4: The Wanderer with mysterious Shadow silhouette looming behind."""
    img = Image.new("RGBA", (WIDTH, HEIGHT), PALETTE["sky_dark"])
    draw = ImageDraw.Draw(img)
    
    # Ominous eclipse twilight background
    for y in range(HEIGHT):
        c = (8 + y // 10, 8 + y // 14, 20 + y // 8, 255)
        draw.line([(0, y), (WIDTH, y)], fill=c)
    draw_starfield(draw, WIDTH, HEIGHT, 28, seed=404)
    
    # Distant ruined monoliths
    draw.rectangle([25, 45, 38, 92], fill=PALETTE["stone_dark"])
    draw.rectangle([200, 50, 215, 92], fill=PALETTE["stone_dark"])
    
    # Giant looming Shadow silhouette in midground (centered at x=148, y=20)
    sx, sy = 145, 22
    # Shadow aura/haze
    draw.ellipse([sx - 25, sy - 5, sx + 45, sy + 75], fill=(22, 10, 25, 120))
    # Shadow hood
    draw.polygon([(sx + 10, sy), (sx - 2, sy + 18), (sx + 22, sy + 18)], fill=PALETTE["shadow_body"])
    # Shadow body & cape widening downwards
    draw.polygon([(sx - 4, sy + 18), (sx + 24, sy + 18), (sx + 35, sy + 72), (sx - 15, sy + 72)], fill=PALETTE["shadow_body"])
    # Piercing Crimson Eyes in shadow hood
    draw.point((sx + 6, sy + 14), fill=PALETTE["crimson_bright"])
    draw.point((sx + 14, sy + 14), fill=PALETTE["crimson_bright"])
    # Ominous Crimson Chest Gem
    draw.ellipse([sx + 7, sy + 28, sx + 13, sy + 34], fill=PALETTE["crimson_bright"])
    draw.point((sx + 10, sy + 31), fill=PALETTE["star_white"])
    
    # Ground
    draw.rectangle([0, 92, WIDTH, HEIGHT], fill=PALETTE["stone_shadow"])
    for y in range(96, HEIGHT, 6):
        draw.line([(0, y), (WIDTH, y)], fill=PALETTE["stone_black"])
        
    # Foreground White Wanderer (x=80, y=55) facing forward
    wx, wy = 78, 55
    # Wanderer hood
    draw.polygon([(wx + 8, wy), (wx + 2, wy + 8), (wx + 14, wy + 8)], fill=PALETTE["cloak_white"])
    draw.rectangle([wx + 5, wy + 7, wx + 11, wy + 11], fill=PALETTE["cloak_dark"])
    draw.point((wx + 7, wy + 8), fill=PALETTE["cyan_bright"])
    draw.point((wx + 9, wy + 8), fill=PALETTE["cyan_bright"])
    # Cloak
    draw.polygon([(wx + 2, wy + 9), (wx + 14, wy + 9), (wx + 17, wy + 33), (wx - 1, wy + 33)], fill=PALETTE["cloak_light"])
    draw.polygon([(wx + 4, wy + 10), (wx + 12, wy + 10), (wx + 14, wy + 32), (wx + 2, wy + 32)], fill=PALETTE["cloak_white"])
    # Cyan chest sigil
    draw.point((wx + 8, wy + 16), fill=PALETTE["cyan_bright"])
    # Boots
    draw.rectangle([wx + 3, wy + 33, wx + 7, wy + 37], fill=PALETTE["cloak_dark"])
    draw.rectangle([wx + 9, wy + 33, wx + 13, wy + 37], fill=PALETTE["cloak_dark"])
    
    # Ground shadows
    draw.ellipse([wx - 4, wy + 35, wx + 20, wy + 39], fill=PALETTE["stone_black"])
    draw.ellipse([sx - 18, sy + 70, sx + 38, sy + 76], fill=PALETTE["stone_black"])
    
    draw_inner_pixel_border(draw, WIDTH, HEIGHT)
    return img

def create_ending_illustration():
    """Ending: Wanderer and Shadow facing each other in the silent ruins."""
    img = Image.new("RGBA", (WIDTH, HEIGHT), PALETTE["sky_dark"])
    draw = ImageDraw.Draw(img)
    
    # Eclipsed sky with deep crimson corona
    for y in range(HEIGHT):
        c = (12 + y // 12, 8 + y // 16, 24 + y // 10, 255)
        draw.line([(0, y), (WIDTH, y)], fill=c)
    draw_starfield(draw, WIDTH, HEIGHT, 35, seed=505)
    
    # Central Eclipse Disc in the heavens
    ex, ey, er = 120, 28, 14
    for r in range(er + 5, er, -1):
        draw.ellipse([ex - r, ey - r, ex + r, ey + r], outline=(210, 35, 60, 90))
    draw.ellipse([ex - er, ey - er, ex + er, ey + er], fill=(6, 6, 12, 255), outline=PALETTE["gold_mid"])
    draw.arc([ex - er, ey - er, ex + er, ey + er], start=45, end=225, fill=PALETTE["gold_bright"], width=2)
    
    # Distant Silent Watcher Statues flanking the arena
    # Left Watcher
    lwx = 35
    draw.rectangle([lwx, 52, lwx + 10, 88], fill=PALETTE["stone_mid"])
    draw.rectangle([lwx + 2, 44, lwx + 8, 52], fill=PALETTE["stone_mid"])
    # Eye is dark/dormant (Watchers fall silent!)
    draw.point((lwx + 5, 47), fill=PALETTE["stone_shadow"])
    
    # Right Watcher
    rwx = 195
    draw.rectangle([rwx, 52, rwx + 10, 88], fill=PALETTE["stone_mid"])
    draw.rectangle([rwx + 2, 44, rwx + 8, 52], fill=PALETTE["stone_mid"])
    draw.point((rwx + 5, 47), fill=PALETTE["stone_shadow"])
    
    # Flagstone Ground
    draw.rectangle([0, 88, WIDTH, HEIGHT], fill=PALETTE["stone_shadow"])
    for y in range(92, HEIGHT, 6):
        draw.line([(0, y), (WIDTH, y)], fill=PALETTE["stone_black"])
        
    # Wanderer on the Left (facing Right)
    wx, wy = 80, 54
    draw.polygon([(wx + 8, wy), (wx + 2, wy + 8), (wx + 14, wy + 8)], fill=PALETTE["cloak_white"])
    draw.rectangle([wx + 5, wy + 7, wx + 11, wy + 11], fill=PALETTE["cloak_dark"])
    draw.point((wx + 9, wy + 8), fill=PALETTE["cyan_bright"]) # Looking right
    draw.polygon([(wx + 2, wy + 9), (wx + 14, wy + 9), (wx + 16, wy + 34), (wx, wy + 34)], fill=PALETTE["cloak_light"])
    draw.polygon([(wx + 4, wy + 10), (wx + 13, wy + 10), (wx + 14, wy + 33), (wx + 3, wy + 33)], fill=PALETTE["cloak_white"])
    draw.point((wx + 8, wy + 16), fill=PALETTE["cyan_bright"])
    draw.rectangle([wx + 4, wy + 34, wx + 8, wy + 37], fill=PALETTE["cloak_dark"])
    draw.rectangle([wx + 10, wy + 34, wx + 14, wy + 37], fill=PALETTE["cloak_dark"])
    draw.ellipse([wx - 2, wy + 35, wx + 18, wy + 39], fill=PALETTE["stone_black"])
    
    # Shadow on the Right (facing Left)
    sx, sy = 145, 54
    draw.polygon([(sx + 6, sy), (sx, sy + 8), (sx + 12, sy + 8)], fill=PALETTE["shadow_body"])
    draw.rectangle([sx + 3, sy + 7, sx + 9, sy + 11], fill=(4, 4, 8, 255))
    draw.point((sx + 5, sy + 8), fill=PALETTE["crimson_bright"]) # Looking left
    draw.polygon([(sx, sy + 9), (sx + 12, sy + 9), (sx + 14, sy + 34), (sx - 2, sy + 34)], fill=PALETTE["shadow_body"])
    # Glowing Crimson Chest Gem
    draw.ellipse([sx + 4, sy + 14, sx + 8, sy + 18], fill=PALETTE["crimson_bright"])
    draw.point((sx + 6, sy + 16), fill=PALETTE["star_white"])
    draw.rectangle([sx + 2, sy + 34, sx + 6, sy + 37], fill=PALETTE["shadow_body"])
    draw.rectangle([sx + 8, sy + 34, sx + 12, sy + 37], fill=PALETTE["shadow_body"])
    draw.ellipse([sx - 4, sy + 35, sx + 16, sy + 39], fill=PALETTE["stone_black"])
    
    # Subtle glowing embers between them
    draw.point((112, 75), fill=PALETTE["cyan_bright"])
    draw.point((128, 72), fill=PALETTE["crimson_bright"])
    draw.point((120, 68), fill=PALETTE["gold_bright"])
    
    draw_inner_pixel_border(draw, WIDTH, HEIGHT)
    return img

def create_eclipse_disc():
    """Standalone pixel-art eclipse emblem for final title card."""
    size = 64
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    cx, cy, r = 32, 32, 20
    # Outer crimson / gold flare rays
    for angle_deg in range(0, 360, 20):
        rad = math.radians(angle_deg)
        x1 = cx + int((r + 1) * math.cos(rad))
        y1 = cy + int((r + 1) * math.sin(rad))
        ray_len = 6 if angle_deg % 40 == 0 else 3
        x2 = cx + int((r + 1 + ray_len) * math.cos(rad))
        y2 = cy + int((r + 1 + ray_len) * math.sin(rad))
        c = PALETTE["gold_bright"] if angle_deg % 40 == 0 else PALETTE["crimson_bright"]
        draw.line([(x1, y1), (x2, y2)], fill=c)
        
    # Corona ring
    draw.ellipse([cx - r - 2, cy - r - 2, cx + r + 2, cy + r + 2], outline=PALETTE["crimson_dark"], width=2)
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=PALETTE["gold_bright"], outline=PALETTE["gold_mid"])
    # Pitch black inner void
    draw.ellipse([cx - r + 2, cy - r + 2, cx + r - 2, cy + r - 2], fill=PALETTE["sky_dark"])
    # Crescent inner shine
    draw.arc([cx - r + 1, cy - r + 1, cx + r - 1, cy + r - 1], start=110, end=250, fill=PALETTE["gold_bright"], width=2)
    
    return img

def main():
    target_dir = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "story")
    os.makedirs(target_dir, exist_ok=True)
    
    illustrations = [
        ("intro_page1.png", create_page1_illustration()),
        ("intro_page2.png", create_page2_illustration()),
        ("intro_page3.png", create_page3_illustration()),
        ("intro_page4.png", create_page4_illustration()),
        ("ending_illustration.png", create_ending_illustration()),
        ("eclipse_disc.png", create_eclipse_disc())
    ]
    
    for filename, img in illustrations:
        filepath = os.path.join(target_dir, filename)
        img.save(filepath, "PNG")
        print(f"Generated: {filepath} ({img.size[0]}x{img.size[1]})")

if __name__ == "__main__":
    main()
