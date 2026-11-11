

from pathlib import Path
import re

from PIL import Image, ImageDraw


HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
FONT_DIR = ROOT / "gfx" / "fonts"
ATLAS_PATH = HERE / "chisholm_check_runtime_atlas.png"
GROUP_NAMES = HERE / "chisholm_group_names.txt"


GLYPH_RE = re.compile(
    r"^char id=(\d+)\s+x=(\d+)\s+y=(\d+)\s+width=(\d+)\s+"
    r"height=(\d+)\s+xoffset=(-?\d+)\s+yoffset=(-?\d+)\s+xadvance=(-?\d+)"
)


def load_font(stem: str):
    metrics = {}
    for line in (FONT_DIR / f"{stem}.fnt").read_text(encoding="utf-8").splitlines():
        match = GLYPH_RE.match(line)
        if match:
            values = tuple(int(v) for v in match.groups())
            metrics[values[0]] = values[1:]
    return metrics, Image.open(FONT_DIR / f"{stem}.tga").convert("RGBA")


def coverage(pixel, include_outline=True):
    # BMFont's outline pages store fill coverage in RGB and the outline in A.
    return max(pixel) if include_outline else max(pixel[:3])


def draw_text(
    destination,
    metrics,
    page,
    text,
    origin,
    max_width=None,
    letter_spacing=0,
    include_outline=True,
):
    pen_x, origin_y = origin
    for character in text:
        glyph = metrics.get(ord(character))
        if glyph is None:
            raise ValueError(f"Aldrich atlas is missing {character!r}")
        x, y, width, height, x_offset, y_offset, x_advance = glyph
        for dy in range(height):
            for dx in range(width):
                alpha = coverage(page.getpixel((x + dx, y + dy)), include_outline)
                target = (pen_x + x_offset + dx, origin_y + y_offset + dy)
                if alpha and target[0] >= 0 and target[1] >= 0:
                    if target[0] < destination.width and target[1] < destination.height:
                        destination.putpixel(target, (255, 255, 255, alpha))
        pen_x += x_advance + letter_spacing
        if max_width is not None and pen_x - origin[0] >= max_width:
            break


def draw_digit_cell(
    destination,
    metrics,
    page,
    digit,
    cell_x,
    cell_y,
    cell_w,
    cell_h,
    center_by_advance=False,
):
    glyph = metrics.get(ord(str(digit)))
    if glyph is None:
        raise ValueError(f"Aldrich atlas is missing digit {digit}")
    x, y, width, height, x_offset, y_offset, x_advance = glyph
    # The large amount row's zero has a wider authored advance than its
    # visible bitmap.  Center that glyph from its advance to remove the one
    # pixel right offset, while leaving the other digits at their existing
    # authored positions.
    layout_width = x_advance if center_by_advance and digit == 0 else width
    start_x = cell_x + (cell_w - layout_width) // 2 + x_offset
    start_y = cell_y + y_offset
    for dy in range(height):
        for dx in range(width):
            alpha = coverage(page.getpixel((x + dx, y + dy)))
            target = (start_x + dx, start_y + dy)
            if (
                alpha
                and cell_x <= target[0] < cell_x + cell_w
                and cell_y <= target[1] < cell_y + cell_h
                and 0 <= target[0] < destination.width
                and 0 <= target[1] < destination.height
            ):
                destination.putpixel(target, (255, 255, 255, alpha))


def main():
    atlas = Image.open(ATLAS_PATH).convert("RGBA")
    if atlas.size != (3872, 158):
        raise ValueError(f"Expected the 11-cell 352x158 atlas, got {atlas.size}")
    draw = ImageDraw.Draw(atlas)

    
    group_metrics, group_page = load_font("aldrich_14_outline")
    digit_metrics, digit_page = load_font("aldrich_36_outline")
    due_metrics, due_page = load_font("aldrich_18_outline")

    # Frames 4/5 are the two four-row group-label pages.  The shader samples
    # these rows directly, so each glyph remains at its authored pixel size.
    for frame in (4, 5):
        draw.rectangle((frame * 352, 0, frame * 352 + 351, 157), fill=(0, 0, 0, 0))
    names = [line.strip() for line in GROUP_NAMES.read_text(encoding="utf-8").splitlines() if line.strip()]
    if len(names) != 8:
        raise ValueError(f"Expected eight Chisholm group names, found {len(names)}")
    for index, name in enumerate(names):
        frame = 4 + index // 4
        row = index % 4
        draw_text(
            atlas,
            group_metrics,
            group_page,
            name,
            (frame * 352 + 2, row * 30 + 12),
            letter_spacing=1,
            include_outline=False,
        )

    # Frame 6 contains native-size amount digits (20x32) and due/rate digits
    # (16x21) in a second row.  The shader selects the row for each field.
    draw.rectangle((6 * 352, 0, 6 * 352 + 351, 157), fill=(0, 0, 0, 0))
    for digit in range(10):
        draw_digit_cell(
            atlas,
            digit_metrics,
            digit_page,
            digit,
            6 * 352 + digit * 20,
            0,
            20,
            32,
            center_by_advance=True,
        )
        draw_digit_cell(atlas, due_metrics, due_page, digit, 6 * 352 + digit * 16, 48, 16, 21)

    # The compact row's eleventh cell supplies the fixed interest-rate suffix.
    draw_text(atlas, due_metrics, due_page, "%", (6 * 352 + 161, 46))

    atlas.save(ATLAS_PATH)
    print(f"Built native Aldrich atlas: {ATLAS_PATH}")


if __name__ == "__main__":
    main()
