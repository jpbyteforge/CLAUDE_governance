#!/bin/bash
# Sync Chrome profile to dedicated Playwright profile
# Run with Chrome CLOSED for full sync (especially cookies)

SRC="C:/Users/jorge/AppData/Local/Google/Chrome/User Data"
DST="C:/Users/jorge/AppData/Local/Google/Chrome/PlaywrightProfile"

# Check if Chrome is running
if tasklist.exe //FI "IMAGENAME eq chrome.exe" 2>/dev/null | grep -q chrome.exe; then
  echo "WARNING: Chrome is running. Cookies and some files will be skipped."
  echo "Close Chrome for a full sync."
fi

mkdir -p "$DST/Default"

# Essential files for session persistence
cp "$SRC/Local State" "$DST/" 2>/dev/null
cp "$SRC/Default/Preferences" "$DST/Default/" 2>/dev/null
cp "$SRC/Default/Secure Preferences" "$DST/Default/" 2>/dev/null
cp "$SRC/Default/Bookmarks" "$DST/Default/" 2>/dev/null
cp "$SRC/Default/Login Data" "$DST/Default/" 2>/dev/null
cp "$SRC/Default/Login Data-journal" "$DST/Default/" 2>/dev/null
cp "$SRC/Default/Web Data" "$DST/Default/" 2>/dev/null
cp -r "$SRC/Default/Network" "$DST/Default/" 2>/dev/null
cp -r "$SRC/Default/Local Storage" "$DST/Default/" 2>/dev/null
cp -r "$SRC/Default/Session Storage" "$DST/Default/" 2>/dev/null
cp -r "$SRC/Default/Sessions" "$DST/Default/" 2>/dev/null

echo "Sync complete: $(date)"
