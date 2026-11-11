import os
import re
import sys

# Base paths
base_path = os.path.dirname(os.path.dirname(os.path.realpath(__file__)))
file_folder = os.path.join(base_path, "localisation", "english")

if "the-new-order-git" not in base_path:
    print("Please run the script in the-new-order-git\\useful_python_programs")
    sys.exit()

print(file_folder)

# Get sorted file list (by size, descending)
file_list = sorted(
    os.listdir(file_folder),
    key=lambda f: os.path.getsize(os.path.join(file_folder, f)),
    reverse=True
)

def extract_loc_key(line):
    """Extract and clean localisation key."""
    if ":" not in line:
        return ""

    loc = line.split(":", 1)[0]
    loc = re.sub(r'^0?\s*"', "", loc).strip()
    return loc

def is_valid_loc(loc):
    """Check if loc key should be processed."""
    return loc and "#" not in loc and "l_english" not in loc

def fix_duplicates(loc_file):
    print(loc_file)

    file_path = os.path.join(file_folder, loc_file)

    with open(file_path, "r", encoding="utf8") as f:
        lines = f.readlines()

    seen_locs = set()
    seen_lines = set()
    lines_to_write = []
    duplicates = 0

    for line in lines:
        loc = extract_loc_key(line)

        if is_valid_loc(loc):
            if loc in seen_locs:
                duplicates += 1

                if line in seen_lines:
                    print(f"\tDUPLICATE STRING {loc}")
                else:
                    print(f"\tDUPLICATE LOC KEY {loc}")
                    line = f"#{line.rstrip()} #duplicate loc key\n"
            else:
                seen_locs.add(loc)

        seen_lines.add(line)
        lines_to_write.append(line)

    if duplicates:
        print(f"WRITING TO FILE {loc_file}")
        with open(file_path, "w", encoding="utf8") as f:
            f.writelines(lines_to_write)


# Process files (TNO_ first, then others)
for file in file_list:
    if "TNO_" in file:
        fix_duplicates(file)

for file in file_list:
    if "TNO_" not in file:
        fix_duplicates(file)