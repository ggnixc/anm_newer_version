import os
import subprocess
import sys

dirName = sys.argv[1] # Get the name of the folder passed to this script
print(f'Creating batch script for directory {dirName}')

outScript = open('HOI4_DDS_Compression.nvtt', 'w') # Start a new script

# Get all files, of every subdirectory
for root, _, files in os.walk(dirName):
    for file in files:
        if file.endswith('.dds'): # Get only DDS files
            file_path = os.path.abspath(os.path.join(root, file))
            outScript.write(f'"{file_path}" --format bc3 --quality normal --mips --mip-filter box --zcmp 5 --output "{file_path}"\n')

outScript.close()

print('Running nvtt_export --batch HOI4_DDS_Compression.nvtt...')
subprocess.run([r'C:\Program Files\NVIDIA Corporation\NVIDIA Texture Tools\nvtt_export.exe', '--batch', 'HOI4_DDS_Compression.nvtt'])
print('Done')

os.remove('HOI4_DDS_Compression.nvtt')