"""
Simple Tkinter helper to batch-generate Congo Crisis Zeitgeist color variants.

Workflow:
1) Pick a source .dds image.
2) Tell the tool which color the source currently uses (from the predefined set).
3) Provide a name format with placeholders to control output filenames.
4) Click Convert to emit one file per color (including the source color) using the
   chosen name format.

Placeholders available in the name format:
  {base}        -> stem of the source filename (no extension)
  {color_name}  -> display name, e.g., "Bitter Orange"
  {color_slug}  -> lowercase/underscore slug, e.g., "bitter_orange"
  {color_key}   -> single-character key, e.g., "u"

Outputs are written next to the source image by default.
"""

from __future__ import annotations

import os
import re
import tkinter as tk
from tkinter.scrolledtext import ScrolledText
from pathlib import Path
from tkinter import filedialog, messagebox

try:
    from PIL import Image
except ImportError:  # pragma: no cover - Pillow is expected to be available in this environment
    raise SystemExit("Pillow is required: pip install pillow")


COLORS = {
    "u": "Bitter Orange",
    ",": "Brown Green",
    "*": "Cyan",
    "&": "Dark Olive",
    "I": "Deep Purple",
    "h": "Jazzberry Jam",
    "l": "Lavender",
    "U": "Peru",
    "Z": "Reddish Brown",
    "a": "Royal Blue",
}

# Placeholder RGB values; adjust to match your palette if needed.
COLOR_RGB = {
    # Pulled from interface/TNO_fonts.gfx, font: aldrich_24_outline (non-Bombardier)
    "u": (210, 119, 39),   # Bitter Orange
    ",": (135, 120, 74),   # Brown-Green
    "*": (0, 155, 178),    # Cyan
    "&": (89, 132, 97),    # Dark Olive
    "I": (116, 71, 209),   # Deep Purple
    "h": (161, 16, 107),   # Jazzberry Jam
    "l": (147, 112, 219),  # Lavender
    "U": (214, 138, 75),   # Peru
    "Z": (128, 48, 56),    # Reddish-Brown
    "a": (60, 114, 240),   # Royal Blue
}

# Alternate names for special-key characters, useful for filenames.
COLOR_KEY_NAME = {
    "&": "amp",
    "*": "asterisk",
    ",": "comma",
}


