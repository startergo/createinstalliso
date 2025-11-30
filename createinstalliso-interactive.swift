#!/usr/bin/env swift

// createinstalliso - Creates a bootable ISO image from a macOS
// installer application (Interactive Version)
// Copyright (C) 2021-2025 Michael Berger <michael.berger@gmx.de>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import Foundation

// MARK: - Global Constants

struct Constants {
    static let scriptName = "createinstalliso"
    static let scriptVersion = "1.2.0"
    static let minimumRequiredMacOSVersion = "10.6"
    static let rootUserId = 0
    
    static let supportedMacOSVersionsRegex = [
        "^10\\.6(\\.[[:digit:]]+)?$",            // Mac OS X Snow Leopard 10.6
        "^10\\.7(\\.[[:digit:]]+)?$",            // Mac OS X Lion         10.7
        "^10\\.8(\\.[[:digit:]]+)?$",            // OS X Mountain Lion    10.8
        "^10\\.9(\\.[[:digit:]]+)?$",            // OS X Mavericks        10.9
        "^10\\.10(\\.[[:digit:]]+)?$",           // OS X Yosemite         10.10
        "^10\\.11(\\.[[:digit:]]+)?$",           // OS X El Capitan       10.11
        "^10\\.12(\\.[[:digit:]]+)?$",           // macOS Sierra          10.12
        "^10\\.13(\\.[[:digit:]]+)?$",           // macOS High Sierra     10.13
        "^10\\.14(\\.[[:digit:]]+)?$",           // macOS Mojave          10.14
        "^10\\.15(\\.[[:digit:]]+)?$",           // macOS Catalina        10.15
        "^11\\.[[:digit:]]+(\\.[[:digit:]]+)?$", // macOS Big Sur         11
        "^12\\.[[:digit:]]+(\\.[[:digit:]]+)?$", // macOS Monterey        12
        "^13\\.[[:digit:]]+(\\.[[:digit:]]+)?$", // macOS Ventura         13
        "^14\\.[[:digit:]]+(\\.[[:digit:]]+)?$", // macOS Sonoma          14
        "^15\\.[[:digit:]]+(\\.[[:digit:]]+)?$", // macOS Sequoia         15
        "^26\\.[[:digit:]]+(\\.[[:digit:]]+)?$"  // macOS Tahoe           26
    ]
    
    static let supportedInstallerNames = [
        "Install Mac OS X Lion",
        "Install OS X Mountain Lion",
        "Install OS X Mavericks",
        "Install OS X Yosemite",
        "Install OS X El Capitan",
        "Install macOS Sierra",
        "Install macOS High Sierra",
        "Install macOS Mojave",
        "Install macOS Catalina",
        "Install macOS Big Sur",
        "Install macOS Monterey",
        "Install macOS Ventura",
        "Install macOS Sonoma",
        "Install macOS Sequoia",
        "Install macOS Tahoe"
    ]
}

// MARK: - Global State

class Configuration {
    var installerPath: String = ""
    var outputDirectory: String = ""
    var isoName: String = ""
    var patchSierra: Bool = false
    var replaceSignatures: Bool = false
    var installerDisplayName: String = ""
    var installerType: InstallerType = .unknown
    var debugMode: Bool = false
}

let config = Configuration()

// MARK: - Installer Types

enum InstallerType: Int {
    case unknown = 0
    case lionMountainLion = 1
    case mavericksElCapitan = 2
    case sierraCatalina = 3
    case bigSurAndLater = 4
    
    var description: String {
        switch self {
        case .unknown: return "Unknown"
        case .lionMountainLion: return "Lion/Mountain Lion (10.7-10.8)"
        case .mavericksElCapitan: return "Mavericks/Yosemite/El Capitan (10.9-10.11)"
        case .sierraCatalina: return "Sierra through Catalina (10.12-10.15)"
        case .bigSurAndLater: return "Big Sur and later (11+)"
        }
    }
    
    var requiresRoot: Bool {
        return self == .sierraCatalina || self == .bigSurAndLater
    }
}

