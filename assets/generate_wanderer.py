from PIL import Image
import os

PALETTE = {
    '.': (0, 0, 0, 0),             # Transparent

    # Charcoal outlines
    '#': (20, 20, 26, 255),
    '|': (36, 34, 44, 255),

    # Ivory hood and cloak
    '6': (255, 255, 250, 255),
    '5': (246, 244, 234, 255),
    '4': (234, 230, 218, 255),
    '3': (212, 207, 194, 255),
    '2': (180, 174, 162, 255),
    '1': (142, 136, 126, 255),
    '0': (102, 98, 90, 255),

    # Face void and cyan eyes
    'k': (10, 10, 14, 255),
    'j': (18, 17, 24, 255),
    'C': (220, 255, 255, 255),
    'c': (65, 235, 230, 255),
    'e': (24, 150, 155, 255),

    # Cyan chest sigil
    '*': (225, 255, 255, 255),
    'S': (45, 230, 222, 255),
    's': (22, 160, 165, 255),
    'q': (14, 95, 100, 255),

    # Belt and buckle
    'b': (24, 22, 30, 255),
    'B': (46, 42, 54, 255),
    'm': (155, 148, 128, 255),
    'M': (205, 196, 170, 255),

    # Gloves
    'g': (22, 20, 28, 255),
    'G': (44, 40, 52, 255),
    'H': (72, 66, 84, 255),

    # Pants
    'p': (26, 24, 32, 255),
    'P': (40, 36, 48, 255),

    # Boots
    't': (16, 14, 20, 255),
    'T': (36, 32, 44, 255),
    'U': (60, 54, 72, 255),
    'u': (88, 80, 102, 255),
}

# Shadow counterpart palette:
# black/charcoal outer clothes, ivory face, red eyes and red chest gem.
SHADOW_PALETTE = PALETTE.copy()
SHADOW_PALETTE.update({
    # Hood and cloak: near-black charcoal with enough shade variation to read clearly
    '#': (8, 8, 12, 255),
    '|': (22, 20, 28, 255),
    '6': (52, 50, 60, 255),
    '5': (44, 42, 52, 255),
    '4': (36, 34, 44, 255),
    '3': (29, 27, 37, 255),
    '2': (23, 21, 31, 255),
    '1': (16, 15, 23, 255),
    '0': (11, 10, 17, 255),

    # Face opening becomes ivory/white
    'k': (244, 241, 230, 255),
    'j': (220, 216, 205, 255),

    # Eyes become red, with bright highlights
    'C': (255, 235, 235, 255),
    'c': (255, 55, 65, 255),
    'e': (145, 10, 24, 255),

    # Chest gem becomes crimson/red
    '*': (255, 238, 238, 255),
    'S': (255, 44, 58, 255),
    's': (195, 16, 32, 255),
    'q': (88, 5, 16, 255),

    # Keep belt, gloves, pants and boots very dark
    'b': (12, 11, 17, 255),
    'B': (25, 23, 32, 255),
    'm': (74, 30, 35, 255),
    'M': (120, 35, 42, 255),
    'g': (8, 7, 12, 255),
    'G': (19, 17, 25, 255),
    'H': (32, 29, 39, 255),
    'p': (10, 9, 15, 255),
    'P': (18, 16, 24, 255),
    't': (6, 6, 9, 255),
    'T': (14, 13, 20, 255),
    'U': (24, 22, 31, 255),
    'u': (35, 32, 43, 255),
})

# 32 columns wide x 48 rows tall
# Character: The Wanderer
GRID = [
    "................................", # 00
    "................................", # 01
    "...............##...............", # 02
    "..............#55#..............", # 03
    ".............#6554#.............", # 04
    "............#655543#............", # 05
    "...........#65555432#...........", # 06
    "..........#6555554321#..........", # 07
    ".........#655555544321#.........", # 08
    "........#65555555443210#........", # 09
    ".......#6555555554432100#.......", # 10
    "......#6555########432100#......", # 11
    ".....#6555#kkkkkkkk#432100#.....", # 12
    ".....#655#kkkkkkkkkk#32100#.....", # 13
    "....#655#kkkkkkkkkkkk#32100#....", # 14
    "....#655#kkCckkkkkkCck#3210#....", # 15
    "....#655#kkeckkkkkkeck#3210#....", # 16
    "....#654#kkkkkkkkkkkk#21000#....", # 17
    ".....#54#kkkkkkkkkkkk#1000#.....", # 18
    ".....#544#kkkkkkkkkk#0000#......", # 19
    "......#443##########0000#.......", # 20
    "....##4445555555544332210##.....", # 21
    "...#55555555555555443322110#....", # 22
    '..#6555555555555554433221100#...', # 23
    '..#655544444#qq#444333221100#...', # 24
    '..#55444444#qSSq#44433221100#...', # 25
    '..#5434444#qS**Sq#4443221100#...', # 26
    '..#5434444#qS**Sq#4443221100#...', # 27
    '..#43244444#qSSq#44443221100#...', # 28
    '...#432#12344#qq#44321#1100#....', # 29
    '...#gG#1123444444443211#0Gg#....', # 30
    '...#gH#bBBBBBBBBBBBBBBb#GHg#....', # 31
    '....#g#bBBBBBmMMmBBBBBb#Gg#.....', # 32
    '.....##123444444444443210##.....', # 33
    '......#123444444444443210#......', # 34
    '.....#01234444444444443210#.....', # 35
    '.....#01234444444444443210#.....', # 36
    '....#0123444444444444443210#....', # 37
    '....#0123444444444444443210#....', # 38
    '...#012344444444444444443210#...', # 39
    '...#012344444444444444443210#...', # 40
    '....#0123444#012210#4443210#....', # 41
    '.....####33#..#pp#..#33####.....', # 42
    '.........#uTt#....#tTu#.........', # 43
    '........#tUTTt#..#tTTUt#........', # 44
    '........#tUUTTt##tTTUUt#........', # 45
    '........#tttttt##tttttt#........', # 46
    '................................'  # 47
]


def validate_grid() -> None:
    """Validate the pixel map once before generating either sprite."""
    assert len(GRID) == 48, f"Expected 48 rows, got {len(GRID)}"
    for idx, row in enumerate(GRID):
        assert len(row) == 32, (
            f"Row {idx} has length {len(row)}, expected 32: {row!r}"
        )
        for ch in row:
            assert ch in PALETTE, f"Unknown character {ch!r} at row {idx}"
            assert ch in SHADOW_PALETTE, (
                f"Shadow palette is missing character {ch!r} at row {idx}"
            )


def render_sprite(palette: dict, filename: str) -> str:
    """Render GRID with the supplied palette and save a transparent PNG."""
    img = Image.new("RGBA", (32, 48), (0, 0, 0, 0))
    for y, row in enumerate(GRID):
        for x, ch in enumerate(row):
            img.putpixel((x, y), palette[ch])

    out_dir = os.path.dirname(os.path.abspath(__file__))
    out_path = os.path.join(out_dir, filename)
    img.save(out_path, "PNG")
    print(f"Successfully generated {out_path} ({img.width}x{img.height})")
    return out_path


def generate() -> str:
    """Generate the original white Wanderer sprite."""
    return render_sprite(PALETTE, "wanderer.png")


def generate_shadow() -> str:
    """Generate the dark counterpart with a pale face and red details."""
    return render_sprite(SHADOW_PALETTE, "shadow.png")


if __name__ == "__main__":
    validate_grid()
    generate()
    generate_shadow()
