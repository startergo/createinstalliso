# createinstalliso - Interactive Swift Version

**No Commands to Type!** Create bootable macOS ISO images with a simple menu interface.

---

## 🚀 Quick Start

### Step 1: Build from Source

First, compile the app. See **BUILD.md** for detailed instructions, or use this quick command:

```bash
swiftc -O createinstalliso-interactive.swift -o createinstalliso-interactive && chmod +x createinstalliso-interactive
```

### Step 2: Run the App

**Option 1: Terminal**
```bash
./createinstalliso-interactive

# Or with sudo (required for macOS 10.12+)
sudo ./createinstalliso-interactive

# Debug mode (shows detailed process information)
sudo ./createinstalliso-interactive --debug
# or
sudo ./createinstalliso-interactive -d
```

**Option 2: Double-Click (optional)**
Create an app bundle for double-clicking. See **BUILD.md** for instructions.

> **Note:** For macOS 10.12+ installers that require sudo, you must use Terminal with `sudo ./createinstalliso-interactive` or create a sudo-enabled app (see Advanced Usage below).

---

## 📖 Complete User Guide

### Step 1: Launch the App

**Double-click** `CreateInstallISO Interactive.app` or run `./createinstalliso-interactive` in Terminal.

You'll see:

```
╔════════════════════════════════════════════════════════════════════╗
║                     createinstalliso v1.2.0                        ║
║              Create Bootable macOS ISO Images                      ║
╚════════════════════════════════════════════════════════════════════╝

Current Configuration:
────────────────────────────────────────────────────────────────────
1. Select Installer Application: [Not Selected]
2. Select Output Directory: [Not Selected]
3. Set ISO Name: [Auto-generate]
────────────────────────────────────────────────────────────────────

Options:
4. [ ] Patch macOS Sierra Installer (version 12.6.06)
5. [ ] Replace Code Signatures
────────────────────────────────────────────────────────────────────

Actions:
6. Create ISO Image
7. Write ISO to USB Drive
8. View System Information
9. Help
0. Exit
────────────────────────────────────────────────────────────────────

Select option (0-9): _
```

### Step 2: Select Your Installer (Press 1)

The app automatically scans `/Applications/` for valid macOS installers:

```
Found installer applications:
────────────────────────────────────────────────────────────────────
1. Install macOS Big Sur
2. Install macOS Monterey
3. Install macOS Sonoma
4. Install macOS Ventura
0. Enter custom path
────────────────────────────────────────────────────────────────────

Select option (0-4): 3
✅ Selected: Install macOS Sonoma
Press Enter to continue...
```

**Tips:**
- Press a number to select from the list
- Press 0 to enter a custom path (e.g., external drive)
- The app validates the installer automatically

### Step 3: Choose Output Directory (Press 2)

Pick from common locations or enter a custom path:

```
Common locations:
────────────────────────────────────────────────────────────────────
1. Desktop (/Users/you/Desktop)
2. Downloads (/Users/you/Downloads)
3. Documents (/Users/you/Documents)
4. Current directory (/Users/you/createinstalliso)
5. Enter custom path
────────────────────────────────────────────────────────────────────

Select option (1-5): 1
✅ Output directory set to Desktop
Press Enter to continue...
```

### Step 4: Customize ISO Name (Optional - Press 3)

```
Default ISO name: Install macOS Sonoma.iso

Enter custom ISO name (without .iso extension)
Press Enter to use default name
ISO Name: [press Enter or type custom name]
```

### Step 5: Configure Options (Optional - Press 4 or 5)

**Option 4: Patch macOS Sierra**
- Only needed for defective Sierra installer version 12.6.06
- Press 4 to toggle: `[ ]` → `[✓]`

**Option 5: Replace Code Signatures**
- For modified installer applications
- Press 5 to toggle: `[ ]` → `[✓]`

### Step 6: Review Configuration

The main menu now shows your complete configuration:

```
Current Configuration:
────────────────────────────────────────────────────────────────────
1. Select Installer Application: ✓
   → Install macOS Sonoma
   → Type: Big Sur and later (11+)
2. Select Output Directory: ✓
   → /Users/you/Desktop
3. Set ISO Name: [Auto-generate]
────────────────────────────────────────────────────────────────────

Options:
4. [ ] Patch macOS Sierra Installer (version 12.6.06)
5. [ ] Replace Code Signatures
```

### Step 7: Create ISO (Press 6)

```
Configuration Summary:
  Installer: Install macOS Sonoma
  Type: Big Sur and later (11+)
  Output: /Users/you/Desktop
  ISO Name: [Auto-generate]
────────────────────────────────────────────────────────────────────

Proceed with ISO creation? [Y/n]: y
```

