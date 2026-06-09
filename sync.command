#!/bin/bash
cd "$(dirname "$0")"
echo "=== Maun Audio Sync ==="
node sync_songs.js
echo ""
echo "Press Enter to close this window..."
read