// MARK: - Helper Functions

func getRealUserHomeDirectory() -> String {
    // When running with sudo, get the actual user's home directory
    if let sudoUser = ProcessInfo.processInfo.environment["SUDO_USER"] {
        let pw = getpwnam(sudoUser)
        if let homeDir = pw?.pointee.pw_dir {
            return String(cString: homeDir)
        }
    }
    return FileManager.default.homeDirectoryForCurrentUser.path
}

// MARK: - UI Utilities

class UI {
    static func clearScreen() {
        print("\u{001B}[2J\u{001B}[H", terminator: "")
    }
    
    static func printHeader() {
        clearScreen()
        print("""
        ╔════════════════════════════════════════════════════════════════════╗
        ║                     createinstalliso v\(Constants.scriptVersion)                     ║
        ║              Create Bootable macOS ISO Images                      ║
        ╚════════════════════════════════════════════════════════════════════╝
        
        """)
    }
    
    static func printSeparator() {
        print("────────────────────────────────────────────────────────────────────")
    }
    
    static func printError(_ message: String) {
        print("❌ Error: \(message)")
    }
    
    static func printSuccess(_ message: String) {
        print("✅ \(message)")
    }
    
    static func printInfo(_ message: String) {
        print("ℹ️  \(message)")
    }
    
    static func printWarning(_ message: String) {
        print("⚠️  Warning: \(message)")
    }
    
    static func readLine(prompt: String) -> String {
        print(prompt, terminator: "")
        return Swift.readLine() ?? ""
    }
    
    static func readYesNo(prompt: String, defaultYes: Bool = false) -> Bool {
        let suffix = defaultYes ? " [Y/n]: " : " [y/N]: "
        let input = readLine(prompt: prompt + suffix).lowercased()
        
        if input.isEmpty {
            return defaultYes
        }
        return input.hasPrefix("y")
    }
    
    static func pressEnterToContinue() {
        print("\nPress Enter to continue...", terminator: "")
        _ = Swift.readLine()
    }
}

// MARK: - System Utilities

func executeCommand(_ command: String, arguments: [String] = []) -> (output: String, exitCode: Int32) {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: command)
    task.arguments = arguments
    
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    
    do {
        try task.run()
        task.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        return (output, task.terminationStatus)
    } catch {
        return ("", -1)
    }
}

func getCurrentMacOSVersion() -> String? {
    let result = executeCommand("/usr/bin/sw_vers", arguments: ["-productVersion"])
    guard result.exitCode == 0 else { return nil }
    return result.output.trimmingCharacters(in: .whitespacesAndNewlines)
}

func isRoot() -> Bool {
    return getuid() == Constants.rootUserId
}

func directoryExists(_ path: String) -> Bool {
    var isDirectory: ObjCBool = false
    let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
    return exists && isDirectory.boolValue
}

func fileExists(_ path: String) -> Bool {
    return FileManager.default.fileExists(atPath: path)
}

func getPlistValue(key: String, plistPath: String) -> String? {
    let result = executeCommand("/usr/libexec/PlistBuddy",
                               arguments: ["-c", "Print \(key)", plistPath])
    guard result.exitCode == 0 else { return nil }
    return result.output.trimmingCharacters(in: .whitespacesAndNewlines)
}

func expandTilde(_ path: String) -> String {
    return NSString(string: path).expandingTildeInPath
}

func isDiskExternalOrRemovable(diskIdentifier: String) -> Bool {
    // Use diskutil info to check if disk is external or removable
    let result = executeCommand("/usr/sbin/diskutil", arguments: ["info", diskIdentifier])
    
    guard result.exitCode == 0 else {
        return false
    }
    
    let output = result.output.lowercased()
    
    // Check for external or removable indicators
    // Looking for "removable media: yes" or "protocol: usb" or "external: yes"
    if output.contains("removable media: yes") {
        return true
    }
    
    if output.contains("protocol: usb") || output.contains("protocol: thunderbolt") {
        return true
    }
    
    // Check for "device location: external"
    if output.contains("device location: external") {
        return true
    }
    
    // Check if device is not internal
    if output.contains("internal: no") {
        return true
    }
    
    return false
}

