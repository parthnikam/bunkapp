"""Generate platform / PWA icons from assets/logo/logo.png."""

from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = Image.open(ROOT / "assets" / "logo" / "logo.png").convert("RGBA")


def resize_cover(img: Image.Image, size: int, pad_ratio: float = 0.0) -> Image.Image:
    """Resize to a square. pad_ratio > 0 shrinks content for maskable safe zone."""
    out = Image.new("RGBA", (size, size), (0, 0, 0, 255))
    content = max(1, int(size * (1 - 2 * pad_ratio)))
    scaled = img.resize((content, content), Image.Resampling.LANCZOS)
    offset = (size - content) // 2
    out.paste(scaled, (offset, offset), scaled)
    return out


def save_png(img: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, format="PNG", optimize=True)
    print(f"wrote {path.relative_to(ROOT)} ({img.size[0]}x{img.size[1]})")


def save_ico(images: list[Image.Image], sizes: list[int], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    images[0].save(
        path,
        format="ICO",
        sizes=[(s, s) for s in sizes],
        append_images=images[1:],
    )
    print(f"wrote {path.relative_to(ROOT)}")


def main() -> None:
    print("source size:", SRC.size)

    # --- Web / PWA ---
    web = ROOT / "web"
    save_png(resize_cover(SRC, 32), web / "favicon.png")
    save_png(resize_cover(SRC, 192), web / "icons" / "Icon-192.png")
    save_png(resize_cover(SRC, 512), web / "icons" / "Icon-512.png")
    # Maskable: ~10% safe padding (Android maskable guidelines)
    save_png(
        resize_cover(SRC, 192, pad_ratio=0.10),
        web / "icons" / "Icon-maskable-192.png",
    )
    save_png(
        resize_cover(SRC, 512, pad_ratio=0.10),
        web / "icons" / "Icon-maskable-512.png",
    )
    save_png(resize_cover(SRC, 180), web / "icons" / "apple-touch-icon.png")

    ico_sizes = [16, 24, 32, 48, 64, 128, 256]
    ico_images = [resize_cover(SRC, s) for s in ico_sizes]
    save_ico(ico_images, ico_sizes, web / "favicon.ico")

    # --- Android launcher mipmaps ---
    android_sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    res = ROOT / "android" / "app" / "src" / "main" / "res"
    for folder, size in android_sizes.items():
        save_png(resize_cover(SRC, size), res / folder / "ic_launcher.png")

    # --- iOS AppIcon ---
    ios_icons = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    ios_dir = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    for name, size in ios_icons.items():
        save_png(resize_cover(SRC, size), ios_dir / name)

    # --- macOS AppIcon ---
    mac_icons = {
        "app_icon_16.png": 16,
        "app_icon_32.png": 32,
        "app_icon_64.png": 64,
        "app_icon_128.png": 128,
        "app_icon_256.png": 256,
        "app_icon_512.png": 512,
        "app_icon_1024.png": 1024,
    }
    mac_dir = ROOT / "macos" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    for name, size in mac_icons.items():
        save_png(resize_cover(SRC, size), mac_dir / name)

    # --- Windows app icon ---
    win_ico = ROOT / "windows" / "runner" / "resources" / "app_icon.ico"
    save_ico(ico_images, ico_sizes, win_ico)

    print("done")


if __name__ == "__main__":
    main()
