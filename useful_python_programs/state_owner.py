import os
import re
import csv

# Define the path to your states folder
states_folder = os.path.expanduser("~/Documents/Paradox Interactive/Hearts of Iron IV/mod/the-new-order-git/history/states")

# Output CSV filename
output_file = "state_owners.csv"

# Regex patterns
id_pattern = re.compile(r"\bid\s*=\s*(\d+)")
owner_pattern = re.compile(r"\bowner\s*=\s*(\w+)")
filename_pattern = re.compile(r"(\d+)-(.+)\.txt")

# Store extracted data
state_data = []

# Process each .txt file
for filename in os.listdir(states_folder):
    if filename.endswith(".txt"):
        filepath = os.path.join(states_folder, filename)
        match = filename_pattern.match(filename)
        if match:
            id_from_filename = match.group(1)
            name_from_filename = match.group(2).replace("_", " ").strip()

            with open(filepath, 'r', encoding='utf-8') as file:
                content = file.read()
                id_match = id_pattern.search(content)
                owner_match = owner_pattern.search(content)

                if id_match and owner_match:
                    owner = owner_match.group(1)
                    state_data.append((id_from_filename, name_from_filename, owner))

# Write the results to CSV
with open(output_file, 'w', newline='', encoding='utf-8') as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow(['State ID', 'State Name', 'Owner'])
    writer.writerows(state_data)

print(f"Extracted {len(state_data)} entries to '{output_file}'")