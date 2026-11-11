

from pathlib import Path

from PIL import Image


HERE = Path(__file__).resolve().parent
PAGE_SIZE = (352, 158)
STACK_SIZE = (352, 316)
GROUP_COUNT = 8
RUNTIME_FRAMES = 11


def main():
    front = Image.open(HERE / "chisholm_check_front2.dds").convert("RGBA")
    back = Image.open(HERE / "chisholm_check_back.dds").convert("RGBA")
    runtime = Image.open(HERE / "chisholm_check_runtime_atlas.png").convert("RGBA")
    details = Image.open(HERE / "chisholm_check_details_atlas.png").convert("RGBA")
    request = Image.open(HERE / "chisholm_request.dds").convert("RGBA")
    pay = Image.open(HERE / "chisholm_pay.dds").convert("RGBA")

    if front.size != PAGE_SIZE or back.size != PAGE_SIZE:
        raise ValueError("Unexpected Chisholm cheque dimensions")
    if runtime.size != (PAGE_SIZE[0] * RUNTIME_FRAMES, PAGE_SIZE[1]):
        raise ValueError("Unexpected Chisholm runtime-atlas dimensions")

    opaque_front = Image.new("RGBA", PAGE_SIZE, (0, 0, 0, 255))
    opaque_front.alpha_composite(front)
    opaque_back = Image.new("RGBA", PAGE_SIZE, (0, 0, 0, 255))
    opaque_back.alpha_composite(back)
    opaque_back.save(HERE / "chisholm_check_back_opaque.png")

    flip_atlas = Image.new(
        "RGBA", (STACK_SIZE[0] * GROUP_COUNT, STACK_SIZE[1]), (0, 0, 0, 0)
    )
    fixed_details = details.crop((0, 0, PAGE_SIZE[0], PAGE_SIZE[1]))
    
    fixed_details.paste((0, 0, 0, 0), (193, 126, 319, 147))

    
    runtime.paste(opaque_front, (0, 0))
    runtime.paste(opaque_back, (PAGE_SIZE[0], 0))
    runtime.save(HERE / "chisholm_check_runtime_atlas.png")

    for group in range(GROUP_COUNT):
        page = opaque_front.copy()
        label_frame = 4 + group // 4
        label_row = group % 4
        label_alpha = runtime.crop(
            (
                label_frame * PAGE_SIZE[0],
                label_row * 30,
                label_frame * PAGE_SIZE[0] + 162,
                label_row * 30 + 22,
            )
        ).getchannel("A")
        label = Image.new("RGBA", (162, 22), (255, 227, 36, 0))
        label.putalpha(label_alpha)
        page.alpha_composite(label, (67, 45))
        page.alpha_composite(fixed_details)
        page.alpha_composite(request, (196, 93))
        page.alpha_composite(pay, (271, 93))

        stack = Image.new("RGBA", STACK_SIZE, (0, 0, 0, 0))
        stack.alpha_composite(page, (0, 0))
        stack.alpha_composite(opaque_front, (0, PAGE_SIZE[1]))
        flip_atlas.alpha_composite(stack, (group * STACK_SIZE[0], 0))

    flip_atlas.save(HERE / "chisholm_fong_flip_atlas.png")

    number_atlas = Image.new(
        "RGBA", (STACK_SIZE[0] * RUNTIME_FRAMES, STACK_SIZE[1]), (0, 0, 0, 0)
    )
    for frame in range(RUNTIME_FRAMES):
        source = runtime.crop(
            (
                frame * PAGE_SIZE[0],
                0,
                (frame + 1) * PAGE_SIZE[0],
                PAGE_SIZE[1],
            )
        )
        number_atlas.alpha_composite(source, (frame * STACK_SIZE[0], 0))
    number_atlas.save(HERE / "chisholm_fong_flip_numbers_atlas.png")

    print("Built Fong-style Chisholm flip atlases")


if __name__ == "__main__":
    main()
