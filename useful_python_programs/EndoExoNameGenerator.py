import re

# Replace paths as needed
STATE_FILE = r"C:/Users/<username>/Documents/Paradox Interactive/Hearts of Iron IV/mod/the-new-order-git/localisation/english/state_names_l_english.yml"
VP_FILE = r"C:/Users/<username>/Documents/Paradox Interactive/Hearts of Iron IV/mod/the-new-order-git/localisation/english/TNO_victory_points_l_english.yml"


# Numeric input validation
def numeric_input(prompt):
    while True:
        value = input(prompt).strip()
        if value.isdigit():
            return value
        print("Invalid input. Please enter numbers only.")


# Load and save helpers
def load_file_lines(file_path):
    with open(file_path, "r", encoding="utf-8-sig") as f:
        lines = f.readlines()
    lines = [line if line.endswith("\n") else line + "\n" for line in lines]
    return lines


def save_file_lines(file_path, lines):
    with open(file_path, "w", encoding="utf-8-sig") as f:
        f.writelines(lines)


# Check if a key exists
def key_exists(lines, key):
    pattern = re.compile(rf"^\s*{re.escape(key)}:")
    return any(pattern.match(line) for line in lines)


# Find the index to insert below a key
def find_insert_after(lines, key):
    pattern = re.compile(rf"^\s*{re.escape(key)}:")
    for i, line in enumerate(lines):
        if pattern.match(line):
            return i + 1
    return None


# Insert a line at an index
def insert_line(lines, index, line):
    if index is None:
        lines.append(line)
    else:
        lines.insert(index, line)


# Generate state localization
def generate_state():
    print("\nSTATE Localization Generator\n")
    state_id = numeric_input("Enter STATE ID: ")
    suffix = input("Enter suffix (example _ger): ").strip()
    name = input("Enter state name: ").strip()

    base_key = f"STATE_{state_id}"
    new_key = f"{base_key}{suffix}"

    lines = load_file_lines(STATE_FILE)

    if key_exists(lines, new_key):
        print(f"Skipped: {new_key} already exists.")
        return

    insert_index = find_insert_after(lines, base_key)
    new_line = f" {new_key}: \"{name}\"\n"

    if insert_index is None:
        print(f"Warning: {base_key} not found. Appending at end.")
        lines.append(new_line)
    else:
        insert_line(lines, insert_index, new_line)

    save_file_lines(STATE_FILE, lines)
    print(f"Added {new_key}")


# Generate VP localization
def generate_vp():
    print("\nVictory Point Localization Generator\n")
    vp_id = numeric_input("Enter VP ID: ")
    suffix = input("Enter suffix (example _ger): ").strip()
    name = input("Enter VP name: ").strip()

    base_key = f"VICTORY_POINTS_{vp_id}"
    new_key = f"{base_key}{suffix}"

    lines = load_file_lines(VP_FILE)

    if key_exists(lines, new_key):
        print(f"Skipped: {new_key} already exists.")
        return

    # Base key creation if missing
    if not key_exists(lines, base_key):
        base_name = input(f"Base key {base_key} not found. Enter base name: ").strip()
        base_line = f" {base_key}: \"{base_name}\"\n"
    else:
        base_line = None  # Base exists

    # Automatic placement: try to place under the base key if it exists
    insert_index = find_insert_after(lines, base_key)

    if insert_index is None:
        # Ask user where to place if base key is missing and automatic placement fails
        print(f"Base key {base_key} not found in file for placement.")
        insert_after_id = numeric_input(
            "Enter VP key ID to insert beside (example 6521): "
        )
        insert_key = f"VICTORY_POINTS_{insert_after_id}"
        insert_index = find_insert_after(lines, insert_key)
        if insert_index is None:
            print(f"{insert_key} not found. Appending at end.")
            insert_index = len(lines)

    # Insert base key first if newly created
    if base_line:
        insert_line(lines, insert_index, base_line)
        insert_index += 1

    # Insert new variant key
    new_line = f" {new_key}: \"{name}\"\n"
    insert_line(lines, insert_index, new_line)

    save_file_lines(VP_FILE, lines)
    print(f"Added {new_key}")


def main():
    while True:
        print("\nEndo Exo Localization Generator")
        print("1. Add State Localization")
        print("2. Add Victory Point Localization")
        print("3. Exit")

        choice = input("Select option: ").strip()

        if choice == "1":
            generate_state()
        elif choice == "2":
            generate_vp()
        elif choice == "3":
            break
        else:
            print("Invalid option.")


if __name__ == "__main__":
    main()