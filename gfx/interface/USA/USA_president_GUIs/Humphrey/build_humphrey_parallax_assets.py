"""Build fixed Humphrey label sprites and the combined opinion-bar sheet.

The labels are copied from the shipped Aldrich 18 bitmap page so their glyph
shapes and hinting match the in-game font renderer exactly.
"""

from pathlib import Path
import re

from PIL import Image, ImageDraw


ASSET_DIR = Path(__file__).resolve().parent
REPO_ROOT = ASSET_DIR.parents[4]
FONT_DIR = REPO_ROOT / "gfx" / "fonts"

LABELS = {
    "independents": ("Independents", (255, 255, 255)),
    "southern_democrats": ("Southern Democrats", (220, 218, 80)),
    "centrist_democrats": ("Centrist Democrats", (89, 199, 194)),
    "liberal_democrats": ("Liberal Democrats", (35, 206, 255)),
    "union_democrats": ("Union Democrats", (255, 128, 114)),
}

GLYPH_RE = re.compile(
    r"^char id=(\d+)\s+x=(\d+)\s+y=(\d+)\s+width=(\d+)\s+"
    r"height=(\d+)\s+xoffset=(-?\d+)\s+yoffset=(-?\d+)\s+xadvance=(-?\d+)"
)


def read_glyphs(path: Path) -> dict[int, tuple[int, ...]]:
    glyphs: dict[int, tuple[int, ...]] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        match = GLYPH_RE.match(line)
        if match:
            values = tuple(int(value) for value in match.groups())
            glyphs[values[0]] = values[1:]
    return glyphs


def render_label(
    text: str,
    color: tuple[int, int, int],
    glyphs: dict[int, tuple[int, ...]],
    page: Image.Image,
) -> Image.Image:
    output = Image.new("RGBA", (175, 18), (0, 0, 0, 0))
    width = sum(glyphs[ord(character)][6] for character in text)
    pen_x = (175 - width) // 2

    page_pixels = page.load()
    output_pixels = output.load()
    for character in text:
        x, y, glyph_width, glyph_height, x_offset, y_offset, x_advance = glyphs[ord(character)]
        for glyph_y in range(glyph_height):
            for glyph_x in range(glyph_width):
                source = page_pixels[x + glyph_x, y + glyph_y]
                fill_coverage = max(source[0], source[1], source[2])
                outline_coverage = source[3]
                alpha = max(fill_coverage, outline_coverage)
                if alpha == 0:
                    continue

                target_x = pen_x + x_offset + glyph_x
                target_y = y_offset + glyph_y
                if not (0 <= target_x < output.width and 0 <= target_y < output.height):
                    continue

                # Store straight alpha while retaining the black one-pixel outline.
                fill_ratio = min(1.0, fill_coverage / alpha)
                rgb = tuple(round(channel * fill_ratio) for channel in color)
                output_pixels[target_x, target_y] = (*rgb, alpha)
        pen_x += x_advance
    return output


def main() -> None:
    glyphs = read_glyphs(FONT_DIR / "aldrich_18_outline.fnt")
    page = Image.open(FONT_DIR / "aldrich_18_outline.tga").convert("RGBA")

    for stem, (text, color) in LABELS.items():
        render_label(text, color, glyphs, page).save(ASSET_DIR / f"HHH_group_{stem}.png")

    full = Image.open(ASSET_DIR / "GFX_USA_HHH_progbar_sup_full.dds").convert("RGBA")
    empty = Image.open(ASSET_DIR / "GFX_USA_HHH_progbar_sup_empty.dds").convert("RGBA")
    if full.size != empty.size:
        raise ValueError("Humphrey opinion-bar textures must have identical dimensions")
    sheet = Image.new("RGBA", (full.width * 2, full.height), (0, 0, 0, 0))
    sheet.paste(full, (0, 0))
    sheet.paste(empty, (full.width, 0))
    sheet.save(ASSET_DIR / "GFX_USA_HHH_progbar_sup_sheet.png")

    # Build the fixed-width five-stop scrollbar as one ordinary sprite. This
    # avoids cornered-tile scaling artifacts and keeps its stops synchronized
    # with the 0/15/30/45/60 arrow positions.
    scrollbar_box = Image.open(ASSET_DIR / "GFX_USA_HHH_scrollbar_box.png").convert("RGBA")
    if scrollbar_box.size != (19, 18):
        raise ValueError("Humphrey scrollbar box must be 19x18 pixels")

    scrollbar_track = Image.new("RGBA", (445, 18), (0, 0, 0, 0))
    ImageDraw.Draw(scrollbar_track).rectangle((0, 8, 444, 9), fill=(89, 199, 194, 255))
    for box_x in (0, 107, 213, 320, 426):
        scrollbar_track.alpha_composite(scrollbar_box, (box_x, 0))
    scrollbar_track.save(ASSET_DIR / "GFX_USA_HHH_scrollbar_track.png")

    print("Built Humphrey labels, opinion-bar sheet, and five-stop scrollbar")


if __name__ == "__main__":
    main()
