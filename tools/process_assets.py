import os
from PIL import Image, ImageEnhance, ImageDraw

BRAIN_DIR = "/Users/niyaz/.gemini/antigravity-cli/brain/b97e40a6-50ba-48f4-972b-fb045cb11188"
ASSETS_DIR = "/Volumes/external-hd/workspace/emberfall/assets"
SPRITES_DIR = os.path.join(ASSETS_DIR, "sprites")
PROPS_DIR = os.path.join(SPRITES_DIR, "props")
ICONS_DIR = os.path.join(ASSETS_DIR, "icons")

os.makedirs(SPRITES_DIR, exist_ok=True)
os.makedirs(PROPS_DIR, exist_ok=True)
os.makedirs(ICONS_DIR, exist_ok=True)

# 1. Process Entity Sprites
entity_map = {
    "keeper_sprite.png": ("keeper_isometric_sprite_1782503587192.jpg", (256, 256)),
    "grunt_sprite.png": ("grunt_isometric_sprite_1782503595608.jpg", (256, 256)),
    "archer_sprite.png": ("archer_isometric_sprite_1782503603535.jpg", (256, 256)),
    "tank_sprite.png": ("tank_isometric_sprite_1782503612146.jpg", (256, 256)),
    "mage_sprite.png": ("mage_sprite_1782651387744.jpg", (256, 256)),
    "overgrown_guardian_sprite.png": ("overgrown_guardian_sprite_1782651395656.jpg", (320, 320)),
    "crystal_sentinel_sprite.png": ("crystal_sentinel_sprite_1782651404090.jpg", (320, 320)),
    "industrial_overseer_sprite.png": ("industrial_overseer_sprite_1782651414004.jpg", (320, 320)),
    "boss_sprite.png": ("boss_isometric_sprite_1782647027464.jpg", (320, 320)),
    "tileset_production.png": ("production_tileset_1782647036202.jpg", (512, 512)),
}

for out_name, (src_name, size) in entity_map.items():
    src_path = os.path.join(BRAIN_DIR, src_name)
    if os.path.exists(src_path):
        img = Image.open(src_path).convert("RGBA")
        img = img.resize(size, Image.Resampling.LANCZOS)
        img.save(os.path.join(SPRITES_DIR, out_name), "PNG")
        print(f"Saved sprite: {out_name}")

# 2. Process Environmental Props
prop_map = {
    "prop_rock.png": "prop_rock_1782651423546.jpg",
    "prop_crystal.png": "prop_crystal_1782651433526.jpg",
    "prop_debris.png": "prop_debris_1782651443248.jpg",
    "prop_broken_pillar.png": "prop_broken_pillar_1782651452182.jpg",
    "prop_scattered_bones.png": "prop_scattered_bones_1782651461936.jpg",
    "prop_fallen_lantern.png": "prop_fallen_lantern_1782651471418.jpg",
    "prop_cracked_tile.png": "prop_cracked_tile_1782651482577.jpg",
    "prop_burnt_wood.png": "prop_burnt_wood_1782651491180.jpg",
}

for out_name, src_name in prop_map.items():
    src_path = os.path.join(BRAIN_DIR, src_name)
    if os.path.exists(src_path):
        img = Image.open(src_path).convert("RGBA")
        img = img.resize((128, 128), Image.Resampling.LANCZOS)
        img.save(os.path.join(PROPS_DIR, out_name), "PNG")
        print(f"Saved prop: {out_name}")

# 3. Process UI Icons (Move & Bespoke Abilities)
icon_map = {
    "icon_move_normal.png": "icon_move_normal_1782651568348.jpg",
    "icon_move_hover.png": "icon_move_hover_1782651579133.jpg",
    "icon_move_disabled.png": "icon_move_disabled_1782651587597.jpg",
}

for out_name, src_name in icon_map.items():
    src_path = os.path.join(BRAIN_DIR, src_name)
    if os.path.exists(src_path):
        img = Image.open(src_path).convert("RGBA")
        img = img.resize((64, 64), Image.Resampling.LANCZOS)
        img.save(os.path.join(ICONS_DIR, out_name), "PNG")
        print(f"Saved icon: {out_name}")

# Bespoke abilities (generate 3 states each)
ability_map = {
    "icon_strike": "strike_ability_icon_1782502744133.jpg",
    "icon_ember": "ember_ability_icon_1782502753208.jpg",
    "icon_quick_dash": "quick_dash_icon_1782502763105.jpg",
}

for base_name, src_name in ability_map.items():
    src_path = os.path.join(BRAIN_DIR, src_name)
    if os.path.exists(src_path):
        img = Image.open(src_path).convert("RGBA").resize((64, 64), Image.Resampling.LANCZOS)
        # Normal
        img.save(os.path.join(ICONS_DIR, f"{base_name}_normal.png"), "PNG")
        # Hover
        hover = ImageEnhance.Brightness(img).enhance(1.3)
        hover.save(os.path.join(ICONS_DIR, f"{base_name}_hover.png"), "PNG")
        # Disabled
        disabled = img.convert("L").convert("RGBA")
        disabled = ImageEnhance.Brightness(disabled).enhance(0.6)
        disabled.save(os.path.join(ICONS_DIR, f"{base_name}_disabled.png"), "PNG")
        print(f"Saved ability icons for: {base_name}")

# 4. Generate Attack and End Turn Icons via PIL ImageDraw
def create_custom_icon(base_name, color, draw_func):
    # Normal
    img = Image.new("RGBA", (64, 64), (20, 20, 25, 255))
    draw = ImageDraw.Draw(img)
    draw.rectangle([2, 2, 61, 61], outline=color, width=2)
    draw_func(draw, color)
    img.save(os.path.join(ICONS_DIR, f"{base_name}_normal.png"), "PNG")
    
    # Hover
    hover = ImageEnhance.Brightness(img).enhance(1.4)
    hover.save(os.path.join(ICONS_DIR, f"{base_name}_hover.png"), "PNG")
    
    # Disabled
    disabled = img.convert("L").convert("RGBA")
    disabled = ImageEnhance.Brightness(disabled).enhance(0.6)
    disabled.save(os.path.join(ICONS_DIR, f"{base_name}_disabled.png"), "PNG")
    print(f"Saved custom icons for: {base_name}")

def draw_attack(draw, color):
    # Crossed swords / slash
    draw.line([16, 16, 48, 48], fill=color, width=6)
    draw.line([16, 48, 48, 16], fill=color, width=6)

def draw_end_turn(draw, color):
    # Hourglass / Flag
    draw.polygon([20, 15, 44, 15, 32, 32], fill=color)
    draw.polygon([20, 49, 44, 49, 32, 32], fill=color)

create_custom_icon("icon_attack", (220, 30, 50, 255), draw_attack)
create_custom_icon("icon_end_turn", (30, 180, 220, 255), draw_end_turn)

print("All assets processed successfully!")
