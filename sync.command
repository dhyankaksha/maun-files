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
  type="meditation"
  cleanName="${file%.*}"

  # Prefix matching
  if [[ "$cleanName" =~ ^sleep ]]; then
    type="sleep"
    cleanName=$(echo "$cleanName" | sed -E 's/^sleep[_-\s]*//I')
  elif [[ "$cleanName" =~ ^chime ]]; then
    type="chime"
    cleanName=$(echo "$cleanName" | sed -E 's/^chime[_-\s]*//I')
  elif [[ "$cleanName" =~ ^(meditation|meditaion|meditatio) ]]; then
    type="meditation"
    cleanName=$(echo "$cleanName" | sed -E 's/^(meditation|meditaion|meditatio)[_-\s]*//I')
  fi

  # Formatting Name
  cleanName=$(echo "$cleanName" | sed -E 's/[_- ]+/ /g' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
  
  # Title Case conversion
  cleanName=$(echo "$cleanName" | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1))tolower(substr($i,2))}}1')

  if [ -z "$cleanName" ]; then
    cleanName="${file%.*}"
  fi

  # URL encoding filename
  encodedFilename=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$filename" 2>/dev/null)
  if [ -z "$encodedFilename" ]; then
    encodedFilename=$(echo -n "$filename" | curl -s -o /dev/null -w %{url_effective} --get --data-urlencode @- "" | cut -c 3-)
  fi

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
