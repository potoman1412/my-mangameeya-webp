"""
Batch-convert .webp images to .png for compatibility with apps.
Usage:
  python convert_webp.py --source /path/to/folder [--recursive] [--delete]

Requires: Pillow (install with `pip install pillow`)
"""
import argparse
import os
from PIL import Image


def convert_file(src_path, dest_path, remove_original=False):
    try:
        with Image.open(src_path) as im:
            im = im.convert("RGBA")
            im.save(dest_path, "PNG")
        if remove_original:
            os.remove(src_path)
        return True, None
    except Exception as e:
        return False, str(e)


def main():
    p = argparse.ArgumentParser(description="Convert .webp images to .png")
    p.add_argument("--source", "-s", required=True, help="Source folder")
    p.add_argument("--recursive", "-r", action="store_true", help="Recurse into subfolders")
    p.add_argument("--delete", "-d", action="store_true", help="Delete original .webp files after conversion")
    args = p.parse_args()

    src = os.path.abspath(args.source)
    if not os.path.isdir(src):
        print("Source must be a folder")
        return

    count = 0
    errors = []
    if args.recursive:
        walker = os.walk(src)
    else:
        walker = [(src, [], os.listdir(src))]

    for root, _, files in walker:
        for f in files:
            if f.lower().endswith('.webp'):
                webp_path = os.path.join(root, f)
                png_name = os.path.splitext(f)[0] + '.png'
                png_path = os.path.join(root, png_name)
                ok, err = convert_file(webp_path, png_path, remove_original=args.delete)
                if ok:
                    count += 1
                    print(f"Converted: {webp_path} -> {png_path}")
                else:
                    errors.append((webp_path, err))
                    print(f"Failed: {webp_path}: {err}")

    print(f"Done. Converted {count} files.")
    if errors:
        print(f"{len(errors)} errors occurred.")

if __name__ == '__main__':
    main()
