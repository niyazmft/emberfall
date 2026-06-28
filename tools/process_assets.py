import os
import glob
import math
from PIL import Image, ImageEnhance, ImageDraw

BRAIN_DIR = "/Users/niyaz/.gemini/antigravity-cli/brain/b97e40a6-50ba-48f4-972b-fb045cb11188"
REPO_DIR = "/Volumes/external-hd/workspace/emberfall"

def get_latest_artifact(prefix):
    files = glob.glob(os.path.join(BRAIN_DIR, f"*{prefix}*.jpg")) + glob.glob(os.path.join(BRAIN_DIR, f"*{prefix}*.png"))
    if not files:
        print(f"Warning: No artifact found for {prefix}")
        return None
    # Sort by modified time to get the latest
    files.sort(key=os.path.getmtime, reverse=True)
    return files[0]

def remove_green_bg(img):
    img = img.convert("RGBA")
    datas = img.getdata()
    new_data = []
    for item in datas:
        # Chroma key green detection: high green, lower red/blue
        if item[1] > 150 and item[0] < 120 and item[2] < 120:
            new_data.append((255, 255, 255, 0))
        else:
            new_data.append(item)
    img.putdata(new_data)
    return img

def remove_black_bg(img):
    img = img.convert("RGBA")
    datas = img.getdata()
    new_data = []
    for item in datas:
        # Pure black detection
        if item[0] < 30 and item[1] < 30 and item[2] < 30:
            new_data.append((255, 255, 255, 0))
        else:
            new_data.append(item)
    img.putdata(new_data)
    return img

def remove_checkerboard_bg(img):
    img = img.convert("RGBA")
    width, height = img.size
    
    # Check if perimeter is already transparent (e.g. from remove_green_bg)
    if img.getpixel((0,0))[3] == 0:
        return img # Already processed
        
    perimeter_pixels = []
    for x in range(width):
        perimeter_pixels.append(img.getpixel((x, 0))[:3])
        perimeter_pixels.append(img.getpixel((x, height-1))[:3])
    for y in range(height):
        perimeter_pixels.append(img.getpixel((0, y))[:3])
        perimeter_pixels.append(img.getpixel((width-1, y))[:3])
        
    r_vals = sorted([p[0] for p in perimeter_pixels])
    g_vals = sorted([p[1] for p in perimeter_pixels])
    b_vals = sorted([p[2] for p in perimeter_pixels])
    
    # Take 5th and 95th percentile to filter out any outliers
    p5 = int(len(r_vals) * 0.05)
    p95 = int(len(r_vals) * 0.95)
    
    min_r, max_r = r_vals[p5] - 20, r_vals[p95] + 20
    min_g, max_g = g_vals[p5] - 20, g_vals[p95] + 20
    min_b, max_b = b_vals[p5] - 20, b_vals[p95] + 20
    
    # Iterative flood fill
    visited = [[False for _ in range(height)] for _ in range(width)]
    stack = []
    
    for x in range(width):
        stack.append((x, 0))
        stack.append((x, height-1))
        visited[x][0] = True
        visited[x][height-1] = True
    for y in range(height):
        stack.append((0, y))
        stack.append((width-1, y))
        visited[0][y] = True
        visited[width-1][y] = True
        
    pixels = img.load()
    
    while stack:
        cx, cy = stack.pop()
        r, g, b, a = pixels[cx, cy]
        if a == 0:
            continue
        if min_r <= r <= max_r and min_g <= g <= max_g and min_b <= b <= max_b:
            pixels[cx, cy] = (255, 255, 255, 0)
            for nx, ny in ((cx-1, cy), (cx+1, cy), (cx, cy-1), (cx, cy+1)):
                if 0 <= nx < width and 0 <= ny < height and not visited[nx][ny]:
                    visited[nx][ny] = True
                    stack.append((nx, ny))
                    
    return img

def generate_radial_shadow(width, height):
    img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    cx, cy = width / 2.0, height / 2.0
    rx, ry = width / 2.0, height / 2.0
    for x in range(width):
        for y in range(height):
            dx = (x - cx) / rx
            dy = (y - cy) / ry
            dist = math.sqrt(dx*dx + dy*dy)
            if dist <= 1.0:
                # 70% black (178 alpha) at center fading to 0
                alpha = int(178 * (1.0 - dist))
                img.putpixel((x, y), (0, 0, 0, alpha))
    return img