**If sudo is required:**
```
⚠️  Warning: This installer type requires root privileges
Please run this script with sudo:
  sudo ./createinstalliso-interactive
```

Exit and restart with: `sudo ./createinstalliso-interactive`

### Step 8: Write ISO to USB Drive (Press 7)

After creating an ISO, you can write it directly to a USB drive to create a bootable installer:

```
Write ISO to USB Drive

Available ISO files:
────────────────────────────────────────────────────────────────────
1. Install macOS Catalina.iso (7.7 GB)
2. Install macOS Sonoma.iso (13.2 GB)
0. Enter custom path
────────────────────────────────────────────────────────────────────

Select ISO file: 1

Selected ISO: /Users/you/Downloads/Install macOS Catalina.iso

Scanning for USB drives...

Available disks:
────────────────────────────────────────────────────────────────────
/dev/disk0 (internal, physical):
/dev/disk2 (external, physical):
   #:                       TYPE NAME                    SIZE
   0:     FDisk_partition_scheme                        *16.0 GB   disk2
   1:                 DOS_FAT_32 USB DRIVE               16.0 GB    disk2s1
────────────────────────────────────────────────────────────────────

⚠️  WARNING: This will ERASE ALL DATA on the selected disk!

Enter disk identifier (e.g., disk2) or 'cancel': disk2

You are about to write:
  ISO: /Users/you/Downloads/Install macOS Catalina.iso
  To:  /dev/disk2

⚠️  This will PERMANENTLY ERASE ALL DATA on /dev/disk2!

Type 'YES' to proceed: YES

ℹ️  Starting USB creation process...

Unmounting disk...
Writing ISO to USB drive (this may take several minutes)...
Please wait...

[Progress output...]

Ejecting disk...

✅ USB installer created successfully!
You can now safely remove the USB drive.
```

**Important Notes:**
- ⚠️ **All data on the USB drive will be erased**
- Requires sudo privileges (app must be run with sudo)
- Minimum USB size: varies by macOS version (typically 16GB+)
- The process may take 10-30 minutes depending on USB speed
- You must type "YES" in all capitals to confirm
- The USB drive will be automatically ejected when complete

**Safety Features:**
- Multiple confirmation prompts
- Shows disk list before selection
- Validates disk identifier format
- Cannot proceed without explicit "YES" confirmation

### Additional Menu Options

**Option 8: View System Information**
```
System Information
────────────────────────────────────────────────────────────────────
macOS Version: 14.2.1
Running as: regular user
Current Directory: /Users/you/createinstalliso
Home Directory: /Users/you
────────────────────────────────────────────────────────────────────

Supported macOS Installers:
  • Install Mac OS X Lion
  • Install OS X Mountain Lion
  ...
  • Install macOS Sequoia
```

**Option 9: Help**
Shows built-in documentation without leaving the app.

**Option 0: Exit**
Cleanly exits the program.

---

## 💻 Supported macOS Installers

✅ Mac OS X Lion 10.7  
✅ OS X Mountain Lion 10.8  
✅ OS X Mavericks 10.9  
✅ OS X Yosemite 10.10  
✅ OS X El Capitan 10.11  
✅ macOS Sierra 10.12  
✅ macOS High Sierra 10.13  
✅ macOS Mojave 10.14  
✅ macOS Catalina 10.15  
✅ macOS Big Sur 11  
✅ macOS Monterey 12  
✅ macOS Ventura 13  
✅ macOS Sonoma 14  
✅ macOS Sequoia 15  
✅ macOS Tahoe 26  

**All installer types supported • Intel & Apple Silicon**

---

## 🔐 Requirements

- macOS 10.6 (Snow Leopard) or later to run the script
- Valid macOS installer application
- Root privileges (sudo) for Sierra 10.12 and later
- Sufficient disk space (varies by installer, typically 8-25GB)

---

## 🎯 Real-World Example

**Creating an ISO for macOS Sonoma:**

1. **Double-click** `CreateInstallISO Interactive.app`
2. **Press 1**, then **3** (select Sonoma)
3. **Press 2**, then **1** (Desktop)
4. **Press 6** (Create ISO)
5. **Press Y** (Confirm)

**Result:** ISO created in `~/Desktop/Install macOS Sonoma.iso`

**Creating a bootable USB installer:**

1. **Run with sudo:** `sudo ./createinstalliso-interactive`
2. **Press 7** (Write ISO to USB Drive)
3. **Select ISO** from the list
4. **Enter disk identifier** (e.g., disk2)
5. **Type YES** to confirm

