#!/usr/bin/env python3
"""
Procedural 9-patch texture generator for Emberfall dark-fantasy UI.

Generates StyleBoxTexture-compatible PNGs from design tokens.
Each texture includes stretchable center + fixed borders/corners.
"""

from PIL import Image, ImageDraw, ImageFilter
import math
import os

OUTPUT_DIR = "assets/ui/9patch"

# Design Tokens (must match assets/main_theme.tres)
TOKENS = {
    "accent_gold": (0.9, 0.72, 0.18),
    "surface_dark": (0.10, 0.10, 0.15),
    "surface_mid": (0.18, 0.18, 0.24),
    "surface_hover": (0.26, 0.26, 0.34),
    "surface_pressed": (0.10, 0.10, 0.14),
    "border_dim": (0.08, 0.08, 0.12),
    "danger_red": (0.85, 0.20, 0.15),
    "focus_gold": (0.8, 0.6, 0.1),
}


def to_rgb(c: tuple, alpha: float = 1.0) -> tuple:
    return (int(c[0] * 255), int(c[1] * 255), int(c[2] * 255), int(alpha * 255))


def add_noise(img: Image.Image, intensity: int = 8) -> Image.Image:
    """Add subtle Perlin-like noise for texture richness."""
    w, h = img.size
    noise = Image.effect_noise((w, h), intensity).convert("RGBA")
    return Image.blend(img, noise, 0.03)


def draw_rounded_rect(
    draw: ImageDraw.ImageDraw,
    xy: tuple,
    radius: int,
    fill: tuple,
    outline: tuple | None = None,
    border_width: int = 0,
) -> None:
    """Draw a rounded rectangle with optional outline."""
    x0, y0, x1, y1 = xy
    draw.rounded_rectangle(xy, radius=radius, fill=fill)
    if outline and border_width > 0:
        for i in range(border_width):
            inset = i
            draw.rounded_rectangle(
                (x0 + inset, y0 + inset, x1 - inset, y1 - inset),
                radius=max(0, radius - inset),
                outline=outline,
                width=1,
            )


def generate_button_9patch(
    name: str,
    size: tuple[int, int],
    margin: int,
    bg_color: tuple,
    border_color: tuple,
    border_widths: tuple[int, int, int, int],
    radius: int,
    inner_glow: tuple | None = None,
) -> str:
    """
    Generate a 9-patch button texture.

    size: (width, height) of the texture
    margin: pixels from each edge that are fixed (corners + edges)
    bg_color: fill RGBA
    border_color: border RGBA
    border_widths: (left, top, right, bottom)
    radius: corner radius
    inner_glow: optional (color, intensity) for hover effect
    """
    w, h = size
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    left_b, top_b, right_b, bottom_b = border_widths

    # Draw background fill
    fill_pad = max(left_b, top_b, right_b, bottom_b, radius)
    draw.rounded_rectangle(
        (fill_pad, fill_pad, w - fill_pad, h - fill_pad),
        radius=max(0, radius - fill_pad),
        fill=bg_color,
    )

    # Fill entire area with rounded rect for seamless corners
    draw.rounded_rectangle((0, 0, w - 1, h - 1), radius=radius, fill=bg_color)

    # Draw borders
    if border_color[3] > 0:
        # Top border
        if top_b > 0:
            draw.rectangle((radius, 0, w - radius, top_b - 1), fill=border_color)
            # Corner fills for top-left and top-right
            draw.pieslice((0, 0, radius * 2, radius * 2), 180, 270, fill=border_color)
            draw.pieslice((w - radius * 2, 0, w, radius * 2), 270, 360, fill=border_color)
        # Bottom border
        if bottom_b > 0:
            draw.rectangle((radius, h - bottom_b, w - radius, h - 1), fill=border_color)
            draw.pieslice((0, h - radius * 2, radius * 2, h), 90, 180, fill=border_color)
            draw.pieslice((w - radius * 2, h - radius * 2, w, h), 0, 90, fill=border_color)
        # Left border
        if left_b > 0:
            draw.rectangle((0, radius, left_b - 1, h - radius), fill=border_color)
        # Right border
        if right_b > 0:
            draw.rectangle((w - right_b, radius, w - 1, h - radius), fill=border_color)

    # Inner glow (for hover state)
    if inner_glow:
        glow_color, glow_intensity = inner_glow
        glow_layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        g_draw = ImageDraw.Draw(glow_layer)
        g_draw.rounded_rectangle(
            (left_b, top_b, w - right_b, h - bottom_b),
            radius=max(0, radius - max(left_b, top_b)),
            fill=glow_color,
        )
        glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(radius=2))
        img = Image.alpha_composite(img, glow_layer)

    # Subtle noise for texture
    img = add_noise(img, intensity=6)

    # Save
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    path = os.path.join(OUTPUT_DIR, f"{name}.png")
    img.save(path)
    print(f"Generated: {path} ({w}x{h}, margin={margin})")
    return path


