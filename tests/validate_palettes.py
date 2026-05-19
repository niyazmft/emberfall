import math
import os
import re
import sys

def srgb_to_linear(c):
    if c <= 0.04045:
        return c / 12.92
    else:
        return ((c + 0.055) / 1.055) ** 2.4

def rgb_to_xyz(r, g, b):
    # Linearize sRGB
    rl = srgb_to_linear(r)
    gl = srgb_to_linear(g)
    bl = srgb_to_linear(b)

    # Convert to XYZ using D65 illuminant
    x = rl * 0.4124564 + gl * 0.3575761 + bl * 0.1804375
    y = rl * 0.2126729 + gl * 0.7151522 + bl * 0.0721750
    z = rl * 0.0193339 + gl * 0.1191920 + bl * 0.9503041
    return x, y, z

def xyz_to_lab(x, y, z):
    # D65 white point
    xn, yn, zn = 0.95047, 1.0, 1.08883

    def f(t):
        if t > 0.008856:
            return t ** (1/3)
        else:
            return (7.787 * t) + (16 / 116)

    fx = f(x / xn)
    fy = f(y / yn)
    fz = f(z / zn)

    l = (116 * fy) - 16
    a = 500 * (fx - fy)
    b = 200 * (fy - fz)
    return l, a, b

def rgb_to_lab(r, g, b):
    x, y, z = rgb_to_xyz(r, g, b)
    return xyz_to_lab(x, y, z)

def linear_to_srgb(c):
    if c <= 0.0031308:
        return 12.92 * c
    else:
        return 1.055 * (max(0, c) ** (1 / 2.4)) - 0.055

def simulate_cvd(r, g, b, mode):
    # Linearize
    rl = srgb_to_linear(r)
    gl = srgb_to_linear(g)
    bl = srgb_to_linear(b)

    if mode == "protanopia":
        r_sim = 0.56667 * rl + 0.43333 * gl + 0 * bl
        g_sim = 0.55833 * rl + 0.44167 * gl + 0 * bl
        b_sim = 0 * rl + 0.24167 * gl + 0.75833 * bl
    elif mode == "deuteranopia":
        r_sim = 0.625 * rl + 0.375 * gl + 0 * bl
        g_sim = 0.7 * rl + 0.3 * gl + 0 * bl
        b_sim = 0 * rl + 0.3 * gl + 0.7 * bl
    elif mode == "tritanopia":
        r_sim = 0.95 * rl + 0.05 * gl + 0 * bl
        g_sim = 0 * rl + 0.43333 * gl + 0.56667 * bl
        b_sim = 0 * rl + 0.475 * gl + 0.525 * bl
    elif mode == "achromatopsia":
        v = 0.2126 * rl + 0.7152 * gl + 0.0722 * bl
        r_sim = g_sim = b_sim = v
    else:
        return r, g, b

    return (
        max(0, min(1, linear_to_srgb(r_sim))),
        max(0, min(1, linear_to_srgb(g_sim))),
        max(0, min(1, linear_to_srgb(b_sim)))
    )

def delta_e_cie76(lab1, lab2):
    return math.sqrt((lab1[0] - lab2[0])**2 + (lab1[1] - lab2[1])**2 + (lab1[2] - lab2[2])**2)

def is_red_green_pair(rgb1, rgb2):
    # Heuristic for red-green pairing
    # Red: high R, low G, low B
    # Green: low R, high G, low B
    def is_red(r, g, b):
        return r > 0.6 and g < 0.4 and b < 0.4
    def is_green(r, g, b):
        return g > 0.6 and r < 0.4 and b < 0.4

    if (is_red(*rgb1) and is_green(*rgb2)) or (is_red(*rgb2) and is_green(*rgb1)):
        return True
    return False

def parse_tres_colors(filepath):
    colors = []
    if not os.path.exists(filepath):
        return colors
    with open(filepath, 'r') as f:
        content = f.read()
        # Look for Color( r, g, b, a ) or similar in .tres
        # Godot 4 tres format for colors usually looks like Color(0.1, 0.2, 0.3, 1)
        matches = re.findall(r'Color\(\s*([\d\.]+),\s*([\d\.]+),\s*([\d\.]+),\s*([\d\.]+)\s*\)', content)
        for m in matches:
            colors.append((float(m[0]), float(m[1]), float(m[2])))
    return colors

def validate_palette(filepath):
    colors = parse_tres_colors(filepath)
    if not colors:
        print(f"No colors found in {filepath}")
        return True

    violations = []

    # Rule 1: Delta L* >= 30 between simultaneous accent slots
    # Assuming all colors in the tres are "simultaneous" for validation
    labs = [rgb_to_lab(*c) for c in colors]
    for i in range(len(labs)):
        for j in range(i + 1, len(labs)):
            dl = abs(labs[i][0] - labs[j][0])
            if dl < 30:
                violations.append(f"Delta L* too low ({dl:.2f} < 30) between color {i} and {j}")

    # Rule 2: No red-green pairings without secondary indicators
    # Lint only flags them.
    for i in range(len(colors)):
        for j in range(i + 1, len(colors)):
            if is_red_green_pair(colors[i], colors[j]):
                violations.append(f"Red-Green pairing detected between color {i} and {j}")

    # Rule 3: Dichromacy collision check
    cvd_modes = ["protanopia", "deuteranopia", "tritanopia", "achromatopsia"]
    for mode in cvd_modes:
        sim_colors = [simulate_cvd(*c, mode) for c in colors]
        sim_labs = [rgb_to_lab(*c) for c in sim_colors]
        for i in range(len(sim_labs)):
            for j in range(i + 1, len(sim_labs)):
                de = delta_e_cie76(sim_labs[i], sim_labs[j])
                # Delta E < 10 is often considered very similar, especially for CVD
                if de < 10:
                    violations.append(f"CVD Collision ({mode}, Delta E={de:.2f} < 10) between color {i} and {j}")

    if violations:
        print(f"Violations in {filepath}:")
        for v in violations:
            print(f"  - {v}")
        return False
    return True

def main():
    palette_dir = "palettes/accent"
    if not os.path.exists(palette_dir):
        print(f"Directory {palette_dir} not found. Skipping.")
        return 0

    all_pass = True
    for filename in os.listdir(palette_dir):
        if filename.endswith(".tres"):
            filepath = os.path.join(palette_dir, filename)
            if not validate_palette(filepath):
                all_pass = False

    if not all_pass:
        return 1
    print("All palettes passed validation.")
    return 0

if __name__ == "__main__":
    sys.exit(main())
