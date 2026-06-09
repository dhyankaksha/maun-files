#!/bin/bash
cd "$(dirname "$0")"

# Load common shell configuration files to populate PATH (NVM, Homebrew, etc.)
[ -f ~/.zshrc ] && source ~/.zshrc
[ -f ~/.bash_profile ] && source ~/.bash_profile
[ -f ~/.profile ] && source ~/.profile

# Add common Node paths (Homebrew)
export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"

echo "=== Maun Audio Sync ==="

if ! command -v node &> /dev/null; then
  echo "Error: Node.js is not installed or not in PATH."
  echo "Please install Node.js from https://nodejs.org"
else
  node sync_songs.js
fi

echo ""
echo "Press Enter to close this window..."
read
