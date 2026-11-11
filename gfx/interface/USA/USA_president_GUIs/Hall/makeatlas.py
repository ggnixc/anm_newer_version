from pathlib import Path
from PIL import Image, ImageChops

folder = Path(__file__).parent

sources = [
    "USA_Hall_channel_washington_placeholder.png",
    "USA_Hall_channel_urban_placeholder.png",
    "USA_Hall_channel_countryside_placeholder.png",
    "USA_Hall_channel_south_placeholder.png",
]

mask = Image.open(folder / "USA_Hall_screen_mask.png").convert("RGBA").getchannel("A")
atlas = Image.new("RGBA", (318 * len(sources), 227))

for index, filename in enumerate(sources):
    frame = Image.open(folder / filename).convert("RGBA")
    frame.putalpha(ImageChops.multiply(frame.getchannel("A"), mask))
    atlas.paste(frame, (index * 318, 0))

atlas.save(folder / "USA_Hall_channel_runtime_atlas.png")