// MARK: - Installer Detection

func getInstallerApplicationDisplayName(_ installerPath: String) -> String? {
    let infoPlistPath = "\(installerPath)/Contents/Info.plist"
    return getPlistValue(key: ":CFBundleDisplayName", plistPath: infoPlistPath)
}

func getInstallerType(_ installerPath: String) -> InstallerType {
    let sharedSupportPath = "\(installerPath)/Contents/SharedSupport"
    let createInstallMediaPath = "\(installerPath)/Contents/Resources/createinstallmedia"
    let installInfoPlistPath = "\(installerPath)/Contents/SharedSupport/InstallInfo.plist"
    let sharedSupportDMGPath = "\(installerPath)/Contents/SharedSupport/SharedSupport.dmg"
    
    guard directoryExists(sharedSupportPath) else {
        return .unknown
    }
    
    if fileExists(createInstallMediaPath) {
        if fileExists(installInfoPlistPath) {
            return .sierraCatalina
        } else if fileExists(sharedSupportDMGPath) {
            return .bigSurAndLater
        } else {
            return .mavericksElCapitan
        }
    } else {
        return .lionMountainLion
    }
}

func findInstallerApplications() -> [(path: String, name: String)] {
    var installers: [(String, String)] = []
    let applicationsPath = "/Applications"
    
    do {
        let contents = try FileManager.default.contentsOfDirectory(atPath: applicationsPath)
        for item in contents {
            let fullPath = "\(applicationsPath)/\(item)"
            if item.hasPrefix("Install") && item.hasSuffix(".app") {
                if let displayName = getInstallerApplicationDisplayName(fullPath) {
                    if Constants.supportedInstallerNames.contains(displayName) {
                        installers.append((fullPath, displayName))
                    }
                }
            }
        }
    } catch {
        // Ignore errors
    }
    
    return installers.sorted(by: { $0.1 < $1.1 })
}

// MARK: - Menu Functions

func showMainMenu() {
    UI.printHeader()
    
    print("Current Configuration:")
    UI.printSeparator()
    if config.installerPath.isEmpty {
        print("1. Select Installer Application: [Not Selected]")
    } else {
        print("1. Select Installer Application: ✓")
        print("   → \(config.installerDisplayName)")
        print("   → Type: \(config.installerType.description)")
    }
    
    if config.outputDirectory.isEmpty {
        print("2. Select Output Directory: [Not Selected]")
    } else {
        print("2. Select Output Directory: ✓")
        print("   → \(config.outputDirectory)")
    }
    
    if config.isoName.isEmpty {
        print("3. Set ISO Name: [Auto-generate]")
    } else {
        print("3. Set ISO Name: ✓")
        print("   → \(config.isoName)")
    }
    
    UI.printSeparator()
    print("\nOptions:")
    print("4. [\(config.patchSierra ? "✓" : " ")] Patch macOS Sierra Installer (version 12.6.06)")
    print("5. [\(config.replaceSignatures ? "✓" : " ")] Replace Code Signatures")
    
    UI.printSeparator()
    print("\nActions:")
    print("6. Create ISO Image")
    print("7. Write ISO to USB Drive")
    print("8. View System Information")
    print("9. Help")
    print("0. Exit")
    
    UI.printSeparator()
    print()
}

func selectInstallerApplication() {
    UI.printHeader()
    print("Select Installer Application\n")
    
    let installers = findInstallerApplications()
    
    if !installers.isEmpty {
        print("Found installer applications:")
        UI.printSeparator()
        for (index, installer) in installers.enumerated() {
            print("\(index + 1). \(installer.name)")
        }
        print("0. Enter custom path")
        UI.printSeparator()
        print()
        
        let choice = UI.readLine(prompt: "Select option (0-\(installers.count)): ")
        
        if let number = Int(choice) {
            if number == 0 {
                selectCustomInstallerPath()
            } else if number > 0 && number <= installers.count {
                let selected = installers[number - 1]
                config.installerPath = selected.path
                config.installerDisplayName = selected.name
                config.installerType = getInstallerType(selected.path)
                UI.printSuccess("Selected: \(selected.name)")
                UI.pressEnterToContinue()
            }
        }
    } else {
        UI.printInfo("No installer applications found in /Applications")
        print("\nWould you like to enter a custom path?")
        if UI.readYesNo(prompt: "Enter custom path?", defaultYes: true) {
            selectCustomInstallerPath()
        }
    }
}

