from PIL import Image
import os

base = os.path.dirname(os.path.abspath(__file__))

patch = Image.new("RGBA", (32 * 6, 32 * 5), (0, 0, 0, 255))

# Row 0: Stone walls
wall = Image.open(os.path.join(base, "stone/stone_wall.png"))
for x in range(6):
    patch.paste(wall, (x * 32, 0))

# Row 1: Stone floor & Void
sf = Image.open(os.path.join(base, "stone/stone_floor_1.png"))
void_norm = Image.open(os.path.join(base, "void/void_normal.png"))
cyan = Image.open(os.path.join(base, "eclipse/cyan_path.png"))

patch.paste(sf, (0, 32))
patch.paste(sf, (32, 32))
patch.paste(void_norm, (64, 32))
patch.paste(cyan, (96, 32))
patch.paste(void_norm, (128, 32))
patch.paste(sf, (160, 32))

# Row 2: Grass and Dirt transition
g1 = Image.open(os.path.join(base, "grass/grass_1.png"))
g2 = Image.open(os.path.join(base, "grass/grass_2.png"))
trans = Image.open(os.path.join(base, "stone/grass_dirt_transition.png"))
d1 = Image.open(os.path.join(base, "dirt/dirt_1.png"))
d2 = Image.open(os.path.join(base, "dirt/dirt_2.png"))

patch.paste(g1, (0, 64))
patch.paste(g2, (32, 64))
patch.paste(trans, (64, 64))
patch.paste(d1, (96, 64))
patch.paste(d2, (128, 64))
patch.paste(g1, (160, 64))

# Row 3 & 4: Grass, Dirt, Props
g3 = Image.open(os.path.join(base, "grass/grass_3.png"))
for x in range(6):
    patch.paste(g3 if x % 2 == 0 else g1, (x * 32, 96))
    patch.paste(g1 if x % 2 == 0 else d1, (x * 32, 128))

# Tree overlay
tree = Image.open(os.path.join(base, "vegetation/tree.png"))
patch.paste(tree, (8, 64), tree)

# Mossy rock overlay
rock = Image.open(os.path.join(base, "props/rock_moss.png"))
patch.paste(rock, (130, 96), rock)

patch.save(os.path.join(base, "sample_patch.png"), "PNG")
print(f"Sample patch successfully generated at {os.path.join(base, 'sample_patch.png')} (192x160)")
