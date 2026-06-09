#!/bin/bash
cd "$(dirname "$0")"

echo "=== Maun Audio Sync (Bash) ==="

REGISTRY="songs.json"
echo "[" > "$REGISTRY"

first=true
shopt -s nullglob
shopt -s nocaseglob

for file in *.mp3; do
  if [ ! -f "$file" ]; then
    continue
  fi

  filename="$file"

  # Use Python for cross-platform robust regex parsing and formatting
  python_result=$(python3 -c '
import sys, re, urllib.parse
filename = sys.argv[1]
base = filename.rsplit(".", 1)[0]
type_val = "meditation"
clean_name = base

if re.match(r"^sleep", base, re.IGNORECASE):
    type_val = "sleep"
    clean_name = re.sub(r"^sleep[-_ ]*", "", base, flags=re.IGNORECASE)
elif re.match(r"^chime", base, re.IGNORECASE):
    type_val = "chime"
    clean_name = re.sub(r"^chime[-_ ]*", "", base, flags=re.IGNORECASE)
elif re.match(r"^(meditation|meditaion|meditatio)", base, re.IGNORECASE):
    type_val = "meditation"
    clean_name = re.sub(r"^(meditation|meditaion|meditatio)[-_ ]*", "", base, flags=re.IGNORECASE)

clean_name = re.sub(r"[-_ ]+", " ", clean_name).strip()
clean_name = " ".join([w.capitalize() for w in clean_name.split()])

if not clean_name:
    clean_name = base

encoded = urllib.parse.quote(filename)
print(f"{clean_name}|{type_val}|{encoded}")
' "$filename")

  IFS='|' read -r cleanName type encodedFilename <<< "$python_result"
  url="https://raw.githubusercontent.com/dhyankaksha/maun-files/main/$encodedFilename"

  if [ "$first" = true ]; then
    first=false
  else
    echo "," >> "$REGISTRY"
  fi

  cat <<EOF >> "$REGISTRY"
  {
    "name": "$cleanName",
    "url": "$url",
    "type": "$type",
    "file": "$filename"
  }
EOF
done

echo "" >> "$REGISTRY"
echo "]" >> "$REGISTRY"

echo "Successfully generated songs.json."

# Git Operations
echo "Staging changes for Git..."
git add .

# Check if there are changes
status=$(git status --porcelain)
if [ -n "$status" ]; then
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  echo "Committing: Sync audio files $timestamp"
  git commit -m "Sync audio files $timestamp"
else
  echo "No new local changes to commit, checking for pending uploads..."
fi

echo "Pushing changes to GitHub..."
git push origin main

echo ""
echo "Press Enter to close this window..."
read