func selectCustomInstallerPath() {
    print("\nEnter the full path to the installer application:")
    print("(e.g., /Applications/Install macOS Sonoma.app)")
    var path = UI.readLine(prompt: "Path: ")
    
    // Expand tilde
    path = expandTilde(path)
    
    // Remove trailing quotes if present
    path = path.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
    
    if directoryExists(path) {
        if let displayName = getInstallerApplicationDisplayName(path) {
            config.installerPath = path
            config.installerDisplayName = displayName
            config.installerType = getInstallerType(path)
            UI.printSuccess("Selected: \(displayName)")
        } else {
            UI.printError("Not a valid macOS installer application")
        }
    } else {
        UI.printError("Path does not exist")
    }
    
    UI.pressEnterToContinue()
}

func selectOutputDirectory() {
    UI.printHeader()
    print("Select Output Directory\n")
    
    print("Common locations:")
    UI.printSeparator()
    let userHome = getRealUserHomeDirectory()
    let desktopPath = (userHome as NSString).appendingPathComponent("Desktop")
    let downloadsPath = (userHome as NSString).appendingPathComponent("Downloads")
    let documentsPath = (userHome as NSString).appendingPathComponent("Documents")
    print("1. Desktop (\(desktopPath))")
    print("2. Downloads (\(downloadsPath))")
    print("3. Documents (\(documentsPath))")
    print("4. Current directory (\(FileManager.default.currentDirectoryPath))")
    print("5. Enter custom path")
    UI.printSeparator()
    print()
    
    let choice = UI.readLine(prompt: "Select option (1-5): ")
    
    switch choice {
    case "1":
        config.outputDirectory = desktopPath
        UI.printSuccess("Output directory set to Desktop")
    case "2":
        config.outputDirectory = downloadsPath
        UI.printSuccess("Output directory set to Downloads")
    case "3":
        config.outputDirectory = documentsPath
        UI.printSuccess("Output directory set to Documents")
    case "4":
        config.outputDirectory = FileManager.default.currentDirectoryPath
        UI.printSuccess("Output directory set to current directory")
    case "5":
        print("\nEnter the full path to the output directory:")
        var path = UI.readLine(prompt: "Path: ")
        path = expandTilde(path)
        path = path.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
        
        if directoryExists(path) {
            config.outputDirectory = path
            UI.printSuccess("Output directory set")
        } else {
            UI.printError("Directory does not exist")
        }
    default:
        UI.printError("Invalid choice")
    }
    
    UI.pressEnterToContinue()
}

func setISOName() {
    UI.printHeader()
    print("Set ISO Name\n")
    
    if config.installerPath.isEmpty {
        UI.printError("Please select an installer application first")
        UI.pressEnterToContinue()
        return
    }
    
    let defaultName = URL(fileURLWithPath: config.installerPath).deletingPathExtension().lastPathComponent
    
    print("Default ISO name: \(defaultName).iso")
    print("\nEnter custom ISO name (without .iso extension)")
    print("Press Enter to use default name")
    print()
    UI.printInfo("Note: The bash script will create the ISO with the default name,")
    print("      then it will be renamed to your custom name if specified.")
    print()
    
    let customName = UI.readLine(prompt: "ISO Name: ")
    
    if customName.isEmpty {
        config.isoName = ""
        UI.printSuccess("Using default name: \(defaultName).iso")
    } else {
        let cleanName = customName.replacingOccurrences(of: ".iso", with: "")
        config.isoName = "\(cleanName).iso"
        UI.printSuccess("ISO will be renamed to: \(config.isoName)")
    }
    
    UI.pressEnterToContinue()
}