def generate_panel_9patch(
    name: str,
    size: tuple[int, int],
    margin: int,
    bg_color: tuple,
    border_color: tuple,
    border_width: int,
    radius: int,
) -> str:
    """Generate a 9-patch panel/modal texture."""
    w, h = size
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Background with rounded corners
    draw.rounded_rectangle((0, 0, w - 1, h - 1), radius=radius, fill=bg_color)

    # Border
    if border_width > 0 and border_color[3] > 0:
        for i in range(border_width):
            draw.rounded_rectangle(
                (i, i, w - 1 - i, h - 1 - i),
                radius=max(0, radius - i),
                outline=border_color,
                width=1,
            )

    # Subtle vignette for depth
    vignette = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    v_draw = ImageDraw.Draw(vignette)
    v_draw.rounded_rectangle((0, 0, w - 1, h - 1), radius=radius, fill=(0, 0, 0, 30))
    vignette = vignette.filter(ImageFilter.GaussianBlur(radius=radius))
    img = Image.alpha_composite(img, vignette)

    # Noise
    img = add_noise(img, intensity=4)

    os.makedirs(OUTPUT_DIR, exist_ok=True)
    path = os.path.join(OUTPUT_DIR, f"{name}.png")
    img.save(path)
    print(f"Generated: {path} ({w}x{h}, margin={margin})")
    return path


def main() -> None:
    print("=== Emberfall 9-Patch Texture Generator ===\n")

    # --- Buttons ---
    generate_button_9patch(
        "button_normal",
        size=(48, 32),
        margin=8,
        bg_color=to_rgb(TOKENS["surface_mid"], 0.9),
        border_color=to_rgb(TOKENS["border_dim"], 1.0),
        border_widths=(2, 2, 2, 4),
        radius=6,
    )

    generate_button_9patch(
        "button_hover",
        size=(48, 32),
        margin=8,
        bg_color=to_rgb(TOKENS["surface_hover"], 1.0),
        border_color=to_rgb(TOKENS["accent_gold"], 1.0),
        border_widths=(2, 2, 2, 4),
        radius=6,
        inner_glow=(to_rgb(TOKENS["accent_gold"], 40), 1.0),
    )

    generate_button_9patch(
        "button_pressed",
        size=(48, 32),
        margin=8,
        bg_color=to_rgb(TOKENS["surface_pressed"], 1.0),
        border_color=to_rgb(TOKENS["border_dim"], 1.0),
        border_widths=(2, 2, 2, 2),
        radius=6,
    )

    generate_button_9patch(
        "button_focus",
        size=(48, 32),
        margin=8,
        bg_color=to_rgb(TOKENS["focus_gold"], 0.25),
        border_color=(0, 0, 0, 0),
        border_widths=(0, 0, 0, 0),
        radius=7,
        inner_glow=(to_rgb(TOKENS["focus_gold"], 60), 1.0),
    )

    # --- Danger Buttons ---
    generate_button_9patch(
        "button_danger_normal",
        size=(48, 32),
        margin=8,
        bg_color=to_rgb(TOKENS["surface_mid"], 0.9),
        border_color=to_rgb(TOKENS["danger_red"], 1.0),
        border_widths=(2, 2, 2, 4),
        radius=6,
    )

    generate_button_9patch(
        "button_danger_hover",
        size=(48, 32),
        margin=8,
        bg_color=to_rgb(TOKENS["danger_red"], 0.3),
        border_color=to_rgb(TOKENS["danger_red"], 1.0),
        border_widths=(2, 2, 2, 4),
        radius=6,
        inner_glow=(to_rgb(TOKENS["danger_red"], 50), 1.0),
    )

    generate_button_9patch(
        "button_danger_pressed",
        size=(48, 32),
        margin=8,
        bg_color=to_rgb((0.5, 0.1, 0.1), 1.0),
        border_color=to_rgb(TOKENS["danger_red"], 1.0),
        border_widths=(2, 2, 2, 2),
        radius=6,
    )

    # --- Panels ---
    generate_panel_9patch(
        "panel_modal",
        size=(48, 48),
        margin=12,
        bg_color=to_rgb(TOKENS["surface_dark"], 0.98),
        border_color=to_rgb(TOKENS["accent_gold"], 1.0),
        border_width=2,
        radius=8,
    )

    generate_panel_9patch(
        "panel_tab_selected",
        size=(48, 24),
        margin=8,
        bg_color=to_rgb(TOKENS["surface_mid"], 0.95),
        border_color=to_rgb(TOKENS["accent_gold"], 1.0),
        border_width=0,
        radius=6,
    )

    generate_panel_9patch(
        "panel_tab_unselected",
        size=(48, 24),
        margin=8,
        bg_color=to_rgb(TOKENS["surface_dark"], 0.7),
        border_color=(0, 0, 0, 0),
        border_width=0,
        radius=6,
    )

    print("\n=== Done ===")
    print(f"Output: {OUTPUT_DIR}/")
    print("Add these as StyleBoxTexture in your Theme with patch_margin=8 (buttons) or 12 (panels).")


if __name__ == "__main__":
    main()