def slugify(name: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", name.lower()).strip("_")


def clamp_channel(v: int) -> int:
    return max(0, min(255, v))


def srgb_to_linear(c: int) -> float:
    c_f = c / 255.0
    if c_f <= 0.04045:
        return c_f / 12.92
    return ((c_f + 0.055) / 1.055) ** 2.4


def linear_to_srgb(v: float) -> int:
    if v <= 0.0031308:
        v = v * 12.92
    else:
        v = 1.055 * (v ** (1 / 2.4)) - 0.055
    return clamp_channel(round(v * 255))


def replace_color(img: Image.Image, src_rgb: tuple[int, int, int], dst_rgb: tuple[int, int, int]) -> Image.Image:
    """Return a copy of img with exact src_rgb replaced by dst_rgb (alpha preserved)."""
    if img.mode not in {"RGB", "RGBA"}:
        img = img.convert("RGBA")
    else:
        img = img.copy()

    pixels = img.load()
    width, height = img.size
    for y in range(height):
        for x in range(width):
            px = pixels[x, y]
            rgb = px[:3] if len(px) == 4 else px
            if rgb == src_rgb:
                if len(px) == 4:
                    pixels[x, y] = (dst_rgb[0], dst_rgb[1], dst_rgb[2], px[3])
                else:
                    pixels[x, y] = dst_rgb
    return img


def contains_color(img: Image.Image, target_rgb: tuple[int, int, int]) -> bool:
    """Check if any pixel matches target_rgb (ignoring alpha)."""
    if img.mode not in {"RGB", "RGBA"}:
        img = img.convert("RGBA")
    data = img.getdata()
    for px in data:
        rgb = px[:3] if isinstance(px, tuple) and len(px) >= 3 else px
        if rgb == target_rgb:
            return True
    return False


def estimate_background_mode(img: Image.Image, target_rgb: tuple[int, int, int]) -> tuple[int, int, int] | None:
    """Return the most common neighbor color around target_rgb pixels (4-neighborhood)."""
    if img.mode not in {"RGB", "RGBA"}:
        img = img.convert("RGBA")
    pixels = img.load()
    w, h = img.size
    counts: dict[tuple[int, int, int], int] = {}
    dirs = [(1, 0), (-1, 0), (0, 1), (0, -1)]
    for y in range(h):
        for x in range(w):
            px = pixels[x, y]
            rgb = px[:3] if len(px) == 4 else px
            if rgb != target_rgb:
                continue
            for dx, dy in dirs:
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h:
                    npx = pixels[nx, ny]
                    nrgb = npx[:3] if len(npx) == 4 else npx
                    if nrgb == target_rgb:
                        continue
                    counts[nrgb] = counts.get(nrgb, 0) + 1
    if not counts:
        return None
    return max(counts.items(), key=lambda kv: kv[1])[0]


def replace_with_estimated_alpha(
    img: Image.Image, src_rgb: tuple[int, int, int], dst_rgb: tuple[int, int, int], bg_rgb: tuple[int, int, int]
) -> Image.Image:
    """Replace src_rgb with dst_rgb by estimating per-pixel alpha against bg_rgb."""
    if img.mode not in {"RGB", "RGBA"}:
        img = img.convert("RGBA")
    else:
        img = img.copy()

    bg_lin = tuple(srgb_to_linear(c) for c in bg_rgb)
    src_lin = tuple(srgb_to_linear(c) for c in src_rgb)
    dst_lin = tuple(srgb_to_linear(c) for c in dst_rgb)

    pixels = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            px = pixels[x, y]
            rgb = px[:3] if len(px) == 4 else px
            if rgb != src_rgb:
                continue
            mix_lin = tuple(srgb_to_linear(c) for c in rgb)
            alphas = []
            for m, b, s in zip(mix_lin, bg_lin, src_lin):
                denom = s - b
                if abs(denom) < 1e-6:
                    continue
                alphas.append((m - b) / denom)
            alpha = max(0.0, min(1.0, sorted(alphas)[len(alphas) // 2])) if alphas else 1.0
            new_lin = tuple(alpha * d + (1 - alpha) * b for d, b in zip(dst_lin, bg_lin))
            new_rgb = tuple(linear_to_srgb(v) for v in new_lin)
            if len(px) == 4:
                pixels[x, y] = (new_rgb[0], new_rgb[1], new_rgb[2], px[3])
            else:
                pixels[x, y] = new_rgb
    return img


def parse_hex_color(token: str) -> tuple[int, int, int] | None:
    token = token.strip().lstrip("#")
    if len(token) != 6 or not all(c in "0123456789aAbBcCdDeEfF" for c in token):
        return None
    return tuple(int(token[i : i + 2], 16) for i in (0, 2, 4))


class ColorBatchUI:
    def __init__(self, root: tk.Tk) -> None:
        self.root = root
        self.root.title("Zeitgeist Color Batch")
        self.root.resizable(False, False)
        self.src_path_var = tk.StringVar()
        # Default uses the filename-safe key name (amp/asterisk/comma instead of symbols).
        self.name_fmt_var = tk.StringVar(value="{base}_{color_slug}_{color_key_name}.dds")
        self.output_dir_var = tk.StringVar()

        keys = sorted(COLORS.keys())
        self.src_color_var = tk.StringVar(value=keys[0])

        pad = {"padx": 8, "pady": 4}

        tk.Label(root, text="Source .dds").grid(row=0, column=0, sticky="w", **pad)
        tk.Entry(root, textvariable=self.src_path_var, width=48).grid(row=0, column=1, columnspan=2, sticky="we", **pad)
        tk.Button(root, text="Browse…", command=self.choose_source).grid(row=0, column=3, sticky="e", **pad)

        tk.Label(root, text="Source color").grid(row=1, column=0, sticky="w", **pad)

        # Build dropdown showing key + name; selection stores the key.
        color_menu = tk.OptionMenu(root, self.src_color_var, *keys)
        # Replace menu entries with custom labels.
        color_menu["menu"].delete(0, "end")
        for k in keys:
            label = f"{k} — {COLORS[k]}"
            color_menu["menu"].add_command(
                label=label,
                command=lambda key=k: (self.src_color_var.set(key), self.update_swatch()),
            )
        color_menu.grid(row=1, column=1, sticky="w", **pad)

        # Swatch showing the currently selected color.
        self.swatch = tk.Label(root, text="   ", relief="groove", width=4)
        self.swatch.grid(row=1, column=2, sticky="w", **pad)
        self.update_swatch()
        tk.Label(root, text="Format").grid(row=2, column=0, sticky="w", **pad)
        tk.Entry(root, textvariable=self.name_fmt_var, width=48).grid(row=2, column=1, columnspan=2, sticky="we", **pad)

        tk.Label(
            root,
            text="Placeholders: {base} {color_name} {color_slug} {color_key} {color_key_name}",
        ).grid(row=3, column=0, columnspan=4, sticky="w", **pad)

        tk.Label(root, text="Output folder").grid(row=4, column=0, sticky="w", **pad)
        tk.Entry(root, textvariable=self.output_dir_var, width=48).grid(row=4, column=1, columnspan=2, sticky="we", **pad)
        tk.Button(root, text="Use source dir", command=self.use_source_dir).grid(row=4, column=3, sticky="e", **pad)

        tk.Label(root, text="Secondary colors (hex, one per line)").grid(row=5, column=0, sticky="nw", **pad)
        self.secondary_text = ScrolledText(root, width=40, height=4)
        self.secondary_text.grid(row=5, column=1, columnspan=3, sticky="we", **pad)

        self.alpha_estimate_var = tk.BooleanVar(value=False)
        tk.Checkbutton(
            root, text="Estimate background/alpha for replacements", variable=self.alpha_estimate_var
        ).grid(row=6, column=0, columnspan=3, sticky="w", **pad)

        tk.Button(root, text="Convert", command=self.convert_all, width=20).grid(row=7, column=0, columnspan=4, pady=10)

        self.status_var = tk.StringVar(value="Select a source image to begin.")
        tk.Label(root, textvariable=self.status_var, fg="gray").grid(row=8, column=0, columnspan=4, sticky="w", **pad)

        root.grid_columnconfigure(1, weight=1)
        root.grid_columnconfigure(2, weight=1)

    def update_swatch(self) -> None:
        key = self.src_color_var.get()
        rgb = COLOR_RGB.get(key, (200, 200, 200))
        hex_color = "#%02x%02x%02x" % rgb
        self.swatch.configure(bg=hex_color)

    def choose_source(self) -> None:
        path = filedialog.askopenfilename(filetypes=[("DDS images", "*.dds"), ("All files", "*.*")])
        if path:
            self.src_path_var.set(path)
            self.output_dir_var.set(str(Path(path).parent))
            self.status_var.set(f"Loaded: {os.path.basename(path)}")

    def use_source_dir(self) -> None:
        src = self.src_path_var.get()
        if src:
            self.output_dir_var.set(str(Path(src).parent))

    def build_filename(self, fmt: str, base: str, color_name: str, color_key: str) -> str:
        key_name = COLOR_KEY_NAME.get(color_key, color_key)
        return fmt.format(
            base=base,
            color_name=color_name,
            color_slug=slugify(color_name),
            color_key=color_key,
            color_key_name=key_name,
        )

    def convert_all(self) -> None:
        src_path = Path(self.src_path_var.get())
        fmt = self.name_fmt_var.get().strip()
        output_dir = Path(self.output_dir_var.get() or src_path.parent)
        src_key = self.src_color_var.get()

        if not src_path.is_file():
            messagebox.showerror("Missing source", "Choose a valid source .dds file.")
            return
        if not fmt:
            messagebox.showerror("Missing format", "Provide a filename format.")
            return
        if src_key not in COLORS:
            messagebox.showerror("Invalid color", "Choose a source color from the list.")
            return

        output_dir.mkdir(parents=True, exist_ok=True)

        try:
            base_img = Image.open(src_path)
        except Exception as exc:  # pragma: no cover - runtime safeguard
            messagebox.showerror("Load failed", f"Could not open image:\n{exc}")
            return

        src_rgb = COLOR_RGB.get(src_key, (255, 255, 255))

        # Parse optional secondary colors.
        secondary_colors: list[tuple[int, int, int]] = []
        sec_text = self.secondary_text.get("1.0", "end").strip()
        if sec_text:
            tokens = re.split(r"[\s,;]+", sec_text)
            for token in tokens:
                if not token:
                    continue
                parsed = parse_hex_color(token)
                if not parsed:
                    messagebox.showerror("Bad secondary color", f"Invalid hex color: {token}")
                    return
                secondary_colors.append(parsed)

        # Validate presence of source/secondary colors; allow user override.
        missing = []
        if not contains_color(base_img, src_rgb):
            missing.append(f"source ({COLORS.get(src_key, src_key)})")
        for sec in secondary_colors:
            if not contains_color(base_img, sec):
                missing.append(f"secondary {sec[0]:02x}{sec[1]:02x}{sec[2]:02x}")
        if missing:
            proceed = messagebox.askyesno(
                "Colors not found",
                "These colors were not found in the image:\n- "
                + "\n- ".join(missing)
                + "\nContinue anyway?",
            )
            if not proceed:
                return

        successes, failures = 0, 0
        base_stem = src_path.stem

        for key, name in COLORS.items():
            dst_rgb = COLOR_RGB.get(key, src_rgb)
            variant = base_img.copy()

            use_alpha = self.alpha_estimate_var.get()
            if use_alpha:
                bg_src = estimate_background_mode(variant, src_rgb) or (0, 0, 0)
                variant = replace_with_estimated_alpha(variant, src_rgb, dst_rgb, bg_src)
            else:
                variant = replace_color(variant, src_rgb, dst_rgb)

            # Apply secondary color shifts using the same delta as primary.
            delta = (dst_rgb[0] - src_rgb[0], dst_rgb[1] - src_rgb[1], dst_rgb[2] - src_rgb[2])
            for sec in secondary_colors:
                shifted = (
                    clamp_channel(sec[0] + delta[0]),
                    clamp_channel(sec[1] + delta[1]),
                    clamp_channel(sec[2] + delta[2]),
                )
                if use_alpha:
                    bg_sec = estimate_background_mode(variant, sec) or bg_src
                    variant = replace_with_estimated_alpha(variant, sec, shifted, bg_sec)
                else:
                    variant = replace_color(variant, sec, shifted)

            filename = self.build_filename(fmt, base_stem, name, key)
            out_path = output_dir / filename
            try:
                variant.save(out_path)
                successes += 1
            except Exception as exc:  # pragma: no cover - runtime safeguard
                failures += 1
                print(f"Failed to save {out_path}: {exc}")

        self.status_var.set(f"Done. Saved {successes} file(s). {failures} failed.")


def main() -> None:
    root = tk.Tk()
    ColorBatchUI(root)
    root.mainloop()


if __name__ == "__main__":
    main()
