# Building the Interactive Swift Version

## Quick Build

```bash
# Compile the binary
swiftc -O createinstalliso-interactive.swift -o createinstalliso-interactive

# Make executable
chmod +x createinstalliso-interactive

# Run it
./createinstalliso-interactive
```

## Create Double-Clickable App (Optional)

The repository includes `CreateInstallISO-Sudo.applescript` which creates a sudo-enabled app:

```bash
# Compile the AppleScript into an app bundle
osacompile -o "CreateInstallISO Interactive.app" CreateInstallISO-Sudo.applescript
```

This app will:
- Open Terminal automatically
- Prompt for your password with sudo
- Work with all installer types including Sierra 10.12+
- Support the new "Write ISO to USB Drive" feature (option 7)

## One-Liner

```bash
swiftc -O createinstalliso-interactive.swift -o createinstalliso-interactive && chmod +x createinstalliso-interactive && ./createinstalliso-interactive
```

## Requirements

- macOS with Swift compiler (Xcode Command Line Tools)
- Swift 5.0 or later

## Notes

- Compiled files are `.gitignore`d (not committed to repository)
- Binary size: ~123KB
- App bundle size: ~200KB

See **README-SWIFT-INTERACTIVE.md** for complete documentation.
