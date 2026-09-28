"""Android launcher icons, from the same 1024 master the iOS icons came from.

    pip install pillow
    python3 tools/android_icons.py

The iOS icon is 读 and its vermilion gloss bar on flat ink, full bleed. Android
wants it in three pieces rather than one square:

- an adaptive icon (Android 8 and later): a flat ink background, and the art
  on a transparent foreground that the launcher masks to its own shape — a
  circle, a squircle, a teardrop — and may shift for parallax;
- a monochrome layer (Android 13 and later), the same art as a silhouette, so
  themed icons tint it rather than showing a full-colour square among them;
- a plain square for the two Android versions before adaptive icons.

The art is lifted off the ink by colour: every pixel is the ink blended with
either the paper white of the glyph or the vermilion of the bar, so each one
is split back into an ink colour and a coverage. That keeps the antialiased
edges, which are exactly what decides whether a small icon looks sharp.

Checked where it matters, as the iOS one was: at 48 px, the launcher's size,
the thin strokes of 读 and the bar under it have to survive.
"""

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
MASTER = ROOT / 'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png'
RES = ROOT / 'android/app/src/main/res'

INK = (18, 32, 58)  # the flat background, #12203A
INKS = [(247, 243, 233), (200, 85, 61)]  # the glyph, the gloss bar

DENSITIES = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}

# An adaptive layer is 108 dp; the launcher shows at most the middle 72. The
# iOS master's whole square maps onto those 72, so the art sits in the icon
# at the proportions it has on an iPhone.
LAYER_DP, VISIBLE_DP, LEGACY_DP = 108, 72, 48


def lift(master: Image.Image) -> Image.Image:
    """The art alone, on transparency."""
    out = Image.new('RGBA', master.size)
    src, dst = master.load(), out.load()
    for y in range(master.height):
        for x in range(master.width):
            p = src[x, y]
            best = None
            for c in INKS:
                d = [c[i] - INK[i] for i in range(3)]
                q = [p[i] - INK[i] for i in range(3)]
                a = sum(q[i] * d[i] for i in range(3)) / sum(v * v for v in d)
                a = min(1.0, max(0.0, a))
                miss = sum((q[i] - a * d[i]) ** 2 for i in range(3))
                if best is None or miss < best[0]:
                    best = (miss, a, c)
            _, a, c = best
            dst[x, y] = (*c, round(a * 255))
    return out


def layer(art: Image.Image, scale: float) -> Image.Image:
    size = round(LAYER_DP * scale)
    inner = round(VISIBLE_DP * scale)
    canvas = Image.new('RGBA', (size, size))
    placed = art.resize((inner, inner), Image.LANCZOS)
    offset = (size - inner) // 2
    canvas.alpha_composite(placed, (offset, offset))
    return canvas


def main() -> None:
    master = Image.open(MASTER).convert('RGB')
    art = lift(master)
    silhouette = Image.new('RGBA', art.size, (255, 255, 255, 0))
    silhouette.putalpha(art.getchannel('A'))

    for name, scale in DENSITIES.items():
        folder = RES / f'mipmap-{name}'
        folder.mkdir(parents=True, exist_ok=True)
        layer(art, scale).save(folder / 'ic_launcher_foreground.png', optimize=True)
        layer(silhouette, scale).save(folder / 'ic_launcher_monochrome.png', optimize=True)
        legacy = round(LEGACY_DP * scale)
        master.resize((legacy, legacy), Image.LANCZOS).save(
            folder / 'ic_launcher.png', optimize=True
        )

    # Play's listing icon: 512 px, full bleed. The store rounds the corners.
    store = ROOT / 'android/play'
    store.mkdir(parents=True, exist_ok=True)
    master.resize((512, 512), Image.LANCZOS).save(store / 'icon-512.png', optimize=True)
    print('icons written under', RES, 'and', store)


if __name__ == '__main__':
    main()
