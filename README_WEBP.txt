If your version of MangaMeeya CE can't open .webp files, you can convert them to .png with the included script.

Requirements:
- Python 3.8+
- Pillow: install with `pip install pillow`

Quick usage:

Open a command prompt in the folder and run:

python convert_webp.py --source . --recursive

Options:
--source / -s : source folder containing .webp files
--recursive / -r : convert in subfolders as well
--delete / -d : delete original .webp files after conversion

This will create .png files alongside the originals which MangaMeeya CE should be able to display.
