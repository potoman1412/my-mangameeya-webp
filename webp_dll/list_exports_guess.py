from __future__ import print_function
import sys
import os
import re

def strings_scan(path, min_len=3):
    with open(path, 'rb') as f:
        data = f.read()
    result = []
    current = []
    for b in data:
        if 32 <= b < 127:  # printable ASCII
            current.append(chr(b))
        else:
            if len(current) >= min_len:
                s = ''.join(current)
                result.append(s)
            current = []
    if len(current) >= min_len:
        result.append(''.join(current))
    return result


def try_pefile(path):
    try:
        import pefile
    except Exception:
        return None
    try:
        pe = pefile.PE(path)
        exports = []
        if hasattr(pe, 'DIRECTORY_ENTRY_EXPORT'):
            for exp in pe.DIRECTORY_ENTRY_EXPORT.symbols:
                if exp.name:
                    exports.append(exp.name.decode('utf-8', errors='ignore'))
        return exports
    except Exception:
        return None


def filter_names(strings):
    seen = set()
    names = []
    pattern = re.compile(r'^[A-Za-z_@\?\$][A-Za-z0-9_@\?$]*$')
    for s in strings:
        if len(s) < 3 or len(s) > 200:
            continue
        if '\\' in s or '/' in s or '.' in s:
            continue
        if pattern.match(s):
            if s not in seen:
                seen.add(s)
                names.append(s)
    return names


def main():
    if len(sys.argv) < 2:
        print('Usage: list_exports_guess.py <dll-file>')
        sys.exit(2)
    path = sys.argv[1]
    if not os.path.isfile(path):
        print('File not found:', path)
        sys.exit(1)

    pe_exports = try_pefile(path)
    if pe_exports is not None:
        print('---exports (from pefile)---')
        for e in pe_exports:
            print(e)
        return

    # fallback: strings scan
    print('pefile not available or failed; falling back to strings scan')
    strs = strings_scan(path, min_len=4)
    candidates = filter_names(strs)
    print('---candidate names found---')
    for n in candidates:
        print(n)

if __name__ == '__main__':
    main()
