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
# NOTE: These are procedural placeholders. For production-quality icons matching
# the GenAI move/ability style, generate via the prompts in genai_prompts.md
# and replace these files.

def create_styled_icon(base_name, draw_func):
    """Create a dark-fantasy-styled procedural icon with panel background."""
    # Normal — dark panel with styled foreground
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Dark rounded panel background
    draw.rounded_rectangle(
        [4, 4, 60, 60], radius=8, fill=(25, 22, 30, 240), outline=(60, 55, 70, 200), width=2
    )
    draw_func(draw)
    img.save(os.path.join(ICONS_DIR, f"{base_name}_normal.png"), "PNG")

    # Hover — brighten panel + white rim glow
    hover = img.copy()
    hover_draw = ImageDraw.Draw(hover)
    hover_draw.rounded_rectangle(
        [4, 4, 60, 60], radius=8, outline=(255, 255, 255, 120), width=2
    )
    hover = ImageEnhance.Brightness(hover).enhance(1.3)
    hover.save(os.path.join(ICONS_DIR, f"{base_name}_hover.png"), "PNG")

    # Disabled — grayscale + dim
    disabled = img.convert("L").convert("RGBA")
    disabled = ImageEnhance.Brightness(disabled).enhance(0.6)
    disabled.save(os.path.join(ICONS_DIR, f"{base_name}_disabled.png"), "PNG")
    print(f"Saved styled icons for: {base_name}")


def draw_attack_icon(draw):
    # Stylized sword with ember-glow blade
    # Blade
    draw.polygon(
        [(18, 20), (32, 8), (46, 20), (40, 28), (32, 22), (24, 28)],
        fill=(220, 45, 55, 230),
        outline=(255, 80, 90, 255),
    )
    # Crossguard
    draw.rectangle([20, 28, 44, 32], fill=(180, 160, 120, 255), outline=(220, 200, 160, 255), width=1)
    # Hilt
    draw.rectangle([30, 32, 34, 48], fill=(140, 120, 90, 255), outline=(180, 160, 120, 255), width=1)
    # Pommel
    draw.ellipse([28, 48, 36, 52], fill=(180, 160, 120, 255), outline=(220, 200, 160, 255), width=1)
    # Glow line on blade
    draw.line([(26, 14), (32, 10), (38, 14)], fill=(255, 180, 160, 200), width=2)


def draw_end_turn_icon(draw):
    # Hourglass with ember falling sand
    # Top funnel
    draw.polygon(
        [(20, 14), (44, 14), (32, 28)],
        fill=(45, 170, 210, 200),
        outline=(80, 210, 240, 255),
        width=2,
    )
    # Neck
    draw.polygon(
        [(32, 28), (26, 38), (38, 38)],
        fill=(45, 170, 210, 200),
        outline=(80, 210, 240, 255),
        width=1,
    )
    # Bottom funnel
    draw.polygon(
        [(26, 38), (38, 38), (44, 50), (20, 50)],
        fill=(45, 170, 210, 200),
        outline=(80, 210, 240, 255),
        width=2,
    )
    # Ember particles falling
    draw.ellipse([30, 30, 34, 34], fill=(255, 180, 60, 220))
    draw.ellipse([31, 36, 33, 38], fill=(255, 200, 100, 180))
    # Frame bars
    draw.rectangle([18, 12, 46, 15], fill=(120, 130, 140, 255))
    draw.rectangle([18, 49, 46, 52], fill=(120, 130, 140, 255))


def draw_empty_slot_icon(draw):
    # Subtle dashed-frame for unused hotbar slots
    draw.rounded_rectangle([14, 14, 50, 50], radius=4, outline=(60, 55, 70, 120), width=1)
    # Small plus in center
    draw.rectangle([29, 22, 35, 42], fill=(60, 55, 70, 100))
    draw.rectangle([22, 29, 42, 35], fill=(60, 55, 70, 100))


create_styled_icon("icon_attack", draw_attack_icon)
create_styled_icon("icon_end_turn", draw_end_turn_icon)
create_styled_icon("icon_empty_slot", draw_empty_slot_icon)

print("All assets processed successfully!")
