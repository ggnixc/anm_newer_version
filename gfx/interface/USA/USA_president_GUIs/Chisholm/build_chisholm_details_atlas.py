"""Pack the check's request, pay, and signature art into animated page cells."""

from pathlib import Path

from PIL import Image


HERE = Path(__file__).resolve().parent
OUT = HERE / "chisholm_check_details_atlas.png"
RUNTIME_ATLAS = HERE / "chisholm_check_runtime_atlas.png"
PAY_CONTROL = HERE / "chisholm_pay_hitbox.png"
FRAME_SIZE = (352, 158)
FRAME_COUNT = 11


def main():
    request = Image.open(HERE / "chisholm_request.dds").convert("RGBA")
    pay = Image.open(HERE / "chisholm_pay.dds").convert("RGBA")
    signature = Image.open(HERE / "chisholm_signature.dds").convert("RGBA")
    if request.size != (52, 23) or pay.size != (40, 23) or signature.size != (126, 21):
        raise ValueError("Unexpected Chisholm detail asset dimensions")

    atlas = Image.new("RGBA", (FRAME_SIZE[0] * FRAME_COUNT, FRAME_SIZE[1]), (0, 0, 0, 0))
    for frame in range(FRAME_COUNT):
        page = Image.new("RGBA", FRAME_SIZE, (0, 0, 0, 0))
        page.alpha_composite(signature, (193, 126))
        atlas.alpha_composite(page, (frame * FRAME_SIZE[0], 0))
    atlas.save(OUT)

    runtime_atlas = Image.open(RUNTIME_ATLAS).convert("RGBA")
    if runtime_atlas.size != (FRAME_SIZE[0] * FRAME_COUNT, FRAME_SIZE[1]):
        raise ValueError("Unexpected Chisholm runtime atlas dimensions")
    source_page = Image.new("RGBA", FRAME_SIZE, (0, 0, 0, 0))
    source_page.alpha_composite(request, (0, 0))
    source_page.alpha_composite(pay, (64, 0))
    runtime_atlas.paste(source_page, (3 * FRAME_SIZE[0], 0))
    runtime_atlas.save(RUNTIME_ATLAS)

    
    pay_control = Image.new("RGBA", (70, 24), (0, 0, 0, 0))
    pay_control.alpha_composite(pay, (0, 0))
    pay_control.save(PAY_CONTROL)
    print(f"Built {OUT} ({atlas.width}x{atlas.height})")


if __name__ == "__main__":
    main()
