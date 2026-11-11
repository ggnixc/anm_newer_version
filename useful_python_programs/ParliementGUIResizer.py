# Afrandez here; steps are the following:
# -Make a file old_values.txt and add your all three arrays and values in there
# -Configure the values in CONFIG section below
# -After code is run, take your new values from newly generated new_values.txt

import os
os.chdir(os.path.dirname(os.path.abspath(__file__)))

# CONFIG
X_OFFSET = 0   #Amount of change that will apply to X
Y_OFFSET = 0   #Amount of change that will apply to Y
ARRAY_NAME = "array_name"    #Name of array

def process_input_line(line):
    line = line.strip().replace("add_to_array = {", "").replace("}", "")
    parts = line.split("=")
    if len(parts) != 2:
        return

    array_name = parts[0].strip()
    value = int(parts[1].strip())

    if array_name in data:
        data[array_name].append(value)
    else:
        print(f"Skipping invalid array name: {array_name}")

def convert_to_original_syntax(array_name, value):
    return f"add_to_array = {{ {array_name} = {value} }}"

# Initialize data structure
data = {
    f"{ARRAY_NAME}_X": [], 
    f"{ARRAY_NAME}_Y": [], 
    ARRAY_NAME: []
}

# Check if old_values.txt exists
if os.path.exists('old_values.txt'):
    with open('old_values.txt', 'r') as file:
        for line in file:
            process_input_line(line)
else:
    print("Error: old_values.txt not found.")
    exit()

# Apply offsets
for i in range(len(data[f"{ARRAY_NAME}_X"])):
    data[f"{ARRAY_NAME}_X"][i] += X_OFFSET
for i in range(len(data[f"{ARRAY_NAME}_Y"])):
    data[f"{ARRAY_NAME}_Y"][i] += Y_OFFSET

# Write updated values to new file
with open('new_values.txt', 'w') as file:
    min_length = min(len(data[f"{ARRAY_NAME}_X"]), len(data[f"{ARRAY_NAME}_Y"]), len(data[ARRAY_NAME]))
    for i in range(min_length):
        file.write(convert_to_original_syntax(f"{ARRAY_NAME}_X", data[f"{ARRAY_NAME}_X"][i]) + '\n')
        file.write(convert_to_original_syntax(f"{ARRAY_NAME}_Y", data[f"{ARRAY_NAME}_Y"][i]) + '\n')
        file.write(convert_to_original_syntax(ARRAY_NAME, data[ARRAY_NAME][i]) + '\n')

print(f"Success! Updated values written to new_values.txt")
print(f"Applied offsets: X={X_OFFSET}, Y={Y_OFFSET}")
print(f"Processed {min_length} coordinate sets")
