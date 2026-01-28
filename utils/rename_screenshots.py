#!/usr/bin/env python3
import os
import re
from datetime import datetime

# Directory to watch
SCREENSHOTS_DIR = os.path.expanduser("~/Desktop/Screenshots")

def rename_screenshots():
    if not os.path.exists(SCREENSHOTS_DIR):
        return

    # Pattern: Screenshot YYYY-MM-DD at H.MM.SS PM.jpg
    # Example: Screenshot 2026-01-22 at 6.38.05 PM.jpg
    # Another pattern: Screenshot 2026-01-22 at 18.38.05.jpg (if system is already 24h)
    
    # We look for files with spaces or "at" that start with Screenshot
    for filename in os.listdir(SCREENSHOTS_DIR):
        if not filename.startswith("Screenshot"):
            continue
        
        # If it already fits the final pattern Screenshot_YYYY_MM_DD_HH_MM_SS.jpg, skip
        if re.match(r"^Screenshot_\d{4}_\d{2}_\d{2}_\d{6}\.jpg$", filename):
            continue

        # Regex to capture date components
        # This handles: 2026-01-22 at 6.38.05 PM
        match = re.search(r"(\d{4})-(\d{2})-(\d{2})\s+at\s+(\d{1,2})\.(\d{2})\.(\d{2})\s*(AM|PM)?", filename)
        
        if match:
            year, month, day, hour, minute, second, meridiem = match.groups()
            h = int(hour)
            
            # Convert to 24h if AM/PM is present
            if meridiem == "PM" and h < 12:
                h += 12
            elif meridiem == "AM" and h == 12:
                h = 0
            
            new_name = f"Screenshot_{year}_{month}_{day}_{h:02d}{minute}{second}.jpg"
            
            old_path = os.path.join(SCREENSHOTS_DIR, filename)
            new_path = os.path.join(SCREENSHOTS_DIR, new_name)
            
            # Check if destination exists to avoid overwriting (unlikely given timestamps)
            if not os.path.exists(new_path):
                print(f"Renaming: {filename} -> {new_name}")
                os.rename(old_path, new_path)

if __name__ == "__main__":
    rename_screenshots()
