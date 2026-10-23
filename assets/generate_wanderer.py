from PIL import Image
import os

PALETTE = {
    '.': (0, 0, 0, 0),             # Transparent
    
    # Charcoal Outlines
    '#': (20, 20, 26, 255),        # Dark silhouette outline
    '|': (36, 34, 44, 255),        # Inner seam / fold divider
    
    # Ivory Hood & Cloak (Warm light top-left, soft cool-grey shadow bottom-right)
    '6': (255, 255, 250, 255),     # Highest ivory highlight
    '5': (246, 244, 234, 255),     # Bright ivory
    '4': (234, 230, 218, 255),     # Main ivory body
    '3': (212, 207, 194, 255),     # Soft ivory midtone
    '2': (180, 174, 162, 255),     # Light grey shadow
    '1': (142, 136, 126, 255),     # Medium grey shadow
    '0': (102, 98, 90, 255),       # Deep fold shadow
    
    # Hood Interior Face Void & Eyes
    'k': (10, 10, 14, 255),        # Void pitch black
    'j': (18, 17, 24, 255),        # Void subtle ambient rim
    'C': (220, 255, 255, 255),     # Glowing eye brilliant white-cyan sparkle
    'c': (65, 235, 230, 255),      # Glowing eye pale cyan
    'e': (24, 150, 155, 255),      # Eye ambient glow edge
    
    # Cyan Chest Sigil (Eclipse Diamond)
    '*': (225, 255, 255, 255),     # Radiant core
    'S': (45, 230, 222, 255),      # Luminous cyan
    's': (22, 160, 165, 255),      # Mid cyan / aura
    'q': (14, 95, 100, 255),       # Deep teal border
    
    # Belt & Buckle
    'b': (24, 22, 30, 255),        # Belt outline
    'B': (46, 42, 54, 255),        # Belt leather
    'm': (155, 148, 128, 255),     # Buckle brass
    'M': (205, 196, 170, 255),     # Buckle highlight
    
    # Dark Gloves
    'g': (22, 20, 28, 255),        # Glove outline
    'G': (44, 40, 52, 255),        # Glove leather
    'H': (72, 66, 84, 255),        # Glove highlight
    
    # Dark Pants / Underlayer
    'p': (26, 24, 32, 255),        # Pants shadow
    'P': (40, 36, 48, 255),        # Pants cloth
    
    # Sturdy Dark Boots
    't': (16, 14, 20, 255),        # Boot sole & outline
    'T': (36, 32, 44, 255),        # Boot dark leather
    'U': (60, 54, 72, 255),        # Boot midtone leather
    'u': (88, 80, 102, 255),       # Boot upper highlight
}

# 32 columns wide x 48 rows tall
# Character: The Wanderer
GRID = [
    # Y = 0..2: Top canvas margin
    "................................", # 00
    "................................", # 01
    "...............##...............", # 02 Hood cowl peak tip
    "..............#55#..............", # 03 Hood cowl apex
    ".............#6554#.............", # 04
    "............#655543#............", # 05
    "...........#65555432#...........", # 06
    "..........#6555554321#..........", # 07
    ".........#655555544321#.........", # 08
    "........#65555555443210#........", # 09
    ".......#6555555554432100#.......", # 10 Hood widest flare
    "......#6555########432100#......", # 11 Face void upper arch
    ".....#6555#kkkkkkkk#432100#.....", # 12 Face void
    ".....#655#kkkkkkkkkk#32100#.....", # 13
    "....#655#kkkkkkkkkkkk#32100#....", # 14 Face void full opening
    "....#655#kkCckkkkkkCck#3210#....", # 15 Pale cyan eyes top sparkle
    "....#655#kkeckkkkkkeck#3210#....", # 16 Pale cyan eyes lower glow
    "....#654#kkkkkkkkkkkk#21000#....", # 17 Face void lower
    ".....#54#kkkkkkkkkkkk#1000#.....", # 18
    ".....#544#kkkkkkkkkk#0000#......", # 19
    "......#443##########0000#.......", # 20 Chin / cowl seam
    "....##4445555555544332210##.....", # 21 Shoulder mantle begins
    "...#55555555555555443322110#....", # 22 Mantle flare
    '..#6555555555555554433221100#...', # 23 Shoulders full width
    '..#655544444#qq#444333221100#...', # 24 Eclipse sigil top
    '..#55444444#qSSq#44433221100#...', # 25 Eclipse sigil upper arc
    '..#5434444#qS**Sq#4443221100#...', # 26 Eclipse sigil radiant center
    '..#5434444#qS**Sq#4443221100#...', # 27 Eclipse sigil radiant center
    '..#43244444#qSSq#44443221100#...', # 28 Eclipse sigil lower arc
    '...#432#12344#qq#44321#1100#....', # 29 Sigil tip & waist taper
    '...#gG#1123444444443211#0Gg#....', # 30 Dark gloves emerging at sides
    '...#gH#bBBBBBBBBBBBBBBb#GHg#....', # 31 Dark belt with side gloves
    '....#g#bBBBBBmMMmBBBBBb#Gg#.....', # 32 Belt buckle in center
    '.....##123444444444443210##.....', # 33 Lower cloak draping below belt
    '......#123444444444443210#......', # 34 Cloak mid body
    '.....#01234444444444443210#.....', # 35
    '.....#01234444444444443210#.....', # 36
    '....#0123444444444444443210#....', # 37 Cloak flare
    '....#0123444444444444443210#....', # 38
    '...#012344444444444444443210#...', # 39 Cloak hem flare
    '...#012344444444444444443210#...', # 40
    '....#0123444#012210#4443210#....', # 41 Cloak hem opening
    '.....####33#..#pp#..#33####.....', # 42 Dark legs / pants visible
    '.........#uTt#....#tTu#.........', # 43 Boots top cuff
    '........#tUTTt#..#tTTUt#........', # 44 Boots instep
    '........#tUUTTt##tTTUUt#........', # 45 Boots body
    '........#tttttt##tttttt#........', # 46 Boots soles on ground
    '................................'  # 47 Ground margin
]

def generate():
    assert len(GRID) == 48, f"Expected 48 rows, got {len(GRID)}"
    for idx, row in enumerate(GRID):
        assert len(row) == 32, f"Row {idx} has length {len(row)}, expected 32: '{row}'"
        for ch in row:
            assert ch in PALETTE, f"Unknown char '{ch}' at row {idx}"
            
    img = Image.new("RGBA", (32, 48), (0, 0, 0, 0))
    for y, row in enumerate(GRID):
        for x, ch in enumerate(row):
            img.putpixel((x, y), PALETTE[ch])
            
    out_dir = os.path.dirname(os.path.abspath(__file__))
    out_path = os.path.join(out_dir, "wanderer.png")
    img.save(out_path, "PNG")
    print(f"Successfully generated {out_path} ({img.size[0]}x{img.size[1]})")

if __name__ == "__main__":
    generate()
