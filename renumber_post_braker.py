#!/usr/bin/env python3

from pathlib import Path
import re

repo_dir = Path.cwd()
scripts_dir = repo_dir / "scripts" / "3-POST-BRAKER"

if not scripts_dir.is_dir():
    raise SystemExit(f"Folder not found: {scripts_dir}")

# Match filenames beginning with an integer:
# 16-file.sh
# 16.1-file.sh
# 29.1.0-file.sh
pattern = re.compile(r"^(\d+)(.*)$")

renames = []

for path in scripts_dir.iterdir():
    if not path.is_file():
        continue

    match = pattern.match(path.name)
    if not match:
        continue

    number = int(match.group(1))
    remainder = match.group(2)

    if number >= 16:
        new_name = f"{number + 1}{remainder}"
        renames.append((path, path.with_name(new_name)))

if not renames:
    raise SystemExit("No files numbered 16 or higher were found.")

print("Files that will be renamed:\n")

for old_path, new_path in sorted(renames):
    print(f"  {old_path.name} -> {new_path.name}")

# First move everything to temporary names.
# This avoids collisions such as:
# 16-file.sh -> 17-file.sh
# while 17-file.sh still exists.
temporary_renames = []

for index, (old_path, new_path) in enumerate(renames):
    temporary_path = old_path.with_name(f".renumber_tmp_{index}_{old_path.name}")
    old_path.rename(temporary_path)
    temporary_renames.append((temporary_path, new_path))

# Move temporary files to their final names.
for temporary_path, new_path in temporary_renames:
    temporary_path.rename(new_path)

# Update references in all Markdown files in the repository.
markdown_files = list(repo_dir.rglob("*.md"))

for markdown_file in markdown_files:
    original_text = markdown_file.read_text(encoding="utf-8")
    updated_text = original_text

    for old_path, new_path in renames:
        updated_text = updated_text.replace(old_path.name, new_path.name)

    if updated_text != original_text:
        markdown_file.write_text(updated_text, encoding="utf-8")
        print(f"Updated links in: {markdown_file.relative_to(repo_dir)}")

print("\nRenaming completed.")