**Result:** Bootable USB installer ready to use

---

## 🔧 Troubleshooting

### Debug Mode

If you encounter issues during ISO creation, enable debug mode to see detailed process information:

```bash
sudo ./createinstalliso-interactive --debug
# or
sudo ./createinstalliso-interactive -d
```

Debug mode shows:
- Script paths and commands being executed
- Process IDs for tracking
- Exit status codes
- Detailed step-by-step progress

This is helpful for diagnosing process suspension issues or tracking where the ISO creation might be failing.

### First Time: "Unidentified Developer" Error

macOS blocks unsigned apps from running. This is normal!

**Solution:**
1. Right-click (or Ctrl+click) `CreateInstallISO Interactive.app`
2. Select **Open**
3. Click **Open** in the dialog
4. macOS remembers your choice (only needed once!)

**Alternative:**
1. System Preferences → Security & Privacy
2. Click **Open Anyway**
3. Confirm

### "Permission Denied" Error

The compiled binary needs execute permission.

**Solution:**
```bash
chmod +x createinstalliso-interactive
```

### Need Sudo But Using the App?

The .app runs as regular user. For Sierra and later installers:

**Solution:**
```bash
# Close the app and run in Terminal:
sudo ./createinstalliso-interactive
```

### No Installers Found

**Possible causes:**
- No installer apps in `/Applications/`
- Installer is on external drive
- Installer is incomplete/corrupted

**Solution:**
- Move installer to `/Applications/`, or
- Press **0** to enter custom path, or
- Download complete installer from Apple

### App Opens Then Immediately Closes

**Cause:** Binary `createinstalliso-interactive` not found

**Solution:**
- Keep the .app and binary in same folder, or
- Recompile: `swiftc -O createinstalliso-interactive.swift -o createinstalliso-interactive`

---

## 🛠️ Building from Source

See **BUILD.md** for complete build instructions including:
- Compiling the binary
- Creating the double-clickable app
- One-liner build commands
- Build requirements

Quick rebuild after changes:
```bash
swiftc -O createinstalliso-interactive.swift -o createinstalliso-interactive
```

### Running Without the App

```bash
# Regular user (for Lion through El Capitan)
./createinstalliso-interactive

# With sudo (for Sierra and later)
sudo ./createinstalliso-interactive
```

### Creating a Sudo-Enabled App

The standard app runs as a regular user. For Sierra (10.12) and later installers that require root privileges, create a sudo-enabled version:

**Option A: Using AppleScript (simpler)**

1. Open **Script Editor** (/Applications/Utilities/)
2. Create new script:
```applescript
set currentPath to do shell script "pwd"
do shell script "cd " & quoted form of currentPath & " && ./createinstalliso-interactive" with administrator privileges
```
3. File → Export → Format: **Application**
4. Save as `CreateInstallISO Interactive (Sudo).app` in the same folder

**Option B: Using BUILD.md method**

See **BUILD.md** for creating a sudo-enabled app that finds the binary automatically.

**Important:** The sudo-enabled app will prompt for your password when launched and can create ISOs for all macOS versions.

---

## 📂 What's Included

| File | Purpose |
|------|---------|
| `createinstalliso-interactive.swift` | Swift source code (compile this!) |
| `createinstalliso` | Original bash script (full functionality) |
| `README-SWIFT-INTERACTIVE.md` | This complete documentation |

**After compilation, you'll have:**
- `createinstalliso-interactive` - Compiled binary
- `CreateInstallISO Interactive.app` - Double-clickable app (optional)

> **Note:** Compiled files (`createinstalliso-interactive` and `*.app`) are not included in the repository. You must compile them from source.

---

**⚠️ In Development:**
- Native Swift ISO creation logic

**Current Behavior:**
When you press "Create ISO", the app shows you the command to run with the original bash script. The interactive configuration is complete and working - it validates everything and builds the correct command for you.

**Future Updates:**
Will add native Swift implementation of the ISO creation process to make it fully self-contained.

---

## 📝 License

GNU General Public License v3.0 or later

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

Copyright (C) 2021-2025 Michael Berger <michael.berger@gmx.de>

---

## 🙏 Credits

- **Original Author:** Michael Berger <michael.berger@gmx.de>
- **Original Script:** bash createinstalliso
- **Swift Interactive Port:** Based on version 1.2.0

---

## 📞 Support

**For the Interactive Swift Version:**
- Built-in help: Press **8** in the app
- This documentation: You're reading it!

**For the Original Bash Script:**
- See original `README.md`
- Contact: michael.berger@gmx.de