func togglePatchSierra() {
    config.patchSierra.toggle()
}

func toggleReplaceSignatures() {
    config.replaceSignatures.toggle()
}

func showSystemInformation() {
    UI.printHeader()
    print("System Information\n")
    UI.printSeparator()
    
    if let version = getCurrentMacOSVersion() {
        print("macOS Version: \(version)")
    }
    
    print("Running as: \(isRoot() ? "root (sudo)" : "regular user")")
    print("Current Directory: \(FileManager.default.currentDirectoryPath)")
    print("Home Directory: \(FileManager.default.homeDirectoryForCurrentUser.path)")
    
    UI.printSeparator()
    print("\nSupported macOS Installers:")
    for name in Constants.supportedInstallerNames {
        print("  • \(name)")
    }
    
    UI.printSeparator()
    UI.pressEnterToContinue()
}

func showHelp() {
    UI.printHeader()
    print("Help\n")
    UI.printSeparator()
    
    print("""
    This interactive tool helps you create bootable ISO images from macOS
    installer applications without typing complex commands.
    
    Steps to create an ISO:
    
    1. Select an installer application from the list or enter a custom path
    2. Choose where to save the ISO file
    3. Optionally customize the ISO name
    4. Enable any special options if needed:
       • Patch Sierra: Fix for defective macOS Sierra 12.6.06 installer
       • Replace Signatures: Re-sign installer components
    5. Press 6 or select "Create ISO Image" to start the process
    
    Requirements:
    • Valid macOS installer application
    • Sufficient disk space (varies by installer)
    • Root privileges (sudo) for newer installers (10.12+)
    
    Supported Versions:
    • Mac OS X Lion through macOS Tahoe (10.7 - 26)
    
    Note: This is a Swift implementation. For full functionality, some
    features may need completion. Refer to the original bash script for
    complete ISO creation capabilities.
    """)
    
    UI.printSeparator()
    UI.pressEnterToContinue()
}

