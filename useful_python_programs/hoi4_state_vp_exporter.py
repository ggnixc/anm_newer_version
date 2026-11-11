import os
import re
import csv

# ========= CONFIGURE PATHS =========
STATE_DIR = r"C:/Users/<username>/Documents/Paradox Interactive/Hearts of Iron IV/mod/the-new-order-git/history/states"
STATE_LOC_FILE = r"C:/Users/<username>/Documents/Paradox Interactive/Hearts of Iron IV/mod/the-new-order-git/localisation/english/state_names_l_english.yml"
VP_LOC_FILE = r"C:/Users/<username>/Documents/Paradox Interactive/Hearts of Iron IV/mod/the-new-order-git/localisation/english/TNO_victory_points_l_english.yml"
OUTPUT_CSV = r"state_vp_output.csv"


# ========= LOCALIZATION =========
loc_line_pattern = re.compile(r'^\s*([A-Za-z0-9_\.]+):\s*"(.*)"')

def load_localization(file_path):
    loc = {}
    with open(file_path, encoding="utf-8-sig") as f:
        for line in f:
            m = loc_line_pattern.match(line)
            if m:
                loc[m.group(1)] = m.group(2)
    return loc


# ========= STATE PARSING =========
state_name_pattern = re.compile(r'name\s*=\s*"([^"]+)"')
state_id_pattern = re.compile(r'id\s*=\s*(\d+)')
vp_block_pattern = re.compile(r'victory_points\s*=\s*{([^}]*)}', re.DOTALL)
vp_entry_pattern = re.compile(r'(\d+)\s+(\d+)')

def parse_state_file(filepath):
    with open(filepath, encoding="utf-8-sig") as f:
        text = f.read()

    state_key_match = state_name_pattern.search(text)
    state_key = state_key_match.group(1) if state_key_match else "UNKNOWN"

    state_id_match = state_id_pattern.search(text)
    state_id = state_id_match.group(1) if state_id_match else ""

    vps = []
    vp_blocks = vp_block_pattern.findall(text)

    for block in vp_blocks:
        clean_block = re.sub(r'#.*', '', block)
        vps.extend(vp_entry_pattern.findall(clean_block))

    return text, state_id, state_key, vps


def matches_country(text, tag):
    if re.search(rf'owner\s*=\s*{tag}', text):
        return True
    return False


# ========= MAIN =========
def main():
    tag = input("Enter country tag (ex: GER): ").strip().upper()

    print("Loading localization...")
    state_loc = load_localization(STATE_LOC_FILE)
    vp_loc = load_localization(VP_LOC_FILE)

    rows = []

    print("Scanning states...")

    for filename in os.listdir(STATE_DIR):
        if not filename.endswith(".txt"):
            continue

        path = os.path.join(STATE_DIR, filename)
        text, state_id, state_key, vps = parse_state_file(path)

        if not matches_country(text, tag):
            continue

        state_name = state_loc.get(state_key, state_key)

        if not vps:
            rows.append([tag, state_id, state_name, "", "", ""])
            continue

        for prov, val in vps:
            vp_key = f"VICTORY_POINTS_{prov}"
            vp_name = vp_loc.get(vp_key, state_name)

            rows.append([
                tag,
                state_id,
                state_name,
                prov,
                vp_name,
                val
            ])

    print("Writing CSV...")
    with open(OUTPUT_CSV, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow([
            "Country",
            "State ID",
            "State Name",
            "Province ID",
            "VP Name",
            "VP Value"
        ])
        writer.writerows(rows)

    print(f"Done! File saved as: {OUTPUT_CSV}")


if __name__ == "__main__":
    main()