# Afrandez here. This script checks for capitalization mismatches 
# between .gfx files and their referenced .dds/.png assets. 
# If it finds a reference that doesn't match the actual 
# file name (case-sensitive), it reports the mismatch.

# This script is necessary because Linux is case sensitive, so 
# that miscapitalized assets just appear transparent in their place.
# Consider this as a warning to take capitalization seriously.

import os
import re
import sys

def collect_assets(root_dir):
    assets = {}
    for root, _, files in os.walk(root_dir):
        for f in files:
            if f.lower().endswith(('.dds', '.png')):
                full_path = os.path.relpath(os.path.join(root, f), root_dir)
                assets[full_path.lower().replace("\\", "/")] = full_path.replace("\\", "/")
    return assets

def find_mismatches(root_dir):
    assets = collect_assets(root_dir)
    print(f"Indexed {len(assets)} assets")
    mismatches = []
    mismatch_count = 0

    for root, _, files in os.walk(root_dir):
        for file in files:
            if file.endswith('.gfx'):
                path = os.path.join(root, file)

                with open(path, 'r', errors='ignore') as f:
                    content = f.read()

                # Extract quoted file paths ending in .dds or .png
                refs = re.findall(r'["\']([^"\']+\.(?:dds|png))["\']', content)

                for ref in refs:
                    ref_clean = ref.replace("\\", "/")
                    ref_lower = ref_clean.lower()

                    if ref_lower in assets:
                        actual = assets[ref_lower]

                        if ref_clean != actual:
                            mismatch_count += 1
                            mismatches.append(
                                f"In {path}: '{ref_clean}' should be '{actual}'"
                            )

    for m in mismatches:
        print(m)
    print(f"\nTotal mismatched asset references: {mismatch_count}")

if __name__ == "__main__":
    directory = sys.argv[1] if len(sys.argv) > 1 else '.'
    find_mismatches(directory)