func createISO() {
    UI.printHeader()
    print("Create ISO Image\n")
    
    // Validate configuration
    var errors: [String] = []
    
    if config.installerPath.isEmpty {
        errors.append("No installer application selected")
    }
    
    if config.outputDirectory.isEmpty {
        errors.append("No output directory selected")
    }
    
    if !errors.isEmpty {
        UI.printError("Cannot create ISO:")
        for error in errors {
            print("  • \(error)")
        }
        UI.pressEnterToContinue()
        return
    }
    
    // Show summary
    UI.printSeparator()
    print("Configuration Summary:")
    print("  Installer: \(config.installerDisplayName)")
    print("  Type: \(config.installerType.description)")
    print("  Output: \(config.outputDirectory)")
    print("  ISO Name: \(config.isoName.isEmpty ? "[Auto-generate]" : config.isoName)")
    if config.patchSierra {
        print("  Options: Patch Sierra")
    }
    if config.replaceSignatures {
        print("  Options: Replace Signatures")
    }
    UI.printSeparator()
    
    // Check root requirement
    if config.installerType.requiresRoot && !isRoot() {
        print()
        UI.printWarning("This installer type requires root privileges")
        print("Please run this script with sudo:")
        print("  sudo ./createinstalliso-interactive")
        UI.pressEnterToContinue()
        return
    }
    
    print()
    if !UI.readYesNo(prompt: "Proceed with ISO creation?", defaultYes: true) {
        print("Cancelled")
        UI.pressEnterToContinue()
        return
    }
    
    print()
    UI.printInfo("Starting ISO creation process...")
    print()
    
    // Get the directory where this executable is located
    let executablePath = CommandLine.arguments[0]
    let executableURL = URL(fileURLWithPath: executablePath)
    let scriptDirectory = executableURL.deletingLastPathComponent().path
    let bashScriptPath = "\(scriptDirectory)/createinstalliso"
    
    // Check if bash script exists
    if !FileManager.default.fileExists(atPath: bashScriptPath) {
        UI.printError("Cannot find createinstalliso bash script at: \(bashScriptPath)")
        print()
        UI.pressEnterToContinue()
        return
    }
    
    // Note: The bash script auto-generates the ISO name based on installer name
    // If user specified a custom name, we'll rename the ISO after creation
    
    print()
    print("Launching ISO creation in bash...")
    print()
    
    // Execute bash script directly - the Terminal already has proper sudo
    // Build command with options
    var scriptArgs = [
        "--isodirectory", config.outputDirectory,
        "--applicationpath", config.installerPath,
        "--nointeraction"
    ]
    
    // Add optional flags
    if config.patchSierra {
        scriptArgs.append("--patchsierrainstaller")
    }
    if config.replaceSignatures {
        scriptArgs.append("--replacecodesignatures")
    }
    
    let scriptCommand = ([bashScriptPath] + scriptArgs).map { "\"\($0)\"" }.joined(separator: " ")
    
    if config.debugMode {
        print("[DEBUG] Script path: \(bashScriptPath)")
        print("[DEBUG] ISO directory: \(config.outputDirectory)")
        print("[DEBUG] Application path: \(config.installerPath)")
        print("[DEBUG] Full command: \(scriptCommand)")
        print("[DEBUG] Current directory: \(scriptDirectory)")
        print()
    }
    
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/bin/bash")
    task.arguments = ["-c", scriptCommand]
    task.currentDirectoryURL = URL(fileURLWithPath: scriptDirectory)
    task.environment = ProcessInfo.processInfo.environment
    
    // Set up proper I/O to prevent process suspension
    task.standardInput = FileHandle.standardInput
    task.standardOutput = FileHandle.standardOutput
    task.standardError = FileHandle.standardError
    
    if config.debugMode {
        print("[DEBUG] Starting process...")
    }
    
    do {
        try task.run()
        
        if config.debugMode {
            print("[DEBUG] Process launched with PID: \(task.processIdentifier)")
            print("[DEBUG] Waiting for process to complete...")
            print()
        }
        
        task.waitUntilExit()
        
        if config.debugMode {
            print()
            print("[DEBUG] Process completed with status: \(task.terminationStatus)")
        }
        
        print()
        if task.terminationStatus == 0 {
            UI.printSuccess("ISO creation completed successfully!")
            
            // Rename ISO if custom name was specified
            if !config.isoName.isEmpty {
                let defaultName = URL(fileURLWithPath: config.installerPath).deletingPathExtension().lastPathComponent
                let defaultISOPath = "\(config.outputDirectory)/\(defaultName).iso"
                let customISOPath = "\(config.outputDirectory)/\(config.isoName)"
                
                if fileExists(defaultISOPath) && defaultISOPath != customISOPath {
                    do {
                        try FileManager.default.moveItem(atPath: defaultISOPath, toPath: customISOPath)
                        print("ISO renamed to: \(config.isoName)")
                    } catch {
                        UI.printWarning("Could not rename ISO: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            UI.printError("ISO creation failed with exit code \(task.terminationStatus)")
        }
    } catch {
        UI.printError("Failed to execute createinstalliso script: \(error)")
    }
    
    print()
    UI.pressEnterToContinue()
}

// MARK: - Write ISO to USB

func writeISOToUSB() {
    UI.printHeader()
    print("Write ISO to USB Drive\n")
    
    // Check for root privileges first
    if !isRoot() {
        UI.printWarning("This feature requires root privileges")
        print("Please run this script with sudo:")
        print("  sudo ./createinstalliso-interactive")
        print()
        UI.pressEnterToContinue()
        return
    }
    
    // Search for ISO files in common locations
    var searchDirectories: [String] = []
    
    if !config.outputDirectory.isEmpty {
        searchDirectories.append(config.outputDirectory)
    }
    
    // Get the real user's home directory (even when running as sudo)
    let homeDir = getRealUserHomeDirectory()
    
    searchDirectories.append(contentsOf: [
        "\(homeDir)/Downloads",
        "\(homeDir)/Desktop",
        "\(homeDir)/Documents"
    ])
    
    // Remove duplicates
    searchDirectories = Array(Set(searchDirectories))
    
    // Find all ISO files
    var isoFileMap: [(path: String, file: String)] = []
    
    for dir in searchDirectories {
        guard directoryExists(dir) else { continue }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: dir)
            let isos = files.filter { $0.hasSuffix(".iso") }
            
            for iso in isos {
                isoFileMap.append((path: dir, file: iso))
            }
        } catch {
            // Skip directories we can't read
            continue
        }
    }
    
    // Display found ISO files
    print("Available ISO files:")
    UI.printSeparator()
    
    if isoFileMap.isEmpty {
        print("No ISO files found in common locations.")
        print("\nSearched directories:")
        for dir in searchDirectories.prefix(3) {
            print("  • \(dir)")
        }
        print("\nYou can enter a custom path to an ISO file.")
        print()
    } else {
        for (index, item) in isoFileMap.enumerated() {
            let fullPath = "\(item.path)/\(item.file)"
            if let attrs = try? FileManager.default.attributesOfItem(atPath: fullPath),
               let size = attrs[.size] as? UInt64 {
                let sizeGB = Double(size) / 1_073_741_824.0
                print("\(index + 1). \(item.file) (\(String(format: "%.1f", sizeGB)) GB)")
                print("   \(item.path)")
            } else {
                print("\(index + 1). \(item.file)")
                print("   \(item.path)")
            }
        }
    }
    
    print("0. Enter custom path")
    UI.printSeparator()
    print()
    
    let choice = UI.readLine(prompt: "Select ISO file: ")
    
    var isoPath = ""
    if let index = Int(choice), index > 0, index <= isoFileMap.count {
        let item = isoFileMap[index - 1]
        isoPath = "\(item.path)/\(item.file)"
    } else if choice == "0" {
        let customPath = UI.readLine(prompt: "Enter ISO file path: ")
        isoPath = expandTilde(customPath)
    } else {
        UI.printError("Invalid choice.")
        print()
        UI.pressEnterToContinue()
        return
    }
    
    guard fileExists(isoPath) else {
        UI.printError("ISO file not found: \(isoPath)")
        print()
        UI.pressEnterToContinue()
        return
    }
    
    print()
    print("Selected ISO: \(isoPath)")
    print()
    
    // List available disks
    print("Scanning for USB drives...")
    let result = executeCommand("/usr/sbin/diskutil", arguments: ["list"])
    
    if result.exitCode != 0 {
        UI.printError("Failed to list disks")
        print()
        UI.pressEnterToContinue()
        return
    }
    
    print()
    print("Available disks:")
    UI.printSeparator()
    print(result.output)
    UI.printSeparator()
    print()
    
    UI.printWarning("⚠️  WARNING: This will ERASE ALL DATA on the selected disk!")
    print()
    
    let diskChoice = UI.readLine(prompt: "Enter disk identifier (e.g., disk2) or 'cancel': ")
    
    if diskChoice.lowercased() == "cancel" || diskChoice.isEmpty {
        print("Operation cancelled.")
        print()
        UI.pressEnterToContinue()
        return
    }
    
    // Validate disk identifier
    guard let diskRegex = try? NSRegularExpression(pattern: "^disk[0-9]+$", options: []) else {
        UI.printError("Internal error: Failed to compile disk identifier regex.")
        print()
        UI.pressEnterToContinue()
        return
    }
    let range = NSRange(location: 0, length: diskChoice.utf16.count)
    guard diskRegex.firstMatch(in: diskChoice, options: [], range: range) != nil else {
        UI.printError("Invalid disk identifier. Must match format 'disk' followed by digits (e.g., disk2)")
        print()
        UI.pressEnterToContinue()
        return
    }
    if diskChoice == "disk0" {
        UI.printError("Refusing to write to disk0 (system disk). Please choose an external/removable disk.")
        print()
        UI.pressEnterToContinue()
        return
    }
    
    // Check if the selected disk is external/removable
    if !isDiskExternalOrRemovable(diskIdentifier: diskChoice) {
        UI.printError("Refusing to write to /dev/\(diskChoice) because it is not detected as external or removable. Please choose an external/removable disk.")
        print()
        UI.pressEnterToContinue()
        return
    }
    
    print()
    print("You are about to write:")
    print("  ISO: \(isoPath)")
    print("  To:  /dev/\(diskChoice)")
    print()
    UI.printWarning("⚠️  This will PERMANENTLY ERASE ALL DATA on /dev/\(diskChoice)!")
    print()
    
    let confirm = UI.readLine(prompt: "Type 'YES' to proceed: ")
    
    if confirm != "YES" {
        print("Operation cancelled.")
        print()
        UI.pressEnterToContinue()
        return
    }
    
    print()
    UI.printInfo("Starting USB creation process...")
    print()
    
    // Unmount the disk
    print("Unmounting disk...")
    let unmountResult = executeCommand("/usr/sbin/diskutil", arguments: ["unmountDisk", "/dev/\(diskChoice)"])
    if unmountResult.exitCode != 0 {
        UI.printError("Failed to unmount disk: \(unmountResult.output)")
        print()
        UI.pressEnterToContinue()
        return
    }
    
    // Write ISO to disk using dd
    print("Writing ISO to USB drive (this may take several minutes)...")
    print("Please wait...")
    print()
    
    // Use BSD dd without GNU-specific status=progress option
    // Already running as root, no need for sudo
    
    
    if config.debugMode {
        print("[DEBUG] Command: dd if=\"\(isoPath)\" of=/dev/r\(diskChoice) bs=1m")
        print("[DEBUG] Running as root: \(isRoot())")
        print()
    }
    
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/bin/dd")
    task.arguments = [
        "if=\(isoPath)",
        "of=/dev/r\(diskChoice)",
        "bs=1m"
    ]
    task.standardInput = FileHandle.standardInput
    task.standardOutput = FileHandle.standardOutput
    task.standardError = FileHandle.standardError
    
    do {
        try task.run()
        task.waitUntilExit()
        
        print()
        if task.terminationStatus == 0 {
            print("Ejecting disk...")
            _ = executeCommand("/usr/sbin/diskutil", arguments: ["eject", "/dev/\(diskChoice)"])
            print()
            UI.printSuccess("USB installer created successfully!")
            print("You can now safely remove the USB drive.")
        } else {
            UI.printError("Failed to write ISO to USB (exit code: \(task.terminationStatus))")
        }
    } catch {
        UI.printError("Failed to execute dd command: \(error)")
    }
    
    print()
    UI.pressEnterToContinue()
}

// MARK: - Main Program

func main() {
    // Parse command-line arguments
    let arguments = CommandLine.arguments
    if arguments.contains("--debug") || arguments.contains("-d") {
        config.debugMode = true
        print("[DEBUG MODE ENABLED]")
        print()
    }
    
    // Check if running on macOS
    let result = executeCommand("/usr/bin/uname", arguments: ["-s"])
    if result.output.trimmingCharacters(in: .whitespacesAndNewlines) != "Darwin" {
        print("Error: This script must be run on macOS")
        exit(1)
    }
    
    var running = true
    
    while running {
        showMainMenu()
        let choice = UI.readLine(prompt: "Select option (0-9): ")
        
        switch choice {
        case "1":
            selectInstallerApplication()
        case "2":
            selectOutputDirectory()
        case "3":
            setISOName()
        case "4":
            togglePatchSierra()
        case "5":
            toggleReplaceSignatures()
        case "6":
            createISO()
        case "7":
            writeISOToUSB()
        case "8":
            showSystemInformation()
        case "9":
            showHelp()
        case "0":
            UI.printHeader()
            print("Thank you for using createinstalliso!")
            print("Goodbye! 👋\n")
            running = false
        default:
            UI.printError("Invalid choice. Please select 0-9.")
            UI.pressEnterToContinue()
        }
    }
}

main()