def create_ui_states(img, base_save_path, icon_name):
    # Normal state
    normal_path = os.path.join(base_save_path, f"{icon_name}_normal.png")
    img.save(normal_path, "PNG")
    print(f"Saved {normal_path}")

    # Hover state (enhanced brightness)
    enhancer = ImageEnhance.Brightness(img)
    hover_img = enhancer.enhance(1.4)
    hover_path = os.path.join(base_save_path, f"{icon_name}_hover.png")
    hover_img.save(hover_path, "PNG")
    print(f"Saved {hover_path}")

    # Disabled state (desaturated & dimmed)
    # Convert to grayscale then back to RGBA to keep alpha
    gray = img.convert("LA").convert("RGBA")
    enhancer_dim = ImageEnhance.Brightness(gray)
    disabled_img = enhancer_dim.enhance(0.6)
    disabled_path = os.path.join(base_save_path, f"{icon_name}_disabled.png")
    disabled_img.save(disabled_path, "PNG")
    print(f"Saved {disabled_path}")

def main():
    os.makedirs(os.path.join(REPO_DIR, "assets", "sprites"), exist_ok=True)
    os.makedirs(os.path.join(REPO_DIR, "assets", "sprites", "props"), exist_ok=True)
    os.makedirs(os.path.join(REPO_DIR, "assets", "icons"), exist_ok=True)

    # 1. Character Sprites (256x256)
    chars_256 = ["keeper_sprite", "grunt_sprite", "archer_sprite", "tank_sprite", "mage_sprite"]
    for c in chars_256:
        f = get_latest_artifact(c)
        if f:
            im = Image.open(f)
            im = remove_green_bg(im)
            im = remove_checkerboard_bg(im)
            im = im.resize((256, 256), Image.Resampling.LANCZOS)
            p = os.path.join(REPO_DIR, "assets", "sprites", f"{c}.png")
            im.save(p, "PNG")
            print(f"Saved {p}")

    # Bosses (320x320)
    bosses_320 = ["overgrown_guardian_sprite", "crystal_sentinel_sprite", "industrial_overseer_sprite", "boss_sprite"]
    for b in bosses_320:
        f = get_latest_artifact(b)
        if f:
            im = Image.open(f)
            im = remove_green_bg(im)
            im = remove_checkerboard_bg(im)
            im = im.resize((320, 320), Image.Resampling.LANCZOS)
            p = os.path.join(REPO_DIR, "assets", "sprites", f"{b}.png")
            im.save(p, "PNG")
            print(f"Saved {p}")

    # 2. UI Icons & 3. Ability Icons (64x64, 3 states)
    # Map prefix to icon_name
    icons = {
        "icon_move_normal": "icon_move",
        "icon_attack_normal": "icon_attack",
        "icon_end_normal": "icon_end_turn",
        "icon_empty_normal": "icon_empty_slot",
        "icon_strike_normal": "icon_strike",
        "icon_ember_normal": "icon_ember",
        "icon_dash_normal": "icon_quick_dash"
    }
    for prefix, name in icons.items():
        f = get_latest_artifact(prefix)
        if f:
            im = Image.open(f)
            im = remove_black_bg(im)
            im = im.resize((64, 64), Image.Resampling.LANCZOS)
            create_ui_states(im, os.path.join(REPO_DIR, "assets", "icons"), name)

    # 4. Environmental Props (128x128)
    props = ["prop_rock", "prop_crystal", "prop_debris", "prop_broken_pillar", "prop_scattered_bones", "prop_fallen_lantern", "prop_cracked_tile", "prop_burnt_wood"]
    for pr in props:
        f = get_latest_artifact(pr)
        if f:
            im = Image.open(f)
            im = remove_green_bg(im)
            im = remove_checkerboard_bg(im)
            im = im.resize((128, 128), Image.Resampling.LANCZOS)
            p = os.path.join(REPO_DIR, "assets", "sprites", "props", f"{pr}.png")
            im.save(p, "PNG")
            print(f"Saved {p}")

    # 5. Shadow Texture (64x32)
    shadow = generate_radial_shadow(64, 32)
    sp = os.path.join(REPO_DIR, "assets", "sprites", "soft_radial_shadow.png")
    shadow.save(sp, "PNG")
    print(f"Saved {sp}")

if __name__ == "__main__":
    main()
